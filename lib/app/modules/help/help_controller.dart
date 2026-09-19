import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/config/env.dart';
import '../../core/localization/locale_keys.dart';
import '../../core/services/auth/auth_service.dart';
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

    isSendingMessage.value = true;
    try {
      final userEmail = Get.find<AuthService>().currentUser?.email ?? 'unknown';
      final uri = Uri(
        scheme: 'mailto',
        path: Env.supportEmail,
        query: _encodeQueryParameters({
          'subject': LocaleKeys.helpMailSubject.tr,
          'body': 'From: $userEmail\n\n$message',
        }),
      );

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
        messageController.clear();
      } else {
        AppSnackbar.error(LocaleKeys.helpNoEmailAppError.tr);
      }
    } finally {
      isSendingMessage.value = false;
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
