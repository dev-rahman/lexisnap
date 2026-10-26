import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';

/// Status bar / Android system nav bar styling, kept explicit rather than
/// left to OS defaults - without this, status bar icons can end up with
/// too little contrast against the app's background (e.g. dark icons
/// showing up on a dark screen).
class AppSystemUi {
  AppSystemUi._();

  /// Matches the given theme brightness: dark icons on our light paper
  /// background, light icons on the dark background.
  static SystemUiOverlayStyle forBrightness(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    return SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
      systemNavigationBarColor: isDark ? AppColors.paperDark : AppColors.paper,
      systemNavigationBarIconBrightness: isDark
          ? Brightness.light
          : Brightness.dark,
      systemNavigationBarDividerColor: Colors.transparent,
    );
  }

  /// For screens with a permanently dark background (e.g. the scan flow),
  /// regardless of the app's light/dark theme setting.
  static const onDarkSurface = SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
    systemNavigationBarColor: AppColors.ink,
    systemNavigationBarIconBrightness: Brightness.light,
    systemNavigationBarDividerColor: Colors.transparent,
  );
}
