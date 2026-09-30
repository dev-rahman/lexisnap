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

  /// Confirms the signed-in user's current password, throwing
  /// [AppAuthException] if it's wrong. Guards changes that shouldn't be
  /// possible for someone who merely picked up an unlocked phone.
  Future<void> reauthenticate({required String password});

  /// Starts moving the account to [newEmail] by emailing a one-time code
  /// to it - and, when the backend requires both sides to agree, another
  /// to the current address. Confirm each with [verifyEmailChangeCode].
  Future<void> requestEmailChange({required String newEmail});

  /// Checks a code from [requestEmailChange], where [email] is the address
  /// the code was sent to. Returns true once the change is complete, or
  /// false when the code was accepted but the other address still has to
  /// confirm with its own code.
  Future<bool> verifyEmailChangeCode({
    required String email,
    required String code,
  });

  /// Updates the signed-in user's profile fields. Pass only what should
  /// change; omitted fields are left as-is.
  Future<void> updateProfile({String? fullName});

  /// Points the user's profile at an uploaded photo, or with null goes
  /// back to their Google/Apple picture or initials.
  Future<void> updateProfilePhoto(String? url);

  /// Permanently deletes the account and every piece of data in it, then
  /// signs out. There is no undo.
  Future<void> deleteAccount();

  /// Available on both Android and iOS.
  Future<void> signInWithGoogle();

  /// Available on iOS only. Callers should not show an Apple sign-in
  /// option on other platforms.
  Future<void> signInWithApple();

  Future<void> signOut();
}
