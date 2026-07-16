import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// A real-time 3D anatomical figure, rendered from a procedural triangle mesh
/// — no image assets, no plugins.
///
/// The body is built once as ~60 000 vertices / ~119 000 triangles (the
/// practical ceiling: [Canvas.drawVertices] indexes vertices with Uint16, so
/// one call can address at most 65 536). The high density is spent on
/// anatomy: fiber striations across pecs, lats and glutes, three-lobed delts,
/// two-headed biceps, a triceps horseshoe, six-pack rows with a linea alba,
/// serratus fingers, a diagonal sartorius line across the quads, hamstring
/// heads, gastrocnemius + soleus, erector columns — every one of them real
/// displaced geometry, not paint.
///
/// Definition comes from two places:
/// - per-vertex lighting (key + fill + specular from a world-fixed lamp), and
/// - baked **cavity ambient occlusion**, normalized by local edge length so
///   it measures true surface curvature: every groove between muscle bellies
///   darkens into the separation lines an anatomy chart lives by.
///
/// Every frame the mesh is rotated by [yaw] about the body's vertical axis,
/// perspective-projected, back-face culled, depth-ordered with an O(n)
/// counting sort into reusable buffers, and drawn with a single
/// [Canvas.drawVertices] call — cheap enough to follow a drag gesture.
///
/// Muscle groups trained in the window are tinted blue by [intensity]
/// (light → deep). Group names match the backend's `muscle_group` values
/// (see MachineSeeder).
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

/// A muscle patch on a body part's surface: a band in (t, θ) parameter space
/// that bulges the mesh outward and owns the group tint there.
///
/// t runs 0→1 down the part, θ ∈ (−π, π] around it with 0 facing the viewer.
/// The patch spans [t0..t1] (fading over [tf]) and angular distance [aHalf]
/// around [aCenter] — matched mirror-symmetrically, so one definition covers
/// both pecs / both lats. [grooves] carve separation lines (sternum, linea
/// alba, spine, the splits between muscle heads) and [mod] sculpts ridges
/// (six-pack rows, fiber striations, the sartorius line). A patch with a
/// negative [bulge] and no [groups] is a pure crease (under-pec line,
/// inguinal fold).
class _Patch {
  const _Patch(
    this.groups, {
    required this.t0,
    required this.t1,
    this.tf = 0.06,
    this.aCenter = 0,
    required this.aHalf,
    this.af = 0.3,
    required this.bulge,
    this.grooves = const [],
    this.mod,
  });

  final List<String> groups;
  final double t0, t1, tf;
  final double aCenter, aHalf, af;
  final double bulge;
  final List<(double, double, double)> grooves; // (center θ, sigma, depth)
  final double Function(double t, double th)? mod;

  /// The smooth band weight only (no grooves/ripples) — used for the tint,
  /// so a muscle reads as one solid colored belly whose grooves darken via
  /// ambient occlusion instead of fading to gray.
  double bandWeight(double t, double th) {
    final wT = _band(t, t0, t1, tf);
    if (wT == 0) return 0;
    final d = math.min(
        _wrapAbs(th - aCenter), _wrapAbs(th + aCenter)); // mirror symmetric
    return wT * _band(d, 0, aHalf, af);
  }

  /// The full sculpt weight (band × grooves × ripples) — used for geometry.
  double weight(double t, double th) {
    var w = bandWeight(t, th);
    if (w == 0) return 0;
    for (final g in grooves) {
      final gd = _wrapAbs(th - g.$1);
      w *= 1 - g.$3 * math.exp(-(gd * gd) / (2 * g.$2 * g.$2));
    }
    if (mod != null) w *= mod!(t, th);
    return w.clamp(0.0, 1.3);
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

  /// Cavity ambient occlusion per vertex: <1 in grooves, ~1 on open surface.
  final Float32List ao;
  final Int16List setId; // index into groupSets, -1 = plain skin
  final Float32List setWeight;
  final Uint16List tris;

  /// Per-face depth-sort bias: where two parts graze (thigh tops inside the
  /// pelvis, arms at the armpit) the painter's algorithm would z-fight
  /// speckle; biasing the torso forward makes it win those ties cleanly.
  final Float32List faceBias;
  final List<List<String>> groupSets;

  int get vertexCount => pos.length ~/ 3;
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
  static const Color _skin = Color(0xFFC2C7D1);
  static const Color _muscle = Color(0xFFACB3BF);
  // Trained muscles ramp from light blue (barely worked) to deep blue (hammered).
  static const Color _blueLow = Color(0xFF7FB2FF);
  static const Color _blueHigh = Color(0xFF0A3EA0);

  static final _Mesh _mesh = _buildMesh();

  // Reusable per-frame scratch buffers (the mesh is a static singleton, so
  // these are sized once) — no per-frame allocations beyond the engine copy.
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
    const l1x = -0.42, l1y = -0.48, l1z = 0.77;
    const l2x = 0.68, l2y = -0.13, l2z = 0.72;
    // Half-vector of the key light for specular.
    const hx = -0.24, hy = -0.27, hz = 0.93;

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
      pos2[i * 2 + 1] = 230 + (py - 230) * p;
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
        // Threshold the tint so blue hugs the muscle belly instead of
        // bleeding across the falloff like clothing.
        base = blue != null
            ? Color.lerp(_skin, blue, ((w - 0.22) * 1.7).clamp(0.0, 1.0))!
            : Color.lerp(_skin, _muscle, (w * 0.9).clamp(0.0, 1.0))!;
      }

