import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../config/env.dart';
import 'support_service.dart';

/// Sends support mail through EmailJS (https://www.emailjs.com) via its REST
/// API, so there's no backend to run. Two emails go out per request:
///   1. the support request to the LexiSnap inbox ([Env.supportEmail]);
///   2. a copy/receipt to the user.
///
/// The inbox email is the one that matters, so it's sent first and its
/// failure is reported; the user's copy is best-effort and a failure there is
/// swallowed. Template content lives in the EmailJS dashboard - see
/// docs/emailjs/SETUP.md - and the `template_params` here fill its
/// `{{variables}}`.
class EmailJsSupportService implements SupportService {
  EmailJsSupportService({http.Client? client})
    : _client = client ?? http.Client();

  final http.Client _client;

  static final _endpoint = Uri.parse(
    'https://api.emailjs.com/api/v1.0/email/send',
  );

  @override
  bool get isConfigured =>
      Env.emailjsServiceId.isNotEmpty &&
      Env.emailjsPublicKey.isNotEmpty &&
      Env.emailjsTemplateSupport.isNotEmpty &&
      Env.emailjsTemplateReceipt.isNotEmpty;

  @override
  Future<void> sendSupportMessage({
    required String message,
    required String userEmail,
    String? userName,
  }) async {
    final name = (userName == null || userName.trim().isEmpty)
        ? 'A LexiSnap user'
        : userName.trim();
    final sharedParams = <String, String>{
      'user_name': name,
      'user_email': userEmail,
      'message': message.trim(),
      'platform': _platformLabel,
      'submitted_at': DateTime.now().toUtc().toIso8601String(),
    };

    // The request to the support inbox is the one that must land.
    await _send(
      templateId: Env.emailjsTemplateSupport,
      params: {
        ...sharedParams,
        'to_email': Env.supportEmail,
        'reply_to': userEmail,
      },
    );

    // The user's copy is a courtesy; don't fail the whole thing if it bounces.
    try {
      await _send(
        templateId: Env.emailjsTemplateReceipt,
        params: {
          ...sharedParams,
          'to_email': userEmail,
          'reply_to': Env.supportEmail,
        },
      );
    } catch (_) {
      // Support already has the message; the receipt is non-critical.
    }
  }

  Future<void> _send({
    required String templateId,
    required Map<String, String> params,
  }) async {
    final body = <String, dynamic>{
      'service_id': Env.emailjsServiceId,
      'template_id': templateId,
      'user_id': Env.emailjsPublicKey,
      'template_params': params,
      // EmailJS blocks non-browser calls unless the private key is sent as
      // the access token. Only included when configured.
      if (Env.emailjsPrivateKey.isNotEmpty)
        'accessToken': Env.emailjsPrivateKey,
    };

    http.Response response;
    try {
      response = await _client.post(
        _endpoint,
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
    } catch (e) {
      debugPrint('EmailJS network error (template $templateId): $e');
      throw SupportException('Network error: $e');
    }

    debugPrint(
      'EmailJS send (template $templateId) -> '
      '${response.statusCode}: ${response.body}',
    );

    if (response.statusCode != 200) {
      throw SupportException(
        'EmailJS ${response.statusCode}: ${response.body}',
      );
    }
  }

  String get _platformLabel {
    if (Platform.isAndroid) return 'Android';
    if (Platform.isIOS) return 'iOS';
    return Platform.operatingSystem;
  }
}
