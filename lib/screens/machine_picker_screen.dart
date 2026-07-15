import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/models.dart';
import '../providers/machine_provider.dart';

/// Full-screen machine selector: search by name and/or filter by muscle
/// group. Pops with the chosen [Machine], or null when dismissed.
class MachinePickerScreen extends StatefulWidget {
  const MachinePickerScreen({super.key, this.selectedMachineId});

  /// Highlights the currently selected machine, if any.
  final int? selectedMachineId;

  @override
  State<MachinePickerScreen> createState() => _MachinePickerScreenState();
}

class _MachinePickerScreenState extends State<MachinePickerScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  String? _muscleFilter;

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
      appBar: AppBar(title: Text(l10n.chooseMachine)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _searchController,
              autofocus: false,
              onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
              decoration: InputDecoration(
                hintText: l10n.searchMachineByNameHint,
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
          _muscleChips(context, provider, l10n),
          Expanded(child: _body(context, provider, l10n)),
        ],
      ),
    );
  }

  /// Horizontal row of muscle-group filter chips, ordered like the catalogue.
  Widget _muscleChips(
      BuildContext context, MachineProvider provider, AppLocalizations l10n) {
    final groups = provider.byMuscleGroup.keys.toList();
    if (groups.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(l10n.allMuscleGroups),
              selected: _muscleFilter == null,
              onSelected: (_) => setState(() => _muscleFilter = null),
            ),
          ),
          for (final group in groups)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(group),
                selected: _muscleFilter == group,
                onSelected: (_) => setState(
                    () => _muscleFilter = _muscleFilter == group ? null : group),
              ),
            ),
        ],
      ),
    );
  }

  Widget _body(
      BuildContext context, MachineProvider provider, AppLocalizations l10n) {
    if (!provider.loaded && provider.machines.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    // Filter by muscle group and name, keeping section grouping.
    final grouped = <String, List<Machine>>{};
    provider.byMuscleGroup.forEach((group, machines) {
      if (_muscleFilter != null && group != _muscleFilter) return;
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
    final selected = machine.id == widget.selectedMachineId;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        selected: selected,
        leading: CircleAvatar(
          backgroundColor:
              Theme.of(context).colorScheme.surfaceContainerHighest,
          child: const Icon(Icons.fitness_center, size: 20),
        ),
        title: Text(machine.name),
        subtitle:
            machine.muscleGroup != null ? Text(machine.muscleGroup!) : null,
        trailing: selected
            ? Icon(Icons.check_circle,
                color: Theme.of(context).colorScheme.primary)
            : null,
        onTap: () => Navigator.of(context).pop(machine),
      ),
    );
  }
}
