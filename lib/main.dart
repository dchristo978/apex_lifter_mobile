import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'l10n/app_localizations.dart';
import 'providers/auth_provider.dart';
import 'providers/challenge_provider.dart';
import 'providers/gym_provider.dart';
import 'providers/leaderboard_provider.dart';
import 'providers/machine_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/workout_provider.dart';
import 'screens/login_screen.dart';
import 'screens/main_shell.dart';
import 'screens/onboarding_screen.dart';
import 'screens/splash_screen.dart';
import 'services/api_client.dart';

void main() {
  final api = ApiClient();

  runApp(
    MultiProvider(
      providers: [
        Provider<ApiClient>.value(value: api),
        ChangeNotifierProvider(create: (_) => SettingsProvider()..load()),
        ChangeNotifierProvider(create: (_) => AuthProvider(api)..bootstrap()),
        ChangeNotifierProvider(create: (_) => GymProvider(api)),
        ChangeNotifierProvider(create: (_) => MachineProvider(api)),
        ChangeNotifierProvider(create: (_) => WorkoutProvider(api)),
        ChangeNotifierProvider(create: (_) => LeaderboardProvider(api)),
        ChangeNotifierProvider(create: (_) => NotificationProvider(api)),
        ChangeNotifierProvider(create: (_) => ChallengeProvider(api)),
      ],
      child: const ApexLifterApp(),
    ),
  );
}

// Pure black + iOS default blue palette with gray accents.
const _blue = Color(0xFF007AFF);
const _black = Color(0xFF000000);
const _grayDark = Color(0xFF1A1A1A);
const _gray = Color(0xFF2A2A2A);
const _grayLight = Color(0xFFBDBDBD);

ThemeData _buildTheme() {
  final base = ColorScheme.fromSeed(
    seedColor: _blue,
    brightness: Brightness.dark,
  );

  final scheme = base.copyWith(
    primary: _blue,
    onPrimary: Colors.white,
    primaryContainer: _blue,
    onPrimaryContainer: Colors.white,
    secondary: _grayLight,
    onSecondary: _black,
    secondaryContainer: _gray,
    onSecondaryContainer: Colors.white,
    surface: _black,
    onSurface: Colors.white,
    onSurfaceVariant: _grayLight,
    surfaceContainerLowest: _black,
    surfaceContainerLow: _grayDark,
    surfaceContainer: _grayDark,
    surfaceContainerHigh: _gray,
    surfaceContainerHighest: _gray,
    outline: const Color(0xFF5A5A5A),
    outlineVariant: const Color(0xFF3A3A3A),
  );

  return ThemeData(
    colorScheme: scheme,
    useMaterial3: true,
    scaffoldBackgroundColor: _black,
    appBarTheme: const AppBarTheme(
      backgroundColor: _black,
      foregroundColor: Colors.white,
      centerTitle: false,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: _black,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: _grayDark,
      indicatorColor: _blue,
    ),
    cardTheme: const CardThemeData(color: _grayDark),
  );
}

class ApexLifterApp extends StatelessWidget {
  const ApexLifterApp({super.key});

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<SettingsProvider>().locale;

    return MaterialApp(
      title: 'Apex Lifter',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(),
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const _RootGate(),
    );
  }
}

/// Shows the branded [SplashScreen] first (which also requests core
/// permissions), then routes to login or the app shell based on auth state.
class _RootGate extends StatefulWidget {
  const _RootGate();

  @override
  State<_RootGate> createState() => _RootGateState();
}

class _RootGateState extends State<_RootGate> {
  bool _splashDone = false;

  @override
  Widget build(BuildContext context) {
    if (!_splashDone) {
      return SplashScreen(onDone: () => setState(() => _splashDone = true));
    }
    return Consumer<AuthProvider>(
      builder: (context, auth, _) => switch (auth.status) {
        AuthStatus.unknown =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
        AuthStatus.unauthenticated => const _OnboardingGate(),
        AuthStatus.authenticated => const MainShell(),
      },
    );
  }
}

/// Plays the 3-slide onboarding before showing the login screen. The gate is
/// rebuilt from scratch whenever auth flips to unauthenticated, so the slides
/// reappear on every fresh launch and right after a logout.
class _OnboardingGate extends StatefulWidget {
  const _OnboardingGate();

  @override
  State<_OnboardingGate> createState() => _OnboardingGateState();
}

class _OnboardingGateState extends State<_OnboardingGate> {
  bool _done = false;

  @override
  Widget build(BuildContext context) {
    if (!_done) {
      return OnboardingScreen(onDone: () => setState(() => _done = true));
    }
    return const LoginScreen();
  }
}
