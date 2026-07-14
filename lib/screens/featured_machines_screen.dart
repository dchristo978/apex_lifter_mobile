import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/models.dart';
import '../providers/auth_provider.dart';
import '../providers/machine_provider.dart';

/// Lets the signed-in user pick and order up to 3 "featured" machines. The
/// order chosen here is pinned to the top of their public profile.
class FeaturedMachinesScreen extends StatefulWidget {
  const FeaturedMachinesScreen({super.key});

  static const maxFeatured = 3;

  @override
  State<FeaturedMachinesScreen> createState() => _FeaturedMachinesScreenState();
}

class _FeaturedMachinesScreenState extends State<FeaturedMachinesScreen> {
  late List<int> _selected;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _selected = List<int>.from(
        context.read<AuthProvider>().user?.featuredMachineIds ?? const []);
    context.read<MachineProvider>().loadMachines();
  }

  bool get _dirty {
    final original =
        context.read<AuthProvider>().user?.featuredMachineIds ?? const [];
    if (original.length != _selected.length) return true;
    for (var i = 0; i < _selected.length; i++) {
      if (original[i] != _selected[i]) return true;
    }
    return false;
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await context
          .read<AuthProvider>()
          .updateProfile({'featured_machine_ids': _selected});
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _remove(int machineId) {
    setState(() => _selected.remove(machineId));
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex--;
      final id = _selected.removeAt(oldIndex);
      _selected.insert(newIndex, id);
    });
  }

  Future<void> _addMachine() async {
    final l10n = AppLocalizations.of(context);
    if (_selected.length >= FeaturedMachinesScreen.maxFeatured) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.featuredLimitReached)),
      );
      return;
    }
    final machines = context.read<MachineProvider>().machines;
    final available =
        machines.where((m) => !_selected.contains(m.id)).toList();

    final picked = await showModalBottomSheet<Machine>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.7,
          maxChildSize: 0.9,
          builder: (context, controller) => ListView.builder(
            controller: controller,
            itemCount: available.length,
            itemBuilder: (context, index) {
              final m = available[index];
              return ListTile(
                leading: const Icon(Icons.fitness_center),
                title: Text(m.name),
                subtitle: Text('${m.brand} · ${m.category}'),
                onTap: () => Navigator.of(sheetContext).pop(m),
              );
            },
          ),
        );
      },
    );

    if (picked != null) {
      setState(() => _selected.add(picked.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final machineProvider = context.watch<MachineProvider>();
    final machinesById = {for (final m in machineProvider.machines) m.id: m};

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.featuredMachines),
        actions: [
          TextButton(
            onPressed: (_saving || !_dirty) ? null : _save,
            child: _saving
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : Text(l10n.save),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: !machineProvider.loaded
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [
                Text(l10n.featuredMachinesHint,
                    style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 12),
                Text(
                  l10n.featuredCount(_selected.length),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
                if (_selected.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text(l10n.noFeaturedMachines,
                          style: Theme.of(context).textTheme.bodySmall),
                    ),
                  )
                else
                  ReorderableListView(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    onReorder: _onReorder,
                    children: [
                      for (var i = 0; i < _selected.length; i++)
                        _selectedTile(
                            context, i, machinesById[_selected[i]]),
                    ],
                  ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _selected.length >=
                          FeaturedMachinesScreen.maxFeatured
                      ? null
                      : _addMachine,
                  icon: const Icon(Icons.add),
                  label: Text(l10n.addMachine),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!,
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.error)),
                ],
              ],
            ),
    );
  }

  Widget _selectedTile(BuildContext context, int index, Machine? machine) {
    final l10n = AppLocalizations.of(context);
    return Card(
      // A stable key per item is required by ReorderableListView.
      key: ValueKey(_selected[index]),
      child: ListTile(
        leading: CircleAvatar(
          radius: 14,
          child: Text('${index + 1}'),
        ),
        title: Text(machine?.name ?? '#${_selected[index]}'),
        subtitle: machine != null
            ? Text('${machine.brand} · ${machine.category}')
            : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: l10n.remove,
              icon: const Icon(Icons.close),
              onPressed: () => _remove(_selected[index]),
            ),
            ReorderableDragStartListener(
              index: index,
              child: const Padding(
                padding: EdgeInsets.all(8),
                child: Icon(Icons.drag_handle),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
