import 'package:get/get.dart';

import '../../core/services/auth/auth_service.dart';
import '../../core/services/onboarding/onboarding_service.dart';
import '../../routes/app_routes.dart';

class SplashController extends GetxController {
  @override
  void onReady() {
    super.onReady();
    _redirect();
  }

  Future<void> _redirect() async {
    // Give Supabase a beat to restore a persisted session from local
    // storage before deciding where to send the user.
    await Future.delayed(const Duration(milliseconds: 600));

    final isSignedIn = Get.find<AuthService>().currentUser != null;
    if (isSignedIn) {
      Get.offAllNamed(AppRoutes.main);
      return;
    }

    final hasSeenOnboarding = await Get.find<OnboardingService>()
        .hasSeenOnboarding();
    Get.offAllNamed(hasSeenOnboarding ? AppRoutes.login : AppRoutes.onboarding);
  }
}
