import '../../../data/models/app_user.dart';

/// Contract for authentication. Controllers and the rest of the app talk
/// only to this interface, never to a specific backend SDK.
///
/// To swap Supabase for Firebase (or anything else) later, write a new
/// class that implements this interface and swap the single registration
/// in `lib/app/core/services/service_locator.dart`. Nothing else changes.
abstract class AuthService {
  /// Emits the current user whenever auth state changes (sign in, sign out,
  /// token refresh, initial session restore). Emits `null` when signed out.
  Stream<AppUser?> get authStateChanges;

  /// The currently signed-in user, if any, read synchronously.
  AppUser? get currentUser;

  Future<void> signInWithEmail({
    required String email,
    required String password,
  });

  Future<void> signUpWithEmail({
    required String email,
    required String password,
    String? fullName,
  });

  Future<void> sendPasswordResetEmail({required String email});

  /// Available on both Android and iOS.
  Future<void> signInWithGoogle();

  /// Available on iOS only. Callers should not show an Apple sign-in
  /// option on other platforms.
  Future<void> signInWithApple();

  Future<void> signOut();
}
