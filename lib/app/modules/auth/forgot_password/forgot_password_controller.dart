import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/errors/auth_exception.dart';
import '../../../core/services/auth/auth_service.dart';
import '../../../core/utils/app_snackbar.dart';

class ForgotPasswordController extends GetxController {
  final formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();

  final isLoading = false.obs;
  final emailSent = false.obs;

  AuthService get _authService => Get.find<AuthService>();

  @override
  void onClose() {
    emailController.dispose();
    super.onClose();
  }

  Future<void> submit() async {
    if (!formKey.currentState!.validate()) return;

    isLoading.value = true;
    try {
      await _authService.sendPasswordResetEmail(email: emailController.text);
      emailSent.value = true;
    } on AppAuthException catch (e) {
      AppSnackbar.error(e.message);
    } finally {
      isLoading.value = false;
    }
  }
}
