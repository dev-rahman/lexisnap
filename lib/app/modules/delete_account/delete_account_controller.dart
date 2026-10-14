import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/errors/auth_exception.dart';
import '../../core/localization/locale_keys.dart';
import '../../core/services/auth/auth_service.dart';
import '../../core/services/auth/user_service.dart';
import '../../core/services/notification/study_reminder_service.dart';
import '../../core/services/streak/streak_service.dart';
import '../../core/services/study/study_preferences_service.dart';
import '../../core/utils/app_snackbar.dart';
import '../../routes/app_routes.dart';

/// Deleting the account is deliberately slow: a screen spelling out what
/// goes, then one that has to be ticked, typed into and (for password
/// accounts) signed for, then a final sheet. Every step is a chance to
/// back out; nothing is touched until the last one is confirmed.
enum DeleteAccountStep { warning, confirm }

class DeleteAccountController extends GetxController {
  /// The word typed to confirm. Not translated: it's friction, not prose,
  /// and one fixed word is the same instruction in every language.
  static const confirmWord = 'DELETE';

  final formKey = GlobalKey<FormState>();
  final confirmWordController = TextEditingController();
  final passwordController = TextEditingController();

  final step = DeleteAccountStep.warning.obs;
  final understood = false.obs;
  final isCheckingPassword = false.obs;
  final isDeleting = false.obs;
  final _typedWord = ''.obs;

  AuthService get _authService => Get.find<AuthService>();

  /// Google accounts have no password to ask for.
  bool get hasPassword =>
      Get.find<UserService>().user.value?.hasPassword ?? false;

  /// The delete button stays disabled until the box is ticked and the word
  /// typed, so it can't be reached by tapping through.
  bool get canDelete =>
      understood.value && _matchesConfirmWord(_typedWord.value);

  @override
  void onInit() {
    super.onInit();
    confirmWordController.addListener(
      () => _typedWord.value = confirmWordController.text,
    );
  }

  @override
  void onClose() {
    confirmWordController.dispose();
    passwordController.dispose();
    super.onClose();
  }

  String? validateConfirmWord(String? value) => _matchesConfirmWord(value)
      ? null
      : LocaleKeys.deleteConfirmTypeLabel.trParams({'word': confirmWord});

  void continueToConfirm() => step.value = DeleteAccountStep.confirm;

  void goBack() {
    if (step.value == DeleteAccountStep.confirm) {
      step.value = DeleteAccountStep.warning;
    } else {
      Get.back();
    }
  }

  /// Checked before the final warning rather than after it, so "Delete
  /// forever" is never answered with "wrong password".
  Future<bool> checkPassword() async {
    if (!hasPassword) return true;

    isCheckingPassword.value = true;
    try {
      await _authService.reauthenticate(password: passwordController.text);
      return true;
    } on WrongPasswordException {
      AppSnackbar.error(LocaleKeys.passwordWrongCurrent.tr);
      return false;
    } on AppAuthException catch (e) {
      AppSnackbar.error(e.message);
      return false;
    } finally {
      isCheckingPassword.value = false;
    }
  }

  Future<void> deleteAccount() async {
    isDeleting.value = true;
    try {
      await _authService.deleteAccount();
      await _forgetThisDevice();
      Get.offAllNamed(AppRoutes.login);
      AppSnackbar.success(LocaleKeys.deleteDone.tr);
    } on AppAuthException catch (e) {
      AppSnackbar.error(e.message);
    } finally {
      isDeleting.value = false;
    }
  }

  /// The server copy is gone; this clears what the account left on the
  /// phone - streaks, study mode, the daily reminder. Theme and language
  /// are the device's settings, not the account's, so they stay.
  Future<void> _forgetThisDevice() async {
    await Get.find<StreakService>().reset();
    await Get.find<StudyPreferencesService>().reset();
    await Get.find<StudyReminderService>().disable();
  }

  bool _matchesConfirmWord(String? value) =>
      value?.trim().toUpperCase() == confirmWord;
}
