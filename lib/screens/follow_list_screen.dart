import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/models.dart';
import '../providers/social_provider.dart';
import '../widgets/user_avatar.dart';
import 'public_profile_screen.dart';

/// Kind of list to show: the lifters following [userId], or those they follow.
enum FollowListKind { followers, following }

/// A lifter's followers or following list. Tapping a row opens that lifter's
/// public profile.
class FollowListScreen extends StatefulWidget {
  const FollowListScreen({
    super.key,
    required this.userId,
    required this.kind,
  });

  final int userId;
  final FollowListKind kind;

  @override
  State<FollowListScreen> createState() => _FollowListScreenState();
}

class _FollowListScreenState extends State<FollowListScreen> {
  Future<List<FollowUser>>? _future;

  @override
  void initState() {
    super.initState();
    final social = context.read<SocialProvider>();
    _future = widget.kind == FollowListKind.followers
        ? social.followers(widget.userId)
        : social.following(widget.userId);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final title = widget.kind == FollowListKind.followers
        ? l10n.followers
        : l10n.following;

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: FutureBuilder<List<FollowUser>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('${snapshot.error}',
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                    textAlign: TextAlign.center),
              ),
            );
          }
          final users = snapshot.data ?? const [];
          if (users.isEmpty) {
            return Center(
              child: Text(
                widget.kind == FollowListKind.followers
                    ? l10n.noFollowers
                    : l10n.noFollowing,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: users.length,
            itemBuilder: (context, index) {
              final u = users[index];
              return ListTile(
                leading: UserAvatar(name: u.name, avatarUrl: u.avatarUrl),
                title: Text(u.name),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => PublicProfileScreen(
                        userId: u.id, initialName: u.name),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
