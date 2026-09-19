abstract class AppRoutes {
  AppRoutes._();

  static const splash = '/splash';
  static const onboarding = '/onboarding';
  static const login = '/login';
  static const signup = '/signup';
  static const forgotPassword = '/forgot-password';

  /// The authenticated shell: bottom-bar navigation between Home and
  /// Profile tabs. This is the post-login landing route.
  static const main = '/main';

  /// Full-screen scan flow, pushed on top of [main].
  static const scan = '/scan';

  /// Help & support, pushed from Profile.
  static const help = '/help';
}
