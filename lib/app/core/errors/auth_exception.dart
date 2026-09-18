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
