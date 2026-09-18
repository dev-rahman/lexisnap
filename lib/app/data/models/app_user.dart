/// App-level user model. The rest of the app depends only on this class,
/// never on a backend SDK's user type. `SupabaseAuthService` is the single
/// place that maps a Supabase `User` into an `AppUser`.
class AppUser {
  const AppUser({
    required this.id,
    required this.email,
    this.fullName,
    this.avatarUrl,
    this.emailConfirmed = false,
  });

  final String id;
  final String? email;
  final String? fullName;
  final String? avatarUrl;
  final bool emailConfirmed;

  @override
  String toString() => 'AppUser(id: $id, email: $email)';
}
