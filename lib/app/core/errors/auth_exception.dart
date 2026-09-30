/// Backend-agnostic auth error. Every `AuthService` implementation must
/// catch its own SDK's exceptions and rethrow this instead, so controllers
/// never need to know whether Supabase, Firebase, or anything else is
/// behind the interface.
class AppAuthException implements Exception {
  const AppAuthException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// The password given to `AuthService.reauthenticate` was wrong. Split out
/// so a screen can say exactly that, rather than passing on the backend's
/// generic "invalid login credentials" - and so a network failure isn't
/// mistaken for a wrong password.
class WrongPasswordException extends AppAuthException {
  const WrongPasswordException(super.message);
}
