import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _prefKeyThemeMode = 'app_theme_mode';

class ThemeProvider extends ChangeNotifier with WidgetsBindingObserver {
  ThemeMode _themeMode = ThemeMode.dark;

  ThemeMode get themeMode => _themeMode;

  ThemeProvider() {
    WidgetsBinding.instance.addObserver(this);
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefKeyThemeMode);
    if (saved != null) {
      _themeMode = ThemeMode.values.firstWhere(
        (e) => e.name == saved,
        orElse: () => ThemeMode.dark,
      );
      notifyListeners();
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKeyThemeMode, mode.name);
  }

  /// Returns the effective brightness, respecting system brightness when in auto mode.
  Brightness get effectiveBrightness {
    if (_themeMode == ThemeMode.light) return Brightness.light;
    if (_themeMode == ThemeMode.dark) return Brightness.dark;
    return WidgetsBinding.instance.platformDispatcher.platformBrightness;
  }

  @override
  void didChangePlatformBrightness() {
    // In auto mode the UI should react to system changes.
    if (_themeMode == ThemeMode.system) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
