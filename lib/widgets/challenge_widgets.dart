import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/app_localizations.dart';
import '../models/models.dart';
import '../providers/challenge_provider.dart';
import '../services/permissions_service.dart';

/// Localized label for a rejection reason code.
String reasonLabel(AppLocalizations l, String code) => switch (code) {
      'load_too_light' => l.reasonLoadTooLight,
      'incomplete_reps' => l.reasonIncompleteReps,
      'wrong_machine' => l.reasonWrongMachine,
      'bad_form' => l.reasonBadForm,
      'partial_range' => l.reasonPartialRange,
      'video_unclear' => l.reasonVideoUnclear,
      _ => l.reasonOther,
    };

/// Localized label + colour for a challenge status chip.
(String, Color) challengeStatus(
    AppLocalizations l, ColorScheme scheme, String status) {
  return switch (status) {
    'pending' => (l.statusPending, scheme.tertiary),
    'active' => (l.statusActive, scheme.primary),
    'completed' => (l.statusCompleted, Colors.green.shade600),
    'declined' => (l.statusDeclined, scheme.error),
    'cancelled' => (l.statusCancelled, scheme.outline),
    _ => (status, scheme.outline),
  };
}

/// Let the user record (camera) or choose (gallery) a proof video. Handles the
/// camera/gallery permission re-prompt. Returns the file path, or null.
Future<String?> pickProofVideo(BuildContext context) async {
  final l10n = AppLocalizations.of(context);

  final source = await showModalBottomSheet<ImageSource>(
    context: context,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.videocam),
            title: Text(l10n.recordProof),
            onTap: () => Navigator.of(ctx).pop(ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.video_library),
            title: Text(l10n.photoSourceGallery),
            onTap: () => Navigator.of(ctx).pop(ImageSource.gallery),
          ),
        ],
      ),
    ),
  );
  if (source == null || !context.mounted) return null;

  final bool allowed;
  if (source == ImageSource.camera) {
    allowed = await PermissionsService.ensureCamera(context);
  } else {
    allowed = await PermissionsService.ensureGallery(context);
  }
  if (!allowed) return null;

  final picked = await ImagePicker().pickVideo(
    source: source,
    maxDuration: const Duration(minutes: 2),
  );
  return picked?.path;
}

/// Open a proof video in the device's player/browser.
Future<void> openVideo(BuildContext context, String url) async {
  final messenger = ScaffoldMessenger.of(context);
  final l10n = AppLocalizations.of(context);
  final ok = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  if (!ok && context.mounted) {
    messenger.showSnackBar(SnackBar(content: Text(l10n.couldNotOpenVideo)));
  }
}

/// Arena judging sheet: validate the 4 criteria, pick the valid winner, and
/// give a reason when rejecting. Returns true if a vote was cast.
Future<bool> showVoteSheet(BuildContext context, Challenge challenge) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => _VoteSheet(challenge: challenge),
  );
  return result ?? false;
}

class _VoteSheet extends StatefulWidget {
  const _VoteSheet({required this.challenge});

  final Challenge challenge;

  @override
  State<_VoteSheet> createState() => _VoteSheetState();
}

class _VoteSheetState extends State<_VoteSheet> {
  bool _load = true;
  bool _form = true;
  bool _machine = true;
  bool _repsSets = true;
  String? _choice;
  String? _reasonCode;
  final _noteController = TextEditingController();
  bool _submitting = false;
  String? _error;

  bool get _anyRejected =>
      _choice == 'invalid' || !_load || !_form || !_machine || !_repsSets;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    if (_choice == null) {
      setState(() => _error = l10n.whoWon);
      return;
    }
    if (_anyRejected && _reasonCode == null) {
      setState(() => _error = l10n.reasonRequired);
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await context.read<ChallengeProvider>().vote(
            widget.challenge.id,
            choice: _choice!,
            criteria: {
              'load': _load,
              'form': _form,
              'machine': _machine,
              'reps_sets': _repsSets,
            },
            reasonCode: _reasonCode,
            reasonText: _noteController.text.trim(),
          );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _submitting = false;
          _error = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = widget.challenge;
    final reasons = context.read<ChallengeProvider>().reasonCodes;

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.judgementTitle,
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.criteriaLoad),
              value: _load,
              onChanged: (v) => setState(() => _load = v),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.criteriaForm),
              value: _form,
              onChanged: (v) => setState(() => _form = v),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.criteriaMachine),
              value: _machine,
              onChanged: (v) => setState(() => _machine = v),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.criteriaRepsSets),
              value: _repsSets,
              onChanged: (v) => setState(() => _repsSets = v),
            ),
            const Divider(height: 24),
            Text(l10n.whoWon, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            RadioGroup<String>(
              groupValue: _choice,
              onChanged: (v) => setState(() => _choice = v),
              child: Column(
                children: [
                  RadioListTile<String>(
                    contentPadding: EdgeInsets.zero,
                    title:
                        Text(l10n.voteWins(c.challenger?.name ?? 'Challenger')),
                    value: 'challenger',
                  ),
                  RadioListTile<String>(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n.voteWins(c.opponent?.name ?? 'Opponent')),
                    value: 'opponent',
                  ),
                  RadioListTile<String>(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n.voteInvalid),
                    value: 'invalid',
                  ),
                ],
              ),
            ),
            if (_anyRejected) ...[
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _reasonCode,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: l10n.reasonLabel,
                  border: const OutlineInputBorder(),
                ),
                items: [
                  for (final code in reasons)
                    DropdownMenuItem(
                        value: code, child: Text(reasonLabel(l10n, code))),
                ],
                onChanged: (v) => setState(() => _reasonCode = v),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _noteController,
                decoration: InputDecoration(
                  labelText: l10n.reasonNote,
                  border: const OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _submitting ? null : _submit,
                child: _submitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(l10n.submitJudgement),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
