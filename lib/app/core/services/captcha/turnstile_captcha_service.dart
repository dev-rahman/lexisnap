import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../config/env.dart';
import '../../localization/locale_keys.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/app_bottom_sheet.dart';
import 'captcha_service.dart';

/// Cloudflare Turnstile, rendered in a webview because there is no native
/// Flutter widget for it. The widget's HTML is loaded with a base URL of
/// `https://lexisnap.app`, which is the hostname registered for the Turnstile
/// widget, so the token Cloudflare issues is accepted.
///
/// The challenge appears in a bottom sheet. For low-risk traffic Turnstile
/// solves itself and the sheet closes almost at once; a risky visitor sees an
/// interactive check. Google sign-in does not go through here - only
/// Supabase's own email/password and reset endpoints need a token.
class TurnstileCaptchaService implements CaptchaService {
  /// Must match a hostname on the Turnstile widget in the Cloudflare
  /// dashboard. Change both together if you change it.
  static const _baseUrl = 'https://lexisnap.app';

  @override
  bool get isEnabled => Env.turnstileSiteKey.isNotEmpty;

  @override
  Future<String?> getToken() {
    final context = Get.context;
    if (!isEnabled || context == null) return Future.value(null);

    return showAppSheet<String>(
      context,
      isScrollControlled: true,
      builder: (_) =>
          _TurnstileSheet(siteKey: Env.turnstileSiteKey, baseUrl: _baseUrl),
    );
  }
}

class _TurnstileSheet extends StatefulWidget {
  const _TurnstileSheet({required this.siteKey, required this.baseUrl});

  final String siteKey;
  final String baseUrl;

  @override
  State<_TurnstileSheet> createState() => _TurnstileSheetState();
}

class _TurnstileSheetState extends State<_TurnstileSheet> {
  late final WebViewController _controller;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..addJavaScriptChannel('Captcha', onMessageReceived: _onMessage)
      ..loadHtmlString(_html, baseUrl: widget.baseUrl);
  }

  void _onMessage(JavaScriptMessage message) {
    if (!mounted) return;
    final data = jsonDecode(message.message) as Map<String, dynamic>;
    switch (data['type']) {
      case 'token':
        Navigator.of(context).pop(data['token'] as String);
      case 'error':
      case 'expired':
        // Let the widget auto-retry once; surface a hint if it keeps failing.
        setState(() => _failed = true);
    }
  }

  String get _html =>
      '''
<!DOCTYPE html>
<html>
<head>
<meta name="viewport" content="width=device-width, initial-scale=1">
<script src="https://challenges.cloudflare.com/turnstile/v0/api.js?render=explicit" async defer></script>
<style>
  html,body{margin:0;height:100%;background:transparent;}
  #box{display:flex;align-items:center;justify-content:center;height:100%;}
</style>
</head>
<body>
<div id="box"><div id="cf"></div></div>
<script>
  function render(){
    if (typeof turnstile === 'undefined'){ setTimeout(render, 100); return; }
    turnstile.render('#cf', {
      sitekey: '${widget.siteKey}',
      callback: function(t){ Captcha.postMessage(JSON.stringify({type:'token', token:t})); },
      'error-callback': function(){ Captcha.postMessage(JSON.stringify({type:'error'})); },
      'expired-callback': function(){ Captcha.postMessage(JSON.stringify({type:'expired'})); }
    });
  }
  render();
</script>
</body>
</html>
''';

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(LocaleKeys.captchaTitle.tr, style: AppTextStyles.heading2),
            const SizedBox(height: AppSpacing.xs),
            Text(
              _failed
                  ? LocaleKeys.captchaError.tr
                  : LocaleKeys.captchaSubtitle.tr,
              style: AppTextStyles.body.copyWith(
                color: _failed ? AppColors.alert : context.colorInkMuted,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              height: 160,
              child: WebViewWidget(controller: _controller),
            ),
          ],
        ),
      ),
    );
  }
}
