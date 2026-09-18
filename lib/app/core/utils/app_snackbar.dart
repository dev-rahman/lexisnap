import 'package:flutter/material.dart';
import 'package:get/get.dart';

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
      'Something went wrong',
      message,
      backgroundColor: AppColors.alert,
      colorText: Colors.white,
      snackPosition: SnackPosition.TOP,
      margin: const EdgeInsets.all(AppSpacing.md),
      borderRadius: AppRadius.md,
    );
  }

  static void success(String message, {String title = 'Success'}) {
    Get.snackbar(
      title,
      message,
      backgroundColor: AppColors.confirm,
      colorText: Colors.white,
      snackPosition: SnackPosition.TOP,
      margin: const EdgeInsets.all(AppSpacing.md),
      borderRadius: AppRadius.md,
    );
  }
}
