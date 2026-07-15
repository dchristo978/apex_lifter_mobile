import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// A real-time 3D anatomical figure, rendered from a procedural triangle mesh
/// — no image assets, no plugins.
///
/// The body is built once as ~2 300 vertices / ~4 400 triangles: generalized
/// cylinders for the torso and limbs, ellipsoids for head and feet. Muscles
/// are *geometry*: each muscle group displaces the surface outward (pec
/// plates, six-pack ridges, quad heads, glute spheres, gastrocnemius bulge),
/// so definition comes from actual light on actual shape.
///
/// Every frame the mesh is rotated by [yaw] about the body's vertical axis,
/// perspective-projected, lit per vertex by a world-fixed lamp (diffuse +
/// specular), back-face culled, depth-sorted and drawn with a single
/// [Canvas.drawVertices] call — Gouraud-shaded, cheap enough to follow a drag
/// gesture in real time.
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
/// alba, spine) and [mod] sculpts ridges like the six-pack rows.
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

  double weight(double t, double th) {
    double band(double v, double lo, double hi, double f) {
      if (v < lo - f || v > hi + f) return 0;
      if (v < lo) return (v - (lo - f)) / f;
      if (v > hi) return ((hi + f) - v) / f;
      return 1;
    }

    final wT = band(t, t0, t1, tf);
    if (wT == 0) return 0;
    final d = math.min(
        _wrapAbs(th - aCenter), _wrapAbs(th + aCenter)); // mirror symmetric
    final wA = band(d, 0, aHalf, af);
    if (wA == 0) return 0;

    var w = wT * wA;
    for (final g in grooves) {
      final gd = _wrapAbs(th - g.$1);
      w *= 1 - g.$3 * math.exp(-(gd * gd) / (2 * g.$2 * g.$2));
    }
    if (mod != null) w *= mod!(t, th);
    return w.clamp(0.0, 1.2);
  }

  static double _wrapAbs(double a) {
    a = a % (2 * math.pi);
    if (a < 0) a += 2 * math.pi;
    return a > math.pi ? 2 * math.pi - a : a;
  }
}

/// The immutable rest-pose mesh: positions, smooth normals, per-vertex muscle
/// ownership (patch-set index + weight) and the triangle index list.
class _Mesh {
  _Mesh(this.pos, this.normal, this.setId, this.setWeight, this.tris,
      this.faceBias, this.groupSets);
  final Float32List pos; // x,y,z triples
  final Float32List normal; // matching triples
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
  static const Color _skin = Color(0xFFB9BFC9);
  static const Color _muscle = Color(0xFFA6ADB8);
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

    // World-fixed lamp: up-left, in front of the viewer. The body rotates
    // under it, so shading sweeps around the figure as it turns.
    const lx = -0.42, ly = -0.48, lz = 0.77; // normalized
    // Half-vector for specular (light + view(0,0,1), normalized).
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

