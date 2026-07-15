import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../services/permissions_service.dart';

/// Let the user pick a new avatar from the camera or gallery and upload it,
/// surfacing success/failure via a SnackBar. Shared by the profile and
/// settings screens.
///
/// Camera / gallery permission is (re-)requested here, so a first-launch denial
/// on the splash screen is recovered the moment the user changes their photo.
Future<void> pickAndUploadAvatar(BuildContext context) async {
  final l10n = AppLocalizations.of(context);

  final source = await showModalBottomSheet<ImageSource>(
    context: context,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.photo_camera),
            title: Text(l10n.photoSourceCamera),
            onTap: () => Navigator.of(ctx).pop(ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library),
            title: Text(l10n.photoSourceGallery),
            onTap: () => Navigator.of(ctx).pop(ImageSource.gallery),
          ),
        ],
      ),
    ),
  );
  if (source == null) return;
  if (!context.mounted) return;

  final bool allowed;
  if (source == ImageSource.camera) {
    allowed = await PermissionsService.ensureCamera(context);
  } else {
    allowed = await PermissionsService.ensureGallery(context);
  }
  if (!allowed || !context.mounted) return;

  final auth = context.read<AuthProvider>();
  final messenger = ScaffoldMessenger.of(context);

  final picked = await ImagePicker().pickImage(
    source: source,
    maxWidth: 800,
    imageQuality: 85,
  );
  if (picked == null) return;

  try {
    final bytes = await picked.readAsBytes();
    await auth.uploadAvatar(bytes, picked.name);
    messenger.showSnackBar(SnackBar(content: Text(l10n.avatarUpdated)));
  } catch (e) {
    messenger.showSnackBar(
      SnackBar(content: Text(l10n.avatarUploadFailed(e.toString()))),
    );
  }
}
