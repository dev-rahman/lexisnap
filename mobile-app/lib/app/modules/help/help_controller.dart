import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/config/env.dart';
import '../../core/localization/locale_keys.dart';
import '../../core/services/auth/auth_service.dart';
import '../../core/services/support/support_service.dart';
import '../../core/utils/app_snackbar.dart';

class FaqEntry {
  const FaqEntry(this.questionKey, this.answerKey);

  /// [LocaleKeys] entries, resolved with `.tr` at the point of display.
  final String questionKey;
  final String answerKey;
}

class HelpController extends GetxController {
  final messageController = TextEditingController();
  final expandedFaqIndex = (-1).obs;
  final isSendingMessage = false.obs;

  static const faqs = [
    FaqEntry(LocaleKeys.helpFaq1Q, LocaleKeys.helpFaq1A),
    FaqEntry(LocaleKeys.helpFaq2Q, LocaleKeys.helpFaq2A),
    FaqEntry(LocaleKeys.helpFaq3Q, LocaleKeys.helpFaq3A),
    FaqEntry(LocaleKeys.helpFaq4Q, LocaleKeys.helpFaq4A),
    FaqEntry(LocaleKeys.helpFaq5Q, LocaleKeys.helpFaq5A),
  ];

  void toggleFaq(int index) {
    expandedFaqIndex.value = expandedFaqIndex.value == index ? -1 : index;
  }

  @override
  void onClose() {
    messageController.dispose();
    super.onClose();
  }

  Future<void> contactSupport() async {
    final message = messageController.text.trim();
    if (message.isEmpty) {
      AppSnackbar.error(LocaleKeys.helpEmptyMessageError.tr);
      return;
    }

    final user = Get.find<AuthService>().currentUser;
    final userEmail = user?.email ?? '';
    final support = Get.find<SupportService>();

    isSendingMessage.value = true;
    try {
      // EmailJS configured: send the request to support and a copy to the
      // user, all in-app. Falls back to the mail app otherwise.
      if (support.isConfigured && userEmail.isNotEmpty) {
        await support.sendSupportMessage(
          message: message,
          userEmail: userEmail,
          userName: user?.fullName,
        );
        messageController.clear();
        AppSnackbar.success(LocaleKeys.helpMessageSentSuccess.tr);
      } else {
        await _openMailApp(message, userEmail);
      }
    } on SupportException catch (e) {
      // Temporary: show the real EmailJS reason while diagnosing setup.
      // Revert to LocaleKeys.helpSendError.tr once sending works.
      AppSnackbar.error(e.message);
    } finally {
      isSendingMessage.value = false;
    }
  }

  /// Fallback used before EmailJS is configured: hand the message to the
  /// user's own mail app, pre-addressed to support.
  Future<void> _openMailApp(String message, String userEmail) async {
    final uri = Uri(
      scheme: 'mailto',
      path: Env.supportEmail,
      query: _encodeQueryParameters({
        'subject': LocaleKeys.helpMailSubject.tr,
        'body':
            'From: ${userEmail.isEmpty ? 'unknown' : userEmail}\n\n$message',
      }),
    );

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
      messageController.clear();
    } else {
      AppSnackbar.error(LocaleKeys.helpNoEmailAppError.tr);
    }
  }

  String _encodeQueryParameters(Map<String, String> params) {
    return params.entries
        .map(
          (e) =>
              '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}',
        )
        .join('&');
  }
}
