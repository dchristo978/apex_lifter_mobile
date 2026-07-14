import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/gym_provider.dart';
import '../providers/notification_provider.dart';
import '../providers/workout_provider.dart';
import 'log_set_sheet.dart';
import 'notifications_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WorkoutProvider>().loadHistory().catchError((_) {});
    });
  }

  void _openLogSetSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const LogSetSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final gym = context.watch<GymProvider>();
    final workout = context.watch<WorkoutProvider>();
    final unread = context.watch<NotificationProvider>().unreadCount;

    return Scaffold(
      appBar: AppBar(
        title: Text('Halo, ${auth.user?.name ?? ''} 💪'),
        actions: [
          IconButton(
            tooltip: 'Notifikasi',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const NotificationsScreen()),
              );
            },
            icon: Badge(
              isLabelVisible: unread > 0,
              label: Text('$unread'),
              child: const Icon(Icons.notifications_outlined),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: Padding(
        // Keep the FAB clear of the floating glass nav bar.
        padding: const EdgeInsets.only(bottom: 84),
        child: FloatingActionButton.extended(
          onPressed: _openLogSetSheet,
          icon: const Icon(Icons.add),
          label: const Text('Tambah Set'),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => workout.loadHistory(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 140),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Check-in Gym',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    if (gym.checkedInGym != null)
                      Row(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.green),
                          const SizedBox(width: 8),
                          Expanded(
                              child: Text(
                                  'Kamu check-in di ${gym.checkedInGym!.name}')),
                        ],
                      )
                    else
                      const Text(
                          'Belum check-in. Check-in bersifat opsional — kamu tetap bisa mencatat set tanpa check-in.'),
                    if (gym.error != null) ...[
                      const SizedBox(height: 8),
                      Text(gym.error!,
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.error)),
                    ],
                    const SizedBox(height: 12),
                    FilledButton.tonalIcon(
                      onPressed:
                          gym.checkingIn ? null : () => gym.checkinWithGps(),
                      icon: gym.checkingIn
                          ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.my_location),
                      label: const Text('Check-in dengan GPS'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Riwayat Set Terakhir',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            if (workout.history.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(
                    child: Text('Belum ada set tercatat. Mulai angkat! 🏋️')),
              )
            else
              ...workout.history.take(20).map(
                    (set) => Card(
                      child: ListTile(
                        leading: const Icon(Icons.fitness_center),
                        title: Text(set.machineName ?? 'Alat'),
                        subtitle: Text(DateFormat('d MMM, HH:mm')
                            .format(set.performedAt)),
                        trailing: Text(
                          '${set.weightKg.toStringAsFixed(set.weightKg % 1 == 0 ? 0 : 1)} kg × ${set.reps}',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
