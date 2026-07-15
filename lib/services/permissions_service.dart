import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

import '../l10n/app_localizations.dart';

/// Central place for runtime permission requests.
///
/// The splash screen requests the core permissions up-front, but every feature
/// also re-requests contextually (location on gym check-in, camera/gallery on
/// profile-photo change) so a first-launch denial is always recoverable.
class PermissionsService {
  /// Proactively ask for the core permissions on first launch. Denials are
  /// non-fatal here — the app continues and features re-prompt when needed.
  /// (Push-notification permission is intentionally skipped for this MVP.)
  static Future<void> requestOnboarding() async {
    // Location — handled via geolocator so it shares state with check-in.
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        await Geolocator.requestPermission();
      }
    } catch (_) {/* ignore — re-requested on check-in */}

    // Camera + gallery.
    try {
      await [Permission.camera, Permission.photos].request();
    } catch (_) {/* ignore — re-requested when changing profile photo */}
  }

  /// Ensure gallery access before picking an image. Returns true when usable.
  /// If the user permanently denied it, offers to open app settings.
  static Future<bool> ensureGallery(BuildContext context) =>
      _ensure(context, Permission.photos);

  /// Ensure camera access before capturing. Returns true when usable.
  static Future<bool> ensureCamera(BuildContext context) =>
      _ensure(context, Permission.camera);

  static Future<bool> _ensure(BuildContext context, Permission permission) async {
    var status = await permission.status;
    if (status.isGranted || status.isLimited) return true;

    if (status.isDenied) {
      status = await permission.request();
      if (status.isGranted || status.isLimited) return true;
    }

    if (status.isPermanentlyDenied || status.isRestricted) {
      if (context.mounted) await _openSettingsDialog(context);
      return false;
    }
    return status.isGranted || status.isLimited;
  }

  static Future<void> _openSettingsDialog(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final go = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.permissionNeededTitle),
        content: Text(l10n.permissionNeededBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.openSettings),
          ),
        ],
      ),
    );
    if (go == true) await openAppSettings();
  }
}
