import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/models.dart';
import '../providers/gym_provider.dart';
import 'gym_leaderboard_screen.dart';

/// Every FTL branch with its address. Public: reachable from the login screen
/// as well as from inside the app. Tapping a gym opens its own leaderboard.
class GymsScreen extends StatefulWidget {
  const GymsScreen({super.key});

  @override
  State<GymsScreen> createState() => _GymsScreenState();
}

class _GymsScreenState extends State<GymsScreen> {
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await context.read<GymProvider>().loadGyms();
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final gyms = context.watch<GymProvider>().gyms;
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.gymLocations)),
      body: _loading && gyms.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : _error != null && gyms.isEmpty
              ? _message(context, _error!, retry: true)
              : gyms.isEmpty
                  ? _message(context, l10n.noGymsFound)
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                        itemCount: gyms.length,
                        itemBuilder: (context, i) => _gymTile(context, gyms[i]),
                      ),
                    ),
    );
  }

  Widget _message(BuildContext context, String text, {bool retry = false}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.location_off_outlined,
                size: 48,
                color: Theme.of(context).colorScheme.onSurfaceVariant),
            const SizedBox(height: 12),
            Text(text, textAlign: TextAlign.center),
            if (retry) ...[
              const SizedBox(height: 12),
              FilledButton.tonalIcon(
                onPressed: _load,
                icon: const Icon(Icons.refresh, size: 18),
                label: Text(AppLocalizations.of(context).update),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _gymTile(BuildContext context, Gym gym) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: scheme.primaryContainer,
          child: const Icon(Icons.location_on, size: 20, color: Colors.white),
        ),
        title: Text(gym.name),
        subtitle: Text(
          gym.address,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: const Icon(Icons.leaderboard_outlined),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => GymLeaderboardScreen(gym: gym)),
        ),
      ),
    );
  }
}
