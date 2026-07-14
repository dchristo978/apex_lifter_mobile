import 'package:flutter/foundation.dart';

import '../models/models.dart';
import '../services/api_client.dart';

class LeaderboardProvider extends ChangeNotifier {
  LeaderboardProvider(this._api);

  final ApiClient _api;

  List<LeaderboardEntry> entries = [];
  int? myRank;
  bool loading = false;
  String? error;

  // Filters
  int? machineId;
  String type = 'multi'; // 'single' (1RM murni) | 'multi' (estimated 1RM)
  String period = 'weekly';
  String? gender;
  String? ageBracket;
  String? weightClass;

  void clear() {
    entries = [];
    myRank = null;
    machineId = null;
    gender = null;
    ageBracket = null;
    weightClass = null;
    notifyListeners();
  }

  Future<void> refresh() async {
    if (machineId == null) return;
    loading = true;
    error = null;
    notifyListeners();

    try {
      final json = await _api.get('/leaderboard', {
        'machine_id': machineId.toString(),
        'type': type,
        'period': period,
        if (gender != null) 'gender': gender!,
        if (ageBracket != null) 'age_bracket': ageBracket!,
        if (weightClass != null) 'weight_class': weightClass!,
      });
      entries = (json['entries'] as List)
          .map((e) => LeaderboardEntry.fromJson(e as Map<String, dynamic>))
          .toList();
      myRank = json['my_rank'] as int?;
    } on ApiException catch (e) {
      error = e.message;
    } finally {
      loading = false;
      notifyListeners();
    }
  }
}
