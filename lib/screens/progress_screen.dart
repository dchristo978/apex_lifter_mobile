import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/models.dart';
import '../services/api_client.dart';

/// Estimated-1RM progression over time for a single machine (MVP 2 #3).
class ProgressScreen extends StatefulWidget {
  const ProgressScreen({
    super.key,
    required this.machineId,
    required this.machineName,
  });

  final int machineId;
  final String machineName;

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  List<ProgressPoint>? _points;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _error = null;
      _points = null;
    });
    try {
      final api = context.read<ApiClient>();
      final json = await api.get('/machines/${widget.machineId}/progress');
      final points = (json['points'] as List)
          .map((p) => ProgressPoint.fromJson(p as Map<String, dynamic>))
          .toList();
      if (mounted) setState(() => _points = points);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text(
              AppLocalizations.of(context).progressTitle(widget.machineName))),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 140),
          children: [_buildBody(context)],
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Center(
            child: Text(_error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error))),
      );
    }
    if (_points == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    final points = _points!;
    if (points.length < 2) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Center(
          child: Text(
            l10n.needTwoDays,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final first = points.first;
    final last = points.last;
    final delta = last.estimated1rm - first.estimated1rm;
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.est1rmOverTime,
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 4),
        Text(
          l10n.deltaSince(
            '${delta >= 0 ? '+' : ''}${delta.toStringAsFixed(1)}',
            DateFormat('d MMM').format(first.date),
          ),
          style: TextStyle(
            color: delta >= 0 ? Colors.greenAccent : scheme.error,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 20, 16, 12),
            child: SizedBox(
              height: 220,
              child: CustomPaint(
                painter: _LineChartPainter(points, scheme.primary),
                child: const SizedBox.expand(),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(l10n.dailyRecord, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        ...points.reversed.map(
          (p) => Card(
            child: ListTile(
              dense: true,
              leading: const Icon(Icons.show_chart),
              title: Text(l10n.est1rmValue(p.estimated1rm.toStringAsFixed(1))),
              subtitle: Text(
                  '${p.weightKg.toStringAsFixed(p.weightKg % 1 == 0 ? 0 : 1)} kg × ${p.reps}'),
              trailing: Text(DateFormat('d MMM yy').format(p.date)),
            ),
          ),
        ),
      ],
    );
  }
}

class _LineChartPainter extends CustomPainter {
  _LineChartPainter(this.points, this.lineColor);

  final List<ProgressPoint> points;
  final Color lineColor;

  @override
  void paint(Canvas canvas, Size size) {
    const leftPad = 40.0;
    const bottomPad = 24.0;
    final chartW = size.width - leftPad;
    final chartH = size.height - bottomPad;

    final values = points.map((p) => p.estimated1rm).toList();
    var minV = values.reduce((a, b) => a < b ? a : b);
    var maxV = values.reduce((a, b) => a > b ? a : b);
    if (maxV == minV) {
      maxV += 1;
      minV -= 1;
    }
    final range = maxV - minV;

    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.10)
      ..strokeWidth = 1;
    final labelStyle = TextStyle(
        color: Colors.white.withValues(alpha: 0.55), fontSize: 10);

    // Horizontal grid lines + y labels.
    for (var i = 0; i <= 3; i++) {
      final y = chartH - (chartH * i / 3);
      canvas.drawLine(Offset(leftPad, y), Offset(size.width, y), gridPaint);
      final v = minV + range * i / 3;
      final tp = TextPainter(
        text: TextSpan(text: v.toStringAsFixed(0), style: labelStyle),
        textDirection: ui.TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(leftPad - tp.width - 6, y - tp.height / 2));
    }

    Offset pointAt(int i) {
      final x = points.length == 1
          ? leftPad + chartW / 2
          : leftPad + chartW * i / (points.length - 1);
      final y = chartH - chartH * (values[i] - minV) / range;
      return Offset(x, y);
    }

    // Area fill.
    final fillPath = Path()..moveTo(leftPad, chartH);
    for (var i = 0; i < points.length; i++) {
      fillPath.lineTo(pointAt(i).dx, pointAt(i).dy);
    }
    fillPath
      ..lineTo(pointAt(points.length - 1).dx, chartH)
      ..close();
    canvas.drawPath(
      fillPath,
      Paint()..color = lineColor.withValues(alpha: 0.15),
    );

    // Line.
    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round;
    final linePath = Path()..moveTo(pointAt(0).dx, pointAt(0).dy);
    for (var i = 1; i < points.length; i++) {
      linePath.lineTo(pointAt(i).dx, pointAt(i).dy);
    }
    canvas.drawPath(linePath, linePaint);

    // Dots.
    final dotPaint = Paint()..color = lineColor;
    for (var i = 0; i < points.length; i++) {
      canvas.drawCircle(pointAt(i), 3, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter old) =>
      old.points != points || old.lineColor != lineColor;
}
