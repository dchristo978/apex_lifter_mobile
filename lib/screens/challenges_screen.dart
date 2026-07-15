import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/models.dart';
import '../providers/challenge_provider.dart';
import '../widgets/challenge_widgets.dart';
import '../widgets/user_avatar.dart';
import 'challenge_detail_screen.dart';

/// The Challenge hub: the community Arena, the user's own challenges, and their
/// medal history.
class ChallengesScreen extends StatefulWidget {
  const ChallengesScreen({super.key, this.initialTab = 0});

  final int initialTab;

  @override
  State<ChallengesScreen> createState() => _ChallengesScreenState();
}

class _ChallengesScreenState extends State<ChallengesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _reload());
  }

  Future<void> _reload() async {
    final p = context.read<ChallengeProvider>();
    await Future.wait([
      p.loadArena().catchError((_) {}),
      p.loadMine().catchError((_) {}),
      p.loadHistory().catchError((_) {}),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final provider = context.watch<ChallengeProvider>();

    return DefaultTabController(
      length: 3,
      initialIndex: widget.initialTab,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.challengeArena),
          bottom: TabBar(
            tabs: [
              Tab(text: l10n.tabArena),
              Tab(text: l10n.tabMine),
              Tab(text: l10n.tabMedals),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _list(context, provider.arena, l10n.noArenaChallenges,
                loading: provider.loadingArena),
            _list(context, provider.mine, l10n.noChallengesYet,
                loading: provider.loadingMine),
            _medals(context, provider),
          ],
        ),
      ),
    );
  }

  Widget _list(BuildContext context, List<Challenge> items, String emptyText,
      {required bool loading}) {
    if (loading && items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    return RefreshIndicator(
      onRefresh: _reload,
      child: items.isEmpty
          ? ListView(
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 120),
                  child: Center(
                      child: Text(emptyText, textAlign: TextAlign.center)),
                ),
              ],
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              itemBuilder: (context, i) => _challengeCard(context, items[i]),
            ),
    );
  }

  Widget _medals(BuildContext context, ChallengeProvider provider) {
    final l10n = AppLocalizations.of(context);
    final won = provider.history
        .where((c) => c.winner != null && _wonByMe(c))
        .toList();

    return RefreshIndicator(
      onRefresh: _reload,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Text('🏅', style: TextStyle(fontSize: 40)),
                  const SizedBox(height: 8),
                  Text(l10n.medalsWithCount(provider.medals),
                      style: Theme.of(context).textTheme.headlineSmall),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (won.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 80),
              child: Center(
                  child: Text(l10n.noMedalsYet, textAlign: TextAlign.center)),
            )
          else
            for (final c in won) _challengeCard(context, c),
        ],
      ),
    );
  }

  bool _wonByMe(Challenge c) =>
      (c.myRole == 'challenger' && c.winnerId == c.challenger?.id) ||
      (c.myRole == 'opponent' && c.winnerId == c.opponent?.id);

  Widget _challengeCard(BuildContext context, Challenge c) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final (statusLabel, statusColor) = challengeStatus(l10n, scheme, c.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
              builder: (_) => ChallengeDetailScreen(challengeId: c.id)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _mini(c.challenger, c.winnerId),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(l10n.vs,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  _mini(c.opponent, c.winnerId),
                  const Spacer(),
                  Chip(
                    label: Text(statusLabel,
                        style: const TextStyle(fontSize: 11)),
                    visualDensity: VisualDensity.compact,
                    backgroundColor: statusColor.withValues(alpha: 0.2),
                    side: BorderSide(color: statusColor.withValues(alpha: 0.5)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${c.machineName ?? '—'} · ${l10n.challengeTarget(c.targetWeightKg.toStringAsFixed(c.targetWeightKg % 1 == 0 ? 0 : 1), c.targetReps, c.targetSets)}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              if (c.status == 'active') ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.how_to_vote,
                        size: 16, color: scheme.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Text(
                      l10n.tallyApproveReject(
                          c.tally.approvers, c.tally.rejecters),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const Spacer(),
                    if (c.canVote)
                      FilledButton.tonalIcon(
                        onPressed: () async {
                          final voted = await showVoteSheet(context, c);
                          if (voted) _reload();
                        },
                        icon: const Icon(Icons.gavel, size: 16),
                        label: Text(l10n.judge),
                        style: FilledButton.styleFrom(
                            visualDensity: VisualDensity.compact),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _mini(ChallengeParticipant? p, int? winnerId) {
    if (p == null) return const SizedBox.shrink();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        UserAvatar(name: p.name, avatarUrl: p.avatarUrl, radius: 14),
        const SizedBox(width: 4),
        if (winnerId == p.id) const Text('🏅', style: TextStyle(fontSize: 12)),
      ],
    );
  }
}
