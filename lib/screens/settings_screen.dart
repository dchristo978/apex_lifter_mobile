import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../providers/gym_provider.dart';
import '../providers/leaderboard_provider.dart';
import '../providers/notification_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/workout_provider.dart';
import '../widgets/avatar_uploader.dart';
import 'edit_profile_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final settings = context.watch<SettingsProvider>();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          _sectionLabel(context, l10n.account),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.person_outline),
                  title: Text(l10n.editProfileData),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => const EditProfileScreen()),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.photo_camera_outlined),
                  title: Text(l10n.editProfilePhoto),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => pickAndUploadAvatar(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _sectionLabel(context, l10n.settings),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  secondary: const Icon(Icons.notifications_outlined),
                  title: Text(l10n.pushNotifications),
                  subtitle: Text(l10n.pushNotificationsSubtitle),
                  value: settings.pushEnabled,
                  onChanged: (v) => settings.setPushEnabled(v),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.language),
                  title: Text(l10n.language),
                  trailing: Text(
                    settings.locale.languageCode == 'id'
                        ? l10n.languageIndonesian
                        : l10n.languageEnglish,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  onTap: () => _pickLanguage(context, settings),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () => _logout(context),
            icon: const Icon(Icons.logout),
            label: Text(l10n.logout),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
      child: Text(
        text.toUpperCase(),
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              letterSpacing: 1,
            ),
      ),
    );
  }

  Future<void> _pickLanguage(
      BuildContext context, SettingsProvider settings) async {
    final l10n = AppLocalizations.of(context);
    final selected = await showDialog<Locale>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: Text(l10n.chooseLanguage),
        children: [
          _languageOption(dialogContext, settings, const Locale('en'),
              l10n.languageEnglish),
          _languageOption(dialogContext, settings, const Locale('id'),
              l10n.languageIndonesian),
        ],
      ),
    );
    if (selected != null) settings.setLocale(selected);
  }

  Widget _languageOption(BuildContext dialogContext, SettingsProvider settings,
      Locale locale, String label) {
    final selected = settings.locale == locale;
    return ListTile(
      title: Text(label),
      trailing: selected
          ? Icon(Icons.check,
              color: Theme.of(dialogContext).colorScheme.primary)
          : null,
      onTap: () => Navigator.of(dialogContext).pop(locale),
    );
  }

  void _logout(BuildContext context) {
    // Clear per-user state so the next account doesn't see stale data.
    context.read<WorkoutProvider>().clear();
    context.read<NotificationProvider>().clear();
    context.read<LeaderboardProvider>().clear();
    context.read<GymProvider>().clear();
    context.read<AuthProvider>().logout();
    // Pop back to the profile tab; the auth switch rebuilds to LoginScreen.
    Navigator.of(context).popUntil((route) => route.isFirst);
  }
}
