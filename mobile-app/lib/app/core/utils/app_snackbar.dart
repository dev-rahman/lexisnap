import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../localization/locale_keys.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';

/// Thin wrapper around `Get.snackbar` so every screen shows messages with the
/// same styling instead of hand-rolling SnackBars.
///
/// Four tones, each its own colour so the kind of message reads at a glance:
/// [error] (red), [warning] (amber), [success] (green), [info] (blue). All
/// use the muted system colours, not the brighter [AppColors.error]/
/// [AppColors.success], which stay reserved for flashcard review.
class AppSnackbar {
  AppSnackbar._();

  static void _show(
    String title,
    String message,
    Color background,
    IconData icon,
  ) {
    Get.snackbar(
      title,
      message,
      backgroundColor: background,
      colorText: Colors.white,
      icon: Icon(icon, color: Colors.white),
      snackPosition: SnackPosition.TOP,
      margin: const EdgeInsets.all(AppSpacing.md),
      borderRadius: AppRadius.md,
    );
  }

  /// Something failed. Red.
  static void error(String message, {String? title}) => _show(
    title ?? LocaleKeys.commonSomethingWentWrong.tr,
    message,
    AppColors.alert,
    Icons.error_outline_rounded,
  );

  /// Something the user should notice but that isn't a failure, like cards
  /// skipped as duplicates. Amber.
  static void warning(String message, {String? title}) => _show(
    title ?? LocaleKeys.commonHeadsUp.tr,
    message,
    AppColors.caution,
    Icons.warning_amber_rounded,
  );

  /// Something worked. Green.
  static void success(String message, {String? title}) => _show(
    title ?? LocaleKeys.commonSuccess.tr,
    message,
    AppColors.confirm,
    Icons.check_circle_outline_rounded,
  );

  /// Neutral note, e.g. a placeholder/not-yet-built feature. Blue.
  static void info(String message, {String? title}) => _show(
    title ?? LocaleKeys.commonComingSoon.tr,
    message,
    AppColors.notice,
    Icons.info_outline_rounded,
  );
}
