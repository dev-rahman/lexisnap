import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../../../data/models/app_user.dart';
import '../../config/env.dart';
import '../../errors/auth_exception.dart';
import 'auth_service.dart';

/// Supabase-backed implementation of [AuthService].
///
/// This is the only file in the app that imports `supabase_flutter` or
/// `google_sign_in` directly. Every other class depends on the
/// [AuthService] interface instead.
class SupabaseAuthService implements AuthService {
  Future<void>? _googleInitFuture;

  sb.GoTrueClient get _auth => sb.Supabase.instance.client.auth;

  @override
  Stream<AppUser?> get authStateChanges =>
      _auth.onAuthStateChange.map((state) => _mapUser(state.session?.user));

  @override
  AppUser? get currentUser => _mapUser(_auth.currentUser);

  /// The user's own uploaded photo lives under its own metadata key, not
  /// `avatar_url`: Supabase refreshes `avatar_url` from Google on every
  /// Google sign-in, which would quietly replace a photo the user chose.
  static const _photoUrlKey = 'photo_url';

  AppUser? _mapUser(sb.User? user) {
    if (user == null) return null;
    final metadata = user.userMetadata ?? const {};
    final ownPhoto = metadata[_photoUrlKey] as String?;
    final providers = user.appMetadata['providers'];
    return AppUser(
      id: user.id,
      email: user.email,
      fullName: metadata['full_name'] as String? ?? metadata['name'] as String?,
      avatarUrl:
          ownPhoto ??
          metadata['avatar_url'] as String? ??
          metadata['picture'] as String?,
      hasOwnPhoto: ownPhoto != null,
      hasPassword: providers is List
          ? providers.contains('email')
          : user.appMetadata['provider'] == 'email',
      emailConfirmed: user.emailConfirmedAt != null,
    );
  }

  @override
  Future<void> signInWithEmail({
    required String email,
    required String password,
    String? captchaToken,
  }) async {
    try {
      await _auth.signInWithPassword(
        email: email.trim(),
        password: password,
        captchaToken: captchaToken,
      );
    } on sb.AuthException catch (e) {
      throw AppAuthException(e.message);
    }
  }

  @override
  Future<void> signUpWithEmail({
    required String email,
    required String password,
    String? fullName,
    String? captchaToken,
  }) async {
    try {
      await _auth.signUp(
        email: email.trim(),
        password: password,
        data: fullName != null && fullName.isNotEmpty
            ? {'full_name': fullName}
            : null,
        captchaToken: captchaToken,
      );
    } on sb.AuthException catch (e) {
      throw AppAuthException(e.message);
    }
  }

  @override
  Future<void> sendPasswordResetEmail({
    required String email,
    String? captchaToken,
  }) async {
    try {
      await _auth.resetPasswordForEmail(
        email.trim(),
        captchaToken: captchaToken,
      );
    } on sb.AuthException catch (e) {
      throw AppAuthException(e.message);
    }
  }

  @override
  Future<void> verifyPasswordResetCode({
    required String email,
    required String code,
  }) async {
    try {
      await _auth.verifyOTP(
        type: sb.OtpType.recovery,
        email: email.trim(),
        token: code.trim(),
      );
    } on sb.AuthException catch (e) {
      throw AppAuthException(e.message);
    }
  }

  @override
  Future<void> updatePassword({required String password}) async {
    try {
      await _auth.updateUser(sb.UserAttributes(password: password));
    } on sb.AuthException catch (e) {
      throw AppAuthException(e.message);
    }
  }

  @override
  Future<void> reauthenticate({required String password}) async {
    final email = _auth.currentUser?.email;
    if (email == null) throw const AppAuthException('Not signed in.');
    try {
      await _auth.signInWithPassword(email: email, password: password);
    } on sb.AuthException catch (e) {
      if (e.code == 'invalid_credentials') {
        throw WrongPasswordException(e.message);
      }
      throw AppAuthException(e.message);
    }
  }

  @override
  Future<void> requestEmailChange({required String newEmail}) async {
    try {
      await _auth.updateUser(sb.UserAttributes(email: newEmail.trim()));
    } on sb.AuthException catch (e) {
      throw AppAuthException(e.message);
    }
  }

  @override
  Future<bool> verifyEmailChangeCode({
    required String email,
    required String code,
  }) async {
    try {
      final response = await _auth.verifyOTP(
        type: sb.OtpType.emailChange,
        email: email.trim(),
        token: code.trim(),
      );
      // With "secure email change" on, the first of the two codes is
      // accepted without a session; the session - and the new email -
      // only arrive once the second one is verified.
      return response.session != null;
    } on sb.AuthException catch (e) {
      throw AppAuthException(e.message);
    }
  }

  @override
  Future<void> updateProfile({String? fullName}) async {
    try {
      await _auth.updateUser(
        sb.UserAttributes(data: {if (fullName != null) 'full_name': fullName}),
      );
    } on sb.AuthException catch (e) {
      throw AppAuthException(e.message);
    }
  }

  @override
  Future<void> updateProfilePhoto(String? url) async {
    try {
      // A null value removes the key rather than storing null.
      await _auth.updateUser(sb.UserAttributes(data: {_photoUrlKey: url}));
    } on sb.AuthException catch (e) {
      throw AppAuthException(e.message);
    }
  }

  @override
  Future<void> deleteAccount() async {
    // Deleting a user takes the service role key, which must never ship in
    // the app, so the `delete-account` Edge Function does the actual work.
    try {
      await sb.Supabase.instance.client.functions.invoke('delete-account');
    } on sb.FunctionException catch (e) {
      final details = e.details;
      throw AppAuthException(
        details is Map && details['error'] is String
            ? details['error'] as String
            : 'Account deletion failed (${e.status}).',
      );
    }

    try {
      await GoogleSignIn.instance.signOut();
    } catch (_) {
      // Not signed in via Google - ignore.
    }
    // The server already revoked every session along with the user, so
    // there's nothing to tell it; just drop the one stored on this device.
    await _auth.signOut(scope: sb.SignOutScope.local);
  }

  /// `GoogleSignIn.instance.initialize` must be called exactly once, and
  /// awaited, before any other GoogleSignIn method is used.
  Future<void> _ensureGoogleInitialized() {
    return _googleInitFuture ??= GoogleSignIn.instance.initialize(
      clientId:
          defaultTargetPlatform == TargetPlatform.iOS &&
              Env.googleIosClientId.isNotEmpty
          ? Env.googleIosClientId
          : null,
      serverClientId: Env.googleServerClientId.isNotEmpty
          ? Env.googleServerClientId
          : null,
    );
  }

  @override
  Future<void> signInWithGoogle() async {
    try {
      await _ensureGoogleInitialized();
      final account = await GoogleSignIn.instance.authenticate();
      final idToken = account.authentication.idToken;

      if (idToken == null) {
        throw const AppAuthException(
          'Google sign-in failed: no ID token returned.',
        );
      }

      await _auth.signInWithIdToken(
        provider: sb.OAuthProvider.google,
        idToken: idToken,
      );
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) return;
      throw AppAuthException(
        'Google sign-in failed: ${e.description ?? e.code.name}',
      );
    } on sb.AuthException catch (e) {
      throw AppAuthException(e.message);
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await GoogleSignIn.instance.signOut();
    } catch (_) {
      // Not signed in via Google, or already signed out - ignore.
    }
    try {
      await _auth.signOut();
    } on sb.AuthException catch (e) {
      throw AppAuthException(e.message);
    }
  }
}
