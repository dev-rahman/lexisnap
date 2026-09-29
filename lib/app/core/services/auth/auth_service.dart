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

  /// Emails a one-time code the user types into the app to reset their
  /// password - no link to open. Check it with [verifyPasswordResetCode].
  Future<void> sendPasswordResetEmail({required String email});

  /// Checks the code sent by [sendPasswordResetEmail]. On success the user
  /// is signed in, so [updatePassword] can set their new password.
  Future<void> verifyPasswordResetCode({
    required String email,
    required String code,
  });

  /// Sets a new password for the signed-in user.
  Future<void> updatePassword({required String password});

  /// Updates the signed-in user's profile fields. Pass only what should
  /// change; omitted fields are left as-is.
  Future<void> updateProfile({String? fullName});

  /// Available on both Android and iOS.
  Future<void> signInWithGoogle();

  /// Available on iOS only. Callers should not show an Apple sign-in
  /// option on other platforms.
  Future<void> signInWithApple();

  Future<void> signOut();
}
