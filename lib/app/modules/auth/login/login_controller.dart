import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/errors/auth_exception.dart';
import '../../../core/services/auth/auth_service.dart';
import '../../../core/utils/app_snackbar.dart';
import '../../../routes/app_routes.dart';

class LoginController extends GetxController {
  final formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  final isEmailLoading = false.obs;
  final isGoogleLoading = false.obs;
  final isAppleLoading = false.obs;

  AuthService get _authService => Get.find<AuthService>();

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }

  Future<void> submitEmailLogin() async {
    if (!formKey.currentState!.validate()) return;

    isEmailLoading.value = true;
    try {
      await _authService.signInWithEmail(
        email: emailController.text,
        password: passwordController.text,
      );
      _goHomeIfSignedIn();
    } on AppAuthException catch (e) {
      AppSnackbar.error(e.message);
    } finally {
      isEmailLoading.value = false;
    }
  }

  Future<void> continueWithGoogle() async {
    isGoogleLoading.value = true;
    try {
      await _authService.signInWithGoogle();
      _goHomeIfSignedIn();
    } on AppAuthException catch (e) {
      AppSnackbar.error(e.message);
    } finally {
      isGoogleLoading.value = false;
    }
  }

  Future<void> continueWithApple() async {
    isAppleLoading.value = true;
    try {
      await _authService.signInWithApple();
      _goHomeIfSignedIn();
    } on AppAuthException catch (e) {
      AppSnackbar.error(e.message);
    } finally {
      isAppleLoading.value = false;
    }
  }

  /// Google/Apple sign-in silently no-ops when the user cancels the
  /// provider's picker (rather than throwing), so only navigate if a
  /// session actually landed.
  void _goHomeIfSignedIn() {
    if (_authService.currentUser != null) {
      Get.offAllNamed(AppRoutes.home);
    }
  }

  void goToSignUp() => Get.toNamed(AppRoutes.signup);

  void goToForgotPassword() => Get.toNamed(AppRoutes.forgotPassword);
}
