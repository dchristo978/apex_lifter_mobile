import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/models.dart';
import '../providers/auth_provider.dart';
import '../providers/leaderboard_provider.dart';
import 'public_profile_screen.dart';

/// Dedicated ranking page for a single machine, opened from the machine
/// picker on the Leaderboard tab. Hosts the leaderboard filters and results.
class MachineLeaderboardScreen extends StatefulWidget {
  const MachineLeaderboardScreen({super.key, required this.machine});

  final Machine machine;

  @override
  State<MachineLeaderboardScreen> createState() =>
      _MachineLeaderboardScreenState();
}

class _MachineLeaderboardScreenState extends State<MachineLeaderboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final board = context.read<LeaderboardProvider>();
      board.machineId = widget.machine.id;
      board.refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final board = context.watch<LeaderboardProvider>();
    final myUserId = context.watch<AuthProvider>().user?.id;
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(widget.machine.name),
            if (widget.machine.muscleGroup != null)
              Text(
                widget.machine.muscleGroup!,
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
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _filterChip(
                    context,
                    label: board.type == 'single'
                        ? l10n.pure1rm
                        : l10n.est1rmMulti,
                    onTap: () {
                      board.type = board.type == 'single' ? 'multi' : 'single';
                      board.refresh();
                    },
                  ),
                  const SizedBox(width: 8),
                  _filterChip(
                    context,
                    label: board.period == 'weekly' ? l10n.weekly : l10n.monthly,
                    onTap: () {
                      board.period =
                          board.period == 'weekly' ? 'monthly' : 'weekly';
                      board.refresh();
                    },
                  ),
                  const SizedBox(width: 8),
                  _cycleChip<String?>(
                    context,
                    label: switch (board.gender) {
                      'male' => l10n.genderMale,
                      'female' => l10n.genderFemale,
                      _ => l10n.allGenders,
                    },
                    values: const [null, 'male', 'female'],
                    current: board.gender,
                    onChanged: (v) {
                      board.gender = v;
                      board.refresh();
                    },
                  ),
                  const SizedBox(width: 8),
                  _cycleChip<String?>(
                    context,
                    label: board.ageBracket == null
                        ? l10n.allAges
                        : l10n.ageFilter(board.ageBracket!),
                    values: const [null, 'u18', '18-29', '30-39', '40+'],
                    current: board.ageBracket,
                    onChanged: (v) {
                      board.ageBracket = v;
                      board.refresh();
                    },
                  ),
                  const SizedBox(width: 8),
                  _cycleChip<String?>(
                    context,
                    label: board.weightClass == null
                        ? l10n.allWeights
                        : l10n.weightFilter(board.weightClass!),
                    values: const [null, 'u60', '60-74', '75-89', '90+'],
                    current: board.weightClass,
                    onChanged: (v) {
                      board.weightClass = v;
                      board.refresh();
                    },
                  ),
                ],
              ),
            ),
          ),
          if (board.myRank != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                color: Theme.of(context).colorScheme.primaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(l10n.yourPosition(board.myRank!),
                      style: Theme.of(context).textTheme.titleMedium),
                ),
              ),
            ),
          Expanded(
            child: board.loading
                ? const Center(child: CircularProgressIndicator())
                : board.entries.isEmpty
                    ? _emptyState(context, board)
                    : RefreshIndicator(
                        onRefresh: () => board.refresh(),
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                          itemCount: board.entries.length,
                          itemBuilder: (context, i) =>
                              _entryTile(context, board.entries[i], myUserId),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState(BuildContext context, LeaderboardProvider board) {
    final l10n = AppLocalizations.of(context);
    final hasCategoryFilters = board.gender != null ||
        board.ageBracket != null ||
        board.weightClass != null;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.leaderboard_outlined,
                size: 48, color: Theme.of(context).colorScheme.onSurfaceVariant),
            const SizedBox(height: 12),
            Text(
              board.error ?? l10n.noOneLogged,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.broadenSearch,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                if (board.period == 'weekly')
                  _suggestionButton(
                    icon: Icons.calendar_month,
                    label: l10n.viewMonthly,
                    onTap: () {
                      board.period = 'monthly';
                      board.refresh();
                    },
                  ),
                _suggestionButton(
                  icon: Icons.swap_horiz,
                  label: board.type == 'single'
                      ? l10n.viewEst1rm
                      : l10n.viewPure1rm,
                  onTap: () {
                    board.type = board.type == 'single' ? 'multi' : 'single';
                    board.refresh();
                  },
                ),
                if (hasCategoryFilters)
                  _suggestionButton(
                    icon: Icons.filter_alt_off,
                    label: l10n.clearFilters,
                    onTap: () {
                      board.gender = null;
                      board.ageBracket = null;
                      board.weightClass = null;
                      board.refresh();
                    },
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              l10n.orPickAnotherMachine,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }

  Widget _suggestionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return FilledButton.tonalIcon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label),
    );
  }

  Widget _entryTile(
      BuildContext context, LeaderboardEntry entry, int? myUserId) {
    final l10n = AppLocalizations.of(context);
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
        leading: CircleAvatar(child: Text(medal ?? '${entry.rank}')),
        title: Text(isMe ? l10n.youSuffix(entry.userName) : entry.userName),
        subtitle: Text(l10n.entrySubtitle(
            entry.weightKg.toStringAsFixed(entry.weightKg % 1 == 0 ? 0 : 1),
            entry.reps)),
        trailing: Text(
          '${entry.value.toStringAsFixed(1)} kg',
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        onTap: isMe
            ? null
            : () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => PublicProfileScreen(
                      userId: entry.userId,
                      initialName: entry.userName,
                    ),
                  ),
                ),
      ),
    );
  }

  Widget _filterChip(BuildContext context,
      {required String label, required VoidCallback onTap}) {
    return ActionChip(label: Text(label), onPressed: onTap);
  }

  Widget _cycleChip<T>(
    BuildContext context, {
    required String label,
    required List<T> values,
    required T current,
    required ValueChanged<T> onChanged,
  }) {
    return ActionChip(
      label: Text(label),
      onPressed: () {
        final next = values[(values.indexOf(current) + 1) % values.length];
        onChanged(next);
      },
    );
  }
}
