import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_scene/scene.dart';
import 'package:vector_math/vector_math.dart' as vm;

import 'muscle_glb_materials.dart';

/// The real-time 3D muscle model, rendered with flutter_scene (Flutter GPU /
/// Impeller) from the procedural body exported to `assets_src/muscle.glb`.
///
/// Each muscle group is its own glTF material (see [kMuscleMaterialGroups]);
/// this widget recolors those materials blue by training [intensity] and spins
/// the figure with a horizontal drag. Requires the Flutter master channel and
/// Impeller — [MuscleModelScreen] falls back to the CustomPaint mesh if this
/// throws.
class Muscle3DView extends StatefulWidget {
  const Muscle3DView({
    super.key,
    this.activeGroups = const {},
    this.intensity = const {},
    this.onError,
  });

  final Set<String> activeGroups;
  final Map<String, double> intensity;

  /// Invoked if the scene fails to load/render, so the host can fall back.
  final void Function(Object error)? onError;

  @override
  State<Muscle3DView> createState() => _Muscle3DViewState();
}

class _Muscle3DViewState extends State<Muscle3DView> {
  final Scene _scene = Scene();
  final List<MeshPrimitive> _primitives = [];
  bool _loaded = false;
  Object? _error;

  /// Yaw around the vertical axis in radians, driven by horizontal drags.
  double _yaw = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      await Scene.initializeStaticResources();
      final body = await loadScene('assets_src/muscle.glb');
      if (!mounted) return;

      // A key light from the upper-left-front plus a dim fill, matching the
      // CustomPaint version's lighting so the two paths look consistent.
      _scene.directionalLight = DirectionalLight(
        direction: vm.Vector3(-0.42, -0.62, -0.66),
        color: vm.Vector3(1, 1, 1),
        intensity: 3.4,
      );
      _scene.environmentIntensity = 0.35;
      _scene.exposure = 1.1;

      _collectPrimitives(body);
      _scene.add(body);
      _applyColors();
      setState(() => _loaded = true);
    } catch (e) {
      if (mounted) setState(() => _error = e);
      widget.onError?.call(e);
    }
  }

  /// Flatten every mesh primitive in the loaded subtree, in traversal order,
  /// so they line up with [kMuscleMaterialGroups] (index 0 = skin).
  void _collectPrimitives(Node node) {
    final mesh = node.mesh;
    if (mesh != null) _primitives.addAll(mesh.primitives);
    for (final child in node.children) {
      _collectPrimitives(child);
    }
  }

  /// sRGB → linear, since flutter_scene's baseColorFactor is linear RGBA.
  static double _lin(double c) => math.pow(c, 2.2).toDouble();

  vm.Vector4 _colorFor(List<String> groups) {
    if (groups.isEmpty) {
      // Skin.
      return vm.Vector4(_lin(0.76), _lin(0.78), _lin(0.82), 1);
    }
    double best = -1;
    for (final g in groups) {
      if (widget.activeGroups.contains(g)) {
        final i = widget.intensity[g] ?? 0.6;
        if (i > best) best = i;
      }
    }
    if (best < 0) {
      // Untrained muscle: neutral gray.
      return vm.Vector4(_lin(0.66), _lin(0.69), _lin(0.74), 1);
    }
    // Light blue → deep blue by intensity.
    final t = best.clamp(0.15, 1.0);
    double lerp(double a, double b) => a + (b - a) * t;
    final r = lerp(0.50, 0.04);
    final g = lerp(0.70, 0.24);
    final b = lerp(1.0, 0.63);
    return vm.Vector4(_lin(r), _lin(g), _lin(b), 1);
  }

  void _applyColors() {
    if (_primitives.length != kMuscleMaterialGroups.length) {
      // Mesh/manifest drift — leave the model its default gray rather than
      // mis-tinting the wrong muscles.
      return;
    }
    for (var i = 0; i < _primitives.length; i++) {
      final mat = _primitives[i].material;
      if (mat is PhysicallyBasedMaterial) {
        mat.baseColorFactor = _colorFor(kMuscleMaterialGroups[i]);
      }
    }
  }

  @override
  void didUpdateWidget(Muscle3DView old) {
    super.didUpdateWidget(old);
    if (old.activeGroups != widget.activeGroups ||
        old.intensity != widget.intensity) {
      _applyColors();
    }
  }

  @override
  void dispose() {
    _scene.removeAll();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      // Host handles fallback via onError; show nothing meaningful here.
      return const SizedBox.shrink();
    }
    if (!_loaded) {
      return const Center(child: CircularProgressIndicator());
    }
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onHorizontalDragUpdate: (d) => setState(() => _yaw += d.delta.dx * 0.012),
      child: SceneView(
        _scene,
        cameraBuilder: (elapsed) {
          const radius = 3.4;
          return PerspectiveCamera(
            position: vm.Vector3(
              math.sin(_yaw) * radius,
              0.15,
              math.cos(_yaw) * radius,
            ),
            target: vm.Vector3(0, 0, 0),
          );
        },
      ),
    );
  }
}
