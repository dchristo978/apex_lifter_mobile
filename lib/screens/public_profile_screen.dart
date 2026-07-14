import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/models.dart';
import '../services/api_client.dart';
import '../widgets/user_avatar.dart';

/// Another lifter's public profile plus their lazily-loaded session history.
class PublicProfileScreen extends StatefulWidget {
  const PublicProfileScreen({
    super.key,
    required this.userId,
    this.initialName,
  });

  final int userId;
  final String? initialName;

  @override
  State<PublicProfileScreen> createState() => _PublicProfileScreenState();
}

class _PublicProfileScreenState extends State<PublicProfileScreen> {
  final _scrollController = ScrollController();

  PublicProfile? _profile;
  String? _profileError;

  final List<GymSession> _sessions = [];
  int _nextPage = 1;
  bool _hasMore = true;
  bool _loadingPage = false;
  String? _sessionError;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadProfile();
    _loadNextPage();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Trigger the next page a little before the very bottom.
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {
      _loadNextPage();
    }
  }

  Future<void> _loadProfile() async {
    try {
      final api = context.read<ApiClient>();
      final json = await api.get('/users/${widget.userId}');
      if (mounted) {
        setState(() => _profile = PublicProfile.fromJson(
            json['user'] as Map<String, dynamic>));
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _profileError = e.message);
    } catch (e) {
      if (mounted) setState(() => _profileError = e.toString());
    }
  }

  Future<void> _loadNextPage() async {
    if (_loadingPage || !_hasMore) return;
    setState(() => _loadingPage = true);
    try {
      final api = context.read<ApiClient>();
      final json = await api.get(
        '/users/${widget.userId}/sessions',
        {'page': '$_nextPage'},
      );
      final data = (json['data'] as List)
          .map((s) => GymSession.fromJson(s as Map<String, dynamic>))
          .toList();
      if (mounted) {
        setState(() {
          _sessions.addAll(data);
          _hasMore = json['has_more'] as bool? ?? false;
          _nextPage++;
        });
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _sessionError = e.message);
    } catch (e) {
      if (mounted) setState(() => _sessionError = e.toString());
    } finally {
      if (mounted) setState(() => _loadingPage = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text(_profile?.name ??
              widget.initialName ??
              AppLocalizations.of(context).profile)),
      body: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 140),
        // header + section title + sessions + footer loader
        itemCount: _sessions.length + 2 + (_hasMore || _loadingPage ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == 0) return _header(context);
          if (index == 1) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(0, 8, 0, 8),
              child: Text(AppLocalizations.of(context).sessionHistory,
                  style: Theme.of(context).textTheme.titleMedium),
            );
          }
          final sessionIndex = index - 2;
          if (sessionIndex < _sessions.length) {
            return _sessionTile(_sessions[sessionIndex]);
          }
          // Footer loader / lazy-load trigger.
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: _sessionError != null
                  ? Text(_sessionError!,
                      style:
                          TextStyle(color: Theme.of(context).colorScheme.error))
                  : const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(strokeWidth: 2)),
            ),
          );
        },
      ),
    );
  }

  Widget _header(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (_profileError != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
            child: Text(_profileError!,
                style: TextStyle(color: Theme.of(context).colorScheme.error))),
      );
    }
    final p = _profile;
    if (p == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final subtitle = [
      if (p.homeGymName != null) p.homeGymName!,
      if (p.ageBracket != null) p.ageBracket!,
      if (p.weightClass != null) l10n.classLabel(p.weightClass!),
    ].join(' · ');

    return Column(
      children: [
        UserAvatar(name: p.name, avatarUrl: p.avatarUrl, radius: 44),
        const SizedBox(height: 12),
        Text(p.name, style: Theme.of(context).textTheme.headlineSmall),
        if (subtitle.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(subtitle,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center),
          ),
        if (p.bodyWeightStale)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: _StaleWeightChip(),
          ),
        const SizedBox(height: 16),
        Row(
          children: [
            _statCard(context, '${p.totalSets}', l10n.statSets),
            _statCard(context, '${p.machinesTrained}', l10n.statMachines),
            _statCard(
                context, p.bestEstimated1rm.toStringAsFixed(0), l10n.statBest1rm),
          ],
        ),
        const SizedBox(height: 8),
        Card(
          child: ListTile(
            leading: const Icon(Icons.local_fire_department_outlined),
            title: Text(l10n.totalVolume),
            trailing: Text('${p.totalVolumeKg.toStringAsFixed(0)} kg'),
          ),
        ),
        if (p.badges.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              l10n.noBadges,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ),
        const SizedBox(height: 16),
        _records(context, p.records),
        const SizedBox(height: 4),
      ],
    );
  }

  Widget _records(BuildContext context, List<MachineRecord> records) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(l10n.machineRecords,
              style: Theme.of(context).textTheme.titleMedium),
        ),
        if (records.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(l10n.noMachineRecords,
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center),
          )
        else
          // The first 3 are the lifter's featured (pinned) machines.
          for (var i = 0; i < records.length; i++)
            _recordTile(context, records[i], featured: i < 3),
      ],
    );
  }

  Widget _recordTile(BuildContext context, MachineRecord r,
      {required bool featured}) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: featured ? scheme.primaryContainer.withValues(alpha: 0.4) : null,
      child: ListTile(
        leading: Icon(
          featured ? Icons.star : Icons.fitness_center,
          color: featured ? scheme.primary : null,
        ),
        title: Text(r.machineName),
        subtitle: Text([
          if (r.machineBrand != null) r.machineBrand!,
          l10n.recordEst1rm(r.estimated1rm.toStringAsFixed(0)),
        ].join(' · ')),
        trailing: Text(
          l10n.recordLift(r.weightKg.toStringAsFixed(0), r.reps),
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _statCard(BuildContext context, String value, String label) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            children: [
              Text(value, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 2),
              Text(label, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sessionTile(GymSession s) {
    final l10n = AppLocalizations.of(context);
    final date = DateTime.tryParse(s.date);
    final dateLabel =
        date != null ? DateFormat('EEE, d MMM yyyy').format(date) : s.date;
    return Card(
      child: ListTile(
        leading: const Icon(Icons.fitness_center),
        title: Text(dateLabel),
        subtitle: Text([
          l10n.setCountLabel(s.setCount),
          if (s.gymName != null) s.gymName!,
          if (s.topMachine != null)
            l10n.topMachineLabel(
                s.topMachine!, s.topEstimated1rm.toStringAsFixed(0)),
        ].join(' · ')),
        trailing: Text('${s.totalVolumeKg.toStringAsFixed(0)} kg'),
      ),
    );
  }
}

class _StaleWeightChip extends StatelessWidget {
  const _StaleWeightChip();

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: const Icon(Icons.warning_amber_rounded, size: 18),
      label: Text(AppLocalizations.of(context).staleWeightTitle),
      backgroundColor: Colors.orange.withValues(alpha: 0.18),
      side: BorderSide(color: Colors.orange.withValues(alpha: 0.5)),
    );
  }
}
