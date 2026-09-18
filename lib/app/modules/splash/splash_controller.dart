import 'package:get/get.dart';

import '../../core/services/auth/auth_service.dart';
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
    await Future.delayed(const Duration(milliseconds: 300));
    final isSignedIn = Get.find<AuthService>().currentUser != null;
    Get.offAllNamed(isSignedIn ? AppRoutes.home : AppRoutes.login);
  }
}
