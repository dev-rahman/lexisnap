import 'package:flutter/material.dart';

/// Single source of truth for colors used across the app. Change values
/// here to re-theme the whole app.
class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF3A5BFF);
  static const Color primaryDark = Color(0xFF2540C9);

  static const Color background = Color(0xFFFFFFFF);
  static const Color backgroundDark = Color(0xFF121212);

  static const Color surface = Color(0xFFF5F6FA);
  static const Color surfaceDark = Color(0xFF1E1E1E);

  static const Color textPrimary = Color(0xFF1A1B25);
  static const Color textPrimaryDark = Color(0xFFF2F2F2);

  static const Color textSecondary = Color(0xFF6B6F80);
  static const Color textSecondaryDark = Color(0xFFA0A3B1);

  static const Color error = Color(0xFFE53935);
  static const Color success = Color(0xFF2E9E5B);

  static const Color border = Color(0xFFE1E3EA);
  static const Color borderDark = Color(0xFF32333D);
}
