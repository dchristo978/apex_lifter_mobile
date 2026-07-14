import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../providers/notification_provider.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotificationProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifikasi'),
        actions: [
          if (provider.unreadCount > 0)
            TextButton(
              onPressed: () => provider.markAllRead(),
              child: const Text('Tandai dibaca'),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => provider.refresh(),
        child: provider.notifications.isEmpty
            ? ListView(
                children: const [
                  Padding(
                    padding: EdgeInsets.only(top: 120),
                    child: Center(
                        child: Text(
                            'Belum ada notifikasi.\nTetap jaga posisimu! 🏆',
                            textAlign: TextAlign.center)),
                  ),
                ],
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: provider.notifications.length,
                itemBuilder: (context, i) {
                  final n = provider.notifications[i];
                  return Card(
                    child: ListTile(
                      leading: Icon(
                        n.isUnread
                            ? Icons.notifications_active
                            : Icons.notifications_none,
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
