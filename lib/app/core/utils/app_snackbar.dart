import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../localization/locale_keys.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';

/// Thin wrapper around `Get.snackbar` so every screen shows errors/success
/// messages with the same styling instead of hand-rolling SnackBars.
///
/// Uses [AppColors.alert]/[AppColors.confirm], not the brighter
/// [AppColors.error]/[AppColors.success] - those are reserved for
/// flashcard review.
class AppSnackbar {
  AppSnackbar._();

  static void error(String message) {
    Get.snackbar(
      LocaleKeys.commonSomethingWentWrong.tr,
      message,
      backgroundColor: AppColors.alert,
      colorText: Colors.white,
      snackPosition: SnackPosition.TOP,
      margin: const EdgeInsets.all(AppSpacing.md),
      borderRadius: AppRadius.md,
    );
  }

  static void success(String message, {String? title}) {
    Get.snackbar(
      title ?? LocaleKeys.commonSuccess.tr,
      message,
      backgroundColor: AppColors.confirm,
      colorText: Colors.white,
      snackPosition: SnackPosition.TOP,
      margin: const EdgeInsets.all(AppSpacing.md),
      borderRadius: AppRadius.md,
    );
  }

  /// Neutral toast for placeholder/not-yet-built features.
  static void info(String message, {String? title}) {
    Get.snackbar(
      title ?? LocaleKeys.commonComingSoon.tr,
      message,
      backgroundColor: AppColors.ink,
      colorText: Colors.white,
      snackPosition: SnackPosition.TOP,
      margin: const EdgeInsets.all(AppSpacing.md),
      borderRadius: AppRadius.md,
    );
  }
}
