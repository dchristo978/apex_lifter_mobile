import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// App-wide user preferences: interface language and push-notification opt-in.
/// English is the default language; both settings persist across launches.
class SettingsProvider extends ChangeNotifier {
  static const _localeKey = 'locale_code';
  static const _pushKey = 'push_enabled';

  /// Languages the app ships translations for. English is first (the default).
  static const supportedLocales = [Locale('en'), Locale('id')];

  Locale _locale = const Locale('en');
  bool _pushEnabled = true;

  Locale get locale => _locale;
  bool get pushEnabled => _pushEnabled;

  /// Restore persisted preferences on app start.
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_localeKey);
    if (code != null &&
        supportedLocales.any((l) => l.languageCode == code)) {
      _locale = Locale(code);
    }
    _pushEnabled = prefs.getBool(_pushKey) ?? true;
    notifyListeners();
  }

  Future<void> setLocale(Locale locale) async {
    if (_locale == locale) return;
    _locale = locale;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localeKey, locale.languageCode);
  }

  Future<void> setPushEnabled(bool enabled) async {
    if (_pushEnabled == enabled) return;
    _pushEnabled = enabled;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_pushKey, enabled);
  }
}
