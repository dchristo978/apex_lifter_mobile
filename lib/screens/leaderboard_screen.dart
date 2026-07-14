import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../providers/auth_provider.dart';
import '../providers/leaderboard_provider.dart';
import '../providers/machine_provider.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MachineProvider>().loadMachines().catchError((_) {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final machines = context.watch<MachineProvider>().machines;
    final board = context.watch<LeaderboardProvider>();
    final myUserId = context.watch<AuthProvider>().user?.id;

    return Scaffold(
      appBar: AppBar(title: const Text('Leaderboard')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                DropdownButtonFormField<int>(
                  initialValue: board.machineId,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Alat',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    for (final m in machines)
                      DropdownMenuItem(value: m.id, child: Text(m.name)),
                  ],
                  onChanged: (id) {
                    board.machineId = id;
                    board.refresh();
                  },
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _filterChip(
                        context,
                        label: board.type == 'single'
                            ? '1RM Murni'
                            : 'Est. 1RM (multi-rep)',
                        onTap: () {
                          board.type =
                              board.type == 'single' ? 'multi' : 'single';
                          board.refresh();
                        },
                      ),
                      const SizedBox(width: 8),
                      _filterChip(
                        context,
                        label: board.period == 'weekly'
                            ? 'Mingguan'
                            : 'Bulanan',
                        onTap: () {
                          board.period = board.period == 'weekly'
                              ? 'monthly'
                              : 'weekly';
                          board.refresh();
                        },
                      ),
                      const SizedBox(width: 8),
                      _cycleChip<String?>(
                        context,
                        label: switch (board.gender) {
                          'male' => 'Pria',
                          'female' => 'Wanita',
                          _ => 'Semua Gender',
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
                            ? 'Semua Umur'
                            : 'Umur ${board.ageBracket}',
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
                            ? 'Semua BB'
                            : 'BB ${board.weightClass} kg',
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
              ],
            ),
          ),
          if (board.myRank != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                color: Theme.of(context).colorScheme.primaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text('Posisimu saat ini: #${board.myRank}',
                      style: Theme.of(context).textTheme.titleMedium),
                ),
              ),
            ),
          Expanded(
            child: board.loading
                ? const Center(child: CircularProgressIndicator())
                : board.machineId == null
                    ? const Center(
                        child: Text('Pilih alat untuk melihat peringkat.'))
                    : board.entries.isEmpty
                        ? const Center(
                            child: Text(
                                'Belum ada yang mencatat set di periode ini.'))
                        : RefreshIndicator(
                            onRefresh: () => board.refresh(),
                            child: ListView.builder(
                              padding:
                                  const EdgeInsets.fromLTRB(16, 16, 16, 140),
                              itemCount: board.entries.length,
                              itemBuilder: (context, i) => _entryTile(
                                  context, board.entries[i], myUserId),
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _entryTile(
      BuildContext context, LeaderboardEntry entry, int? myUserId) {
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
        leading: CircleAvatar(
          child: Text(medal ?? '${entry.rank}'),
        ),
        title: Text(isMe ? '${entry.userName} (kamu)' : entry.userName),
        subtitle: Text(
            '${entry.weightKg.toStringAsFixed(entry.weightKg % 1 == 0 ? 0 : 1)} kg × ${entry.reps} reps'),
        trailing: Text(
          '${entry.value.toStringAsFixed(1)} kg',
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.bold),
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
