import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/permissions_service.dart';

/// Branded launch screen shown while the app boots. It also requests the core
/// runtime permissions (location, camera, gallery) up-front, then hands off to
/// the authenticated app via [onDone].
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, required this.onDone});

  final VoidCallback onDone;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _run() async {
    // Request permissions but keep a minimum on-screen time so the splash
    // doesn't flash. Both complete before we move on.
    await Future.wait([
      PermissionsService.requestOnboarding(),
      Future<void>.delayed(const Duration(milliseconds: 1600)),
    ]);
    if (mounted) widget.onDone();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(flex: 3),
            ClipRRect(
              borderRadius: BorderRadius.circular(32),
              child: Image.asset(
                'assets/icon/app_icon.png',
                width: 140,
                height: 140,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              l10n.appTitle,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
            ),
            const Spacer(flex: 3),
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }
}
