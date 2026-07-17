// ⚠️ HIDDEN — ENTIRE FILE COMMENTED OUT. ⚠️
//
// Dev-only harness (not shipped) for the flutter_scene 3D muscle model, which
// only compiles on the Flutter *master* channel. The app is back on stable
// 3.35.7, and lib/widgets/muscle_3d_view.dart is commented out along with the
// flutter_scene deps in pubspec.yaml, so this harness is disabled too.
//
// The pure-Dart CustomPaint mesh ([MuscleBody]) still renders fine on stable,
// so it can be previewed without this harness while the feature is hidden.
//
// To restore: switch to the master channel and uncomment this file along with
// muscle_3d_view.dart and the flutter_scene deps.
//   flutter run -d chrome -t lib/dev_muscle_preview.dart
/*
import 'package:flutter/material.dart';

import 'widgets/muscle_3d_view.dart';

void main() => runApp(const _PreviewApp());

class _PreviewApp extends StatelessWidget {
  const _PreviewApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(scaffoldBackgroundColor: const Color(0xFF0B0E16)),
      home: const Scaffold(
        body: SafeArea(
          child: Muscle3DView(
            activeGroups: {
              'Chest', 'Quadriceps', 'Biceps', 'Abdominals', 'Calves',
              'Glutes', 'Hamstrings', 'Lats',
            },
            intensity: {
              'Chest': 1.0, 'Quadriceps': 0.7, 'Biceps': 0.35,
              'Abdominals': 0.5, 'Calves': 0.4, 'Glutes': 0.9,
              'Hamstrings': 0.8, 'Lats': 0.45,
            },
          ),
        ),
      ),
    );
  }
}
*/
