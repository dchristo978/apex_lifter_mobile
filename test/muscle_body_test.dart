import 'dart:math' as math;

import 'package:apex_lifter_mobile/widgets/muscle_body.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(
        home:
            Scaffold(body: Center(child: SizedBox(height: 400, child: child))),
      );

  testWidgets('front (yaw 0) paints with active + intensity', (tester) async {
    await tester.pumpWidget(wrap(const MuscleBody(
      activeGroups: {'Chest', 'Quadriceps', 'Biceps'},
      intensity: {'Chest': 1.0, 'Quadriceps': 0.5, 'Biceps': 0.2},
    )));
    expect(tester.takeException(), isNull);
    expect(find.byType(MuscleBody), findsOneWidget);
  });

  testWidgets('back (yaw π) paints the back muscle set', (tester) async {
    await tester.pumpWidget(wrap(MuscleBody(
      yaw: math.pi,
      activeGroups: const {'Glutes', 'Hamstrings', 'Lats', 'Triceps'},
      intensity: const {'Glutes': 0.8, 'Hamstrings': 0.6},
    )));
    expect(tester.takeException(), isNull);
  });

  testWidgets('mid-rotation yaws paint without throwing', (tester) async {
    for (final yaw in [0.4, math.pi / 2, 2.2, -0.9]) {
      await tester.pumpWidget(wrap(MuscleBody(
        yaw: yaw,
        activeGroups: const {'Chest', 'Lats', 'Glutes'},
        intensity: const {'Chest': 0.9, 'Lats': 0.5},
      )));
      expect(tester.takeException(), isNull, reason: 'yaw $yaw threw');
    }
  });

  testWidgets('empty activation paints the untrained figure', (tester) async {
    await tester.pumpWidget(wrap(const MuscleBody()));
    expect(tester.takeException(), isNull);
  });
}
