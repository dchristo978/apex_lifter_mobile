import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/models.dart';
import '../providers/gym_provider.dart';
import '../widgets/user_avatar.dart';
import 'public_profile_screen.dart';

/// Lifters currently checked in at the same gym as the user.
class GymPresenceScreen extends StatefulWidget {
  const GymPresenceScreen({
    super.key,
    required this.gymId,
    required this.gymName,
  });

  final int gymId;
  final String gymName;

  @override
  State<GymPresenceScreen> createState() => _GymPresenceScreenState();
}

class _GymPresenceScreenState extends State<GymPresenceScreen> {
  List<GymPerson>? _people;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _error = null;
      _people = null;
    });
    try {
      final people = await context.read<GymProvider>().activePeople(widget.gymId);
      if (mounted) setState(() => _people = people);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).atGym),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(28),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(widget.gymName,
                style: Theme.of(context).textTheme.bodyMedium),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _buildBody(context),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (_error != null) {
      return ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(48),
            child: Center(
                child: Text(_error!,
                    style:
                        TextStyle(color: Theme.of(context).colorScheme.error))),
          ),
        ],
      );
    }
    if (_people == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final people = _people!;
    if (people.isEmpty) {
      return ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(48),
            child: Center(
              child: Text(
                l10n.noRecentCheckins,
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 140),
      itemCount: people.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(4, 4, 4, 12),
            child: Text(
              l10n.liftersHere(people.length),
              style: Theme.of(context).textTheme.titleMedium,
            ),
          );
        }
        final person = people[index - 1];
        return Card(
          child: ListTile(
            leading: UserAvatar(name: person.name, avatarUrl: person.avatarUrl),
            title: Row(
              children: [
                Flexible(child: Text(person.name)),
                if (person.isMe)
                  Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: Text(l10n.you,
                        style:
                            const TextStyle(fontStyle: FontStyle.italic)),
                  ),
              ],
            ),
            subtitle: Text(l10n.checkedInTime(
                DateFormat('HH:mm').format(person.checkedInAt))),
            trailing: person.isMe ? null : const Icon(Icons.chevron_right),
            onTap: person.isMe
                ? null
                : () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => PublicProfileScreen(
                          userId: person.userId,
                          initialName: person.name,
                        ),
                      ),
                    ),
          ),
        );
      },
    );
  }
}
