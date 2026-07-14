import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../providers/gym_provider.dart';
import '../providers/machine_provider.dart';
import '../providers/workout_provider.dart';
import '../services/api_client.dart';

/// Glassmorphism bottom sheet for logging a set from the home screen.
class LogSetSheet extends StatefulWidget {
  const LogSetSheet({super.key});

  @override
  State<LogSetSheet> createState() => _LogSetSheetState();
}

class _LogSetSheetState extends State<LogSetSheet> {
  final _formKey = GlobalKey<FormState>();
  final _weight = TextEditingController();
  final _reps = TextEditingController();
  Machine? _machine;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MachineProvider>().loadMachines().catchError((_) {});
    });
  }

  @override
  void dispose() {
    _weight.dispose();
    _reps.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _machine == null) return;

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      final set = await context.read<WorkoutProvider>().logSet(
            machineId: _machine!.id,
            weightKg: double.parse(_weight.text),
            reps: int.parse(_reps.text),
            gymId: context.read<GymProvider>().checkedInGym?.id,
          );
      navigator.pop();
      messenger.showSnackBar(SnackBar(
        content: Text(
            'Set tercatat! Estimated 1RM: ${set.estimated1rm.toStringAsFixed(1)} kg'),
      ));
    } on ApiException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      messenger.showSnackBar(
          const SnackBar(content: Text('Tidak bisa terhubung ke server.')));
    }
  }

  static const _categoryLabels = {
    'chest': 'Dada',
    'back': 'Punggung',
    'shoulders': 'Bahu',
    'arms': 'Lengan',
    'legs': 'Kaki',
    'core': 'Core',
  };

  @override
  Widget build(BuildContext context) {
    final machines = context.watch<MachineProvider>();
    final submitting = context.watch<WorkoutProvider>().submitting;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              border: Border(
                top: BorderSide(color: Colors.white.withValues(alpha: 0.14)),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text('Tambah Set',
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<Machine>(
                      initialValue: _machine,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Pilih alat',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        for (final entry in machines.byCategory.entries) ...[
                          DropdownMenuItem<Machine>(
                            enabled: false,
                            child: Text(
                              _categoryLabels[entry.key] ?? entry.key,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ),
                          for (final machine in entry.value)
                            DropdownMenuItem<Machine>(
                              value: machine,
                              child: Text('   ${machine.name}'),
                            ),
                        ],
                      ],
                      onChanged: (m) => setState(() => _machine = m),
                      validator: (m) => m == null ? 'Pilih alat dulu' : null,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _weight,
                            keyboardType:
                                const TextInputType.numberWithOptions(
                                    decimal: true),
                            decoration: const InputDecoration(
                              labelText: 'Beban (kg)',
                              border: OutlineInputBorder(),
                            ),
                            validator: (v) {
                              final n = double.tryParse(v ?? '');
                              return (n == null || n <= 0)
                                  ? 'Beban tidak valid'
                                  : null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _reps,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Repetisi',
                              border: OutlineInputBorder(),
                            ),
                            validator: (v) {
                              final n = int.tryParse(v ?? '');
                              return (n == null || n < 1 || n > 100)
                                  ? 'Reps 1-100'
                                  : null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Reps = 1 masuk leaderboard 1RM murni; reps ≥ 2 masuk leaderboard estimated 1RM.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      onPressed: submitting ? null : _submit,
                      icon: submitting
                          ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.check),
                      label: const Text('Simpan Set'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
