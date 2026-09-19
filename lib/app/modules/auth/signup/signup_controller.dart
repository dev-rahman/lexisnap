import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/errors/auth_exception.dart';
import '../../../core/localization/locale_keys.dart';
import '../../../core/services/auth/auth_service.dart';
import '../../../core/utils/app_snackbar.dart';
import '../../../routes/app_routes.dart';

class SignupController extends GetxController {
  final formKey = GlobalKey<FormState>();
  final fullNameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  final isLoading = false.obs;

  AuthService get _authService => Get.find<AuthService>();

  @override
  void onClose() {
    fullNameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.onClose();
  }

  Future<void> submit() async {
    if (!formKey.currentState!.validate()) return;

    isLoading.value = true;
    try {
      await _authService.signUpWithEmail(
        email: emailController.text,
        password: passwordController.text,
        fullName: fullNameController.text.trim(),
      );

      if (_authService.currentUser != null) {
        // Email confirmation is disabled on this Supabase project, so
        // sign-up returned an active session immediately.
        Get.offAllNamed(AppRoutes.main);
      } else {
        // Email confirmation is required - Supabase already sent a
        // confirmation link.
        AppSnackbar.success(
          LocaleKeys.signupCheckInboxBody.tr,
          title: LocaleKeys.signupCheckInboxTitle.tr,
        );
        Get.offNamed(AppRoutes.login);
      }
    } on AppAuthException catch (e) {
      AppSnackbar.error(e.message);
    } finally {
      isLoading.value = false;
    }
  }

  void goToLogin() => Get.back();
}
