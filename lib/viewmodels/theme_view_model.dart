import 'package:flutter/material.dart';

import '../services/preferences_service.dart';

/// Owns the user's preferred [ThemeMode] and persists it.
class ThemeViewModel extends ChangeNotifier {
  ThemeViewModel({PreferencesService? preferencesService})
      : _preferences = preferencesService ?? PreferencesService();

  final PreferencesService _preferences;
  ThemeMode _themeMode = ThemeMode.light;

  ThemeMode get themeMode => _themeMode;

  Future<void> load() async {
    final stored = await _preferences.loadThemeMode();
    _themeMode = switch (stored) {
      'dark' => ThemeMode.dark,
      _ => ThemeMode.light, // default to light
    };
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();
    await _preferences.saveThemeMode(mode.name);
  }
}
