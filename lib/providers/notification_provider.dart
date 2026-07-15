import 'package:flutter/foundation.dart';

import '../models/models.dart';
import '../services/api_client.dart';

class NotificationProvider extends ChangeNotifier {
  NotificationProvider(this._api);

  final ApiClient _api;
  List<RankNotification> notifications = [];
  int unreadCount = 0;

  void clear() {
    notifications = [];
    unreadCount = 0;
    notifyListeners();
  }

  Future<void> refresh() async {
    final json = await _api.get('/notifications');
    notifications = (json['notifications'] as List)
        .map((n) => RankNotification.fromJson(n as Map<String, dynamic>))
        .toList();
    unreadCount = json['unread_count'] as int;
    notifyListeners();
  }

  Future<void> markAllRead() async {
    await _api.post('/notifications/read-all');
    unreadCount = 0;
    notifications = [
      for (final n in notifications)
        RankNotification(
          id: n.id,
          title: n.title,
          body: n.body,
          createdAt: n.createdAt,
          readAt: n.readAt ?? DateTime.now(),
          type: n.type,
          challengeId: n.challengeId,
          actorId: n.actorId,
          actorName: n.actorName,
        ),
    ];
    notifyListeners();
  }
}