      // Key + fill diffuse, cavity-occluded, plus a touch of specular.
      final d1 = math.max(0.0, nx * l1x + ny * l1y + nz * l1z);
      final d2 = math.max(0.0, nx * l2x + ny * l2y + nz * l2z);
      final ao = mAo[i];
      final lum = (0.28 + 0.62 * d1 + 0.12 * d2) * ao;
      final specDot = math.max(0.0, nx * hx + ny * hy + nz * hz);
      final spec = specDot * specDot * specDot * specDot; // ^4
      final sp = spec * spec * spec * 45 * ao; // ≈ ^12
      final r = (base.r * 255 * lum + sp).round().clamp(0, 255);
      final g = (base.g * 255 * lum + sp).round().clamp(0, 255);
      final b = (base.b * 255 * lum + sp).round().clamp(0, 255);
      colors[i] = 0xFF000000 | (r << 16) | (g << 8) | b;
    }

    // Back-face cull via screen winding, then depth-order the kept faces with
    // an O(n) counting sort (far first). Bucketing by depth + face-index
    // order within a bucket keeps grazing surfaces (the two inner thighs)
    // resolving identically every frame.
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
      final z =
          (depth[a] + depth[b] + depth[c]) / 3 + faceBias[f] - zMin + 2;
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

    /// Cosine-smoothed profile through (t, value) control points — C1-smooth
    /// so the dense mesh shows no creases at the knots.
    double profile(List<(double, double)> pts, double t) {
      for (var i = 0; i < pts.length - 1; i++) {
        if (t <= pts[i + 1].$1) {
          final u = ((t - pts[i].$1) / (pts[i + 1].$1 - pts[i].$1))
              .clamp(0.0, 1.0);
          final f = (1 - math.cos(math.pi * u)) / 2;
          return pts[i].$2 + (pts[i + 1].$2 - pts[i].$2) * f;
        }
      }
      return pts.last.$2;
    }

    /// A generalized cylinder: rings of [segs] vertices from y0→y1, centre
    /// drifting cx0→cx1, radius from [rPts], flattened by [zRatio], ends
    /// rounded over [capTop]/[capBottom] of t, surface displaced by [patches].
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
          // Strongest patch owns the vertex's tint (by its smooth band
          // weight); the full sculpted weight displaces the surface.
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

    /// An ellipsoid (head, hands, feet) — poles as degenerate rings.
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

    /// Duplicate everything built since [fromVertex]/[fromTri], mirrored
    /// across x = 100 (winding flipped to stay outward).
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

    /// Rows of raised segments (six-pack, oblique/serratus fingers): a deep
    /// sharpened cosine ripple down the patch.
    double Function(double, double) rows(double from, double period) {
      return (t, th) {
        final c = 0.5 + 0.5 * math.cos(2 * math.pi * (t - from) / period);
        return 0.12 + 0.88 * c * c;
      };
    }

    /// Fiber striations: a fine ripple across the belly, optionally sheared
    /// so the fibers run diagonally like a lat or pec fan.
    double Function(double, double) fibers(double freq, double shear,
        [double depth = 0.10]) {
      return (t, th) => (1 - depth) + depth * math.cos(freq * th + shear * t);
    }

    // Classic figure proportions on a 7.5-head canon (head unit ≈ 58 of
    // the 440-tall design space): chin ~66, shoulders ~96, nipples ~126,
    // navel ~182, crotch ~240 (half height), knees ~325, soles ~422. The
    // torso carries an S-posture (chest proud, pelvis tucked) via its
    // curved z centerline.

    // ── Torso: bodybuilder V-taper with full musculature ───────────────────
    tube(
      y0: 88,
      y1: 240,
      cxPts: const [(0, 100), (1, 100)],
      czPts: const [(0, 3), (0.35, 4), (0.6, 1), (1, -3)],
      rPts: const [
        (0, 34),
        (0.1, 39),
        (0.35, 35.5),
        (0.6, 25),
        (0.82, 28),
        (1, 26.5),
      ],
      zRatio: 0.6,
      rings: 176,
      segs: 132,
      capTop: 0.08,
      capBottom: 0.12,
      bias: 0.8,
      patches: [
        // Traps rising toward the neck, split by the spine, fiber-striated.
        _Patch(const ['Traps'],
            t0: 0.0,
            t1: 0.10,
            tf: 0.06,
            aCenter: math.pi,
            aHalf: 1.5,
            af: 0.4,
            bulge: 3.0,
            grooves: const [(math.pi, 0.08, 0.55)],
            mod: fibers(10, 8, 0.05)),
        // Pec plates: deep sternum cleft, separation from the delts, and a
        // subtle fan of fiber striations.
        _Patch(const ['Chest'],
            t0: 0.07,
            t1: 0.28,
            tf: 0.05,
            aHalf: 1.02,
            af: 0.22,
            bulge: 5.0,
            grooves: const [
              (0, 0.09, 0.8),
              (1.05, 0.10, 0.5),
              (-1.05, 0.10, 0.5),
            ],
            mod: (t, th) =>
                0.965 + 0.035 * math.cos(2 * math.pi * (t - 0.07) / 0.05)),
        // Crease under the pecs.
        _Patch(const [],
            t0: 0.28, t1: 0.325, tf: 0.02, aHalf: 0.85, af: 0.2, bulge: -1.8),
        // Six-pack rows with the linea alba down the middle.
        _Patch(const ['Abdominals'],
            t0: 0.34,
            t1: 0.82,
            tf: 0.05,
            aHalf: 0.34,
            af: 0.12,
            bulge: 3.4,
            grooves: const [(0, 0.08, 0.65)],
            mod: rows(0.34, 0.13)),
        // Obliques rippling down the flank.
        _Patch(const ['Abdominals'],
            t0: 0.38,
            t1: 0.80,
            tf: 0.06,
            aCenter: 0.62,
            aHalf: 0.2,
            bulge: 2.0,
            mod: rows(0.38, 0.10)),
        // Serratus fingers under the armpit.
        _Patch(const ['Abdominals'],
            t0: 0.27,
            t1: 0.44,
            tf: 0.04,
            aCenter: 0.98,
            aHalf: 0.18,
            bulge: 1.6,
            mod: rows(0.27, 0.065)),
        // Rhomboids / teres mass between the shoulder blades.
        _Patch(const ['Upper Back'],
            t0: 0.10,
            t1: 0.34,
            tf: 0.06,
            aCenter: math.pi - 0.55,
            aHalf: 0.5,
            af: 0.25,
            bulge: 2.6,
            grooves: const [(2.2, 0.07, 0.3), (-2.2, 0.07, 0.3)],
            mod: (t, th) =>
                0.85 + 0.15 * math.cos(2 * math.pi * (t - 0.10) / 0.12)),
        // Lats: the wings of the V-taper, with diagonal fiber striations.
        _Patch(const ['Lats'],
            t0: 0.27,
            t1: 0.66,
            tf: 0.07,
            aCenter: math.pi - 0.6,
            aHalf: 0.5,
            af: 0.22,
            bulge: 3.6,
            mod: fibers(9, 6, 0.10)),
        // Erector columns with a deep spine channel.
        _Patch(const ['Lower Back'],
            t0: 0.45,
            t1: 0.96,
            tf: 0.06,
            aCenter: math.pi,
            aHalf: 0.3,
            af: 0.12,
            bulge: 2.2,
            grooves: const [
              (math.pi, 0.08, 0.8),
              (math.pi - 0.34, 0.07, 0.3),
              (-(math.pi - 0.34), 0.07, 0.3),
            ]),
        // Inguinal fold across the front of the pelvis.
        _Patch(const [],
            t0: 0.90, t1: 0.95, tf: 0.03, aHalf: 0.5, af: 0.25, bulge: -0.8),
      ],
    );

    // ── Neck: traps up the back, sternocleidomastoid ridges in front ──────
    tube(
      y0: 60,
      y1: 92,
      cxPts: const [(0, 100), (1, 100)],
      czPts: const [(0, 1), (1, 2)],
      rPts: const [(0, 10), (1, 15.5)],
      zRatio: 0.95,
      rings: 24,
      segs: 48,
      capTop: 0,
      capBottom: 0,
      patches: [
        _Patch(const ['Traps'],
            t0: 0.25,
            t1: 1,
            tf: 0.2,
            aCenter: math.pi,
            aHalf: 1.35,
            af: 0.5,
            bulge: 1.8),
        _Patch(const ['Neck'],
            t0: 0.15,
            t1: 0.85,
            tf: 0.15,
            aCenter: 0.4,
            aHalf: 0.14,
            bulge: 1.0),
      ],
    );

    // ── Head: skull → brow → cheekbones → jaw, with a sculpted face ───────
    tube(
      y0: 8,
      y1: 66,
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
        // Brow ridge.
        _Patch(const [],
            t0: 0.30, t1: 0.40, tf: 0.04, aHalf: 0.5, af: 0.2, bulge: 1.0),
        // Eye sockets: shadowed hollows under the brow.
        _Patch(const [],
            t0: 0.40,
            t1: 0.50,
            tf: 0.03,
            aCenter: 0.45,
            aHalf: 0.13,
            af: 0.08,
            bulge: -1.0),
        // Nose.
        _Patch(const [],
            t0: 0.46, t1: 0.64, tf: 0.04, aHalf: 0.11, af: 0.07, bulge: 2.4),
        // Cheekbones.
        _Patch(const [],
            t0: 0.48,
            t1: 0.62,
            tf: 0.04,
            aCenter: 0.55,
            aHalf: 0.22,
            bulge: 0.9),
        // Mouth crease.
        _Patch(const [],
            t0: 0.72, t1: 0.75, tf: 0.02, aHalf: 0.2, af: 0.1, bulge: -0.5),
        // Chin.
        _Patch(const [],
            t0: 0.82, t1: 0.95, tf: 0.04, aHalf: 0.17, af: 0.1, bulge: 1.1),
        // Ears.
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

    // ── Left arm: hangs with the elbow swung outward, opening the armpit
    // gap of a relaxed athletic stance; fist lands beside the thigh ────────
    var v0 = pos.length ~/ 3;
    var t0 = tris.length;
    tube(
      y0: 92,
      y1: 260,
      cxPts: const [(0, 52), (0.35, 58), (0.75, 52), (1, 50)],
      czPts: const [(0, 0), (0.4, 1), (1, 6)],
      rPts: const [
        (0, 13),
        (0.2, 10.2),
        (0.42, 9.4),
        (0.52, 8),
        (0.62, 9.2),
        (1, 5),
      ],
      rings: 92,
      segs: 56,
      capTop: 0.12,
      capBottom: 0.06,
      patches: [
        // Deltoid: three lobes (anterior/lateral/posterior) split by grooves.
        _Patch(const ['Shoulders'],
            t0: 0.0,
            t1: 0.15,
            tf: 0.05,
            aHalf: 3.2,
            af: 0.3,
            bulge: 3.8,
            grooves: const [
              (1.05, 0.10, 0.35),
              (-1.05, 0.10, 0.35),
              (2.1, 0.10, 0.3),
              (-2.1, 0.10, 0.3),
            ],
            mod: (t, th) =>
                0.85 + 0.15 * math.cos(2 * (th.abs() - math.pi / 2))),
        // Biceps: two heads with a peak.
        _Patch(const ['Biceps'],
            t0: 0.18,
            t1: 0.40,
            tf: 0.05,
            aHalf: 0.9,
            af: 0.3,
            bulge: 2.8,
            grooves: const [(0, 0.08, 0.3)],
            mod: (t, th) =>
                math.sin(math.pi * (t - 0.18) / 0.22).clamp(0.0, 1.0)),
        // Triceps horseshoe: long, lateral and medial heads.
        _Patch(const ['Triceps'],
            t0: 0.18,
            t1: 0.44,
            tf: 0.05,
            aCenter: math.pi,
            aHalf: 0.95,
            af: 0.3,
            bulge: 2.4,
            grooves: const [
              (math.pi, 0.09, 0.4),
              (math.pi - 0.7, 0.08, 0.25),
              (-(math.pi - 0.7), 0.08, 0.25),
            ]),
        // Forearm mass with the brachioradialis ridge lines.
        _Patch(const ['Forearms'],
            t0: 0.50,
            t1: 0.82,
            tf: 0.06,
            aHalf: 3.2,
            af: 0.3,
            bulge: 1.7,
            grooves: const [(0.9, 0.09, 0.25), (-0.9, 0.09, 0.25)],
            mod: (t, th) =>
                math.sin(math.pi * (t - 0.50) / 0.32).clamp(0.0, 1.0)),
      ],
    );
    // Fist beside the thigh, slightly forward.
    ellipsoid(50, 264, 5, 5.5, 9, 6.5, 14, 24);
    mirror(v0, t0);

    // ── Left leg: from the true crotch height (half the figure) ───────────
    v0 = pos.length ~/ 3;
    t0 = tris.length;
    tube(
      y0: 228,
      y1: 414,
      cxPts: const [(0, 87), (0.5, 89.5), (1, 89)],
      czPts: const [(0, -1), (0.3, 1), (0.55, 0), (0.78, -2), (1, -1)],
      rPts: const [
        (0, 15.5),
        (0.44, 10.4),
        (0.52, 9.6),
        (0.64, 10.8),
        (1, 5.4),
      ],
      zRatio: 0.95,
      rings: 120,
      segs: 92,
      capTop: 0.05,
      capBottom: 0.05,
      patches: [
        // Glute sphere with fiber striations.
        _Patch(const ['Glutes'],
            t0: 0.04,
            t1: 0.18,
            tf: 0.06,
            aCenter: math.pi,
            aHalf: 1.2,
            af: 0.3,
            bulge: 4.2,
            mod: fibers(10, 0, 0.06)),
        // Quads: three heads split by grooves, cut by the diagonal sartorius
        // line running from the outer hip to the inner knee.
        _Patch(const ['Quadriceps', 'Adductors'],
            t0: 0.06,
            t1: 0.48,
            tf: 0.06,
            aHalf: 1.1,
            af: 0.28,
            bulge: 3.6,
            grooves: const [
              (0, 0.09, 0.35),
              (0.55, 0.10, 0.5),
              (-0.55, 0.10, 0.5),
            ],
            mod: (t, th) {
              final line = -0.9 + (t - 0.06) * 3.64;
              final d = th - line;
              return 1 - 0.3 * math.exp(-(d * d) / (2 * 0.1 * 0.1));
            }),
        // Vastus medialis teardrop above the knee.
        _Patch(const ['Quadriceps', 'Adductors'],
            t0: 0.40,
            t1: 0.53,
            tf: 0.04,
            aCenter: 0.7,
            aHalf: 0.35,
            bulge: 2.4),
        // Adductor mass filling the inner thigh.
        _Patch(const ['Quadriceps', 'Adductors'],
            t0: 0.04,
            t1: 0.28,
            tf: 0.06,
            aCenter: 1.35,
            aHalf: 0.3,
            bulge: 1.8),
        // Hamstrings: biceps femoris + semitendinosus + semimembranosus.
        _Patch(const ['Hamstrings'],
            t0: 0.20,
            t1: 0.50,
            tf: 0.05,
            aCenter: math.pi,
            aHalf: 0.95,
            af: 0.3,
            bulge: 3.0,
            grooves: const [
              (math.pi, 0.09, 0.45),
              (2.6, 0.08, 0.3),
              (-2.6, 0.08, 0.3),
            ]),
        // Gastrocnemius diamond: twin heads over the soleus.
        _Patch(const ['Calves'],
            t0: 0.55,
            t1: 0.78,
            tf: 0.05,
            aCenter: math.pi,
            aHalf: 1.05,
            af: 0.3,
            bulge: 3.4,
            grooves: const [(math.pi, 0.09, 0.5)]),
        // Soleus ridge below the gastroc heads.
        _Patch(const ['Calves'],
            t0: 0.78,
            t1: 0.90,
            tf: 0.04,
            aCenter: math.pi,
            aHalf: 0.8,
            bulge: 1.2),
        // Tibialis along the shin with the bone line beside it.
        _Patch(const ['Calves'],
            t0: 0.55,
            t1: 0.86,
            aHalf: 0.4,
            af: 0.25,
            bulge: 1.3,
            grooves: const [(0, 0.07, 0.3)]),
      ],
    );
    // Foot: long, low, and turned slightly outward like a relaxed stance.
    ellipsoid(88, 416, 7, 7, 6, 15, 16, 28, rotY: -0.3);
    mirror(v0, t0);

    // ── Smooth normals: accumulate face normals per vertex ────────────────
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

    // ── Cavity ambient occlusion: darken concavities ───────────────────────
    // For each vertex, the offset of the average neighbour from its tangent
    // plane, normalized by the local mean squared edge length, approximates
    // signed surface curvature — independent of tessellation density. Concave
    // (grooves between muscle bellies) darkens toward an anatomy chart's
    // separation lines; convex belly peaks brighten slightly.
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
      ao[i] = (1 - curv * 1.35).clamp(0.40, 1.12).toDouble();
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
