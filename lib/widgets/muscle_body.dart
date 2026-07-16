import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// A real-time 3D anatomical figure, rendered from a procedural triangle mesh
/// — no image assets, no plugins.
///
/// The body is built once as ~4 800 vertices / ~9 500 triangles with
/// bodybuilder proportions: capped delts, a trapezius slope into the neck,
/// lat wings tapering to the waist, pec plates, six-pack rows, three-headed
/// quads, glute spheres and gastrocnemius diamonds — every muscle is real
/// displaced geometry, not paint.
///
/// Definition comes from two places:
/// - per-vertex lighting (key + fill + specular from a world-fixed lamp), and
/// - a **cavity ambient-occlusion** pass baked at build time: concave
///   vertices (the grooves between muscle bellies) darken automatically,
///   drawing the anatomical separation lines an anatomy chart lives by.
///
/// Every frame the mesh is rotated by [yaw] about the body's vertical axis,
/// perspective-projected, back-face culled, depth-sorted and drawn with a
/// single [Canvas.drawVertices] call — cheap enough to follow a drag gesture.
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
/// alba, spine) and [mod] sculpts ridges like the six-pack rows. A patch with
/// a negative [bulge] and no [groups] is a pure crease (under-pec line,
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
    return w.clamp(0.0, 1.25);
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

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(
        size.width / MuscleBody._designW, size.height / MuscleBody._designH);

    final mesh = _mesh;
    final n = mesh.vertexCount;
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
    final pos2 = Float32List(n * 2);
    final depth = Float32List(n);
    final colors = Int32List(n);

    for (var i = 0; i < n; i++) {
      final px = mesh.pos[i * 3] - 100;
      final py = mesh.pos[i * 3 + 1];
      final pz = mesh.pos[i * 3 + 2];
      // Rotate about the vertical axis, then perspective-project.
      final rx = px * cosY + pz * sinY;
      final rz = -px * sinY + pz * cosY;
      final p = focal / (focal - rz);
      pos2[i * 2] = 100 + rx * p;
      pos2[i * 2 + 1] = 230 + (py - 230) * p;
      depth[i] = rz;

      // Rotate the rest normal the same way.
      final nx0 = mesh.normal[i * 3];
      final ny = mesh.normal[i * 3 + 1];
      final nz0 = mesh.normal[i * 3 + 2];
      final nx = nx0 * cosY + nz0 * sinY;
      final nz = -nx0 * sinY + nz0 * cosY;

      // Vertex tint: skin → sculpted gray or training blue by patch weight.
      var base = _skin;
      final s = mesh.setId[i];
      if (s >= 0) {
        final blue = setColors[s];
        final w = mesh.setWeight[i];
        // Threshold the tint so blue hugs the muscle belly instead of
        // bleeding across the falloff like clothing.
        base = blue != null
            ? Color.lerp(_skin, blue, ((w - 0.22) * 1.7).clamp(0.0, 1.0))!
            : Color.lerp(_skin, _muscle, (w * 0.9).clamp(0.0, 1.0))!;
      }

      // Key + fill diffuse, cavity-occluded, plus a touch of specular.
      final d1 = math.max(0.0, nx * l1x + ny * l1y + nz * l1z);
      final d2 = math.max(0.0, nx * l2x + ny * l2y + nz * l2z);
      final ao = mesh.ao[i];
      final lum = (0.30 + 0.58 * d1 + 0.16 * d2) * ao;
      final specDot = math.max(0.0, nx * hx + ny * hy + nz * hz);
      final spec = specDot * specDot * specDot * specDot; // ^4
      final sp = spec * spec * spec * 45 * ao; // ≈ ^12
      final r = (base.r * 255 * lum + sp).round().clamp(0, 255);
      final g = (base.g * 255 * lum + sp).round().clamp(0, 255);
      final b = (base.b * 255 * lum + sp).round().clamp(0, 255);
      colors[i] = 0xFF000000 | (r << 16) | (g << 8) | b;
    }

    // Back-face cull via screen winding, then painter's-algorithm sort.
    final tris = mesh.tris;
    final faces = <(double, int)>[]; // (avg depth, tri index)
    for (var f = 0; f < tris.length; f += 3) {
      final a = tris[f], b = tris[f + 1], c = tris[f + 2];
      final ax = pos2[a * 2], ay = pos2[a * 2 + 1];
      final bx = pos2[b * 2], by = pos2[b * 2 + 1];
      final cx = pos2[c * 2], cy = pos2[c * 2 + 1];
      final area = (bx - ax) * (cy - ay) - (cx - ax) * (by - ay);
      if (area <= 0) continue; // facing away
      faces.add((
        (depth[a] + depth[b] + depth[c]) / 3 + mesh.faceBias[f ~/ 3],
        f
      ));
    }
    // Far first; ties broken by build order so grazing surfaces (the two
    // inner thighs at the crotch) resolve identically every frame.
    faces.sort((p, q) {
      final byZ = p.$1.compareTo(q.$1);
      return byZ != 0 ? byZ : p.$2.compareTo(q.$2);
    });

    final indices = Uint16List(faces.length * 3);
    var k = 0;
    for (final face in faces) {
      indices[k++] = tris[face.$2];
      indices[k++] = tris[face.$2 + 1];
      indices[k++] = tris[face.$2 + 2];
    }

    canvas.drawVertices(
      ui.Vertices.raw(
        VertexMode.triangles,
        pos2,
        colors: colors,
        indices: indices,
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

    /// Piecewise-linear profile through (t, value) control points.
    double profile(List<(double, double)> pts, double t) {
      for (var i = 0; i < pts.length - 1; i++) {
        if (t <= pts[i + 1].$1) {
          final f = (t - pts[i].$1) / (pts[i + 1].$1 - pts[i].$1);
          return pts[i].$2 + (pts[i + 1].$2 - pts[i].$2) * f.clamp(0.0, 1.0);
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
      required double cx0,
      required double cx1,
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
        final cx = cx0 + (cx1 - cx0) * t;
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
            ..add((r * zRatio + disp) * math.cos(th));
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
        double rz, int latN, int segs) {
      final base = pos.length ~/ 3;
      for (var i = 0; i <= latN; i++) {
        final phi = -math.pi / 2 + math.pi * i / latN;
        final c = math.cos(phi);
        for (var j = 0; j < segs; j++) {
          final th = -math.pi + 2 * math.pi * j / segs;
          pos
            ..add(cx + rx * c * math.sin(th))
            ..add(cy + ry * math.sin(phi))
            ..add(cz + rz * c * math.cos(th));
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

    // ── Torso: bodybuilder V-taper with full musculature ───────────────────
    tube(
      y0: 78,
      y1: 216,
      cx0: 100,
      cx1: 100,
      rPts: const [
        (0, 36),
        (0.07, 40),
        (0.3, 37),
        (0.62, 25.5),
        (0.85, 27.5),
        (1, 26),
      ],
      zRatio: 0.6,
      rings: 36,
      segs: 40,
      capTop: 0.06,
      capBottom: 0.12,
      bias: 0.8,
      patches: [
        // Traps rising toward the neck, split by the spine.
        _Patch(const ['Traps'],
            t0: 0.0,
            t1: 0.13,
            tf: 0.07,
            aCenter: math.pi,
            aHalf: 1.5,
            af: 0.4,
            bulge: 3.0,
            grooves: const [(math.pi, 0.08, 0.5)]),
        // Pec plates: deep sternum cleft + separation from the delts.
        _Patch(const ['Chest'],
            t0: 0.05,
            t1: 0.28,
            tf: 0.05,
            aHalf: 1.02,
            af: 0.22,
            bulge: 5.0,
            grooves: const [
              (0, 0.10, 0.75),
              (1.05, 0.10, 0.45),
              (-1.05, 0.10, 0.45),
            ]),
        // Crease under the pecs.
        _Patch(const [],
            t0: 0.28, t1: 0.33, tf: 0.025, aHalf: 0.85, af: 0.2, bulge: -1.8),
        // Six-pack rows with the linea alba down the middle.
        _Patch(const ['Abdominals'],
            t0: 0.36,
            t1: 0.88,
            tf: 0.05,
            aHalf: 0.34,
            af: 0.12,
            bulge: 3.4,
            grooves: const [(0, 0.09, 0.6)],
            mod: (t, th) =>
                0.55 + 0.45 * math.cos(2 * math.pi * (t - 0.36) / 0.15)),
        // Obliques rippling down the flank.
        _Patch(const ['Abdominals'],
            t0: 0.42,
            t1: 0.86,
            tf: 0.06,
            aCenter: 0.62,
            aHalf: 0.2,
            bulge: 2.0,
            mod: (t, th) =>
                0.75 + 0.25 * math.cos(2 * math.pi * (t - 0.42) / 0.13)),
        // Serratus fingers under the armpit.
        _Patch(const ['Abdominals'],
            t0: 0.3,
            t1: 0.48,
            tf: 0.04,
            aCenter: 0.98,
            aHalf: 0.18,
            bulge: 1.5,
            mod: (t, th) =>
                0.7 + 0.3 * math.cos(2 * math.pi * (t - 0.3) / 0.09)),
        // Rhomboids / teres mass between the shoulder blades.
        _Patch(const ['Upper Back'],
            t0: 0.12,
            t1: 0.38,
            tf: 0.06,
            aCenter: math.pi - 0.55,
            aHalf: 0.5,
            af: 0.25,
            bulge: 2.6,
            mod: (t, th) =>
                0.8 + 0.2 * math.cos(2 * math.pi * (t - 0.12) / 0.13)),
        // Lats: the wings of the V-taper.
        _Patch(const ['Lats'],
            t0: 0.3,
            t1: 0.72,
            tf: 0.07,
            aCenter: math.pi - 0.6,
            aHalf: 0.5,
            af: 0.22,
            bulge: 3.6),
        // Erector columns with a deep spine channel.
        _Patch(const ['Lower Back'],
            t0: 0.5,
            t1: 0.98,
            tf: 0.06,
            aCenter: math.pi,
            aHalf: 0.3,
            af: 0.12,
            bulge: 2.2,
            grooves: const [(math.pi, 0.06, 0.7)]),
        // Inguinal fold across the front of the pelvis.
        _Patch(const [],
            t0: 0.88, t1: 0.93, tf: 0.03, aHalf: 0.5, af: 0.25, bulge: -0.8),
      ],
    );

    // ── Neck: traps up the back, sternocleidomastoid ridges in front ──────
    tube(
      y0: 46,
      y1: 84,
      cx0: 100,
      cx1: 100,
      rPts: const [(0, 8), (1, 13)],
      zRatio: 0.95,
      rings: 7,
      segs: 16,
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
            aHalf: 0.16,
            bulge: 0.8),
      ],
    );

    // ── Head: profiled skull → cheek → jaw, not an egg ─────────────────────
    tube(
      y0: 6,
      y1: 58,
      cx0: 100,
      cx1: 100,
      rPts: const [
        (0, 9),
        (0.2, 15.5),
        (0.5, 15),
        (0.75, 12),
        (1, 7.5),
      ],
      zRatio: 1.08,
      rings: 10,
      segs: 18,
      capTop: 0.22,
      capBottom: 0.18,
    );

    // ── Left arm (delts, biceps, triceps, forearm), then mirrored ─────────
    var v0 = pos.length ~/ 3;
    var t0 = tris.length;
    tube(
      y0: 84,
      y1: 232,
      cx0: 53,
      cx1: 47,
      rPts: const [
        (0, 13.2),
        (0.18, 10),
        (0.42, 9.2),
        (0.52, 7.8),
        (0.64, 9),
        (1, 4.8),
      ],
      rings: 26,
      segs: 18,
      capTop: 0.12,
      capBottom: 0.06,
      patches: [
        // Deltoid cap, strongest on its lateral head.
        _Patch(const ['Shoulders'],
            t0: 0.0,
            t1: 0.17,
            tf: 0.05,
            aHalf: 3.2,
            af: 0.3,
            bulge: 3.8,
            mod: (t, th) =>
                0.85 + 0.15 * math.cos(2 * (th.abs() - math.pi / 2))),
        // Biceps with a peak.
        _Patch(const ['Biceps'],
            t0: 0.2,
            t1: 0.44,
            tf: 0.05,
            aHalf: 0.9,
            af: 0.3,
            bulge: 2.6,
            mod: (t, th) =>
                math.sin(math.pi * (t - 0.2) / 0.24).clamp(0.0, 1.0)),
        // Triceps horseshoe: long/lateral heads split down the back.
        _Patch(const ['Triceps'],
            t0: 0.2,
            t1: 0.48,
            tf: 0.05,
            aCenter: math.pi,
            aHalf: 0.95,
            af: 0.3,
            bulge: 2.2,
            grooves: const [(math.pi, 0.10, 0.35)]),
        // Forearm mass tapering to the wrist.
        _Patch(const ['Forearms'],
            t0: 0.52,
            t1: 0.86,
            tf: 0.06,
            aHalf: 3.2,
            af: 0.3,
            bulge: 1.6,
            mod: (t, th) =>
                math.sin(math.pi * (t - 0.52) / 0.34).clamp(0.0, 1.0)),
      ],
    );
    // Fist by the thigh.
    ellipsoid(47, 238, 3, 5.5, 8, 6.5, 6, 10);
    mirror(v0, t0);

    // ── Left leg (glutes, quads, hams, calves), then mirrored ─────────────
    v0 = pos.length ~/ 3;
    t0 = tris.length;
    tube(
      y0: 196,
      y1: 402,
      cx0: 86,
      cx1: 88.5,
      rPts: const [
        (0, 17.5),
        (0.42, 11),
        (0.5, 10.2),
        (0.62, 11.5),
        (1, 5.8),
      ],
      zRatio: 0.95,
      rings: 30,
      segs: 28,
      capTop: 0.05,
      capBottom: 0.05,
      patches: [
        // Glute sphere.
        _Patch(const ['Glutes'],
            t0: 0.07,
            t1: 0.2,
            tf: 0.07,
            aCenter: math.pi,
            aHalf: 1.2,
            af: 0.3,
            bulge: 4.2),
        // Quads: three heads with separation grooves.
        _Patch(const ['Quadriceps', 'Adductors'],
            t0: 0.05,
            t1: 0.45,
            tf: 0.06,
            aHalf: 1.1,
            af: 0.28,
            bulge: 3.4,
            grooves: const [(0.5, 0.08, 0.35), (-0.5, 0.08, 0.35)],
            mod: (t, th) => 0.8 + 0.2 * math.cos(th * 3.2)),
        // Vastus medialis teardrop above the knee.
        _Patch(const ['Quadriceps', 'Adductors'],
            t0: 0.36,
            t1: 0.5,
            tf: 0.04,
            aCenter: 0.7,
            aHalf: 0.35,
            bulge: 2.2),
        // Adductor mass filling the inner thigh.
        _Patch(const ['Quadriceps', 'Adductors'],
            t0: 0.03,
            t1: 0.28,
            tf: 0.06,
            aCenter: 1.35,
            aHalf: 0.3,
            bulge: 1.8),
        // Hamstrings with the split between the two heads.
        _Patch(const ['Hamstrings'],
            t0: 0.22,
            t1: 0.5,
            tf: 0.05,
            aCenter: math.pi,
            aHalf: 0.95,
            af: 0.3,
            bulge: 2.8,
            grooves: const [(math.pi, 0.08, 0.4)]),
        // Gastrocnemius diamond: twin heads.
        _Patch(const ['Calves'],
            t0: 0.53,
            t1: 0.78,
            tf: 0.05,
            aCenter: math.pi,
            aHalf: 1.05,
            af: 0.3,
            bulge: 3.2,
            grooves: const [(math.pi, 0.07, 0.4)]),
        // Tibialis along the shin.
        _Patch(const ['Calves'],
            t0: 0.52, t1: 0.86, aHalf: 0.4, af: 0.25, bulge: 1.2),
      ],
    );
    // Foot pointing toward the viewer.
    ellipsoid(87, 404, 9, 7.5, 6, 16, 7, 12);
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
    // For each vertex, compare the average neighbour position against its
    // tangent plane: neighbours in front of the plane (along the normal) mean
    // the surface bends inward there — a groove between muscle bellies — so
    // the vertex darkens, drawing the anatomy chart's separation lines.
    final nVerts = pos.length ~/ 3;
    final acc = Float64List(nVerts * 3);
    final cnt = Int32List(nVerts);
    void edge(int a, int b) {
      acc[a * 3] += pos[b * 3];
      acc[a * 3 + 1] += pos[b * 3 + 1];
      acc[a * 3 + 2] += pos[b * 3 + 2];
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
      ao[i] = (1 - concave * 0.6).clamp(0.45, 1.1).toDouble();
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
