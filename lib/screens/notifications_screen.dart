import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/notification_provider.dart';
import 'challenge_detail_screen.dart';
import 'public_profile_screen.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotificationProvider>();
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.notifications),
        actions: [
          if (provider.unreadCount > 0)
            TextButton(
              onPressed: () => provider.markAllRead(),
              child: Text(l10n.markRead),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => provider.refresh(),
        child: provider.notifications.isEmpty
            ? ListView(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 120),
                    child: Center(
                        child: Text(l10n.noNotifications,
                            textAlign: TextAlign.center)),
                  ),
                ],
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: provider.notifications.length,
                itemBuilder: (context, i) {
                  final n = provider.notifications[i];
                  final VoidCallback? onTap = n.isChallenge
                      ? () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ChallengeDetailScreen(
                                challengeId: n.challengeId!,
                                celebrateOnOpen:
                                    n.type == 'challenge_received',
                              ),
                            ),
                          )
                      : (n.isFollow
                          ? () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => PublicProfileScreen(
                                    userId: n.actorId!,
                                    initialName: n.actorName,
                                  ),
                                ),
                              )
                          : null);

                  return Card(
                    child: ListTile(
                      onTap: onTap,
                      trailing: (n.isChallenge || n.isFollow)
                          ? const Icon(Icons.chevron_right)
                          : null,
                      leading: Icon(
                        n.isChallenge
                            ? Icons.sports_mma
                            : (n.isFollow
                                ? Icons.person_add_alt_1
                                : (n.isUnread
                                    ? Icons.notifications_active
                                    : Icons.notifications_none)),
                        color: n.isUnread
                            ? Theme.of(context).colorScheme.primary
                            : null,
                      ),
                      title: Text(n.title,
                          style: TextStyle(
                              fontWeight: n.isUnread
                                  ? FontWeight.bold
                                  : FontWeight.normal)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(n.body),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat('d MMM yyyy, HH:mm').format(n.createdAt),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
