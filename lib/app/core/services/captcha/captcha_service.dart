/// Contract for bot-protection challenges on auth actions (sign in, sign up,
/// password reset). Controllers talk to this interface, never to a specific
/// captcha provider.
abstract class CaptchaService {
  /// Whether a captcha is configured at all. When false the whole step is
  /// skipped, which is correct while CAPTCHA is turned off in the backend -
  /// the app keeps working untouched. Callers only challenge when this is
  /// true, so turning it on is a matter of configuring the key.
  bool get isEnabled;

  /// Runs the challenge and returns a fresh single-use token to hand to the
  /// auth call, or null if the user dismissed it or it failed. Only call this
  /// when [isEnabled] is true.
  Future<String?> getToken();
}
