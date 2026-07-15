import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

/// A lifter's weekly gym streak — one calendar week (Mon–Sun) with at least one
/// session keeps the flame going. Shown on both the owner's profile and the
/// public profile. When [weeks] is 0 the card falls into a muted "start your
/// streak" state.
class StreakCard extends StatelessWidget {
  const StreakCard({super.key, required this.weeks});

  final int weeks;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final active = weeks > 0;

    // A cool blue gradient for an active streak; a flat muted surface when idle.
    final flameStart = active ? const Color(0xFF409CFF) : scheme.surfaceContainerHigh;
    final flameEnd = active ? const Color(0xFF007AFF) : scheme.surfaceContainerHigh;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              flameStart.withValues(alpha: active ? 0.22 : 0.35),
              flameEnd.withValues(alpha: active ? 0.28 : 0.35),
            ],
          ),
          border: Border.all(
            color: active
                ? const Color(0xFF409CFF).withValues(alpha: 0.45)
                : scheme.outlineVariant,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            _FlameBadge(weeks: weeks, active: active),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.streakTitle,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                          letterSpacing: 0.5,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l10n.weekStreakLabel(weeks),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: active ? Colors.white : scheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    active ? l10n.streakActiveHint : l10n.streakStartHint,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The circular flame emblem with the week count layered on top.
class _FlameBadge extends StatelessWidget {
  const _FlameBadge({required this.weeks, required this.active});

  final int weeks;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: active
            ? const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF5AC8FA), Color(0xFF007AFF)],
              )
            : null,
        color: active ? null : scheme.surfaceContainerHighest,
        boxShadow: active
            ? [
                BoxShadow(
                  color: const Color(0xFF007AFF).withValues(alpha: 0.5),
                  blurRadius: 16,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            Icons.local_fire_department,
            size: 34,
            color: active
                ? Colors.white.withValues(alpha: 0.35)
                : scheme.onSurfaceVariant.withValues(alpha: 0.4),
          ),
          Text(
            '$weeks',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: active ? Colors.white : scheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}
