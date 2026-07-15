import 'dart:async';
import 'dart:math' as math;

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';

/// Gold-heavy palette shared by every celebration in the app.
const List<Color> kCelebrationColors = [
  Color(0xFFFFD700), // gold
  Color(0xFFFFB300), // amber
  Color(0xFFFFF176), // light gold
  Color(0xFFFF8F00), // deep amber
  Color(0xFFFFFFFF),
];

/// Fire a short full-screen confetti blast: two cannons in the top corners
/// shooting inwards. Used when a challenge is created, judged, or won, and
/// when a medal is tapped. Fire-and-forget: the overlay removes itself.
void celebrate(BuildContext context) {
  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) return;
  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => _CelebrationOverlay(onDone: () => entry.remove()),
  );
  overlay.insert(entry);
}

class _CelebrationOverlay extends StatefulWidget {
  const _CelebrationOverlay({required this.onDone});

  final VoidCallback onDone;

  @override
  State<_CelebrationOverlay> createState() => _CelebrationOverlayState();
}

class _CelebrationOverlayState extends State<_CelebrationOverlay> {
  final _left = ConfettiController(duration: const Duration(milliseconds: 700));
  final _right =
      ConfettiController(duration: const Duration(milliseconds: 700));
  Timer? _cleanup;

  @override
  void initState() {
    super.initState();
    _left.play();
    _right.play();
    // Give the last particles time to fall before tearing the overlay down.
    _cleanup = Timer(const Duration(milliseconds: 3500), widget.onDone);
  }

  @override
  void dispose() {
    _cleanup?.cancel();
    _left.dispose();
    _right.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          Align(
            alignment: Alignment.topLeft,
            child: ConfettiWidget(
              confettiController: _left,
              blastDirection: math.pi / 4, // down-right
              emissionFrequency: 0.6,
              numberOfParticles: 12,
              maxBlastForce: 35,
              minBlastForce: 10,
              gravity: 0.25,
              colors: kCelebrationColors,
            ),
          ),
          Align(
            alignment: Alignment.topRight,
            child: ConfettiWidget(
              confettiController: _right,
              blastDirection: 3 * math.pi / 4, // down-left
              emissionFrequency: 0.6,
              numberOfParticles: 12,
              maxBlastForce: 35,
              minBlastForce: 10,
              gravity: 0.25,
              colors: kCelebrationColors,
            ),
          ),
        ],
      ),
    );
  }
}
