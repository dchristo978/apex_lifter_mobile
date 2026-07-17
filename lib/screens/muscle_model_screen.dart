import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/models.dart';
import '../services/api_client.dart';
// HIDDEN: the flutter_scene 3D path needs the Flutter master channel; the app
// is back on stable 3.35.7, so muscle_3d_view.dart is commented out and this
// screen renders the pure-Dart CustomPaint mesh below. See feature_flags.dart.
// import '../widgets/muscle_3d_view.dart';
import '../widgets/muscle_body.dart';

/// A rotatable 3D-style muscle model. The lifter drags left/right to spin the
/// figure around its vertical axis, revealing front and back; muscles trained
/// in the last 7 days glow blue, deeper blue the more they were worked.
class MuscleModelScreen extends StatefulWidget {
  const MuscleModelScreen({super.key});

  @override
  State<MuscleModelScreen> createState() => _MuscleModelScreenState();
}

class _MuscleModelScreenState extends State<MuscleModelScreen>
    with SingleTickerProviderStateMixin {
  MuscleActivation? _data;
  String? _error;

  /// Rotation about the vertical axis, in radians. 0 = facing front.
  double _angle = 0;

  /// Forced to false while the flutter_scene 3D path is commented out for the
  /// stable channel (see the import above) — the CustomPaint mesh is the only
  /// path that compiles on stable. Restore to `true` when re-enabling 3D.
  final bool _use3d = false;
  late final AnimationController _spin;
  Animation<double>? _snap;

  @override
  void initState() {
    super.initState();
    _spin = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..addListener(() {
        if (_snap != null) setState(() => _angle = _snap!.value);
      });
    _load();
  }

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _error = null;
      _data = null;
    });
    try {
      final api = context.read<ApiClient>();
      final json = await api.get('/insights/muscle-activation', {'days': '7'});
      if (mounted) {
        setState(() => _data = MuscleActivation.fromJson(json));
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  void _onDragUpdate(DragUpdateDetails d) {
    _spin.stop();
    setState(() => _angle += d.delta.dx * 0.012);
  }

  void _onDragEnd(DragEndDetails d) {
    // Carry a little momentum from the fling, then settle on the nearest face.
    final momentum = d.velocity.pixelsPerSecond.dx * 0.0004;
    final target = ((_angle + momentum) / math.pi).round() * math.pi;
    _snap = Tween<double>(begin: _angle, end: target.toDouble())
        .animate(CurvedAnimation(parent: _spin, curve: Curves.easeOutCubic));
    _spin.forward(from: 0);
  }

  bool get _showingFront => math.cos(_angle) >= 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.muscleModelTitle)),
      body: _buildBody(context, l10n),
    );
  }

  Widget _buildBody(BuildContext context, AppLocalizations l10n) {
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(_error!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).colorScheme.error)),
        ),
      );
    }
    final data = _data;
    if (data == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final active = data.trained.toSet();
    final intensity = {for (final g in data.groups) g.group: data.intensityFor(g.group)};

    return Column(
      children: [
        const SizedBox(height: 8),
        // The 3D scene rotates freely, so the FRONT/BACK caption only applies
        // to the CustomPaint fallback.
        if (!_use3d)
          Text(
            _showingFront ? l10n.frontView : l10n.backView,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  letterSpacing: 1.2,
                ),
          )
        else
          const SizedBox(height: 20),
        // HIDDEN: the flutter_scene branch that rendered Muscle3DView here is
        // commented out — it only compiles on the master channel. Restore it
        // alongside muscle_3d_view.dart when re-enabling the 3D path:
        //
        //   child: _use3d
        //       ? Padding(
        //           padding: const EdgeInsets.symmetric(vertical: 12),
        //           child: Muscle3DView(
        //             activeGroups: active,
        //             intensity: intensity,
        //             onError: (_) {
        //               if (mounted) setState(() => _use3d = false);
        //             },
        //           ),
        //         )
        //       : <the GestureDetector below>,
        Expanded(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onHorizontalDragUpdate: _onDragUpdate,
            onHorizontalDragEnd: _onDragEnd,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: _RotatingBody(
                  angle: _angle,
                  activeGroups: active,
                  intensity: intensity,
                ),
              ),
            ),
          ),
        ),
        _DragHint(text: l10n.swipeToRotate),
        _TrainedSummary(data: data),
        const SizedBox(height: 16),
      ],
    );
  }
}

/// Hosts the cylindrically-projected body. The rotation happens inside the
/// painter itself (muscles wrap around the torso, limbs orbit it), so there is
/// no flat plane flip here — just a mild dim toward edge-on and a ground
/// shadow to seat the figure in space.
class _RotatingBody extends StatelessWidget {
  const _RotatingBody({
    required this.angle,
    required this.activeGroups,
    required this.intensity,
  });

  final double angle;
  final Set<String> activeGroups;
  final Map<String, double> intensity;

  @override
  Widget build(BuildContext context) {
    // 1 when face-on to the viewer, 0 when edge-on mid-spin.
    final facing = math.cos(angle).abs();

    Widget body = SizedBox(
      height: 460,
      child: MuscleBody(
        yaw: angle,
        activeGroups: activeGroups,
        intensity: intensity,
      ),
    );

    // Slight dim toward edge-on, on top of the painter's own light sweep.
    final b = 0.78 + 0.22 * facing;
    body = ColorFiltered(
      colorFilter: ColorFilter.matrix([
        b, 0, 0, 0, 0, //
        0, b, 0, 0, 0, //
        0, 0, b, 0, 0, //
        0, 0, 0, 1, 0, //
      ]),
      child: body,
    );

    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        // Soft ground shadow that narrows as the body turns edge-on,
        // grounding the figure in space.
        Positioned(
          bottom: 0,
          child: Container(
            width: 70 + 60 * facing,
            height: 10,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.all(Radius.elliptical(70, 6)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.45),
                  blurRadius: 14,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
        ),
        body,
      ],
    );
  }
}

class _DragHint extends StatelessWidget {
  const _DragHint({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurfaceVariant;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.chevron_left, size: 18, color: color),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(color: color, fontSize: 12)),
        const SizedBox(width: 4),
        Icon(Icons.chevron_right, size: 18, color: color),
      ],
    );
  }
}

/// The list of muscle groups worked this week, shown as blue chips under the
/// model, with an encouraging empty state when nothing was trained.
class _TrainedSummary extends StatelessWidget {
  const _TrainedSummary({required this.data});
  final MuscleActivation data;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (data.trained.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        child: Text(l10n.noMuscleTrained,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium),
      );
    }

    // Busiest groups first.
    final groups = [...data.groups]..sort((a, b) => b.sets.compareTo(a.sets));

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.trainedThisWeek,
              style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final g in groups)
                Chip(
                  visualDensity: VisualDensity.compact,
                  backgroundColor: Color.lerp(const Color(0xFF7FB2FF),
                      const Color(0xFF0A3EA0), data.intensityFor(g.group)),
                  label: Text(
                    '${g.group} · ${g.sets}',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
