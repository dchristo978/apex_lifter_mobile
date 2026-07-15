import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/models.dart';
import '../services/api_client.dart';

/// Long-term retention insights: a training-frequency heatmap, a muscle-balance
/// radar (which groups you're neglecting), and strength standards that place
/// your big lifts against population norms.
class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key});

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  Heatmap? _heatmap;
  MuscleActivation? _balance;
  StrengthStandards? _standards;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _error = null;
      _loading = true;
    });
    try {
      final api = context.read<ApiClient>();
      final results = await Future.wait([
        api.get('/insights/heatmap'),
        api.get('/insights/muscle-activation', {'days': '30'}),
        api.get('/insights/strength-standards'),
      ]);
      if (!mounted) return;
      setState(() {
        _heatmap = Heatmap.fromJson(results[0]);
        _balance = MuscleActivation.fromJson(results[1]);
        _standards = StrengthStandards.fromJson(results[2]);
        _loading = false;
      });
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _error = e.message;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.insightsTitle)),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? ListView(children: [
                    Padding(
                      padding: const EdgeInsets.all(32),
                      child: Center(
                        child: Text(_error!,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.error)),
                      ),
                    ),
                  ])
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 140),
                    children: [
                      _SectionTitle(l10n.trainingFrequency),
                      const SizedBox(height: 8),
                      _HeatmapCard(heatmap: _heatmap!),
                      const SizedBox(height: 24),
                      _SectionTitle(l10n.muscleBalance),
                      const SizedBox(height: 8),
                      _MuscleBalanceCard(balance: _balance!),
                      const SizedBox(height: 24),
                      _SectionTitle(l10n.strengthStandards),
                      const SizedBox(height: 8),
                      _StandardsCard(standards: _standards!),
                    ],
                  ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) =>
      Text(text, style: Theme.of(context).textTheme.titleMedium);
}

// ─── Heatmap ────────────────────────────────────────────────────────────────

class _HeatmapCard extends StatelessWidget {
  const _HeatmapCard({required this.heatmap});
  final Heatmap heatmap;

  static const _cell = 13.0;
  static const _gap = 3.0;

