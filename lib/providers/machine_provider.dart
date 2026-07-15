import 'package:flutter/foundation.dart';

import '../models/models.dart';
import '../services/api_client.dart';

class MachineProvider extends ChangeNotifier {
  MachineProvider(this._api);

  final ApiClient _api;
  List<Machine> machines = [];
  bool loaded = false;

  Future<void> loadMachines() async {
    if (loaded) return;
    final json = await _api.get('/machines');
    machines = (json['machines'] as List)
        .map((m) => Machine.fromJson(m as Map<String, dynamic>))
        .toList();
    loaded = true;
    notifyListeners();
  }

  /// Machines grouped by category, preserving backend ordering.
  Map<String, List<Machine>> get byCategory {
    final map = <String, List<Machine>>{};
    for (final machine in machines) {
      map.putIfAbsent(machine.category, () => []).add(machine);
    }
    return map;
  }

  /// Preferred display order for muscle-group sections.
  static const List<String> muscleOrder = [
    'Chest',
    'Upper Back',
    'Lats',
    'Lower Back',
    'Traps',
    'Shoulders',
    'Neck',
    'Biceps',
    'Triceps',
    'Forearms',
    'Quadriceps',
    'Hamstrings',
    'Glutes',
    'Calves',
    'Abductors',
    'Adductors',
    'Abdominals',
    'Full Body',
    'Other',
  ];

  /// Machines grouped by fine-grained muscle group, sections ordered by
  /// [muscleOrder] and machines within a section kept in backend order.
  Map<String, List<Machine>> get byMuscleGroup {
    final map = <String, List<Machine>>{};
    for (final machine in machines) {
      map.putIfAbsent(machine.muscleGroup ?? machine.category, () => [])
          .add(machine);
    }
    final keys = map.keys.toList()
      ..sort((a, b) {
        int idx(String s) {
          final i = muscleOrder.indexOf(s);
          return i == -1 ? muscleOrder.length : i;
        }

        final c = idx(a).compareTo(idx(b));
        return c != 0 ? c : a.compareTo(b);
      });
    return {for (final k in keys) k: map[k]!};
  }
}
