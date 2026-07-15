import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import '../screens/challenge_detail_screen.dart';
import 'api_client.dart';

/// Handles a data/notification message delivered while the app is terminated or
/// backgrounded. Must be a top-level function annotated for the Dart VM so the
/// background isolate can find it. The OS renders the notification banner
/// itself; there is nothing to do here beyond keeping the handler registered.
@pragma('vm:entry-point')
Future<void> firebaseBackgroundHandler(RemoteMessage message) async {}

/// FCM push integration. Firebase is optional: if it isn't configured (no
/// `google-services.json` / `GoogleService-Info.plist` / `firebase_options`),
/// [init] fails softly and every other call becomes a no-op, so the app runs
/// exactly as before with in-app notifications only.
class PushService {
  PushService(this._api, {required this.navigatorKey});

  final ApiClient _api;
  final GlobalKey<NavigatorState> navigatorKey;

  bool _available = false;

  /// True once Firebase initialized successfully — push can be used.
  bool get available => _available;

  /// Call once at startup, before the app runs. Safe to call without Firebase
  /// configured; it simply leaves push disabled.
  Future<void> init() async {
    try {
      await Firebase.initializeApp();
      _available = true;
    } catch (e) {
      // No Firebase config yet — disable push, keep the app fully functional.
      debugPrint('Push disabled (Firebase not configured): $e');
      return;
    }

    FirebaseMessaging.onBackgroundMessage(firebaseBackgroundHandler);
    FirebaseMessaging.onMessage.listen(_handleForeground);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleTap);

    // A tap that cold-started the app from a terminated state.
    final initial = await FirebaseMessaging.instance.getInitialMessage();
    if (initial != null) _handleTap(initial);

    // Keep the backend's stored token current if the device rotates it.
    FirebaseMessaging.instance.onTokenRefresh.listen(_syncToken);
  }

  /// Request permission (first call only shows the OS prompt), then send this
  /// device's token to the backend. Called after login and when the user turns
  /// push on. No-op when Firebase isn't configured or permission is denied.
  Future<void> register() async {
    if (!_available) return;

    final settings = await FirebaseMessaging.instance.requestPermission();
    if (settings.authorizationStatus == AuthorizationStatus.denied) return;

    final token = await FirebaseMessaging.instance.getToken();
    if (token != null) await _syncToken(token);
  }

  /// Stop pushing to this device: clear the token on the server and locally.
  /// Called on logout, account deletion, and when the user turns push off.
  Future<void> unregister() async {
    try {
      await _api.patch('/profile', {'fcm_token': null});
    } catch (_) {
      // Best-effort; the token also dies server-side once FCM rejects it.
    }
    if (!_available) return;
    try {
      await FirebaseMessaging.instance.deleteToken();
    } catch (_) {}
  }

  Future<void> _syncToken(String token) async {
    try {
      await _api.patch('/profile', {'fcm_token': token});
    } catch (_) {
      // A failed sync just means this device won't receive push until the next
      // successful profile update; nothing user-facing to do.
    }
  }

  /// Foreground messages aren't shown by the OS, so surface a lightweight
  /// banner using the notification payload.
  void _handleForeground(RemoteMessage message) {
    final notification = message.notification;
    final context = navigatorKey.currentContext;
    if (notification == null || context == null) return;

    final text = notification.body ?? notification.title;
    if (text == null) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        action: _challengeIdOf(message) == null
            ? null
            : SnackBarAction(
                label: 'View',
                onPressed: () => _handleTap(message),
              ),
      ),
    );
  }

  /// Route a tapped notification to the same place the in-app feed would.
  /// Challenge notifications deep-link to the challenge; rank alerts just open
  /// the app.
  void _handleTap(RemoteMessage message) {
    final challengeId = _challengeIdOf(message);
    if (challengeId == null) return;

    navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (_) => ChallengeDetailScreen(
          challengeId: challengeId,
          celebrateOnOpen: message.data['type'] == 'challenge_received',
        ),
      ),
    );
  }

  int? _challengeIdOf(RemoteMessage message) {
    final data = message.data;
    final type = data['type']?.toString() ?? '';
    if (!type.startsWith('challenge_')) return null;
    final raw = data['challenge_id']?.toString();
    if (raw == null || raw.isEmpty) return null;
    return int.tryParse(raw);
  }
}
