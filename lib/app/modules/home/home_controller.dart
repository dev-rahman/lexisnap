import 'package:get/get.dart';

import '../../core/services/auth/auth_service.dart';
import '../../data/models/app_user.dart';
import '../../routes/app_routes.dart';

class HomeController extends GetxController {
  AuthService get _authService => Get.find<AuthService>();

  AppUser? get user => _authService.currentUser;

  final isSigningOut = false.obs;

  Future<void> signOut() async {
    isSigningOut.value = true;
    try {
      await _authService.signOut();
      Get.offAllNamed(AppRoutes.login);
    } finally {
      isSigningOut.value = false;
    }
  }
}
