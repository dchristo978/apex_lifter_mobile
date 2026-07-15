import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../models/models.dart';
import '../services/api_client.dart';

class GymProvider extends ChangeNotifier {
  GymProvider(this._api);

  final ApiClient _api;
  List<Gym> gyms = [];
  Gym? checkedInGym;
  bool checkingIn = false;
  String? error;

  void clear() {
    checkedInGym = null;
    error = null;
    notifyListeners();
  }

  Future<void> loadGyms() async {
    final json = await _api.get('/gyms');
    gyms = (json['gyms'] as List)
        .map((g) => Gym.fromJson(g as Map<String, dynamic>))
        .toList();
    notifyListeners();
  }

  /// Restore the most recent check-in so the home screen and the "who's here"
  /// feature work across app restarts, not just after a fresh GPS check-in.
  Future<void> loadLatestCheckin() async {
    final json = await _api.get('/gyms/checkin/latest');
    final checkin = json['checkin'] as Map<String, dynamic>?;
    final gym = checkin?['gym'] as Map<String, dynamic>?;
    if (gym != null) {
      checkedInGym = Gym.fromJson(gym);
      notifyListeners();
    }
  }

  /// Public per-gym leaderboard — works without a logged-in session.
  Future<List<GymLeaderboardEntry>> gymLeaderboard(
    int gymId, {
    String period = 'weekly',
  }) async {
    final json = await _api.get('/gyms/$gymId/leaderboard', {'period': period});
    return (json['entries'] as List)
        .map((e) => GymLeaderboardEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Lifters currently checked in at the same gym.
  Future<List<GymPerson>> activePeople(int gymId) async {
    final json = await _api.get('/gyms/$gymId/active-checkins');
    return (json['people'] as List)
        .map((p) => GymPerson.fromJson(p as Map<String, dynamic>))
        .toList();
  }

  /// GPS check-in: asks for location permission, then lets the backend
  /// match the nearest FTL branch.
  Future<void> checkinWithGps() async {
    checkingIn = true;
    error = null;
    notifyListeners();

    try {
      final position = await _currentPosition();
      final json = await _api.post('/gyms/checkin', {
        'latitude': position.latitude,
        'longitude': position.longitude,
      });
      checkedInGym = Gym.fromJson(json['gym'] as Map<String, dynamic>);
    } on ApiException catch (e) {
      error = e.message;
    } catch (e) {
      error = e.toString();
    } finally {
      checkingIn = false;
      notifyListeners();
    }
  }

  Future<Position> _currentPosition() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw Exception('Aktifkan layanan lokasi (GPS) terlebih dahulu.');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw Exception('Izin lokasi ditolak. Check-in butuh akses lokasi.');
    }

    return Geolocator.getCurrentPosition();
  }
}
