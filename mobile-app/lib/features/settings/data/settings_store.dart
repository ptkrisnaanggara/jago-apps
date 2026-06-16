import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persisted settings snapshot; `null` fields mean "not set, use the default".
typedef SettingsSnapshot = ({Locale? locale, ThemeMode? themeMode});

/// Persists user preferences (language + theme). Abstracted so the bloc depends
/// on a contract — `main.dart` wires the prefs-backed impl, tests use in-memory.
abstract class SettingsStore {
  Future<SettingsSnapshot> read();
  Future<void> saveLocale(Locale locale);
  Future<void> saveThemeMode(ThemeMode mode);
}

/// Default, non-persistent store (used by tests and as a safe fallback).
class InMemorySettingsStore implements SettingsStore {
  Locale? _locale;
  ThemeMode? _themeMode;

  @override
  Future<SettingsSnapshot> read() async =>
      (locale: _locale, themeMode: _themeMode);

  @override
  Future<void> saveLocale(Locale locale) async => _locale = locale;

  @override
  Future<void> saveThemeMode(ThemeMode mode) async => _themeMode = mode;
}

/// Persists preferences with `shared_preferences` (non-sensitive data; PRD §5).
class PrefsSettingsStore implements SettingsStore {
  static const _localeKey = 'settings_locale';
  static const _themeModeKey = 'settings_theme_mode';

  final SharedPreferences _prefs;

  const PrefsSettingsStore(this._prefs);

  @override
  Future<SettingsSnapshot> read() async {
    final localeCode = _prefs.getString(_localeKey);
    final themeName = _prefs.getString(_themeModeKey);
    return (
      locale: localeCode == null ? null : Locale(localeCode),
      themeMode: _themeModeFromName(themeName),
    );
  }

  @override
  Future<void> saveLocale(Locale locale) async =>
      _prefs.setString(_localeKey, locale.languageCode);

  @override
  Future<void> saveThemeMode(ThemeMode mode) async =>
      _prefs.setString(_themeModeKey, mode.name);

  static ThemeMode? _themeModeFromName(String? name) {
    return switch (name) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      'system' => ThemeMode.system,
      _ => null,
    };
  }
}
