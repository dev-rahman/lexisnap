import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/errors/auth_exception.dart';
import '../../../core/localization/locale_keys.dart';
import '../../../core/services/auth/auth_service.dart';
import '../../../core/services/captcha/captcha_service.dart';
import '../../../core/utils/app_snackbar.dart';
import '../../../routes/app_routes.dart';

/// The reset happens entirely in the app: ask for the email, check the
/// code emailed to it, then choose a new password. No link to open.
enum ForgotPasswordStep { email, code, newPassword }

class ForgotPasswordController extends GetxController {
  /// Supabase refuses a second reset email to the same address within 60
  /// seconds by default, so the resend button waits that long too.
  static const resendCooldownSeconds = 60;

  final emailFormKey = GlobalKey<FormState>();
  final codeFormKey = GlobalKey<FormState>();
  final passwordFormKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final codeController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  final step = ForgotPasswordStep.email.obs;
  final isLoading = false.obs;
  final isResending = false.obs;
  final resendSecondsLeft = 0.obs;

  Timer? _resendTimer;

  AuthService get _authService => Get.find<AuthService>();
  CaptchaService get _captcha => Get.find<CaptchaService>();

  @override
  void onClose() {
    _resendTimer?.cancel();
    emailController.dispose();
    codeController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.onClose();
  }

  Future<void> sendCode() async {
    if (!emailFormKey.currentState!.validate()) return;

    isLoading.value = true;
    try {
      String? captchaToken;
      if (_captcha.isEnabled) {
        captchaToken = await _captcha.getToken();
        if (captchaToken == null) return;
      }
      await _authService.sendPasswordResetEmail(
        email: emailController.text,
        captchaToken: captchaToken,
      );
      codeController.clear();
      step.value = ForgotPasswordStep.code;
      _startResendCooldown();
    } on AppAuthException catch (e) {
      AppSnackbar.error(e.message);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> resendCode() async {
    isResending.value = true;
    try {
      String? captchaToken;
      if (_captcha.isEnabled) {
        captchaToken = await _captcha.getToken();
        if (captchaToken == null) return;
      }
      await _authService.sendPasswordResetEmail(
        email: emailController.text,
        captchaToken: captchaToken,
      );
      codeController.clear();
      _startResendCooldown();
      AppSnackbar.success(LocaleKeys.forgotPasswordCodeResent.tr);
    } on AppAuthException catch (e) {
      AppSnackbar.error(e.message);
    } finally {
      isResending.value = false;
    }
  }

  Future<void> verifyCode() async {
    if (!codeFormKey.currentState!.validate()) return;

    isLoading.value = true;
    try {
      await _authService.verifyPasswordResetCode(
        email: emailController.text,
        code: codeController.text,
      );
      step.value = ForgotPasswordStep.newPassword;
    } on AppAuthException catch (e) {
      AppSnackbar.error(e.message);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> savePassword() async {
    if (!passwordFormKey.currentState!.validate()) return;

    isLoading.value = true;
    try {
      await _authService.updatePassword(password: passwordController.text);
      AppSnackbar.success(LocaleKeys.forgotPasswordUpdated.tr);
      Get.offAllNamed(AppRoutes.main);
    } on AppAuthException catch (e) {
      AppSnackbar.error(e.message);
    } finally {
      isLoading.value = false;
    }
  }

  /// Back from the code step returns to the email step so a mistyped
  /// address can be fixed. A verified code signs the user in, so leaving
  /// before saving a new password signs them out again - otherwise the
  /// next launch would drop them into the app with a password they still
  /// don't know.
  Future<void> goBack() async {
    switch (step.value) {
      case ForgotPasswordStep.email:
        Get.back();
      case ForgotPasswordStep.code:
        _resendTimer?.cancel();
        resendSecondsLeft.value = 0;
        step.value = ForgotPasswordStep.email;
      case ForgotPasswordStep.newPassword:
        try {
          await _authService.signOut();
          Get.back();
        } on AppAuthException catch (e) {
          AppSnackbar.error(e.message);
        }
    }
  }

  void _startResendCooldown() {
    _resendTimer?.cancel();
    resendSecondsLeft.value = resendCooldownSeconds;
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      resendSecondsLeft.value--;
      if (resendSecondsLeft.value <= 0) timer.cancel();
    });
  }
}
