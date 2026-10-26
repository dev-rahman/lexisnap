import 'package:get/get.dart';

import '../localization/locale_keys.dart';

class Validators {
  Validators._();

  static final RegExp _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  /// Supabase email codes are 6 digits by default, but a project can raise
  /// the length to 10, so accept the whole range.
  static final RegExp _oneTimeCodeRegex = RegExp(r'^\d{6,10}$');

  static String? email(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return LocaleKeys.validatorEmailRequired.tr;
    if (!_emailRegex.hasMatch(trimmed)) {
      return LocaleKeys.validatorEmailInvalid.tr;
    }
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return LocaleKeys.validatorPasswordRequired.tr;
    }
    if (value.length < 8) return LocaleKeys.validatorPasswordTooShort.tr;
    return null;
  }

  static String? confirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return LocaleKeys.validatorConfirmPasswordRequired.tr;
    }
    if (value != password) return LocaleKeys.validatorPasswordsDontMatch.tr;
    return null;
  }

  static String? oneTimeCode(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return LocaleKeys.validatorCodeRequired.tr;
    if (!_oneTimeCodeRegex.hasMatch(trimmed)) {
      return LocaleKeys.validatorCodeInvalid.tr;
    }
    return null;
  }

  static String? required(String? value, {String? message}) {
    if (value == null || value.trim().isEmpty) {
      return message ?? LocaleKeys.validatorFieldRequired.tr;
    }
    return null;
  }
}
