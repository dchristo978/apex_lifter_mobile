import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/models.dart';
import '../providers/social_provider.dart';
import '../services/api_client.dart';
import '../widgets/user_avatar.dart';
import 'public_profile_screen.dart';

/// The comment thread for a single feed activity, with an inline composer.
class CommentsScreen extends StatefulWidget {
  const CommentsScreen({super.key, required this.activityId});

  final int activityId;

  @override
  State<CommentsScreen> createState() => _CommentsScreenState();
}

class _CommentsScreenState extends State<CommentsScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  List<ActivityComment> _comments = [];
  bool _loading = true;
  bool _sending = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final comments =
          await context.read<SocialProvider>().comments(widget.activityId);
      if (mounted) {
        setState(() {
          _comments = comments;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  Future<void> _send() async {
    final body = _controller.text.trim();
    if (body.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      final comment =
          await context.read<SocialProvider>().addComment(widget.activityId, body);
      if (mounted) {
        setState(() {
          _comments = [..._comments, comment];
          _controller.clear();
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
          }
        });
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _delete(ActivityComment comment) async {
    try {
      await context
          .read<SocialProvider>()
          .deleteComment(widget.activityId, comment.id);
      if (mounted) {
        setState(() => _comments.removeWhere((c) => c.id == comment.id));
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.commentsTitle)),
      body: Column(
        children: [
          Expanded(child: _list(l10n)),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      decoration: InputDecoration(
                        hintText: l10n.addCommentHint,
                        border: const OutlineInputBorder(),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _sending ? null : _send,
                    icon: _sending
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.send),
                    tooltip: l10n.send,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _list(AppLocalizations l10n) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(_error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
              textAlign: TextAlign.center),
        ),
      );
    }
    if (_comments.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(l10n.noComments,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center),
        ),
      );
    }
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _comments.length,
      itemBuilder: (context, index) {
        final c = _comments[index];
        return ListTile(
          leading: UserAvatar(name: c.authorName, avatarUrl: c.authorAvatarUrl),
          title: InkWell(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => PublicProfileScreen(
                    userId: c.authorId, initialName: c.authorName),
              ),
            ),
            child: Text(c.authorName,
                style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(c.body),
              const SizedBox(height: 2),
              Text(DateFormat('d MMM · HH:mm').format(c.createdAt),
                  style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
          trailing: c.isMine
              ? IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  tooltip: l10n.deleteComment,
                  onPressed: () => _delete(c),
                )
              : null,
        );
      },
    );
  }
}
