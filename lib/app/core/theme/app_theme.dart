import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_radius.dart';
import 'app_spacing.dart';
import 'app_text_styles.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get light => _build(Brightness.light);

  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    final paper = isDark ? AppColors.paperDark : AppColors.paper;
    final surface = isDark ? AppColors.surfaceDark : AppColors.surface;
    final ink = isDark ? AppColors.inkDark : AppColors.ink;
    final inkMuted = isDark ? AppColors.inkMutedDark : AppColors.inkMuted;
    final border = isDark ? AppColors.borderDark : AppColors.border;

    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: AppColors.accent,
      onPrimary: Colors.white,
      secondary: AppColors.accent600,
      onSecondary: Colors.white,
      // Generic system/form error color - kept separate from
      // AppColors.error, which is reserved for flashcard review.
      error: AppColors.alert,
      onError: Colors.white,
      surface: surface,
      onSurface: ink,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: paper,
      // No app-wide fontFamily override: body text uses the native system
      // font stack (see AppTextStyles). Only display styles opt into
      // Space Grotesk explicitly.
      textTheme: TextTheme(
        headlineMedium: AppTextStyles.heading1.copyWith(color: ink),
        headlineSmall: AppTextStyles.heading2.copyWith(color: ink),
        bodyLarge: AppTextStyles.body.copyWith(color: ink),
        bodyMedium: AppTextStyles.body.copyWith(color: inkMuted),
        labelLarge: AppTextStyles.button,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.alert),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          textStyle: AppTextStyles.button,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: ink,
          minimumSize: const Size.fromHeight(52),
          side: BorderSide(color: border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          textStyle: AppTextStyles.button,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.accent,
          textStyle: AppTextStyles.bodyMedium,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: paper,
        foregroundColor: ink,
        elevation: 0,
        centerTitle: true,
      ),
    );
  }
}
