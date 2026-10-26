/// Contract for sending a support message from the help screen.
///
/// The app talks to this interface, never to a specific email provider, so
/// EmailJS can be swapped for a backend endpoint later by writing a new
/// implementation and changing one line in the service locator.
abstract class SupportService {
  /// Whether sending is configured. When false the help screen falls back to
  /// opening the user's own mail app, so support still works before EmailJS
  /// is set up.
  bool get isConfigured;

  /// Sends the support request to the LexiSnap inbox and a copy to the user.
  /// Throws [SupportException] if the request to the inbox fails.
  Future<void> sendSupportMessage({
    required String message,
    required String userEmail,
    String? userName,
  });
}

/// Thrown when a support message can't be sent.
class SupportException implements Exception {
  const SupportException(this.message);

  final String message;

  @override
  String toString() => 'SupportException: $message';
}
