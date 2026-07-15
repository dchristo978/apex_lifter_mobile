import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/models.dart';
import '../providers/machine_provider.dart';
import 'challenges_screen.dart';
import 'machine_leaderboard_screen.dart';

/// Leaderboard tab: a searchable list of every machine, grouped by muscle
/// group. Picking a machine opens its dedicated ranking page.
class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MachineProvider>().loadMachines().catchError((_) {});
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MachineProvider>();
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.leaderboard),
        actions: [
          IconButton(
            tooltip: l10n.challengeArena,
            icon: const Icon(Icons.stadium),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ChallengesScreen()),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
              decoration: InputDecoration(
                hintText: l10n.searchMachine,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                      ),
                border: const OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ),
          Expanded(child: _body(context, provider, l10n)),
        ],
      ),
    );
  }

  Widget _body(
      BuildContext context, MachineProvider provider, AppLocalizations l10n) {
    if (!provider.loaded && provider.machines.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    // Filter + group.
    final grouped = <String, List<Machine>>{};
    provider.byMuscleGroup.forEach((group, machines) {
      final matches = _query.isEmpty
          ? machines
          : machines
              .where((m) => m.name.toLowerCase().contains(_query))
              .toList();
      if (matches.isNotEmpty) grouped[group] = matches;
    });

    if (grouped.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            l10n.noMachinesFound,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
        ),
      );
    }

    // Flatten into a list of (header | tile) rows.
    final rows = <Widget>[];
    grouped.forEach((group, machines) {
      rows.add(_sectionHeader(context, group, machines.length));
      for (final m in machines) {
        rows.add(_machineTile(context, m));
      }
    });

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      itemCount: rows.length,
      itemBuilder: (context, i) => rows[i],
    );
  }

  Widget _sectionHeader(BuildContext context, String group, int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 16, 4, 4),
      child: Row(
        children: [
          Text(
            group.toUpperCase(),
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                ),
          ),
          const SizedBox(width: 8),
          Text(
            '$count',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _machineTile(BuildContext context, Machine machine) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: const Icon(Icons.fitness_center, size: 20),
        ),
        title: Text(machine.name),
        subtitle: machine.muscleGroup != null ? Text(machine.muscleGroup!) : null,
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => MachineLeaderboardScreen(machine: machine),
          ),
        ),
      ),
    );
  }
}
