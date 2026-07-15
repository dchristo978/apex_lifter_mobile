import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/models.dart';
import '../providers/social_provider.dart';
import '../widgets/user_avatar.dart';
import 'comments_screen.dart';
import 'public_profile_screen.dart';

/// The social activity feed: PRs, medals, and check-ins from lifters the viewer
/// follows (and themselves), newest first, with infinite scroll. A "who to
/// follow" strip sits at the top to help lifters build their feed.
class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final social = context.read<SocialProvider>();
      if (social.feed.isEmpty) social.refreshFeed();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {
      context.read<SocialProvider>().loadNextPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final social = context.watch<SocialProvider>();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.feedTitle)),
      body: RefreshIndicator(
        onRefresh: () => social.refreshFeed(),
        child: _body(context, social, l10n),
      ),
    );
  }

  Widget _body(
      BuildContext context, SocialProvider social, AppLocalizations l10n) {
    if (social.feed.isEmpty && social.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    // A leading suggestions strip is always item 0; the feed (or an empty-state
    // message) follows.
    final showEmpty = social.feed.isEmpty;
    final itemCount = 1 +
        (showEmpty ? 1 : social.feed.length) +
        (!showEmpty && (social.hasMore || social.loading) ? 1 : 0);

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 140),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        if (index == 0) return const _SuggestionsStrip();

        if (showEmpty) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
            child: Column(
              children: [
                Icon(Icons.groups_outlined,
                    size: 56, color: Theme.of(context).colorScheme.outline),
                const SizedBox(height: 16),
                Text(
                  social.error ?? l10n.feedEmpty,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          );
        }

        final feedIndex = index - 1;
        if (feedIndex >= social.feed.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }
        return _FeedTile(item: social.feed[feedIndex]);
      },
    );
  }
}

class _FeedTile extends StatelessWidget {
  const _FeedTile({required this.item});

  final FeedItem item;

  ({IconData icon, Color color}) _visual(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    switch (item.type) {
      case 'pr':
        return (icon: Icons.trending_up, color: scheme.primary);
      case 'medal':
        return (icon: Icons.emoji_events, color: const Color(0xFFFFC107));
      case 'checkin':
      default:
        return (icon: Icons.location_on, color: scheme.secondary);
    }
  }

  String _sentence(AppLocalizations l10n) {
    final meta = item.meta;
    switch (item.type) {
      case 'pr':
        final weight = _fmtNum(meta['weight_kg']);
        final reps = (meta['reps'] as num?)?.toInt() ?? 0;
        final machine = meta['machine_name'] as String?;
        return machine == null
            ? l10n.feedPrNoMachine(weight, reps)
            : l10n.feedPr(machine, weight, reps);
      case 'medal':
        final machine = (meta['machine_name'] as String?) ?? '';
        final defeated = meta['defeated_name'] as String?;
        return defeated == null
            ? l10n.feedMedal(machine)
            : l10n.feedMedalVs(machine, defeated);
      case 'checkin':
      default:
        return l10n.feedCheckin((meta['gym_name'] as String?) ?? '');
    }
  }

  static String _fmtNum(dynamic value) {
    final n = (value as num?)?.toDouble() ?? 0;
    return n == n.roundToDouble() ? n.toStringAsFixed(0) : n.toStringAsFixed(1);
  }

  void _openProfile(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PublicProfileScreen(
            userId: item.actorId, initialName: item.actorName),
      ),
    );
  }

  void _openComments(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => CommentsScreen(activityId: item.id)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final v = _visual(context);
    final when = DateFormat('d MMM · HH:mm').format(item.createdAt);

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListTile(
            onTap: () => _openProfile(context),
            leading: Stack(
              alignment: Alignment.bottomRight,
              children: [
                UserAvatar(
                    name: item.actorName, avatarUrl: item.actorAvatarUrl),
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: scheme.surface,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(v.icon, size: 15, color: v.color),
                ),
              ],
            ),
            title: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: item.actorName,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const TextSpan(text: ' '),
                  TextSpan(text: _sentence(l10n)),
                ],
              ),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child:
                  Text(when, style: Theme.of(context).textTheme.bodySmall),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 4),
            child: Row(
              children: [
                _ActionButton(
                  icon: item.viewerKudoed
                      ? Icons.favorite
                      : Icons.favorite_border,
                  color: item.viewerKudoed ? scheme.primary : null,
                  label: l10n.kudos,
                  count: item.kudosCount,
                  onTap: () =>
                      context.read<SocialProvider>().toggleKudos(item),
                ),
                _ActionButton(
                  icon: Icons.mode_comment_outlined,
                  label: l10n.comments,
                  count: item.commentCount,
                  onTap: () => _openComments(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.count,
    required this.onTap,
    this.color,
  });

  final IconData icon;
  final String label;
  final int count;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18, color: color),
      label: Text(
        count > 0 ? '$label · $count' : label,
        style: TextStyle(color: color ?? Theme.of(context).colorScheme.onSurface),
      ),
      style: TextButton.styleFrom(
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        padding: const EdgeInsets.symmetric(horizontal: 12),
      ),
    );
  }
}

/// A horizontal "who to follow" strip. Self-hides when there are no
/// suggestions; each card can be followed inline, then disappears.
class _SuggestionsStrip extends StatefulWidget {
  const _SuggestionsStrip();

  @override
  State<_SuggestionsStrip> createState() => _SuggestionsStripState();
}

class _SuggestionsStripState extends State<_SuggestionsStrip> {
  List<FollowSuggestion> _suggestions = [];
  final Set<int> _following = {};
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final list = await context.read<SocialProvider>().suggestions();
      if (mounted) {
        setState(() {
          _suggestions = list;
          _loaded = true;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loaded = true);
    }
  }

  Future<void> _follow(FollowSuggestion s) async {
    setState(() => _following.add(s.id));
    try {
      await context.read<SocialProvider>().follow(s.id);
      if (mounted) {
        setState(() => _suggestions.removeWhere((x) => x.id == s.id));
      }
    } catch (_) {
      if (mounted) setState(() => _following.remove(s.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded || _suggestions.isEmpty) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
          child: Text(l10n.suggestedLifters,
              style: Theme.of(context).textTheme.titleMedium),
        ),
        SizedBox(
          height: 190,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _suggestions.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) => _SuggestionCard(
              suggestion: _suggestions[index],
              busy: _following.contains(_suggestions[index].id),
              onFollow: () => _follow(_suggestions[index]),
            ),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}

class _SuggestionCard extends StatelessWidget {
  const _SuggestionCard({
    required this.suggestion,
    required this.busy,
    required this.onFollow,
  });

  final FollowSuggestion suggestion;
  final bool busy;
  final VoidCallback onFollow;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final reason = suggestion.reason == 'gym'
        ? l10n.suggestionReasonGym
        : l10n.suggestionReasonPopular;

    return SizedBox(
      width: 150,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              InkWell(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => PublicProfileScreen(
                        userId: suggestion.id, initialName: suggestion.name),
                  ),
                ),
                child: UserAvatar(
                    name: suggestion.name,
                    avatarUrl: suggestion.avatarUrl,
                    radius: 28),
              ),
              const SizedBox(height: 8),
              Text(suggestion.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              Text(reason,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: busy ? null : onFollow,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    visualDensity: VisualDensity.compact,
                  ),
                  child: busy
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(l10n.follow),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
