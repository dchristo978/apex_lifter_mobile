import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/models.dart';
import '../providers/challenge_provider.dart';
import '../providers/machine_provider.dart';
import '../widgets/challenge_widgets.dart';
import 'challenge_detail_screen.dart';
import 'machine_picker_screen.dart';

/// Create a challenge against [opponentId]. Machine and target can be
/// pre-filled (e.g. when launched from one of the opponent's machine records).
class CreateChallengeScreen extends StatefulWidget {
  const CreateChallengeScreen({
    super.key,
    required this.opponentId,
    required this.opponentName,
    this.initialMachineId,
    this.initialWeightKg,
    this.initialReps,
    this.initialSets,
  });

  final int opponentId;
  final String opponentName;
  final int? initialMachineId;
  final double? initialWeightKg;
  final int? initialReps;
  final int? initialSets;

  @override
  State<CreateChallengeScreen> createState() => _CreateChallengeScreenState();
}

class _CreateChallengeScreenState extends State<CreateChallengeScreen> {
  final _formKey = GlobalKey<FormState>();
  int? _machineId;
  late final TextEditingController _weight;
  late final TextEditingController _reps;
  late final TextEditingController _sets;
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _machineId = widget.initialMachineId;
    _weight = TextEditingController(
        text: widget.initialWeightKg == null
            ? ''
            : widget.initialWeightKg!.toStringAsFixed(
                widget.initialWeightKg! % 1 == 0 ? 0 : 1));
    _reps = TextEditingController(text: widget.initialReps?.toString() ?? '');
    _sets = TextEditingController(text: widget.initialSets?.toString() ?? '1');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MachineProvider>().loadMachines().catchError((_) {});
    });
  }

  @override
  void dispose() {
    _weight.dispose();
    _reps.dispose();
    _sets.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    if (!_formKey.currentState!.validate() || _machineId == null) {
      if (_machineId == null) setState(() => _error = l10n.chooseMachineFirst);
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final provider = context.read<ChallengeProvider>();
      final challenge = await provider.create(
        opponentId: widget.opponentId,
        machineId: _machineId!,
        targetWeightKg: double.parse(_weight.text.replaceAll(',', '.')),
        targetReps: int.parse(_reps.text),
        targetSets: int.parse(_sets.text),
      );
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.challengeSent(widget.opponentName))),
      );
      // Offer to record proof immediately.
      final recordNow = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          content: Text(l10n.challengeCreatedRecordNow),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: Text(l10n.later)),
            FilledButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: Text(l10n.recordNow)),
          ],
        ),
      );
      if (!mounted) return;
      var current = challenge;
      if (recordNow == true) {
        final path = await pickProofVideo(context);
        if (path != null && mounted) {
          current = await provider.submitVideo(challenge.id, path);
        }
      }
      if (!mounted) return;
      // Replace this screen with the challenge detail.
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
            builder: (_) => ChallengeDetailScreen(challengeId: current.id)),
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _submitting = false;
          _error = e.toString();
        });
      }
    }
  }

  Future<void> _pickMachine() async {
    final machine = await Navigator.of(context).push<Machine>(
      MaterialPageRoute(
        builder: (_) => MachinePickerScreen(selectedMachineId: _machineId),
      ),
    );
    if (machine != null && mounted) {
      setState(() {
        _machineId = machine.id;
        _error = null;
      });
    }
  }

  /// Read-only field that opens the full-screen machine picker.
  Widget _machineField(
      BuildContext context, AppLocalizations l10n, List<Machine> machines) {
    Machine? selected;
    for (final m in machines) {
      if (m.id == _machineId) {
        selected = m;
        break;
      }
    }
    return InkWell(
      onTap: _pickMachine,
      borderRadius: BorderRadius.circular(4),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: l10n.machine,
          border: const OutlineInputBorder(),
          suffixIcon: const Icon(Icons.chevron_right),
        ),
        isEmpty: selected == null,
        child: selected == null
            ? null
            : Text(selected.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final machines = context.watch<MachineProvider>().machines;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.newChallenge)),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: ListTile(
                leading: const Icon(Icons.sports_mma),
                title: Text(l10n.challengeOpponent(widget.opponentName)),
              ),
            ),
            const SizedBox(height: 16),
            _machineField(context, l10n, machines),
            const SizedBox(height: 16),
            TextFormField(
              controller: _weight,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: l10n.targetWeightKgLabel,
                border: const OutlineInputBorder(),
              ),
              validator: (v) {
                final n = double.tryParse((v ?? '').replaceAll(',', '.'));
                return (n == null || n <= 0) ? l10n.invalidLoad : null;
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _reps,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: l10n.targetRepsLabel,
                      border: const OutlineInputBorder(),
                    ),
                    validator: (v) {
                      final n = int.tryParse(v ?? '');
                      return (n == null || n < 1 || n > 100)
                          ? l10n.reps1to100
                          : null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _sets,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: l10n.targetSetsLabel,
                      border: const OutlineInputBorder(),
                    ),
                    validator: (v) {
                      final n = int.tryParse(v ?? '');
                      return (n == null || n < 1 || n > 20) ? '1-20' : null;
                    },
                  ),
                ),
              ],
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _submitting ? null : _submit,
              icon: const Icon(Icons.send),
              label: Text(_submitting ? '...' : l10n.sendChallenge),
            ),
          ],
        ),
      ),
    );
  }
}
