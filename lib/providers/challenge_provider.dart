import 'package:flutter/foundation.dart';

import '../models/models.dart';
import '../services/api_client.dart';

/// Owns challenge state: the community Arena, the current user's own
/// challenges, medal history, and the actions that mutate them.
class ChallengeProvider extends ChangeNotifier {
  ChallengeProvider(this._api);

  final ApiClient _api;

  List<Challenge> arena = [];
  List<Challenge> mine = [];
  List<Challenge> history = [];
  int medals = 0;

  /// Rejection reason codes offered as a dropdown in the voting sheet.
  List<String> reasonCodes = const [
    'load_too_light',
    'incomplete_reps',
    'wrong_machine',
    'bad_form',
    'partial_range',
    'video_unclear',
    'other',
  ];

  bool loadingArena = false;
  bool loadingMine = false;

  void clear() {
    arena = [];
    mine = [];
    history = [];
    medals = 0;
    notifyListeners();
  }

  Future<void> loadArena() async {
    loadingArena = true;
    notifyListeners();
    try {
      final json = await _api.get('/challenges/arena');
      arena = _parseList(json['challenges']);
      final codes = (json['reason_codes'] as List?)?.map((e) => e.toString());
      if (codes != null && codes.isNotEmpty) reasonCodes = codes.toList();
    } finally {
      loadingArena = false;
      notifyListeners();
    }
  }

  Future<void> loadMine() async {
    loadingMine = true;
    notifyListeners();
    try {
      final json = await _api.get('/challenges');
      mine = _parseList(json['challenges']);
    } finally {
      loadingMine = false;
      notifyListeners();
    }
  }

  Future<void> loadHistory() async {
    final json = await _api.get('/challenges/history');
    history = _parseList(json['challenges']);
    medals = json['medals'] as int? ?? 0;
    notifyListeners();
  }

  Future<Challenge> fetch(int id) async {
    final json = await _api.get('/challenges/$id');
    return Challenge.fromJson(json['challenge'] as Map<String, dynamic>);
  }

  Future<Challenge> create({
    required int opponentId,
    required int machineId,
    required double targetWeightKg,
    required int targetReps,
    required int targetSets,
  }) async {
    final json = await _api.post('/challenges', {
      'opponent_id': opponentId,
      'machine_id': machineId,
      'target_weight_kg': targetWeightKg,
      'target_reps': targetReps,
      'target_sets': targetSets,
    });
    final challenge = Challenge.fromJson(json['challenge'] as Map<String, dynamic>);
    await loadMine();
    return challenge;
  }

  Future<Challenge> submitVideo(int id, String filePath) async {
    final json = await _api.uploadFile(
      '/challenges/$id/video',
      field: 'video',
      filePath: filePath,
    );
    final challenge = Challenge.fromJson(json['challenge'] as Map<String, dynamic>);
    _replace(challenge);
    return challenge;
  }

  Future<Challenge> decline(int id) async {
    final json = await _api.post('/challenges/$id/decline');
    final challenge = Challenge.fromJson(json['challenge'] as Map<String, dynamic>);
    _replace(challenge);
    return challenge;
  }

  Future<Challenge> vote(
    int id, {
    required String choice,
    Map<String, bool>? criteria,
    String? reasonCode,
    String? reasonText,
  }) async {
    final json = await _api.post('/challenges/$id/vote', {
      'choice': choice,
      if (criteria != null) 'criteria': criteria,
      if (reasonCode != null) 'reason_code': reasonCode,
      if (reasonText != null && reasonText.isNotEmpty) 'reason_text': reasonText,
    });
    final challenge = Challenge.fromJson(json['challenge'] as Map<String, dynamic>);
    _replace(challenge);
    return challenge;
  }

  void _replace(Challenge c) {
    void patch(List<Challenge> list) {
      final i = list.indexWhere((e) => e.id == c.id);
      if (i != -1) list[i] = c;
    }

    patch(arena);
    patch(mine);
    patch(history);
    notifyListeners();
  }

  List<Challenge> _parseList(dynamic raw) => (raw as List)
      .map((e) => Challenge.fromJson(e as Map<String, dynamic>))
      .toList();
}
