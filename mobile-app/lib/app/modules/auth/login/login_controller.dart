import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/errors/auth_exception.dart';
import '../../../core/services/auth/auth_service.dart';
import '../../../core/services/captcha/captcha_service.dart';
import '../../../core/utils/app_snackbar.dart';
import '../../../routes/app_routes.dart';

class LoginController extends GetxController {
  final formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  final isEmailLoading = false.obs;
  final isGoogleLoading = false.obs;

  AuthService get _authService => Get.find<AuthService>();
  CaptchaService get _captcha => Get.find<CaptchaService>();

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
      String? captchaToken;
      if (_captcha.isEnabled) {
        captchaToken = await _captcha.getToken();
        // The user dismissed the challenge, or it failed - don't try to sign
        // in without a token when protection is on.
        if (captchaToken == null) return;
      }
      await _authService.signInWithEmail(
        email: emailController.text,
        password: passwordController.text,
        captchaToken: captchaToken,
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

  /// Google sign-in silently no-ops when the user cancels the provider's
  /// picker (rather than throwing), so only navigate if a session actually
  /// landed.
  void _goHomeIfSignedIn() {
    if (_authService.currentUser != null) {
      Get.offAllNamed(AppRoutes.main);
    }
  }

  void goToSignUp() => Get.toNamed(AppRoutes.signup);

  void goToForgotPassword() => Get.toNamed(AppRoutes.forgotPassword);
}
