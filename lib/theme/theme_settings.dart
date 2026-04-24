import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _prefsKeyThemeMode = 'app_theme_mode';

/// Persists and notifies [ThemeMode] for the whole app.
class ThemeSettings extends ChangeNotifier {
  ThemeSettings();

  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKeyThemeMode);
    _themeMode = _decode(raw);
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKeyThemeMode, _encode(mode));
  }

  static ThemeMode _decode(String? raw) {
    return switch (raw) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  static String _encode(ThemeMode mode) => switch (mode) {
        ThemeMode.light => 'light',
        ThemeMode.dark => 'dark',
        ThemeMode.system => 'system',
      };
}

/// Injected via [MaterialApp.builder] so every route can read [ThemeSettings].
class InheritedThemeSettings extends InheritedNotifier<ThemeSettings> {
  const InheritedThemeSettings({
    super.key,
    required ThemeSettings super.notifier,
    required super.child,
  });

  static ThemeSettings of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<InheritedThemeSettings>();
    assert(scope != null, 'InheritedThemeSettings not found');
    return scope!.notifier!;
  }
}
