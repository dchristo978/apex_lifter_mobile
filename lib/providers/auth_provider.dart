import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/models.dart';
import '../services/api_client.dart';

enum AuthStatus { unknown, unauthenticated, authenticated }

class AuthProvider extends ChangeNotifier {
  AuthProvider(this._api);

  static const _tokenKey = 'auth_token';
  static const _rememberEmailKey = 'remember_email';

  final ApiClient _api;
  AuthStatus status = AuthStatus.unknown;
  User? user;
  bool loading = false;

  /// The email a returning user asked us to remember, or `null` if they opted
  /// out. Used to prefill the login form after they've logged out.
  Future<String?> rememberedEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_rememberEmailKey);
  }

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

  Future<void> login({
    required String email,
    required String password,
    bool rememberMe = false,
  }) async {
    await _authenticate('/auth/login', {'email': email, 'password': password});

    // Only reached when authentication succeeds. Persist (or clear) the email
    // so the login form can prefill it next time. The password is never stored.
    final prefs = await SharedPreferences.getInstance();
    if (rememberMe) {
      await prefs.setString(_rememberEmailKey, email);
    } else {
      await prefs.remove(_rememberEmailKey);
    }
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

  /// Ask the server to email a reset code. Always succeeds (the server gives an
  /// identical response whether or not the email is registered), so the UI must
  /// not reveal whether an account exists.
  Future<void> forgotPassword(String email) async {
    await _api.post('/auth/forgot-password', {'email': email});
  }

  /// Complete a reset with the emailed code. On success the server returns a
  /// fresh session token, so the lifter lands signed in.
  Future<void> resetPassword({
    required String email,
    required String code,
    required String password,
  }) async {
    await _authenticate('/auth/reset-password', {
      'email': email,
      'code': code,
      'password': password,
    });
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

  /// Permanently delete the account after re-entering the password, then drop
  /// the local session exactly as logout does.
  Future<void> deleteAccount(String password) async {
    await _api.delete('/auth/account', {'password': password});
    _api.token = null;
    user = null;
    status = AuthStatus.unauthenticated;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_rememberEmailKey);
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
