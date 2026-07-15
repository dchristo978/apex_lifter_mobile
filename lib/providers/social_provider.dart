import 'package:flutter/foundation.dart';

import '../models/models.dart';
import '../services/api_client.dart';

/// The result of a follow/unfollow call: the new relationship state and the
/// target's refreshed follower count, so callers can update UI without a reload.
class FollowState {
  const FollowState({required this.isFollowing, required this.followersCount});

  final bool isFollowing;
  final int followersCount;

  factory FollowState.fromJson(Map<String, dynamic> json) => FollowState(
        isFollowing: json['is_following'] as bool? ?? false,
        followersCount: json['followers_count'] as int? ?? 0,
      );
}

/// Owns the activity feed (paginated, infinite scroll) and follow actions.
class SocialProvider extends ChangeNotifier {
  SocialProvider(this._api);

  final ApiClient _api;

  final List<FeedItem> feed = [];
  int _nextPage = 1;
  bool hasMore = true;
  bool loading = false;
  String? error;

  void clear() {
    feed.clear();
    _nextPage = 1;
    hasMore = true;
    loading = false;
    error = null;
    notifyListeners();
  }

  /// Reload the feed from the first page (pull-to-refresh / first open).
  Future<void> refreshFeed() async {
    _nextPage = 1;
    hasMore = true;
    error = null;
    feed.clear();
    notifyListeners();
    await loadNextPage();
  }

  /// Fetch the next page of feed items; no-op while a load is in flight or the
  /// end has been reached.
  Future<void> loadNextPage() async {
    if (loading || !hasMore) return;
    loading = true;
    notifyListeners();
    try {
      final json = await _api.get('/feed', {'page': '$_nextPage'});
      final data = (json['data'] as List)
          .map((f) => FeedItem.fromJson(f as Map<String, dynamic>))
          .toList();
      feed.addAll(data);
      hasMore = json['has_more'] as bool? ?? false;
      _nextPage++;
      error = null;
    } on ApiException catch (e) {
      error = e.message;
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<FollowState> follow(int userId) async {
    final json = await _api.post('/users/$userId/follow');
    return FollowState.fromJson(json);
  }

  Future<FollowState> unfollow(int userId) async {
    final json = await _api.delete('/users/$userId/follow');
    return FollowState.fromJson(json);
  }

  Future<List<FollowUser>> followers(int userId) => _userList(userId, 'followers');

  Future<List<FollowUser>> following(int userId) => _userList(userId, 'following');

  Future<List<FollowUser>> _userList(int userId, String kind) async {
    final json = await _api.get('/users/$userId/$kind');
    return (json['users'] as List)
        .map((u) => FollowUser.fromJson(u as Map<String, dynamic>))
        .toList();
  }

  /// Toggle kudos on a feed item, updating its counters optimistically and
  /// rolling back if the request fails.
  Future<void> toggleKudos(FeedItem item) async {
    final wasKudoed = item.viewerKudoed;
    item.viewerKudoed = !wasKudoed;
    item.kudosCount += wasKudoed ? -1 : 1;
    notifyListeners();
    try {
      final json = wasKudoed
          ? await _api.delete('/activities/${item.id}/kudos')
          : await _api.post('/activities/${item.id}/kudos');
      item.kudosCount = json['kudos_count'] as int? ?? item.kudosCount;
      item.viewerKudoed = json['viewer_kudoed'] as bool? ?? item.viewerKudoed;
    } catch (_) {
      // Roll back the optimistic change.
      item.viewerKudoed = wasKudoed;
      item.kudosCount += wasKudoed ? 1 : -1;
    } finally {
      notifyListeners();
    }
  }

  Future<List<ActivityComment>> comments(int activityId) async {
    final json = await _api.get('/activities/$activityId/comments');
    return (json['comments'] as List)
        .map((c) => ActivityComment.fromJson(c as Map<String, dynamic>))
        .toList();
  }

  /// Post a comment and reflect the new count on the matching feed item.
  Future<ActivityComment> addComment(int activityId, String body) async {
    final json = await _api.post('/activities/$activityId/comments', {'body': body});
    _bumpCommentCount(activityId, 1);
    return ActivityComment.fromJson(json['comment'] as Map<String, dynamic>);
  }

  Future<void> deleteComment(int activityId, int commentId) async {
    await _api.delete('/activities/$activityId/comments/$commentId');
    _bumpCommentCount(activityId, -1);
  }

  void _bumpCommentCount(int activityId, int delta) {
    for (final item in feed) {
      if (item.id == activityId) {
        item.commentCount = (item.commentCount + delta).clamp(0, 1 << 30);
        notifyListeners();
        break;
      }
    }
  }

  Future<List<FollowSuggestion>> suggestions() async {
    final json = await _api.get('/follow-suggestions');
    return (json['users'] as List)
        .map((u) => FollowSuggestion.fromJson(u as Map<String, dynamic>))
        .toList();
  }
}
