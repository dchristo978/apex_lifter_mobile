import 'package:flutter/foundation.dart';

import '../models/models.dart';
import '../services/api_client.dart';

class WorkoutProvider extends ChangeNotifier {
  WorkoutProvider(this._api);

  final ApiClient _api;
  List<WorkoutSet> history = [];
  bool submitting = false;

  void clear() {
    history = [];
    notifyListeners();
  }

  Future<void> loadHistory() async {
    final json = await _api.get('/workout-sets');
    history = (json['workout_sets'] as List)
        .map((s) => WorkoutSet.fromJson(s as Map<String, dynamic>))
        .toList();
    notifyListeners();
  }

  Future<WorkoutSet> logSet({
    required int machineId,
    required double weightKg,
    required int reps,
    int? gymId,
  }) async {
    submitting = true;
    notifyListeners();
    try {
      final json = await _api.post('/workout-sets', {
        'machine_id': machineId,
        'weight_kg': weightKg,
        'reps': reps,
        if (gymId != null) 'gym_id': gymId,
      });
      final set =
          WorkoutSet.fromJson(json['workout_set'] as Map<String, dynamic>);
      history.insert(0, set);
      return set;
    } finally {
      submitting = false;
      notifyListeners();
    }
  }

  Future<void> deleteSet(int id) async {
    await _api.delete('/workout-sets/$id');
    history.removeWhere((s) => s.id == id);
    notifyListeners();
  }
}
