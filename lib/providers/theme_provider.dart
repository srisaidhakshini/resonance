import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
  return ThemeNotifier();
});

class ThemeNotifier extends StateNotifier<ThemeMode> {
  static const String _prefKey = 'app_theme_mode';

  ThemeNotifier() : super(ThemeMode.light) {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedMode = prefs.getString(_prefKey);
      if (savedMode != null) {
        if (savedMode == 'dark') {
          state = ThemeMode.dark;
        } else if (savedMode == 'light') {
          state = ThemeMode.light;
        } else if (savedMode == 'system') {
          state = ThemeMode.system;
        }
      }
    } catch (_) {}
  }

  Future<void> toggleTheme() async {
    final nextMode = state == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    state = nextMode;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKey, nextMode == ThemeMode.dark ? 'dark' : 'light');
    } catch (_) {}
  }

  Future<void> setTheme(ThemeMode mode) async {
    state = mode;
    try {
      final prefs = await SharedPreferences.getInstance();
      final modeStr = mode == ThemeMode.dark
          ? 'dark'
          : (mode == ThemeMode.light ? 'light' : 'system');
      await prefs.setString(_prefKey, modeStr);
    } catch (_) {}
  }
}
