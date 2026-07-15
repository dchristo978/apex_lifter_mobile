import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/models.dart';
import '../providers/auth_provider.dart';
import '../services/api_client.dart';
import '../widgets/avatar_uploader.dart';
import '../widgets/muscle_body.dart';
import '../widgets/streak_card.dart';
import '../widgets/user_avatar.dart';
import 'featured_machines_screen.dart';
import 'insights_screen.dart';
import 'medals_screen.dart';
import 'muscle_model_screen.dart';
import 'public_profile_screen.dart';
import 'settings_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    if (user == null) return const SizedBox.shrink();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.profile),
        actions: [
          IconButton(
            tooltip: l10n.settings,
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 140),
        children: [
          Center(
            child: GestureDetector(
              onTap: () => pickAndUploadAvatar(context),
              child: Stack(
                children: [
                  UserAvatar(
                      name: user.name, avatarUrl: user.avatarUrl, radius: 44),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: CircleAvatar(
                      radius: 14,
                      backgroundColor:
                          Theme.of(context).colorScheme.primary,
                      child: const Icon(Icons.camera_alt,
                          size: 15, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(user.name,
                style: Theme.of(context).textTheme.headlineSmall),
          ),
          Center(child: Text(user.email)),
          const SizedBox(height: 20),
          StreakCard(weeks: user.weekStreak),
          const SizedBox(height: 16),
          const _MusclePreview(),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const Icon(Icons.insights_outlined),
              title: Text(l10n.insightsTitle),
              subtitle: Text(l10n.insightsSubtitle),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const InsightsScreen()),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.wc),
                  title: Text(l10n.gender),
                  trailing: Text(user.gender == 'male'
                      ? l10n.genderMale
                      : l10n.genderFemale),
                ),
                ListTile(
                  leading: const Icon(Icons.cake_outlined),
                  title: Text(l10n.age),
                  trailing: Text(user.age != null
                      ? l10n.ageValue(user.age!, user.ageBracket ?? '-')
                      : '-'),
                ),
                ListTile(
                  leading: const Icon(Icons.monitor_weight_outlined),
                  title: Text(l10n.bodyWeight),
                  subtitle: user.bodyWeightUpdatedAt != null
                      ? Text(l10n.updatedOn(DateFormat('d MMM yyyy')
                          .format(user.bodyWeightUpdatedAt!)))
                      : null,
                  trailing: Text(user.bodyWeightKg != null
                      ? l10n.weightWithClass(
                          '${user.bodyWeightKg}', user.weightClass ?? '-')
                      : l10n.notSet),
                  onTap: () => _editWeight(context),
                ),
              ],
            ),
          ),
          if (user.bodyWeightStale) ...[
            const SizedBox(height: 8),
            Card(
              color: const Color(0xFF007AFF).withValues(alpha: 0.15),
              child: ListTile(
                leading: const Icon(Icons.warning_amber_rounded,
                    color: Color(0xFF007AFF)),
                title: Text(l10n.staleWeightTitle),
                subtitle: Text(l10n.staleWeightBody),
                trailing: TextButton(
                  onPressed: () => _editWeight(context),
                  child: Text(l10n.update),
                ),
              ),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            l10n.tapWeightHint,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const Text('🏅', style: TextStyle(fontSize: 22)),
              title: Text(l10n.medalCase),
              subtitle: Text(l10n.viewMedalCase),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => MedalsScreen(
                      userId: user.id, initialName: user.name),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const Icon(Icons.star_outline),
              title: Text(l10n.featuredMachines),
              subtitle: Text(
                user.featuredMachineIds.isEmpty
                    ? l10n.noFeaturedMachines
                    : l10n.featuredCount(user.featuredMachineIds.length),
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (_) => const FeaturedMachinesScreen()),
              ),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.tonalIcon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => PublicProfileScreen(
                    userId: user.id, initialName: user.name),
              ),
            ),
            icon: const Icon(Icons.badge_outlined),
            label: Text(l10n.viewPublicProfile),
          ),
        ],
      ),
    );
  }

  Future<void> _editWeight(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final controller = TextEditingController();
    final auth = context.read<AuthProvider>();

    final value = await showDialog<double>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.updateBodyWeight),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: l10n.bodyWeightKg,
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext)
                .pop(double.tryParse(controller.text)),
            child: Text(l10n.save),
          ),
        ],
      ),
    );

    if (value != null && value > 0) {
      await auth.updateProfile({'body_weight_kg': value});
    }
  }
}

/// A tappable preview of this week's muscle activation: a small front figure
/// with the muscles trained in the last 7 days shaded blue. Opens the rotatable
/// 3D muscle model. Fetches its own data so the profile stays a cheap list.
class _MusclePreview extends StatefulWidget {
  const _MusclePreview();

  @override
  State<_MusclePreview> createState() => _MusclePreviewState();
}

class _MusclePreviewState extends State<_MusclePreview> {
  MuscleActivation? _data;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final api = context.read<ApiClient>();
      final json = await api.get('/insights/muscle-activation', {'days': '7'});
      if (mounted) setState(() => _data = MuscleActivation.fromJson(json));
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final data = _data;
    final active = data?.trained.toSet() ?? const <String>{};
    final intensity = data == null
        ? const <String, double>{}
        : {for (final g in data.groups) g.group: data.intensityFor(g.group)};

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const MuscleModelScreen()),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              SizedBox(
                height: 120,
                child: _failed
                    ? const Icon(Icons.accessibility_new, size: 60)
                    : MuscleBody(
                        activeGroups: active,
                        intensity: intensity,
                      ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.muscleModelTitle,
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 6),
                    Text(
                      data == null
                          ? l10n.muscleModelSubtitle
                          : (active.isEmpty
                              ? l10n.noMuscleTrained
                              : l10n.muscleModelTrainedCount(active.length)),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(Icons.threed_rotation,
                            size: 16,
                            color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 6),
                        Text(l10n.viewIn3d,
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
