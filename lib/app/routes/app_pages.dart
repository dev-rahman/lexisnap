import 'package:get/get.dart';

import '../modules/auth/forgot_password/forgot_password_binding.dart';
import '../modules/auth/forgot_password/forgot_password_view.dart';
import '../modules/auth/login/login_binding.dart';
import '../modules/auth/login/login_view.dart';
import '../modules/auth/signup/signup_binding.dart';
import '../modules/auth/signup/signup_view.dart';
import '../modules/deck_detail/deck_detail_binding.dart';
import '../modules/deck_detail/deck_detail_view.dart';
import '../modules/help/help_binding.dart';
import '../modules/help/help_view.dart';
import '../modules/main/main_binding.dart';
import '../modules/main/main_view.dart';
import '../modules/onboarding/onboarding_binding.dart';
import '../modules/onboarding/onboarding_view.dart';
import '../modules/scan/scan_binding.dart';
import '../modules/scan/scan_view.dart';
import '../modules/splash/splash_binding.dart';
import '../modules/splash/splash_view.dart';
import 'app_routes.dart';
import 'auth_middleware.dart';

class AppPages {
  AppPages._();

  static const initial = AppRoutes.splash;

  static final routes = [
    GetPage(
      name: AppRoutes.splash,
      page: () => const SplashView(),
      binding: SplashBinding(),
    ),
    GetPage(
      name: AppRoutes.onboarding,
      page: () => const OnboardingView(),
      binding: OnboardingBinding(),
    ),
    GetPage(
      name: AppRoutes.login,
      page: () => const LoginView(),
      binding: LoginBinding(),
      middlewares: [AuthMiddleware(requiresAuth: false)],
    ),
    GetPage(
      name: AppRoutes.signup,
      page: () => const SignupView(),
      binding: SignupBinding(),
      middlewares: [AuthMiddleware(requiresAuth: false)],
    ),
    GetPage(
      name: AppRoutes.forgotPassword,
      page: () => const ForgotPasswordView(),
      binding: ForgotPasswordBinding(),
      middlewares: [AuthMiddleware(requiresAuth: false)],
    ),
    GetPage(
      name: AppRoutes.main,
      page: () => const MainView(),
      binding: MainBinding(),
      middlewares: [AuthMiddleware(requiresAuth: true)],
    ),
    GetPage(
      name: AppRoutes.scan,
      page: () => const ScanView(),
      binding: ScanBinding(),
      middlewares: [AuthMiddleware(requiresAuth: true)],
    ),
    GetPage(
      name: AppRoutes.deckDetail,
      page: () => const DeckDetailView(),
      binding: DeckDetailBinding(),
      middlewares: [AuthMiddleware(requiresAuth: true)],
    ),
    GetPage(
      name: AppRoutes.help,
      page: () => const HelpView(),
      binding: HelpBinding(),
      middlewares: [AuthMiddleware(requiresAuth: true)],
    ),
  ];
}
