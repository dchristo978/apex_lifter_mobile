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
