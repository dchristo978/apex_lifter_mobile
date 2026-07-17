import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// A real-time anatomical figure, rendered from a procedural triangle mesh —
/// no image assets, no plugins.
///
/// The body is built once as ~60 000 vertices / ~119 000 triangles (the
/// practical ceiling: [Canvas.drawVertices] indexes vertices with Uint16, so
/// one call can address at most 65 536). Every part is a generalized cylinder
/// whose surface is sculpted by parametric [_Patch]es — one per muscle belly —
/// that bulge the mesh outward and carve the separation lines an anatomy chart
/// lives by.
///
/// The realistic "chart" look comes from three things working together:
///  - smooth muscle **bellies** (each patch is a soft raised band),
///  - crisp, narrow **separation grooves** between bellies (the dark lines:
///    sternum, linea alba, tendinous inscriptions, the split between quad and
///    hamstring heads), carved both around the part ([_Patch.grooves]) and
///    along it ([_Patch.tGrooves]), and
///  - baked **cavity ambient occlusion** that darkens exactly those grooves,
///    normalized by local edge length so it reads true surface curvature at any
///    tessellation density.
///
/// Every frame the mesh is rotated by [yaw] about the vertical axis,
/// perspective-projected, back-face culled, depth-ordered with an O(n) counting
/// sort into reusable buffers, and drawn with a single [Canvas.drawVertices]
/// call — cheap enough to follow a drag gesture.
///
/// Muscle groups trained in the window are tinted blue by [intensity]
/// (light → deep). Group names match the backend's `muscle_group` values.
class MuscleBody extends StatelessWidget {
  const MuscleBody({
    super.key,
    this.yaw = 0,
    this.activeGroups = const {},
    this.intensity = const {},
  });

  /// Rotation around the vertical axis in radians; 0 faces the viewer.
  final double yaw;

  /// Muscle groups trained in the window — these get the blue treatment.
  final Set<String> activeGroups;

  /// Group name → 0..1 intensity, controlling how deep the blue is.
  final Map<String, double> intensity;

