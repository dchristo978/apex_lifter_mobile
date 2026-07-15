import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/models.dart';
import '../providers/auth_provider.dart';
import '../providers/gym_provider.dart';
import '../widgets/user_avatar.dart';
import 'create_challenge_screen.dart';
import 'login_screen.dart';
import 'public_profile_screen.dart';

/// A gym's own leaderboard: each lifter's best set logged at this branch,
/// ranked by estimated 1RM. Public — guests can browse, but challenging
/// someone requires logging in first.
class GymLeaderboardScreen extends StatefulWidget {
  const GymLeaderboardScreen({super.key, required this.gym});

  final Gym gym;

  @override
  State<GymLeaderboardScreen> createState() => _GymLeaderboardScreenState();
}

class _GymLeaderboardScreenState extends State<GymLeaderboardScreen> {
  List<GymLeaderboardEntry> _entries = [];
  String _period = 'weekly';
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final entries = await context
          .read<GymProvider>()
          .gymLeaderboard(widget.gym.id, period: _period);
      if (mounted) setState(() => _entries = entries);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  bool get _loggedIn =>
      context.read<AuthProvider>().status == AuthStatus.authenticated;

  /// Guests are sent to the login screen; lifters go straight to the
  /// challenge form against [entry].
  void _challenge(GymLeaderboardEntry entry) {
    if (!_loggedIn) {
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.loginToChallenge)),
      );
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CreateChallengeScreen(
          opponentId: entry.userId,
          opponentName: entry.userName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(widget.gym.name),
            Text(
              widget.gym.address,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                ActionChip(
                  avatar: const Icon(Icons.calendar_today, size: 16),
                  label: Text(_period == 'weekly' ? l10n.weekly : l10n.monthly),
                  onPressed: () {
                    _period = _period == 'weekly' ? 'monthly' : 'weekly';
                    _load();
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _entries.isEmpty
                    ? _emptyState(context, l10n)
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                          itemCount: _entries.length,
                          itemBuilder: (context, i) =>
                              _entryTile(context, _entries[i]),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState(BuildContext context, AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.leaderboard_outlined,
                size: 48,
                color: Theme.of(context).colorScheme.onSurfaceVariant),
            const SizedBox(height: 12),
            Text(
              _error ?? l10n.gymLeaderboardEmpty,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            if (_period == 'weekly') ...[
              const SizedBox(height: 16),
              FilledButton.tonalIcon(
                onPressed: () {
                  _period = 'monthly';
                  _load();
                },
                icon: const Icon(Icons.calendar_month, size: 18),
                label: Text(l10n.viewMonthly),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _entryTile(BuildContext context, GymLeaderboardEntry entry) {
    final l10n = AppLocalizations.of(context);
    final myUserId = context.watch<AuthProvider>().user?.id;
    final isMe = entry.userId == myUserId;
    final medal = switch (entry.rank) {
      1 => '🥇',
      2 => '🥈',
      3 => '🥉',
      _ => null,
    };

    return Card(
      color: isMe ? Theme.of(context).colorScheme.secondaryContainer : null,
      child: ListTile(
        contentPadding: const EdgeInsets.fromLTRB(16, 4, 8, 4),
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 28,
              child: Text(
                medal ?? '${entry.rank}',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const SizedBox(width: 8),
            UserAvatar(
                name: entry.userName, avatarUrl: entry.avatarUrl, radius: 18),
          ],
        ),
        title: Text(
          isMe ? l10n.youSuffix(entry.userName) : entry.userName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          l10n.gymEntrySubtitle(
            entry.weightKg.toStringAsFixed(entry.weightKg % 1 == 0 ? 0 : 1),
            entry.reps,
            entry.machineName,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${entry.value.toStringAsFixed(1)} kg',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            if (!isMe)
              IconButton(
                tooltip: l10n.challengeAction,
                icon: const Icon(Icons.sports_mma),
                color: Theme.of(context).colorScheme.primary,
                onPressed: () => _challenge(entry),
              ),
          ],
        ),
        // Public profiles are an authenticated API — only navigate when
        // logged in; guests keep browsing the board.
        onTap: !isMe && _loggedIn
            ? () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => PublicProfileScreen(
                      userId: entry.userId,
                      initialName: entry.userName,
                    ),
                  ),
                )
            : null,
      ),
    );
  }
}
