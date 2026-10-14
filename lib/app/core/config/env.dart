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
