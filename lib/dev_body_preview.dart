// Dev-only harness (not shipped): renders the CustomPaint [MuscleBody] mesh
// front and back, side by side, so the procedural figure can be compared
// against an anatomy reference while tuning geometry.
//   flutter run -d chrome -t lib/dev_body_preview.dart
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'widgets/muscle_body.dart';

void main() => runApp(const _PreviewApp());

const _active = {'Quadriceps', 'Glutes', 'Hamstrings', 'Calves'};
const _intensity = {
  'Quadriceps': 0.8,
  'Glutes': 0.75,
  'Hamstrings': 0.7,
  'Calves': 0.65,
};

class _PreviewApp extends StatelessWidget {
  const _PreviewApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(scaffoldBackgroundColor: const Color(0xFF0B0E16)),
      home: Scaffold(
        body: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              SizedBox(
                height: 640,
                child: MuscleBody(
                  yaw: 0,
                  activeGroups: _active,
                  intensity: _intensity,
                ),
              ),
              SizedBox(width: 24),
              SizedBox(
                height: 640,
                child: MuscleBody(
                  yaw: math.pi,
                  activeGroups: _active,
                  intensity: _intensity,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
