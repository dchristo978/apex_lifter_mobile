import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/models.dart';
import '../providers/challenge_provider.dart';
import '../widgets/challenge_widgets.dart';
import '../widgets/confetti_burst.dart';
import '../widgets/user_avatar.dart';

class ChallengeDetailScreen extends StatefulWidget {
  const ChallengeDetailScreen({
    super.key,
    required this.challengeId,
    this.celebrateOnOpen = false,
  });

  final int challengeId;

  /// Blast confetti once the challenge loads — set when opening a freshly
  /// received challenge from the notifications screen.
  final bool celebrateOnOpen;

  @override
  State<ChallengeDetailScreen> createState() => _ChallengeDetailScreenState();
}

class _ChallengeDetailScreenState extends State<ChallengeDetailScreen> {
  Challenge? _challenge;
  String? _error;
  bool _busy = false;
  bool _celebratedWin = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final c = await context.read<ChallengeProvider>().fetch(widget.challengeId);
      if (mounted) {
        setState(() => _challenge = c);
        // One-time ovation: seeing the challenge you won, or opening one you
        // just received from a notification.
        if (!_celebratedWin &&
            ((c.status == 'completed' && _isMeWinner(c)) ||
                widget.celebrateOnOpen)) {
          _celebratedWin = true;
          celebrate(context);
        }
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  Future<void> _run(Future<Challenge> Function() action) async {
    setState(() => _busy = true);
    try {
      final c = await action();
      if (mounted) setState(() => _challenge = c);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _submitProof() async {
    final path = await pickProofVideo(context);
    if (path == null || !mounted) return;
    final provider = context.read<ChallengeProvider>();
    await _run(() => provider.submitVideo(widget.challengeId, path));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = _challenge;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.challenge)),
      body: _error != null
          ? Center(child: Text(_error!))
          : c == null
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: _content(context, c),
                  ),
                ),
    );
  }

  List<Widget> _content(BuildContext context, Challenge c) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final (statusLabel, statusColor) = challengeStatus(l10n, scheme, c.status);

    return [
      // Versus header
      Row(
        children: [
          Expanded(child: _sideAvatar(c.challenger, c.winnerId)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(l10n.vs,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold)),
          ),
          Expanded(child: _sideAvatar(c.opponent, c.winnerId)),
        ],
      ),
      const SizedBox(height: 16),
      Center(
        child: Chip(
          label: Text(statusLabel),
          backgroundColor: statusColor.withValues(alpha: 0.2),
          side: BorderSide(color: statusColor.withValues(alpha: 0.6)),
        ),
      ),
      const SizedBox(height: 16),
      Card(
        child: Column(
          children: [
            ListTile(
              leading: const Icon(Icons.fitness_center),
              title: Text(c.machineName ?? '—'),
              subtitle: c.machineMuscleGroup != null
                  ? Text(c.machineMuscleGroup!)
                  : null,
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.flag),
              title: Text(l10n.challengeTarget(
                  c.targetWeightKg.toStringAsFixed(
                      c.targetWeightKg % 1 == 0 ? 0 : 1),
                  c.targetReps,
                  c.targetSets)),
              subtitle: c.gymName != null ? Text(c.gymName!) : null,
            ),
          ],
        ),
      ),
      const SizedBox(height: 8),

      // Proof videos (visible once judging begins)
      if (c.challengerVideoUrl != null)
        _proofTile(context, l10n.watchChallengerProof, c.challengerVideoUrl!),
      if (c.opponentVideoUrl != null)
        _proofTile(context, l10n.watchOpponentProof, c.opponentVideoUrl!),

      // Winner
      if (c.status == 'completed' && c.winner != null) ...[
        const SizedBox(height: 8),
        Card(
          color: Colors.green.withValues(alpha: 0.15),
          child: ListTile(
            leading: const Text('🏅', style: TextStyle(fontSize: 24)),
            title: Text(c.myRole != 'judge' && c.winnerId != null &&
                    _isMeWinner(c)
                ? l10n.youWon
                : l10n.winnerLabel(c.winner!.name)),
          ),
        ),
      ],

      // Arena tally + timing
      if (c.status == 'active') ...[
        const SizedBox(height: 8),
        Card(
          child: ListTile(
            leading: const Icon(Icons.how_to_vote),
            title: Text(l10n.tallyApproveReject(
                c.tally.approvers, c.tally.rejecters)),
            subtitle: c.votingEndsAt != null
                ? Text(l10n.votingEndsIn(
                    DateFormat('d MMM, HH:mm').format(c.votingEndsAt!)))
                : null,
          ),
        ),
      ],

      const SizedBox(height: 16),
      ..._actions(context, c),
    ];
  }

  bool _isMeWinner(Challenge c) {
    // The viewer is a participant; winner is their side.
    return (c.myRole == 'challenger' && c.winnerId == c.challenger?.id) ||
        (c.myRole == 'opponent' && c.winnerId == c.opponent?.id);
  }

  List<Widget> _actions(BuildContext context, Challenge c) {
    final l10n = AppLocalizations.of(context);
    final widgets = <Widget>[];

    // Participant: submit / re-record proof while pending or active.
    if (c.isParticipant &&
        (c.status == 'pending' || c.status == 'active')) {
      widgets.add(FilledButton.icon(
        onPressed: _busy ? null : _submitProof,
        icon: const Icon(Icons.videocam),
        label: Text(c.iSubmitted ? l10n.reRecordProof : l10n.recordProof),
      ));
      if (c.iSubmitted) {
        widgets.add(const SizedBox(height: 8));
        widgets.add(Text(l10n.proofSubmitted,
            textAlign: TextAlign.center,
            style: TextStyle(color: Theme.of(context).colorScheme.primary)));
      } else if (c.status == 'pending') {
        widgets.add(const SizedBox(height: 8));
        widgets.add(Text(l10n.awaitingOpponentProof,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall));
      }
    }

    // Opponent can decline a pending challenge.
    if (c.myRole == 'opponent' && c.status == 'pending') {
      widgets.add(const SizedBox(height: 8));
      widgets.add(OutlinedButton.icon(
        onPressed: _busy
            ? null
            : () => _run(() =>
                context.read<ChallengeProvider>().decline(widget.challengeId)),
        icon: const Icon(Icons.close),
        label: Text(l10n.declineChallenge),
      ));
    }

    // Judge: vote in the arena.
    if (c.canVote) {
      widgets.add(FilledButton.icon(
        onPressed: _busy
            ? null
            : () async {
                final voted = await showVoteSheet(context, c);
                if (voted && context.mounted) {
                  celebrate(context);
                  _load();
                }
              },
        icon: const Icon(Icons.gavel),
        label: Text(l10n.judge),
      ));
    } else if (c.myRole == 'judge' && c.myVote != null) {
      widgets.add(Text(l10n.alreadyJudged,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall));
    }

    return widgets;
  }

  Widget _sideAvatar(ChallengeParticipant? p, int? winnerId) {
    if (p == null) return const SizedBox.shrink();
    final isWinner = winnerId != null && winnerId == p.id;
    return Column(
      children: [
        Stack(
          alignment: Alignment.topRight,
          children: [
            UserAvatar(name: p.name, avatarUrl: p.avatarUrl, radius: 36),
            if (isWinner) const Text('🏅', style: TextStyle(fontSize: 20)),
          ],
        ),
        const SizedBox(height: 6),
        Text(p.name,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis),
      ],
    );
  }

  Widget _proofTile(BuildContext context, String label, String url) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.play_circle_outline),
        title: Text(label),
        trailing: const Icon(Icons.open_in_new, size: 18),
        onTap: () => openVideo(context, url),
      ),
    );
  }
}
