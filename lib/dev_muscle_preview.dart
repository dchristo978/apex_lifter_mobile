// Dev-only harness (not shipped): renders just the flutter_scene 3D muscle
// model so it can be viewed in isolation, without the app's auth/backend.
//   flutter run -d chrome -t lib/dev_muscle_preview.dart
//   flutter build web -t lib/dev_muscle_preview.dart
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