  /// GitHub-style shade ramp for a day's set count.
  static Color _shade(int count) {
    if (count <= 0) return const Color(0xFF23262B);
    if (count <= 2) return const Color(0xFF11408C);
    if (count <= 5) return const Color(0xFF1E63D6);
    if (count <= 9) return const Color(0xFF4F8DF5);
    return const Color(0xFF9DC1FF);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // Build week columns from the first Monday on/before the range start.
    final start = heatmap.start;
    var firstMonday = start.subtract(Duration(days: (start.weekday - 1) % 7));
    final end = heatmap.end;
    final weeks = <DateTime>[];
    for (var d = firstMonday;
        !d.isAfter(end);
        d = d.add(const Duration(days: 7))) {
      weeks.add(d);
    }

    final total = heatmap.days.values.fold(0, (a, b) => a + b);
    final activeDays = heatmap.days.values.where((c) => c > 0).length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.heatmapSummary(total, activeDays),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              reverse: true, // latest weeks visible first
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      for (final week in weeks)
                        Padding(
                          padding: const EdgeInsets.only(right: _gap),
                          child: Column(
                            children: [
                              for (var day = 0; day < 7; day++)
                                Builder(builder: (_) {
                                  final date =
                                      week.add(Duration(days: day));
                                  final inRange = !date.isBefore(start) &&
                                      !date.isAfter(end);
                                  final count = inRange
                                      ? heatmap.countFor(date)
                                      : -1;
                                  return Container(
                                    width: _cell,
                                    height: _cell,
                                    margin:
                                        const EdgeInsets.only(bottom: _gap),
                                    decoration: BoxDecoration(
                                      color: inRange
                                          ? _shade(count)
                                          : Colors.transparent,
                                      borderRadius:
                                          BorderRadius.circular(3),
                                    ),
                                  );
                                }),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(l10n.less,
                    style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(width: 6),
                for (final c in const [0, 1, 3, 6, 10])
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Container(
                      width: _cell,
                      height: _cell,
                      decoration: BoxDecoration(
                        color: _shade(c),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                const SizedBox(width: 6),
                Text(l10n.more,
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Muscle balance radar ────────────────────────────────────────────────────

class _MuscleBalanceCard extends StatelessWidget {
  const _MuscleBalanceCard({required this.balance});
  final MuscleActivation balance;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final byGroup = balance.byGroup;
    final maxSets = balance.maxSets;

    final axes = balance.balanceGroups
        .map((g) => _RadarAxis(
              label: g,
              value: maxSets == 0
                  ? 0
                  : (byGroup[g]?.sets ?? 0) / maxSets,
            ))
        .toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
        child: Column(
          children: [
            Text(l10n.muscleBalanceCaption,
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center),
            const SizedBox(height: 12),
            AspectRatio(
              aspectRatio: 1,
              child: CustomPaint(
                painter: _RadarPainter(axes, scheme.primary),
                child: const SizedBox.expand(),
              ),
            ),
            if (balance.neglected.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: scheme.error.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  l10n.neglectedMuscles(
                      balance.neglected.take(4).join(', '), balance.days),
                  style: TextStyle(color: scheme.error),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RadarAxis {
  _RadarAxis({required this.label, required this.value});
  final String label;
  final double value; // 0..1
}

class _RadarPainter extends CustomPainter {
  _RadarPainter(this.axes, this.color);
  final List<_RadarAxis> axes;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (axes.isEmpty) return;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 34;
    final n = axes.length;

    final gridPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = Colors.white.withValues(alpha: 0.10);

    // Concentric rings.
    for (var ring = 1; ring <= 4; ring++) {
      final r = radius * ring / 4;
      final path = Path();
      for (var i = 0; i < n; i++) {
        final a = -math.pi / 2 + 2 * math.pi * i / n;
        final p = center + Offset(math.cos(a), math.sin(a)) * r;
        i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
      }
      path.close();
      canvas.drawPath(path, gridPaint);
    }

    // Spokes + labels.
    final labelStyle = TextStyle(
        color: Colors.white.withValues(alpha: 0.7), fontSize: 9);
    for (var i = 0; i < n; i++) {
      final a = -math.pi / 2 + 2 * math.pi * i / n;
      final dir = Offset(math.cos(a), math.sin(a));
      canvas.drawLine(center, center + dir * radius, gridPaint);

      final tp = TextPainter(
        text: TextSpan(text: axes[i].label, style: labelStyle),
        textDirection: ui.TextDirection.ltr,
        textAlign: TextAlign.center,
      )..layout(maxWidth: 60);
      final lp = center + dir * (radius + 16);
      tp.paint(canvas, lp - Offset(tp.width / 2, tp.height / 2));
    }

    // Value polygon.
    final valuePath = Path();
    for (var i = 0; i < n; i++) {
      final a = -math.pi / 2 + 2 * math.pi * i / n;
      final r = radius * axes[i].value.clamp(0.0, 1.0);
      final p = center + Offset(math.cos(a), math.sin(a)) * r;
      i == 0 ? valuePath.moveTo(p.dx, p.dy) : valuePath.lineTo(p.dx, p.dy);
    }
    valuePath.close();
    canvas.drawPath(valuePath, Paint()..color = color.withValues(alpha: 0.28));
    canvas.drawPath(
      valuePath,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = color,
    );

    // Vertices.
    final dot = Paint()..color = color;
    for (var i = 0; i < n; i++) {
      final a = -math.pi / 2 + 2 * math.pi * i / n;
      final r = radius * axes[i].value.clamp(0.0, 1.0);
      canvas.drawCircle(center + Offset(math.cos(a), math.sin(a)) * r, 2.5, dot);
    }
  }

  @override
  bool shouldRepaint(covariant _RadarPainter old) =>
      old.axes != axes || old.color != color;
}

// ─── Strength standards ──────────────────────────────────────────────────────

class _StandardsCard extends StatelessWidget {
  const _StandardsCard({required this.standards});
  final StrengthStandards standards;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (standards.needsProfile) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(l10n.standardsNeedProfile,
              style: Theme.of(context).textTheme.bodyMedium),
        ),
      );
    }
    if (standards.lifts.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(l10n.standardsNoLifts,
              style: Theme.of(context).textTheme.bodyMedium),
        ),
      );
    }
    return Column(
      children: [
        for (final lift in standards.lifts) _StandardTile(lift: lift),
      ],
    );
  }
}

class _StandardTile extends StatelessWidget {
  const _StandardTile({required this.lift});
  final StrengthLift lift;

  static const _levelColors = [
    Color(0xFF6C727C), // Untrained
    Color(0xFF3E7BD6), // Beginner
    Color(0xFF2E8B57), // Novice
    Color(0xFFD9A400), // Intermediate
    Color(0xFFE0662E), // Advanced
    Color(0xFFB0202E), // Elite
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final color = _levelColors[lift.levelIndex.clamp(0, 5)];
    // Progress bar fraction across the 5 named levels.
    final frac = (lift.levelIndex / 5).clamp(0.0, 1.0);

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(lift.name,
                      style: Theme.of(context).textTheme.titleSmall),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _levelLabel(l10n, lift.levelIndex),
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              l10n.standardsBest(lift.best1rm.toStringAsFixed(1),
                  lift.ratio.toStringAsFixed(2)),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: frac == 0 ? 0.04 : frac,
                minHeight: 8,
                backgroundColor: Colors.white.withValues(alpha: 0.08),
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
            if (lift.nextLevel != null && lift.nextTargetKg != null) ...[
              const SizedBox(height: 8),
              Text(
                l10n.standardsNext(
                    _levelName(l10n, lift.nextLevel!),
                    lift.nextTargetKg!.toStringAsFixed(1)),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _levelLabel(AppLocalizations l10n, int index) => switch (index) {
        0 => l10n.levelUntrained,
        1 => l10n.levelBeginner,
        2 => l10n.levelNovice,
        3 => l10n.levelIntermediate,
        4 => l10n.levelAdvanced,
        _ => l10n.levelElite,
      };

  String _levelName(AppLocalizations l10n, String english) => switch (english) {
        'Beginner' => l10n.levelBeginner,
        'Novice' => l10n.levelNovice,
        'Intermediate' => l10n.levelIntermediate,
        'Advanced' => l10n.levelAdvanced,
        'Elite' => l10n.levelElite,
        _ => english,
      };
}
