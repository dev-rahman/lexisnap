/// App-level user model. The rest of the app depends only on this class,
/// never on a backend SDK's user type. `SupabaseAuthService` is the single
/// place that maps a Supabase `User` into an `AppUser`.
class AppUser {
  const AppUser({
    required this.id,
    required this.email,
    this.fullName,
    this.avatarUrl,
    this.hasOwnPhoto = false,
    this.hasPassword = false,
    this.emailConfirmed = false,
  });

  final String id;
  final String? email;
  final String? fullName;

  /// The photo to show: one the user uploaded, else their Google
  /// picture, else null (initials).
  final String? avatarUrl;

  /// Whether [avatarUrl] is a photo the user uploaded themselves - the
  /// only kind "Remove photo" can take away.
  final bool hasOwnPhoto;

  /// Whether the account has an email + password sign-in. Accounts made
  /// through Google don't, so there's no current password to ask
  /// for before setting one.
  final bool hasPassword;

  final bool emailConfirmed;

  @override
  String toString() => 'AppUser(id: $id, email: $email)';
}
