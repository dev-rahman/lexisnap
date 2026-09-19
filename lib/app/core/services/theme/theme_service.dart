import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists and applies the user's light/dark/system theme preference.
/// `init()` must be awaited once at startup (see `service_locator.dart`)
/// before `GetMaterialApp` reads `themeMode.value` for its initial theme.
class ThemeService {
  static const _key = 'app_theme_mode';

  final themeMode = ThemeMode.system.obs;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_key);
    themeMode.value = switch (saved) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    themeMode.value = mode;
    Get.changeThemeMode(mode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, mode.name);
  }
}