      // Lambert diffuse + a touch of specular.
      final diff = math.max(0.0, nx * lx + ny * ly + nz * lz);
      final lum = 0.34 + 0.66 * diff;
      final specDot = math.max(0.0, nx * hx + ny * hy + nz * hz);
      final spec = specDot * specDot * specDot * specDot; // ^4
      final sp = spec * spec * spec * 55; // ≈ ^12, scaled to 0..55
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
    faces.sort((p, q) => p.$1.compareTo(q.$1)); // far first

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
          // Strongest patch owns the vertex; all patches displace it.
          var disp = 0.0;
          var bestW = 0.0;
          var bestSet = -1;
          for (final p in patches) {
            final w = p.weight(t, th);
            if (w <= 0) continue;
            disp += p.bulge * w;
            if (w > bestW) {
              bestW = w;
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

    /// An ellipsoid (head, feet) — poles included as degenerate rings.
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

    // ── Torso: V-taper barrel with chest, abs, back musculature ────────────
    tube(
      y0: 80,
      y1: 216,
      cx0: 100,
      cx1: 100,
      rPts: const [(0, 37), (0.16, 36), (0.55, 27), (0.78, 26), (1, 28.5)],
      zRatio: 0.58,
      rings: 32,
      segs: 32,
      capTop: 0.07,
      capBottom: 0.12,
      bias: 0.8,
      patches: [
        // Pecs: broad plates with the sternum groove between them.
        _Patch(const ['Chest'],
            t0: 0.05,
            t1: 0.30,
            tf: 0.07,
            aHalf: 0.95,
            af: 0.28,
            bulge: 3.8,
            grooves: const [(0, 0.12, 0.65)]),
        // Six-pack: ridged rows + linea alba down the middle.
        _Patch(const ['Abdominals'],
            t0: 0.38,
            t1: 0.86,
            tf: 0.07,
            aHalf: 0.34,
            af: 0.14,
            bulge: 2.4,
            grooves: const [(0, 0.07, 0.45)],
            mod: (t, th) =>
                0.62 + 0.38 * math.cos(2 * math.pi * (t - 0.38) / 0.185)),
        // Obliques framing the six-pack.
        _Patch(const ['Abdominals'],
            t0: 0.44, t1: 0.84, aCenter: 0.58, aHalf: 0.17, bulge: 1.4),
        // Traps across the upper back.
        _Patch(const ['Traps'],
            t0: 0.0,
            t1: 0.2,
            tf: 0.1,
            aCenter: math.pi,
            aHalf: 1.4,
            af: 0.5,
            bulge: 2.0,
            grooves: const [(math.pi, 0.09, 0.4)]),
        // Rhomboids / teres between the shoulder blades.
        _Patch(const ['Upper Back'],
            t0: 0.2,
            t1: 0.44,
            aCenter: math.pi - 0.5,
            aHalf: 0.45,
            bulge: 1.9),
        // Lats: wings high on the back, tapering toward the waist.
        _Patch(const ['Lats'],
            t0: 0.36,
            t1: 0.72,
            tf: 0.08,
            aCenter: math.pi - 0.5,
            aHalf: 0.38,
            af: 0.22,
            bulge: 2.4),
        // Erectors with the spine groove.
        _Patch(const ['Lower Back'],
            t0: 0.5,
            t1: 0.97,
            aCenter: math.pi,
            aHalf: 0.3,
            af: 0.12,
            bulge: 1.5,
            grooves: const [(math.pi, 0.07, 0.55)]),
      ],
    );

    // ── Neck (traps rise up its back) ──────────────────────────────────────
    tube(
      y0: 50,
      y1: 86,
      cx0: 100,
      cx1: 100,
      rPts: const [(0, 7), (1, 13.5)],
      zRatio: 0.9,
      rings: 6,
      segs: 14,
      capTop: 0,
      capBottom: 0,
      patches: [
        _Patch(const ['Traps', 'Neck'],
            t0: 0.3,
            t1: 1,
            tf: 0.2,
            aCenter: math.pi,
            aHalf: 1.3,
            af: 0.5,
            bulge: 1.0),
      ],
    );

    // ── Head ───────────────────────────────────────────────────────────────
    ellipsoid(100, 34, 0, 15, 19, 16, 9, 16);

    // ── Left arm (delts, biceps, triceps, forearm), then mirrored ─────────
    var v0 = pos.length ~/ 3;
    var t0 = tris.length;
    tube(
      y0: 86,
      y1: 228,
      cx0: 57,
      cx1: 47,
      rPts: const [(0, 11.5), (0.32, 8.4), (0.5, 8.6), (1, 4.6)],
      rings: 18,
      segs: 13,
      capTop: 0.08,
      capBottom: 0.05,
      patches: [
        // Deltoid cap wrapping the whole shoulder.
        _Patch(const ['Shoulders'],
            t0: 0.0, t1: 0.16, tf: 0.07, aHalf: 3.2, af: 0.4, bulge: 2.6),
        _Patch(const ['Biceps'],
            t0: 0.2, t1: 0.42, tf: 0.06, aHalf: 0.95, af: 0.35, bulge: 2.2),
        _Patch(const ['Triceps'],
            t0: 0.2,
            t1: 0.48,
            tf: 0.06,
            aCenter: math.pi,
            aHalf: 0.95,
            af: 0.35,
            bulge: 1.9),
        _Patch(const ['Forearms'],
            t0: 0.55, t1: 0.85, tf: 0.08, aHalf: 3.2, af: 0.4, bulge: 1.1),
      ],
    );
    mirror(v0, t0);

    // ── Left leg (glutes, quads, hams, calves), then mirrored ─────────────
    v0 = pos.length ~/ 3;
    t0 = tris.length;
    tube(
      y0: 196,
      y1: 400,
      cx0: 87.5,
      cx1: 88.5,
      rPts: const [(0, 16), (0.44, 9.6), (0.6, 10), (1, 5.4)],
      zRatio: 0.9,
      rings: 26,
      segs: 20,
      capTop: 0.05,
      capBottom: 0.05,
      patches: [
        // Glute: the big sphere up back.
        _Patch(const ['Glutes'],
            t0: 0.02,
            t1: 0.22,
            tf: 0.08,
            aCenter: math.pi,
            aHalf: 1.15,
            af: 0.35,
            bulge: 3.4),
        // Quads: three heads sweeping the front of the thigh.
        _Patch(const ['Quadriceps', 'Adductors'],
            t0: 0.07,
            t1: 0.47,
            tf: 0.07,
            aHalf: 1.05,
            af: 0.3,
            bulge: 2.6,
            mod: (t, th) => 0.8 + 0.2 * math.cos(th * 3.4)),
        // Hamstrings with the split between the two heads.
        _Patch(const ['Hamstrings'],
            t0: 0.26,
            t1: 0.52,
            tf: 0.06,
            aCenter: math.pi,
            aHalf: 0.95,
            af: 0.3,
            bulge: 2.2,
            grooves: const [(math.pi, 0.09, 0.35)]),
        // Gastrocnemius: twin heads bulging the upper calf.
        _Patch(const ['Calves'],
            t0: 0.57,
            t1: 0.8,
            tf: 0.06,
            aCenter: math.pi,
            aHalf: 1.0,
            af: 0.3,
            bulge: 2.6,
            grooves: const [(math.pi, 0.08, 0.3)]),
        // Tibialis along the shin.
        _Patch(const ['Calves'],
            t0: 0.56, t1: 0.86, aHalf: 0.4, af: 0.25, bulge: 0.9),
      ],
    );
    mirror(v0, t0);

    // ── Feet: forward-pointing ellipsoids, then mirrored ───────────────────
    v0 = pos.length ~/ 3;
    t0 = tris.length;
    ellipsoid(87, 401, 7, 7, 6, 14, 6, 10);
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

    return _Mesh(
      Float32List.fromList(pos),
      normal,
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
