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
}
