import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/errors/auth_exception.dart';
import '../../core/localization/locale_keys.dart';
import '../../core/services/auth/auth_service.dart';
import '../../core/services/auth/user_service.dart';
import '../../core/utils/app_snackbar.dart';
import '../../core/utils/validators.dart';

/// Moving the account to a new address, confirmed by emailed codes rather
/// than links. The new address always gets a code. With Supabase's
/// "secure email change" on (its default) the current address gets one
/// too, and the change only happens once both are entered - so the
/// [currentCode] step appears only if the first code didn't finish it.
enum ChangeEmailStep { newEmail, newCode, currentCode }

class ChangeEmailController extends GetxController {
  /// Supabase refuses another email to the same address within 60 seconds
  /// by default, so the resend button waits that long too.
  static const resendCooldownSeconds = 60;

  final emailFormKey = GlobalKey<FormState>();
  final codeFormKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final codeController = TextEditingController();

  final step = ChangeEmailStep.newEmail.obs;
  final isLoading = false.obs;
  final isResending = false.obs;
  final resendSecondsLeft = 0.obs;

  Timer? _resendTimer;

  /// Captured once: the user's email only changes when this flow succeeds,
  /// and the second code has to be checked against the old address.
  final String currentEmail = Get.find<UserService>().user.value?.email ?? '';

  String get newEmail => emailController.text.trim();

  AuthService get _authService => Get.find<AuthService>();

  @override
  void onClose() {
    _resendTimer?.cancel();
    emailController.dispose();
    codeController.dispose();
    super.onClose();
  }

  String? validateNewEmail(String? value) {
    final error = Validators.email(value);
    if (error != null) return error;
    if (value!.trim().toLowerCase() == currentEmail.toLowerCase()) {
      return LocaleKeys.emailChangeSameEmail.tr;
    }
    return null;
  }

  Future<void> sendCode() async {
    if (!emailFormKey.currentState!.validate()) return;

    isLoading.value = true;
    try {
      await _authService.requestEmailChange(newEmail: newEmail);
      codeController.clear();
      step.value = ChangeEmailStep.newCode;
      _startResendCooldown();
    } on AppAuthException catch (e) {
      AppSnackbar.error(e.message);
    } finally {
      isLoading.value = false;
    }
  }

  /// Asking again issues fresh codes to both addresses and voids any code
  /// already entered, so the flow restarts at the new address's code.
  Future<void> resendCode() async {
    isResending.value = true;
    try {
      await _authService.requestEmailChange(newEmail: newEmail);
      codeController.clear();
      step.value = ChangeEmailStep.newCode;
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
      final complete = await _authService.verifyEmailChangeCode(
        email: step.value == ChangeEmailStep.newCode ? newEmail : currentEmail,
        code: codeController.text,
      );
      if (complete) {
        // closeOverlays, or an open snackbar would swallow the pop.
        Get.back(closeOverlays: true);
        AppSnackbar.success(
          LocaleKeys.emailChangeUpdated.trParams({'email': newEmail}),
        );
      } else {
        codeController.clear();
        step.value = ChangeEmailStep.currentCode;
      }
    } on AppAuthException catch (e) {
      AppSnackbar.error(e.message);
    } finally {
      isLoading.value = false;
    }
  }

  /// Back from either code step returns to the address, so a typo can be
  /// fixed. A fresh request replaces the pending change, so nothing needs
  /// undoing.
  void goBack() {
    if (step.value == ChangeEmailStep.newEmail) {
      Get.back();
      return;
    }
    _resendTimer?.cancel();
    resendSecondsLeft.value = 0;
    step.value = ChangeEmailStep.newEmail;
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
