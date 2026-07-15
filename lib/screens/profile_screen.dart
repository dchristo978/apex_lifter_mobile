import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../widgets/avatar_uploader.dart';
import '../widgets/streak_card.dart';
import '../widgets/user_avatar.dart';
import 'featured_machines_screen.dart';
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
