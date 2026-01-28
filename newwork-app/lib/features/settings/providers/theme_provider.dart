import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../data/providers/dashboard_providers.dart';

// Theme Mode Key for SharedPreferences
const String _themeModeKey = 'theme_mode';

// Theme Mode Provider
class ThemeNotifier extends StateNotifier<ThemeMode> {
  ThemeNotifier() : super(ThemeMode.system) {
    _loadTheme();
  }

  // Load theme from SharedPreferences
  Future<void> _loadTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final themeModeStr = prefs.getString(_themeModeKey);

      if (themeModeStr != null) {
        state = ThemeMode.values.firstWhere(
          (mode) => mode.name == themeModeStr,
          orElse: () => ThemeMode.system,
        );
      }
    } catch (e) {
      // Keep default (system) on error
      state = ThemeMode.system;
    }
  }

  // Set theme mode and save to SharedPreferences
  Future<void> setTheme(ThemeMode themeMode) async {
    state = themeMode;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themeModeKey, themeMode.name);
    } catch (e) {
      // Save failed, but we already updated state
    }
  }

  // Convert ThemeModeOption (from settings) to ThemeMode
  ThemeMode convertToThemeMode(ThemeModeOption option) {
    switch (option) {
      case ThemeModeOption.light:
        return ThemeMode.light;
      case ThemeModeOption.dark:
        return ThemeMode.dark;
      case ThemeModeOption.system:
        return ThemeMode.system;
    }
  }
}

// Theme Provider
final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
  return ThemeNotifier();
});

// Helper provider to get current theme data based on theme mode
final themeDataProvider = Provider<ThemeData>((ref) {
  final themeMode = ref.watch(themeProvider);
  return _getThemeData(themeMode);
});

// Get theme data based on mode
ThemeData _getThemeData(ThemeMode mode) {
  switch (mode) {
    case ThemeMode.light:
      return ThemeData.light(useMaterial3: true);
    case ThemeMode.dark:
      return ThemeData.dark(useMaterial3: true);
    case ThemeMode.system:
      final brightness =
          WidgetsBinding.instance.platformDispatcher.platformBrightness;
      return brightness == Brightness.dark
          ? ThemeData.dark(useMaterial3: true)
          : ThemeData.light(useMaterial3: true);
  }
}
