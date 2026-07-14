import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/gym_provider.dart';
import '../providers/leaderboard_provider.dart';
import '../providers/notification_provider.dart';
import '../providers/workout_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    if (user == null) return const SizedBox.shrink();

    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 140),
        children: [
          CircleAvatar(
            radius: 40,
            child: Text(
              user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(user.name,
                style: Theme.of(context).textTheme.headlineSmall),
          ),
          Center(child: Text(user.email)),
          const SizedBox(height: 24),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.wc),
                  title: const Text('Gender'),
                  trailing: Text(user.gender == 'male' ? 'Pria' : 'Wanita'),
                ),
                ListTile(
                  leading: const Icon(Icons.cake_outlined),
                  title: const Text('Umur'),
                  trailing: Text(user.age != null
                      ? '${user.age} th (bracket ${user.ageBracket})'
                      : '-'),
                ),
                ListTile(
                  leading: const Icon(Icons.monitor_weight_outlined),
                  title: const Text('Berat badan'),
                  trailing: Text(user.bodyWeightKg != null
                      ? '${user.bodyWeightKg} kg (kelas ${user.weightClass})'
                      : 'Belum diisi'),
                  onTap: () => _editWeight(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ketuk "Berat badan" untuk memperbarui. Rekor akan mengikuti kelas berat badan terbaru.',
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () {
              // Clear per-user state so the next account doesn't see stale data.
              context.read<WorkoutProvider>().clear();
              context.read<NotificationProvider>().clear();
              context.read<LeaderboardProvider>().clear();
              context.read<GymProvider>().clear();
              auth.logout();
            },
            icon: const Icon(Icons.logout),
            label: const Text('Keluar'),
          ),
        ],
      ),
    );
  }

  Future<void> _editWeight(BuildContext context) async {
    final controller = TextEditingController();
    final auth = context.read<AuthProvider>();

    final value = await showDialog<double>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Perbarui berat badan'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Berat badan (kg)',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext)
                .pop(double.tryParse(controller.text)),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );

    if (value != null && value > 0) {
      await auth.updateProfile({'body_weight_kg': value});
    }
  }
}