  static const double _designW = 200;
  static const double _designH = 440;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: _designW / _designH,
      child: CustomPaint(
        painter: MuscleBodyPainter(
          yaw: yaw,
          activeGroups: activeGroups,
          intensity: intensity,
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}

/// A muscle patch on a body part's surface: a smooth raised band in (t, θ)
/// space that owns the muscle's tint and can carve separation grooves.
///
/// t runs 0→1 down the part; θ ∈ (−π, π] around it with 0 facing the viewer.
/// The band spans [t0..t1] (fading over [tf]) and angular half-width [aHalf]
/// around [aCenter] (fading over [af]) — matched mirror-symmetrically about the
/// front meridian, so one definition covers both pecs / both quads.
///
/// [grooves] are longitudinal creases at fixed angles (sternum, the gap
/// between muscle heads); [tGrooves] are transverse creases at fixed t
/// (tendinous inscriptions of the six-pack, the knee line). Grooves cut only
/// the *geometry* — the flat tint stays continuous, so a muscle reads as one
/// solid belly whose separations darken through ambient occlusion, exactly like
/// a printed anatomy chart. A patch with negative [bulge] and no [groups] is a
/// pure crease (under-pec line, gluteal fold).
class _Patch {
  const _Patch(
    this.groups, {
    required this.t0,
    required this.t1,
    this.tf = 0.05,
    this.aCenter = 0,
    required this.aHalf,
    this.af = 0.28,
    required this.bulge,
    this.grooves = const [],
    this.tGrooves = const [],
    this.mod,
  });

  final List<String> groups;
  final double t0, t1, tf;
  final double aCenter, aHalf, af;
  final double bulge;
  final List<(double, double, double)> grooves; // (center θ, sigma, depth)
  final List<(double, double, double)> tGrooves; // (center t, sigma, depth)
  final double Function(double t, double th)? mod;

  /// The smooth band weight only (no grooves) — drives the tint, so the muscle
  /// is one flat colour and the grooves show up as shaded lines, not gaps.
  double bandWeight(double t, double th) {
    final wT = _band(t, t0, t1, tf);
    if (wT == 0) return 0;
    final d = math.min(
        _wrapAbs(th - aCenter), _wrapAbs(th + aCenter)); // mirror symmetric
    return wT * _band(d, 0, aHalf, af);
  }

  /// The full sculpt weight (band × grooves × ripples) — drives geometry.
  double weight(double t, double th) {
    var w = bandWeight(t, th);
    if (w == 0) return 0;
    for (final g in grooves) {
      final gd = _wrapAbs(th - g.$1);
      w *= 1 - g.$3 * math.exp(-(gd * gd) / (2 * g.$2 * g.$2));
    }
    for (final g in tGrooves) {
      final td = t - g.$1;
      w *= 1 - g.$3 * math.exp(-(td * td) / (2 * g.$2 * g.$2));
    }
    if (mod != null) w *= mod!(t, th);
    return w.clamp(0.0, 1.4);
  }

  static double _band(double v, double lo, double hi, double f) {
    if (v < lo - f || v > hi + f) return 0;
    if (v < lo) return (v - (lo - f)) / f;
    if (v > hi) return ((hi + f) - v) / f;
    return 1;
  }

  static double _wrapAbs(double a) {
    a = a % (2 * math.pi);
    if (a < 0) a += 2 * math.pi;
    return a > math.pi ? 2 * math.pi - a : a;
  }
}

/// The immutable rest-pose mesh: positions, smooth normals, baked cavity
/// occlusion, per-vertex muscle ownership and the triangle index list.
class _Mesh {
  _Mesh(this.pos, this.normal, this.ao, this.setId, this.setWeight, this.tris,
      this.faceBias, this.groupSets);
  final Float32List pos; // x,y,z triples
  final Float32List normal; // matching triples
  final Float32List ao; // cavity AO: <1 in grooves, ~1 on open surface
  final Int16List setId; // index into groupSets, -1 = plain skin
  final Float32List setWeight;
  final Uint16List tris;
  final Float32List faceBias; // per-face depth-sort bias (grazing parts)
  final List<List<String>> groupSets;

  int get vertexCount => pos.length ~/ 3;
}

/// Public snapshot of the rest-pose geometry, used by the offline GLB exporter
/// (tool/export_muscle_glb) so the shipped 3D model is the exact same body the
/// [CustomPaint] path draws.
class MuscleMeshExport {
  MuscleMeshExport(this.positions, this.normals, this.groupOfVertex,
      this.triangles, this.groupNames);

  /// x,y,z triples in the 200×440 design space.
  final Float32List positions;
  final Float32List normals;

  /// Per-vertex muscle set: -1 for plain skin, else an index into [groupNames].
  final Int16List groupOfVertex;
  final Uint16List triangles;

  /// Each entry is the list of backend `muscle_group` names a set covers
  /// (e.g. `['Quadriceps','Adductors']`).
  final List<List<String>> groupNames;
}

class MuscleBodyPainter extends CustomPainter {
  MuscleBodyPainter({
    required this.yaw,
    required this.activeGroups,
    required this.intensity,
  });

  final double yaw;
  final Set<String> activeGroups;
  final Map<String, double> intensity;

  // Base body tone (anatomy-chart steel gray) and the untrained muscle tone.
  static const Color _skin = Color(0xFFCED3DC);
  static const Color _muscle = Color(0xFFAEB5C1);
  // Trained muscles ramp from light blue (barely worked) to deep blue.
  static const Color _blueLow = Color(0xFF6FA8FF);
  static const Color _blueHigh = Color(0xFF083A96);

  static final _Mesh _mesh = _buildMesh();

  /// Geometry snapshot for the offline GLB exporter.
  static MuscleMeshExport exportMesh() {
    final m = _buildMesh();
    return MuscleMeshExport(m.pos, m.normal, m.setId, m.tris, m.groupSets);
  }

  // Reusable per-frame scratch buffers (the mesh is a static singleton).
  static Float32List? _sPos2;
  static Float32List? _sDepth;
  static Int32List? _sColors;
  static Int32List? _sFaceBucket;
  static Uint16List? _sIndices;
  static const int _nBuckets = 2048;
  static final Int32List _bucketCount = Int32List(_nBuckets);
  static final Int32List _bucketStart = Int32List(_nBuckets);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(
        size.width / MuscleBody._designW, size.height / MuscleBody._designH);

    final mesh = _mesh;
    final n = mesh.vertexCount;
    final nFaces = mesh.tris.length ~/ 3;
    final pos2 = _sPos2 ??= Float32List(n * 2);
    final depth = _sDepth ??= Float32List(n);
    final colors = _sColors ??= Int32List(n);
    final faceBucket = _sFaceBucket ??= Int32List(nFaces);
    final indices = _sIndices ??= Uint16List(mesh.tris.length);

    final cosY = math.cos(yaw);
    final sinY = math.sin(yaw);

    // World-fixed key light (up-left, in front) + a soft fill from the right.
    // The body rotates under them, so shading sweeps around as it turns.
    const l1x = -0.40, l1y = -0.52, l1z = 0.76;
    const l2x = 0.66, l2y = -0.10, l2z = 0.74;
    // Half-vector of the key light for specular.
    const hx = -0.22, hy = -0.30, hz = 0.93;

    // Resolve each group set's tint once.
    final setColors = List<Color?>.filled(mesh.groupSets.length, null);
    for (var s = 0; s < mesh.groupSets.length; s++) {
      double best = 0;
      var active = false;
      for (final g in mesh.groupSets[s]) {
        if (activeGroups.contains(g)) {
          active = true;
          final i = intensity[g] ?? 0.6;
          if (i > best) best = i;
        }
      }
      setColors[s] = active
          ? Color.lerp(_blueLow, _blueHigh, best.clamp(0.15, 1.0))!
          : null;
    }

    const focal = 900.0;
    final mPos = mesh.pos;
    final mNormal = mesh.normal;
    final mAo = mesh.ao;
    final mSetId = mesh.setId;
    final mSetW = mesh.setWeight;
    var zMin = double.infinity;
    var zMax = double.negativeInfinity;

    for (var i = 0; i < n; i++) {
      final px = mPos[i * 3] - 100;
      final py = mPos[i * 3 + 1];
      final pz = mPos[i * 3 + 2];
      // Rotate about the vertical axis, then perspective-project.
      final rx = px * cosY + pz * sinY;
      final rz = -px * sinY + pz * cosY;
      final p = focal / (focal - rz);
      pos2[i * 2] = 100 + rx * p;
      pos2[i * 2 + 1] = 232 + (py - 232) * p;
      depth[i] = rz;
      if (rz < zMin) zMin = rz;
      if (rz > zMax) zMax = rz;

      // Rotate the rest normal the same way.
      final nx0 = mNormal[i * 3];
      final ny = mNormal[i * 3 + 1];
      final nz0 = mNormal[i * 3 + 2];
      final nx = nx0 * cosY + nz0 * sinY;
      final nz = -nx0 * sinY + nz0 * cosY;

      // Vertex tint: skin → sculpted gray or training blue by patch weight.
      var base = _skin;
      final s = mSetId[i];
      if (s >= 0) {
        final blue = setColors[s];
        final w = mSetW[i];
        // Threshold the tint so colour hugs the belly instead of bleeding
        // across the falloff like clothing.
        base = blue != null
            ? Color.lerp(_skin, blue, ((w - 0.18) * 1.8).clamp(0.0, 1.0))!
            : Color.lerp(_skin, _muscle, (w * 0.95).clamp(0.0, 1.0))!;
      }

      // Key + fill diffuse, cavity-occluded, plus a touch of specular.
      final d1 = math.max(0.0, nx * l1x + ny * l1y + nz * l1z);
      final d2 = math.max(0.0, nx * l2x + ny * l2y + nz * l2z);
      final ao = mAo[i];
      final lum = (0.24 + 0.66 * d1 + 0.14 * d2) * ao;
      final specDot = math.max(0.0, nx * hx + ny * hy + nz * hz);
      final spec = specDot * specDot * specDot * specDot; // ^4
      final sp = spec * spec * spec * 42 * ao; // ≈ ^12
      final r = (base.r * 255 * lum + sp).round().clamp(0, 255);
      final g = (base.g * 255 * lum + sp).round().clamp(0, 255);
      final b = (base.b * 255 * lum + sp).round().clamp(0, 255);
      colors[i] = 0xFF000000 | (r << 16) | (g << 8) | b;
    }

    // Back-face cull via screen winding, then depth-order the kept faces with
    // an O(n) counting sort (far first).
    final tris = mesh.tris;
    final faceBias = mesh.faceBias;
    final invRange = (_nBuckets - 1) / (zMax - zMin + 4);
    _bucketCount.fillRange(0, _nBuckets, 0);
    for (var f = 0; f < nFaces; f++) {
      final a = tris[f * 3], b = tris[f * 3 + 1], c = tris[f * 3 + 2];
      final ax = pos2[a * 2], ay = pos2[a * 2 + 1];
      final area = (pos2[b * 2] - ax) * (pos2[c * 2 + 1] - ay) -
          (pos2[c * 2] - ax) * (pos2[b * 2 + 1] - ay);
      if (area <= 0) {
        faceBucket[f] = -1; // facing away
        continue;
      }
      final z = (depth[a] + depth[b] + depth[c]) / 3 + faceBias[f] - zMin + 2;
      final bucket = (z * invRange).toInt().clamp(0, _nBuckets - 1);
      faceBucket[f] = bucket;
      _bucketCount[bucket]++;
    }
    var offset = 0;
    for (var i = 0; i < _nBuckets; i++) {
      _bucketStart[i] = offset;
      offset += _bucketCount[i];
    }
    final kept = offset;
    for (var f = 0; f < nFaces; f++) {
      final bucket = faceBucket[f];
      if (bucket < 0) continue;
      final slot = _bucketStart[bucket]++ * 3;
      indices[slot] = tris[f * 3];
      indices[slot + 1] = tris[f * 3 + 1];
      indices[slot + 2] = tris[f * 3 + 2];
    }

    canvas.drawVertices(
      ui.Vertices.raw(
        VertexMode.triangles,
        pos2,
        colors: colors,
        indices: Uint16List.sublistView(indices, 0, kept * 3),
      ),
      BlendMode.dst,
      Paint(),
    );

    canvas.restore();
  }

  // ───────────────────────────── mesh construction ─────────────────────────

  static _Mesh _buildMesh() {
    final pos = <double>[];
    final setId = <int>[];
    final setWeight = <double>[];
    final tris = <int>[];
    final faceBias = <double>[];
    final groupSets = <List<String>>[];
    final setIndex = <String, int>{};

    int setOf(List<String> groups) {
      final key = groups.join('|');
      return setIndex.putIfAbsent(key, () {
        groupSets.add(groups);
        return groupSets.length - 1;
      });
    }

    /// Cosine-smoothed profile through (t, value) control points — C1-smooth so
    /// the dense mesh shows no creases at the knots.
    double profile(List<(double, double)> pts, double t) {
      for (var i = 0; i < pts.length - 1; i++) {
        if (t <= pts[i + 1].$1) {
          final u =
              ((t - pts[i].$1) / (pts[i + 1].$1 - pts[i].$1)).clamp(0.0, 1.0);
          final f = (1 - math.cos(math.pi * u)) / 2;
          return pts[i].$2 + (pts[i + 1].$2 - pts[i].$2) * f;
        }
      }
      return pts.last.$2;
    }

    /// A generalized cylinder: rings of [segs] vertices from y0→y1, centre
    /// drifting cx0→cx1 / cz0→cz1, radius from [rPts], flattened front-to-back
    /// by [zRatio], ends rounded over [capTop]/[capBottom], surface displaced by
    /// [patches].
    void tube({
      required double y0,
      required double y1,
      required List<(double, double)> cxPts,
      List<(double, double)> czPts = const [(0, 0), (1, 0)],
      required List<(double, double)> rPts,
      double zRatio = 1,
      required int rings,
      required int segs,
      List<_Patch> patches = const [],
      double capTop = 0.06,
      double capBottom = 0.06,
      double bias = 0,
    }) {
      final base = pos.length ~/ 3;
      for (var i = 0; i <= rings; i++) {
        final t = i / rings;
        var r = profile(rPts, t);
        if (t < capTop) {
          final u = (capTop - t) / capTop;
          r *= math.sqrt(math.max(0.0, 1 - u * u));
        }
        if (t > 1 - capBottom) {
          final u = (t - (1 - capBottom)) / capBottom;
          r *= math.sqrt(math.max(0.0, 1 - u * u));
        }
        final y = y0 + (y1 - y0) * t;
        final cx = profile(cxPts, t);
        final cz = profile(czPts, t);
        for (var j = 0; j < segs; j++) {
          final th = -math.pi + 2 * math.pi * j / segs;
          // Strongest patch owns the vertex's tint (by smooth band weight);
          // the summed sculpt weights displace the surface.
          var disp = 0.0;
          var bestW = 0.0;
          var bestSet = -1;
          for (final p in patches) {
            final wBand = p.bandWeight(t, th);
            if (wBand <= 0) continue;
            disp += p.bulge * p.weight(t, th);
            if (wBand > bestW && p.groups.isNotEmpty) {
              bestW = wBand;
              bestSet = setOf(p.groups);
            }
          }
          pos
            ..add(cx + (r + disp) * math.sin(th))
            ..add(y)
            ..add(cz + (r * zRatio + disp) * math.cos(th));
          setId.add(bestSet);
          setWeight.add(bestW.clamp(0.0, 1.0));
        }
      }
      for (var i = 0; i < rings; i++) {
        for (var j = 0; j < segs; j++) {
          final j1 = (j + 1) % segs;
          final v00 = base + i * segs + j;
          final v01 = base + i * segs + j1;
          final v10 = base + (i + 1) * segs + j;
          final v11 = base + (i + 1) * segs + j1;
          tris.addAll([v00, v11, v10, v00, v01, v11]);
          faceBias.addAll([bias, bias]);
        }
      }
    }

    /// An ellipsoid (head-cap, hands, feet) — poles as degenerate rings.
    void ellipsoid(double cx, double cy, double cz, double rx, double ry,
        double rz, int latN, int segs,
        {double rotY = 0}) {
      final base = pos.length ~/ 3;
      final cosR = math.cos(rotY);
      final sinR = math.sin(rotY);
      for (var i = 0; i <= latN; i++) {
        final phi = -math.pi / 2 + math.pi * i / latN;
        final c = math.cos(phi);
        for (var j = 0; j < segs; j++) {
          final th = -math.pi + 2 * math.pi * j / segs;
          final x0 = rx * c * math.sin(th);
          final z0 = rz * c * math.cos(th);
          pos
            ..add(cx + x0 * cosR + z0 * sinR)
            ..add(cy + ry * math.sin(phi))
            ..add(cz - x0 * sinR + z0 * cosR);
          setId.add(-1);
          setWeight.add(0);
        }
      }
      for (var i = 0; i < latN; i++) {
        for (var j = 0; j < segs; j++) {
          final j1 = (j + 1) % segs;
          final v00 = base + i * segs + j;
          final v01 = base + i * segs + j1;
          final v10 = base + (i + 1) * segs + j;
          final v11 = base + (i + 1) * segs + j1;
          tris.addAll([v00, v11, v10, v00, v01, v11]);
          faceBias.addAll([0, 0]);
        }
      }
    }

    /// Duplicate everything built since [fromVertex]/[fromTri], mirrored across
    /// x = 100 (winding flipped to stay outward).
    void mirror(int fromVertex, int fromTri) {
      final vCount = pos.length ~/ 3 - fromVertex;
      final base = pos.length ~/ 3;
      for (var i = 0; i < vCount; i++) {
        final v = (fromVertex + i) * 3;
        pos
          ..add(200 - pos[v])
          ..add(pos[v + 1])
          ..add(pos[v + 2]);
        setId.add(setId[fromVertex + i]);
        setWeight.add(setWeight[fromVertex + i]);
      }
      final tCount = tris.length - fromTri;
      final fromFace = fromTri ~/ 3;
      for (var i = 0; i < tCount; i += 3) {
        final a = tris[fromTri + i] - fromVertex + base;
        final b = tris[fromTri + i + 1] - fromVertex + base;
        final c = tris[fromTri + i + 2] - fromVertex + base;
        tris.addAll([a, c, b]); // flip winding
        faceBias.add(faceBias[fromFace + i ~/ 3]);
      }
    }

    /// Fine fiber striations across a belly, optionally sheared so the fibers
    /// run diagonally like a lat or pec fan. Kept shallow so it reads as
    /// texture, never as separate blocks.
    double Function(double, double) fibers(double freq, double shear,
        [double depth = 0.06]) {
      return (t, th) => (1 - depth) + depth * math.cos(freq * th + shear * t);
    }

    // Classic heroic proportions on an 8-head canon. Head unit ≈ 55 of the
    // 440-tall design space: crown ~8, chin ~63, shoulders ~96, nipples ~128,
    // navel ~186, crotch ~232, knee ~330, sole ~424. A wide clavicle yoke over
    // a narrow waist gives the V-taper.

    // ── Torso: bodybuilder V-taper with full front & back musculature ───────
    tube(
      y0: 90,
      y1: 236,
      cxPts: const [(0, 100), (1, 100)],
      czPts: const [(0, 3), (0.32, 5), (0.6, 1), (1, -3)],
      rPts: const [
        (0, 33),
        (0.09, 42),
        (0.30, 37),
        (0.58, 25.5),
        (0.80, 28),
        (1, 25),
      ],
      zRatio: 0.60,
      rings: 176,
      segs: 132,
      capTop: 0.07,
      capBottom: 0.12,
      bias: 0.8,
      patches: [
        // Trapezius: sweeps from neck to mid-back, split by the spine.
        _Patch(const ['Traps'],
            t0: 0.0,
            t1: 0.13,
            tf: 0.08,
            aCenter: math.pi,
            aHalf: 1.5,
            af: 0.45,
            bulge: 2.5,
            grooves: const [(math.pi, 0.07, 0.5)]),
        // Pectorals: two full rounded plates. Deep sternal cleft down the
        // middle, a clean lower border, and separation from the delts.
        _Patch(const ['Chest'],
            t0: 0.10,
            t1: 0.30,
            tf: 0.05,
            aHalf: 1.05,
            af: 0.20,
            bulge: 5.6,
            grooves: const [
              (0, 0.075, 0.85), // sternum
              (1.12, 0.10, 0.45), // deltopectoral groove
              (-1.12, 0.10, 0.45),
            ],
            tGrooves: const [(0.30, 0.02, 0.7)], // crisp lower pec border
            mod: fibers(7, 5, 0.05)),
        // Soft shadow crease just under the pecs.
        _Patch(const [],
            t0: 0.31, t1: 0.35, tf: 0.02, aHalf: 0.9, af: 0.22, bulge: -1.0),
        // Rectus abdominis: one smooth column with the linea alba down the
        // centre and three tendinous inscriptions carving the six-pack.
        _Patch(const ['Abdominals'],
            t0: 0.35,
            t1: 0.66,
            tf: 0.04,
            aHalf: 0.32,
            af: 0.13,
            bulge: 3.8,
            grooves: const [(0, 0.055, 0.6)], // linea alba
            tGrooves: const [
              (0.44, 0.014, 0.5),
              (0.52, 0.014, 0.5),
              (0.60, 0.014, 0.45),
            ]),
        // Lower belly below the last inscription, tapering to the pubis.
        _Patch(const ['Abdominals'],
            t0: 0.66,
            t1: 0.80,
            tf: 0.05,
            aHalf: 0.30,
            af: 0.13,
            bulge: 3.0,
            grooves: const [(0, 0.06, 0.5)]),
        // External oblique / serratus interface down the flank.
        _Patch(const ['Abdominals'],
            t0: 0.34,
            t1: 0.74,
            tf: 0.06,
            aCenter: 0.60,
            aHalf: 0.20,
            af: 0.12,
            bulge: 1.7),
        // Serratus fingers under the armpit.
        _Patch(const ['Abdominals'],
            t0: 0.27,
            t1: 0.42,
            tf: 0.04,
            aCenter: 0.95,
            aHalf: 0.17,
            bulge: 1.6,
            mod: (t, th) =>
                0.6 + 0.4 * math.cos(2 * math.pi * (t - 0.27) / 0.05)),
        // Inguinal fold across the front of the pelvis.
        _Patch(const [],
            t0: 0.88, t1: 0.94, tf: 0.03, aHalf: 0.55, af: 0.22, bulge: -0.8),

        // Rhomboid / teres mass between the shoulder blades.
        _Patch(const ['Upper Back'],
            t0: 0.10,
            t1: 0.33,
            tf: 0.06,
            aCenter: math.pi - 0.52,
            aHalf: 0.46,
            af: 0.24,
            bulge: 2.8,
            grooves: const [(2.25, 0.06, 0.35), (-2.25, 0.06, 0.35)]),
        // Latissimus: the wings of the V-taper, diagonal fibers, sweeping in
        // to the waist.
        _Patch(const ['Lats'],
            t0: 0.26,
            t1: 0.64,
            tf: 0.07,
            aCenter: math.pi - 0.62,
            aHalf: 0.52,
            af: 0.22,
            bulge: 3.6,
            grooves: const [(math.pi - 1.2, 0.09, 0.3)],
            mod: fibers(8, 6, 0.08)),
        // Erector spinae columns with a deep spinal channel.
        _Patch(const ['Lower Back'],
            t0: 0.44,
            t1: 0.94,
            tf: 0.06,
            aCenter: math.pi,
            aHalf: 0.30,
            af: 0.12,
            bulge: 2.2,
            grooves: const [
              (math.pi, 0.06, 0.8), // spine
              (math.pi - 0.34, 0.06, 0.32),
              (-(math.pi - 0.34), 0.06, 0.32),
            ]),
      ],
    );

    // ── Neck: sternocleidomastoid ridges in front, traps behind ─────────────
    tube(
      y0: 60,
      y1: 94,
      cxPts: const [(0, 100), (1, 100)],
      czPts: const [(0, 1), (1, 3)],
      rPts: const [(0, 10.5), (1, 16)],
      zRatio: 0.95,
      rings: 24,
      segs: 48,
      capTop: 0,
      capBottom: 0,
      patches: [
        _Patch(const ['Traps'],
            t0: 0.3,
            t1: 1,
            tf: 0.2,
            aCenter: math.pi,
            aHalf: 1.4,
            af: 0.5,
            bulge: 1.6),
        _Patch(const ['Neck'],
            t0: 0.15,
            t1: 0.9,
            tf: 0.15,
            aCenter: 0.42,
            aHalf: 0.16,
            bulge: 1.1),
      ],
    );

    // ── Head: skull → brow → cheekbones → jaw, with a sculpted face ─────────
    tube(
      y0: 8,
      y1: 64,
      cxPts: const [(0, 100), (1, 100)],
      czPts: const [(0, 0), (0.75, 1), (1, 0)],
      rPts: const [
        (0, 9),
        (0.22, 15.5),
        (0.5, 14.8),
        (0.72, 12.5),
        (1, 8),
      ],
      zRatio: 1.1,
      rings: 26,
      segs: 52,
      capTop: 0.26,
      capBottom: 0.2,
      patches: [
        _Patch(const [],
            t0: 0.30, t1: 0.40, tf: 0.04, aHalf: 0.5, af: 0.2, bulge: 1.0),
        _Patch(const [],
            t0: 0.40,
            t1: 0.50,
            tf: 0.03,
            aCenter: 0.45,
            aHalf: 0.13,
            af: 0.08,
            bulge: -1.0),
        _Patch(const [],
            t0: 0.46, t1: 0.64, tf: 0.04, aHalf: 0.11, af: 0.07, bulge: 2.4),
        _Patch(const [],
            t0: 0.48,
            t1: 0.62,
            tf: 0.04,
            aCenter: 0.55,
            aHalf: 0.22,
            bulge: 0.9),
        _Patch(const [],
            t0: 0.72, t1: 0.75, tf: 0.02, aHalf: 0.2, af: 0.1, bulge: -0.5),
        _Patch(const [],
            t0: 0.82, t1: 0.95, tf: 0.04, aHalf: 0.17, af: 0.1, bulge: 1.1),
        _Patch(const [],
            t0: 0.42,
            t1: 0.58,
            tf: 0.04,
            aCenter: 1.45,
            aHalf: 0.12,
            af: 0.08,
            bulge: 1.5),
      ],
    );

    // ── Left arm: hangs with the elbow swung slightly outward, opening the
    // armpit of a relaxed athletic stance; fist lands beside the thigh ───────
    var v0 = pos.length ~/ 3;
    var t0 = tris.length;
    tube(
      y0: 96,
      y1: 262,
      cxPts: const [(0, 51), (0.32, 57), (0.75, 52), (1, 50)],
      czPts: const [(0, 0), (0.4, 1), (1, 6)],
      rPts: const [
        (0, 14),
        (0.16, 11.6),
        (0.40, 10.6),
        (0.50, 8.6),
        (0.60, 10.2),
        (0.80, 6.8),
        (1, 5),
      ],
      rings: 92,
      segs: 56,
      capTop: 0.10,
      capBottom: 0.06,
      patches: [
        // Deltoid cap: three lobes split by grooves, sitting proud on top of
        // the arm to widen the shoulder yoke.
        _Patch(const ['Shoulders'],
            t0: 0.0,
            t1: 0.18,
            tf: 0.06,
            aHalf: 3.2,
            af: 0.30,
            bulge: 4.8,
            grooves: const [
              (1.15, 0.10, 0.40),
              (-1.15, 0.10, 0.40),
              (2.15, 0.10, 0.32),
              (-2.15, 0.10, 0.32),
            ],
            mod: (t, th) => 0.9 + 0.1 * math.cos(2 * (th.abs() - math.pi / 2))),
        // Biceps: two heads with a peak, split from the triceps by the
        // bicipital grooves on either side.
        _Patch(const ['Biceps'],
            t0: 0.19,
            t1: 0.42,
            tf: 0.05,
            aHalf: 0.85,
            af: 0.26,
            bulge: 3.0,
            grooves: const [
              (0, 0.09, 0.28),
              (0.95, 0.08, 0.35),
              (-0.95, 0.08, 0.35),
            ],
            mod: (t, th) =>
                math.sin(math.pi * (t - 0.19) / 0.23).clamp(0.0, 1.0)),
        // Triceps horseshoe: long, lateral and medial heads on the back.
        _Patch(const ['Triceps'],
            t0: 0.16,
            t1: 0.44,
            tf: 0.05,
            aCenter: math.pi,
            aHalf: 0.95,
            af: 0.28,
            bulge: 2.7,
            grooves: const [
              (math.pi, 0.08, 0.4),
              (math.pi - 0.7, 0.07, 0.28),
              (-(math.pi - 0.7), 0.07, 0.28),
            ]),
        // Forearm: flexor / extensor masses with the brachioradialis ridge,
        // tapering hard into the wrist.
        _Patch(const ['Forearms'],
            t0: 0.48,
            t1: 0.84,
            tf: 0.06,
            aHalf: 3.2,
            af: 0.30,
            bulge: 1.8,
            grooves: const [(0.85, 0.09, 0.28), (-0.85, 0.09, 0.28)],
            mod: (t, th) =>
                math.sin(math.pi * (t - 0.48) / 0.36).clamp(0.0, 1.0)),
      ],
    );
    // Fist beside the thigh, slightly forward.
    ellipsoid(50, 266, 5, 5.5, 9, 6.5, 14, 24);
    mirror(v0, t0);

    // ── Left leg: from the true crotch height (half the figure) ─────────────
    v0 = pos.length ~/ 3;
    t0 = tris.length;
    tube(
      y0: 224,
      y1: 416,
      cxPts: const [(0, 86), (0.5, 89), (1, 88.5)],
      czPts: const [(0, -1), (0.3, 1), (0.55, 0), (0.78, -2), (1, -1)],
      rPts: const [
        (0, 17),
        (0.12, 17.5),
        (0.44, 11),
        (0.52, 10),
        (0.62, 11.6),
        (0.74, 8),
        (1, 5),
      ],
      zRatio: 0.95,
      rings: 120,
      segs: 92,
      capTop: 0.05,
      capBottom: 0.05,
      patches: [
        // Gluteus maximus: a full rounded sphere, the cheeks split at the back
        // meridian and a crisp gluteal fold underneath.
        _Patch(const ['Glutes'],
            t0: 0.03,
            t1: 0.19,
            tf: 0.06,
            aCenter: math.pi,
            aHalf: 1.25,
            af: 0.28,
            bulge: 4.6,
            grooves: const [(math.pi, 0.09, 0.45)],
            tGrooves: const [(0.19, 0.02, 0.6)]),
        // Quadriceps: rectus femoris centre + vastus lateralis outer + vastus
        // medialis teardrop, split by grooves and cut by the diagonal
        // sartorius line running from the outer hip to the inner knee.
        _Patch(const ['Quadriceps', 'Adductors'],
            t0: 0.06,
            t1: 0.47,
            tf: 0.05,
            aHalf: 1.05,
            af: 0.26,
            bulge: 3.8,
            grooves: const [
              (0, 0.09, 0.30), // rectus femoris centre line
              (0.62, 0.09, 0.5), // outer sweep of vastus lateralis
              (-0.62, 0.09, 0.5),
            ],
            mod: (t, th) {
              final line = -0.9 + (t - 0.06) * 3.7;
              final d = th - line;
              return 1 - 0.3 * math.exp(-(d * d) / (2 * 0.09 * 0.09));
            }),
        // Vastus medialis teardrop bulging just above the inner knee.
        _Patch(const ['Quadriceps', 'Adductors'],
            t0: 0.38,
            t1: 0.50,
            tf: 0.04,
            aCenter: 0.62,
            aHalf: 0.32,
            bulge: 2.6),
        // Adductor mass filling the inner thigh.
        _Patch(const ['Quadriceps', 'Adductors'],
            t0: 0.05,
            t1: 0.30,
            tf: 0.06,
            aCenter: 1.35,
            aHalf: 0.28,
            bulge: 1.9),
        // Hamstrings: biceps femoris + semitendinosus + semimembranosus, a
        // central groove between the heads.
        _Patch(const ['Hamstrings'],
            t0: 0.20,
            t1: 0.49,
            tf: 0.05,
            aCenter: math.pi,
            aHalf: 0.95,
            af: 0.28,
            bulge: 3.2,
            grooves: const [
              (math.pi, 0.08, 0.42),
              (2.55, 0.07, 0.28),
              (-2.55, 0.07, 0.28),
            ]),
        // Popliteal hollow behind the knee.
        _Patch(const [],
            t0: 0.50,
            t1: 0.54,
            tf: 0.02,
            aCenter: math.pi,
            aHalf: 0.7,
            af: 0.2,
            bulge: -1.2),
        // Gastrocnemius diamond: twin heads over the soleus.
        _Patch(const ['Calves'],
            t0: 0.55,
            t1: 0.78,
            tf: 0.05,
            aCenter: math.pi,
            aHalf: 1.05,
            af: 0.28,
            bulge: 3.5,
            grooves: const [(math.pi, 0.08, 0.5)]),
        // Soleus ridge below the gastroc heads.
        _Patch(const ['Calves'],
            t0: 0.78,
            t1: 0.90,
            tf: 0.04,
            aCenter: math.pi,
            aHalf: 0.8,
            bulge: 1.2),
        // Tibialis along the shin with the sharp bone line beside it.
        _Patch(const ['Calves'],
            t0: 0.55,
            t1: 0.88,
            aHalf: 0.4,
            af: 0.22,
            bulge: 1.3,
            grooves: const [(0, 0.06, 0.35)]),
      ],
    );
    // Foot: long, low, turned slightly outward like a relaxed stance.
    ellipsoid(88, 418, 7, 7, 6, 15, 16, 28, rotY: -0.3);
    mirror(v0, t0);

    // ── Smooth normals: accumulate face normals per vertex ──────────────────
    final normal = Float32List(pos.length);
    for (var f = 0; f < tris.length; f += 3) {
      final a = tris[f] * 3, b = tris[f + 1] * 3, c = tris[f + 2] * 3;
      final ux = pos[b] - pos[a],
          uy = pos[b + 1] - pos[a + 1],
          uz = pos[b + 2] - pos[a + 2];
      final vx = pos[c] - pos[a],
          vy = pos[c + 1] - pos[a + 1],
          vz = pos[c + 2] - pos[a + 2];
      final nx = uy * vz - uz * vy;
      final ny = uz * vx - ux * vz;
      final nz = ux * vy - uy * vx;
      for (final i in [tris[f], tris[f + 1], tris[f + 2]]) {
        normal[i * 3] += nx;
        normal[i * 3 + 1] += ny;
        normal[i * 3 + 2] += nz;
      }
    }
    for (var i = 0; i < normal.length; i += 3) {
      final len = math.sqrt(normal[i] * normal[i] +
          normal[i + 1] * normal[i + 1] +
          normal[i + 2] * normal[i + 2]);
      if (len > 1e-9) {
        normal[i] /= len;
        normal[i + 1] /= len;
        normal[i + 2] /= len;
      }
    }

    // ── Cavity ambient occlusion: darken concavities ────────────────────────
    // For each vertex, the offset of the average neighbour from its tangent
    // plane, normalized by the local mean squared edge length, approximates
    // signed surface curvature — independent of tessellation density. Concave
    // grooves darken toward an anatomy chart's separation lines; convex belly
    // peaks brighten slightly. Contrast is intentionally strong so the
    // separations read as crisp lines, not soft shading.
    final nVerts = pos.length ~/ 3;
    final acc = Float64List(nVerts * 3);
    final d2acc = Float64List(nVerts);
    final cnt = Int32List(nVerts);
    void edge(int a, int b) {
      final dx = pos[b * 3] - pos[a * 3];
      final dy = pos[b * 3 + 1] - pos[a * 3 + 1];
      final dz = pos[b * 3 + 2] - pos[a * 3 + 2];
      acc[a * 3] += pos[b * 3];
      acc[a * 3 + 1] += pos[b * 3 + 1];
      acc[a * 3 + 2] += pos[b * 3 + 2];
      d2acc[a] += dx * dx + dy * dy + dz * dz;
      cnt[a]++;
    }

    for (var f = 0; f < tris.length; f += 3) {
      final a = tris[f], b = tris[f + 1], c = tris[f + 2];
      edge(a, b);
      edge(a, c);
      edge(b, a);
      edge(b, c);
      edge(c, a);
      edge(c, b);
    }
    final ao = Float32List(nVerts);
    for (var i = 0; i < nVerts; i++) {
      if (cnt[i] == 0) {
        ao[i] = 1;
        continue;
      }
      final mx = acc[i * 3] / cnt[i] - pos[i * 3];
      final my = acc[i * 3 + 1] / cnt[i] - pos[i * 3 + 1];
      final mz = acc[i * 3 + 2] / cnt[i] - pos[i * 3 + 2];
      final concave =
          mx * normal[i * 3] + my * normal[i * 3 + 1] + mz * normal[i * 3 + 2];
      final meanD2 = d2acc[i] / cnt[i];
      final curv = 2 * concave / math.max(meanD2, 1e-6);
      ao[i] = (1 - curv * 1.5).clamp(0.34, 1.14).toDouble();
    }

    return _Mesh(
      Float32List.fromList(pos),
      normal,
      ao,
      Int16List.fromList(setId),
      Float32List.fromList(setWeight),
      Uint16List.fromList(tris),
      Float32List.fromList(faceBias),
      groupSets,
    );
  }

  @override
  bool shouldRepaint(covariant MuscleBodyPainter old) =>
      old.yaw != yaw ||
      old.activeGroups != activeGroups ||
      old.intensity != intensity;
}
