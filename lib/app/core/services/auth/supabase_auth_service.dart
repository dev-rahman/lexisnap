import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../../../data/models/app_user.dart';
import '../../config/env.dart';
import '../../errors/auth_exception.dart';
import 'auth_service.dart';

/// Supabase-backed implementation of [AuthService].
///
/// This is the only file in the app that imports `supabase_flutter`,
/// `google_sign_in`, or `sign_in_with_apple` directly. Every other class
/// depends on the [AuthService] interface instead.
class SupabaseAuthService implements AuthService {
  Future<void>? _googleInitFuture;

  sb.GoTrueClient get _auth => sb.Supabase.instance.client.auth;

  @override
  Stream<AppUser?> get authStateChanges =>
      _auth.onAuthStateChange.map((state) => _mapUser(state.session?.user));

  @override
  AppUser? get currentUser => _mapUser(_auth.currentUser);

  AppUser? _mapUser(sb.User? user) {
    if (user == null) return null;
    final metadata = user.userMetadata ?? const {};
    return AppUser(
      id: user.id,
      email: user.email,
      fullName: metadata['full_name'] as String? ?? metadata['name'] as String?,
      avatarUrl: metadata['avatar_url'] as String?,
      emailConfirmed: user.emailConfirmedAt != null,
    );
  }

  @override
  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithPassword(email: email.trim(), password: password);
    } on sb.AuthException catch (e) {
      throw AppAuthException(e.message);
    }
  }

  @override
  Future<void> signUpWithEmail({
    required String email,
    required String password,
    String? fullName,
  }) async {
    try {
      await _auth.signUp(
        email: email.trim(),
        password: password,
        data: fullName != null && fullName.isNotEmpty
            ? {'full_name': fullName}
            : null,
      );
    } on sb.AuthException catch (e) {
      throw AppAuthException(e.message);
    }
  }

  @override
  Future<void> sendPasswordResetEmail({required String email}) async {
    try {
      await _auth.resetPasswordForEmail(email.trim());
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
  Future<void> updateProfile({String? fullName}) async {
    try {
      await _auth.updateUser(
        sb.UserAttributes(data: {if (fullName != null) 'full_name': fullName}),
      );
    } on sb.AuthException catch (e) {
      throw AppAuthException(e.message);
    }
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
  Future<void> signInWithApple() async {
    try {
      final rawNonce = _generateRawNonce();
      final hashedNonce = sha256.convert(utf8.encode(rawNonce)).toString();

      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: hashedNonce,
      );

      final idToken = credential.identityToken;
      if (idToken == null) {
        throw const AppAuthException(
          'Apple sign-in failed: no identity token returned.',
        );
      }

      await _auth.signInWithIdToken(
        provider: sb.OAuthProvider.apple,
        idToken: idToken,
        nonce: rawNonce,
      );

      // Apple only sends the name on the very first authorization. Persist
      // it on the Supabase user the first time we see it.
      final fullName = [
        credential.givenName,
        credential.familyName,
      ].whereType<String>().where((s) => s.isNotEmpty).join(' ');

      if (fullName.isNotEmpty) {
        await _auth.updateUser(
          sb.UserAttributes(data: {'full_name': fullName}),
        );
      }
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) return;
      throw AppAuthException('Apple sign-in failed: ${e.message}');
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

  String _generateRawNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz';
    final random = Random.secure();
    return List.generate(
      length,
      (_) => charset[random.nextInt(charset.length)],
    ).join();
  }
}
