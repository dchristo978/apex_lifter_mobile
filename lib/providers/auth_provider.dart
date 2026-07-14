import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/models.dart';
import '../services/api_client.dart';

enum AuthStatus { unknown, unauthenticated, authenticated }

class AuthProvider extends ChangeNotifier {
  AuthProvider(this._api);

  static const _tokenKey = 'auth_token';

  final ApiClient _api;
  AuthStatus status = AuthStatus.unknown;
  User? user;
  bool loading = false;

  /// Restore a persisted session on app start.
  Future<void> bootstrap() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);

    if (token == null) {
      status = AuthStatus.unauthenticated;
      notifyListeners();
      return;
    }

    _api.token = token;
    try {
      final json = await _api.get('/auth/me');
      user = User.fromJson(json['user'] as Map<String, dynamic>);
      status = AuthStatus.authenticated;
    } catch (_) {
      _api.token = null;
      await prefs.remove(_tokenKey);
      status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String gender,
    required String birthDate,
    double? bodyWeightKg,
  }) async {
    await _authenticate('/auth/register', {
      'name': name,
      'email': email,
      'password': password,
      'gender': gender,
      'birth_date': birthDate,
      if (bodyWeightKg != null) 'body_weight_kg': bodyWeightKg,
    });
  }

  Future<void> login({required String email, required String password}) async {
    await _authenticate('/auth/login', {'email': email, 'password': password});
  }

  Future<void> _authenticate(String path, Map<String, dynamic> body) async {
    loading = true;
    notifyListeners();
    try {
      final json = await _api.post(path, body);
      final token = json['token'] as String;
      _api.token = token;
      user = User.fromJson(json['user'] as Map<String, dynamic>);
      status = AuthStatus.authenticated;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, token);
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> updateProfile(Map<String, dynamic> fields) async {
    final json = await _api.patch('/profile', fields);
    user = User.fromJson(json['user'] as Map<String, dynamic>);
    notifyListeners();
  }

  Future<void> uploadAvatar(List<int> bytes, String filename) async {
    final json = await _api.uploadBytes(
      '/profile/avatar',
      field: 'avatar',
      bytes: bytes,
      filename: filename,
    );
    user = User.fromJson(json['user'] as Map<String, dynamic>);
    notifyListeners();
  }

  Future<void> logout() async {
    try {
      await _api.post('/auth/logout');
    } catch (_) {
      // Token may already be invalid; clear the local session regardless.
    }
    _api.token = null;
    user = null;
    status = AuthStatus.unauthenticated;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    notifyListeners();
  }
}
