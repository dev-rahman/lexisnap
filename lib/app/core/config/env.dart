import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Centralized access to environment/config values.
///
/// Values are loaded from `.env` at startup (see `main.dart`). Keeping every
/// secret-reading call behind this class means nothing else in the app talks
/// to `dotenv` directly.
class Env {
  Env._();

  static String get supabaseUrl => _require('SUPABASE_URL');

  /// The Supabase "publishable" key (formerly called the "anon" key). Safe
  /// to ship in client apps - it only grants what your RLS policies allow.
  static String get supabasePublishableKey =>
      _require('SUPABASE_PUBLISHABLE_KEY');

  /// iOS OAuth client ID from Google Cloud Console, used by google_sign_in
  /// on iOS. Not required on Android (that platform reads it from
  /// `google-services.json` instead).
  static String get googleIosClientId =>
      dotenv.env['GOOGLE_IOS_CLIENT_ID'] ?? '';

  /// Web/Server OAuth client ID from Google Cloud Console. Required by
  /// google_sign_in on both platforms so Supabase can verify the ID token.
  static String get googleServerClientId =>
      dotenv.env['GOOGLE_SERVER_CLIENT_ID'] ?? '';

  /// Inbox that "Contact support" messages are addressed to (opens the
  /// user's own mail app via a `mailto:` link - no backend required).
  static String get supportEmail =>
      dotenv.env['SUPPORT_EMAIL'] ?? 'support@lexisnap.app';

  /// Cloudflare Turnstile site key (public). When empty, the app skips the
  /// captcha entirely, which is correct while CAPTCHA is turned off in the
  /// Supabase dashboard. Set it, and enable CAPTCHA in Supabase, to switch
  /// bot protection on - the two must be done together. The matching secret
  /// key lives only in Supabase, never here.
  static String get turnstileSiteKey => dotenv.env['TURNSTILE_SITE_KEY'] ?? '';

  // --- EmailJS (support form) ---------------------------------------------
  // When these are set, the help form sends two emails through EmailJS: the
  // support request to [supportEmail] and a copy to the user. When they're
  // empty the form falls back to opening the user's mail app. See
  // docs/emailjs/SETUP.md.

  static String get emailjsServiceId => dotenv.env['EMAILJS_SERVICE_ID'] ?? '';

  /// Public key (Account > General). Safe in the app.
  static String get emailjsPublicKey => dotenv.env['EMAILJS_PUBLIC_KEY'] ?? '';

  /// Private key (Account > Security). Required by EmailJS to allow sends
  /// from a non-browser app. It can be extracted from the app binary, so
  /// EmailJS's own rate limits are the real guard - keep those tight.
  static String get emailjsPrivateKey =>
      dotenv.env['EMAILJS_PRIVATE_KEY'] ?? '';

  /// Template that emails the support request to the LexiSnap inbox.
  static String get emailjsTemplateSupport =>
      dotenv.env['EMAILJS_TEMPLATE_SUPPORT'] ?? '';

  /// Template that emails the user their copy/receipt.
  static String get emailjsTemplateReceipt =>
      dotenv.env['EMAILJS_TEMPLATE_RECEIPT'] ?? '';

  static String _require(String key) {
    final value = dotenv.env[key];
    if (value == null || value.isEmpty) {
      throw StateError(
        'Missing required env var "$key". Did you create a .env file '
        'from .env.example and populate it?',
      );
    }
    return value;
  }
}
