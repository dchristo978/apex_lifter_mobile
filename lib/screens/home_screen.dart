import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/models.dart';
import '../providers/auth_provider.dart';
import '../providers/gym_provider.dart';
import '../providers/notification_provider.dart';
import '../providers/workout_provider.dart';
import '../services/api_client.dart';
import 'gym_presence_screen.dart';
import 'log_set_sheet.dart';
import 'notifications_screen.dart';
import 'progress_screen.dart';

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
      context.read<GymProvider>().loadLatestCheckin().catchError((_) {});
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

  Future<void> _confirmDeleteSet(WorkoutSet set) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.deleteSetTitle),
        content: Text(l10n.deleteSetWarning),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.deleteSetConfirm),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      await context.read<WorkoutProvider>().deleteSet(set.id);
      messenger.showSnackBar(SnackBar(content: Text(l10n.deleteSetSuccess)));
    } on ApiException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final gym = context.watch<GymProvider>();
    final workout = context.watch<WorkoutProvider>();
    final unread = context.watch<NotificationProvider>().unreadCount;
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.greeting(auth.user?.name ?? '')),
        actions: [
          IconButton(
            tooltip: l10n.notifications,
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
        padding: const EdgeInsets.only(bottom: 36),
        child: FloatingActionButton.extended(
          onPressed: _openLogSetSheet,
          icon: const Icon(Icons.add),
          label: Text(l10n.addSet),
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
                    Text(l10n.gymCheckin,
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    if (gym.checkedInGym != null) ...[
                      Row(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.green),
                          const SizedBox(width: 8),
                          Expanded(
                              child: Text(
                                  l10n.checkedInAt(gym.checkedInGym!.name))),
                        ],
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: () {
                          final g = gym.checkedInGym!;
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => GymPresenceScreen(
                                  gymId: g.id, gymName: g.name),
                            ),
                          );
                        },
                        icon: const Icon(Icons.groups_outlined),
                        label: Text(l10n.whoIsHere),
                      ),
                    ] else
                      Text(l10n.notCheckedIn),
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
                      label: Text(l10n.checkinWithGps),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(l10n.recentSets,
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            if (workout.history.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Center(child: Text(l10n.noSetsYet)),
              )
            else
              ...workout.history.take(20).map(
                    (set) => Card(
                      child: ListTile(
                        leading: const Icon(Icons.fitness_center),
                        title: Text(set.machineName ?? l10n.machine),
                        subtitle: Text(DateFormat('d MMM, HH:mm')
                            .format(set.performedAt)),
                        trailing: Text(
                          '${set.weightKg.toStringAsFixed(set.weightKg % 1 == 0 ? 0 : 1)} kg × ${set.reps}',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        onTap: (set.machineId != null &&
                                set.machineName != null)
                            ? () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => ProgressScreen(
                                      machineId: set.machineId!,
                                      machineName: set.machineName!,
                                    ),
                                  ),
                                )
                            : null,
                        onLongPress:
                            set.isDeletable ? () => _confirmDeleteSet(set) : null,
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
