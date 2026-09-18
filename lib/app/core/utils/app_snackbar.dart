import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../theme/app_colors.dart';

/// Thin wrapper around `Get.snackbar` so every screen shows errors/success
/// messages with the same styling instead of hand-rolling SnackBars.
class AppSnackbar {
  AppSnackbar._();

  static void error(String message) {
    Get.snackbar(
      'Something went wrong',
      message,
      backgroundColor: AppColors.error,
      colorText: Get.theme.colorScheme.onError,
      snackPosition: SnackPosition.TOP,
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
    );
  }

  static void success(String message, {String title = 'Success'}) {
    Get.snackbar(
      title,
      message,
      backgroundColor: AppColors.success,
      colorText: Get.theme.colorScheme.onPrimary,
      snackPosition: SnackPosition.TOP,
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
    );
  }
}
