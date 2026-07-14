import 'dart:ui';

import 'package:cupertino_native/cupertino_native.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/notification_provider.dart';
import 'home_screen.dart';
import 'leaderboard_screen.dart';
import 'profile_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  /// Native Liquid Glass UITabBar hanya tersedia di iOS/macOS;
  /// platform lain memakai _GlassNavBar buatan Flutter.
  bool get _isApplePlatform =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS);

  @override
  void initState() {
    super.initState();
    // Refresh the notification badge on app open.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationProvider>().refresh().catchError((_) {});
    });
  }

  @override
  Widget build(BuildContext context) {
    const screens = [
      HomeScreen(),
      LeaderboardScreen(),
      ProfileScreen(),
    ];

    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          IndexedStack(index: _index, children: screens),
          Positioned(
            left: 0,
            right: 0,
            bottom: 24,
            child: SafeArea(
              child: Center(
                child: _isApplePlatform
                    // Real UITabBar via platform view: genuine iOS Liquid
                    // Glass, not a Flutter imitation.
                    ? Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: CNTabBar(
                          items: const [
                            CNTabBarItem(
                                label: 'Beranda', icon: CNSymbol('house.fill')),
                            CNTabBarItem(
                                label: 'Peringkat',
                                icon: CNSymbol('chart.bar.fill')),
                            CNTabBarItem(
                                label: 'Profil',
                                icon: CNSymbol('person.crop.circle.fill')),
                          ],
                          currentIndex: _index,
                          onTap: (i) => setState(() => _index = i),
                          tint: Theme.of(context).colorScheme.primary,
                        ),
                      )
                    : _GlassNavBar(
                        index: _index,
                        onChanged: (i) => setState(() => _index = i),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Floating Apple-style glassmorphism pill navigation.
class _GlassNavBar extends StatelessWidget {
  const _GlassNavBar({required this.index, required this.onChanged});

  final int index;
  final ValueChanged<int> onChanged;

  static const _items = [
    (icon: Icons.home_outlined, activeIcon: Icons.home, label: 'Beranda'),
    (
      icon: Icons.leaderboard_outlined,
      activeIcon: Icons.leaderboard,
      label: 'Peringkat'
    ),
    (icon: Icons.person_outline, activeIcon: Icons.person, label: 'Profil'),
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(36),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(36),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.14),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.45),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < _items.length; i++)
                _navItem(context, i, scheme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(BuildContext context, int i, ColorScheme scheme) {
    final selected = i == index;
    final item = _items[i];

    return GestureDetector(
      onTap: () => onChanged(i),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? scheme.primary.withValues(alpha: 0.28)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          children: [
            Icon(
              selected ? item.activeIcon : item.icon,
              size: 22,
              color: selected
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.6),
            ),
            if (selected) ...[
              const SizedBox(width: 8),
              Text(
                item.label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
