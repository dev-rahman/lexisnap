abstract class AppRoutes {
  AppRoutes._();

  static const splash = '/splash';
  static const onboarding = '/onboarding';
  static const login = '/login';
  static const signup = '/signup';
  static const forgotPassword = '/forgot-password';

  /// The authenticated shell: bottom-bar navigation between Home and
  /// Decks tabs, with a floating button to [profile]. This is the
  /// post-login landing route.
  static const main = '/main';

  /// Full-screen scan flow, pushed on top of [main].
  static const scan = '/scan';

  /// A single saved deck's flashcards, pushed from Home/Decks. Expects the
  /// deck's id as the route arguments.
  static const deckDetail = '/deck';

  /// Account & settings, pushed from the floating profile button.
  static const profile = '/profile';

  /// Help & support, pushed from Profile.
  static const help = '/help';

  /// Photo, name, email, password and account deletion, pushed from
  /// Profile.
  static const editProfile = '/edit-profile';

  /// Moving the account to a new email address, pushed from [editProfile].
  static const changeEmail = '/change-email';

  /// The multi-step, can't-be-undone account deletion, pushed from
  /// [editProfile].
  static const deleteAccount = '/delete-account';
}
