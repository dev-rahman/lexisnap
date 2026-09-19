import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/config/env.dart';
import '../../core/services/auth/auth_service.dart';
import '../../core/utils/app_snackbar.dart';

class FaqEntry {
  const FaqEntry(this.question, this.answer);

  final String question;
  final String answer;
}

class HelpController extends GetxController {
  final messageController = TextEditingController();
  final expandedFaqIndex = (-1).obs;
  final isSendingMessage = false.obs;

  static const faqs = [
    FaqEntry(
      'How do I sign in?',
      'Use your email and password, or continue with Google on Android or '
          'iOS, or Apple on iOS.',
    ),
    FaqEntry(
      "I forgot my password. What now?",
      "On the login screen, tap 'Forgot password?' and we'll email you a "
          'reset link.',
    ),
    FaqEntry(
      'Is my data secure?',
      "Yes. Your account is authenticated through Supabase, and your "
          "password is never stored in plain text.",
    ),
    FaqEntry(
      'How do I sign out?',
      "Open the Profile tab and tap 'Sign out' at the bottom.",
    ),
    FaqEntry(
      'Can I change my display name?',
      'Yes - go to Profile and tap your name to update it.',
    ),
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
      AppSnackbar.error('Tell us what you need help with first.');
      return;
    }

    isSendingMessage.value = true;
    try {
      final userEmail = Get.find<AuthService>().currentUser?.email ?? 'unknown';
      final uri = Uri(
        scheme: 'mailto',
        path: Env.supportEmail,
        query: _encodeQueryParameters({
          'subject': 'LexiSnap support request',
          'body': 'From: $userEmail\n\n$message',
        }),
      );

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
        messageController.clear();
      } else {
        AppSnackbar.error('No email app is set up on this device.');
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
