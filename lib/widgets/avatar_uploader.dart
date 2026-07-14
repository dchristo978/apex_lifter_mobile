import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';

/// Pick an image from the gallery and upload it as the user's avatar,
/// surfacing success/failure via a SnackBar. Shared by the profile and
/// settings screens.
Future<void> pickAndUploadAvatar(BuildContext context) async {
  final auth = context.read<AuthProvider>();
  final messenger = ScaffoldMessenger.of(context);
  final l10n = AppLocalizations.of(context);

  final picked = await ImagePicker().pickImage(
    source: ImageSource.gallery,
    maxWidth: 800,
    imageQuality: 85,
  );
  if (picked == null) return;

  try {
    final bytes = await picked.readAsBytes();
    await auth.uploadAvatar(bytes, picked.name);
    messenger.showSnackBar(
      SnackBar(content: Text(l10n.avatarUpdated)),
    );
  } catch (e) {
    messenger.showSnackBar(
      SnackBar(content: Text(l10n.avatarUploadFailed(e.toString()))),
    );
  }
}
