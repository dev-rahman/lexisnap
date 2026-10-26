import 'package:get/get.dart';

import '../../core/services/auth/auth_service.dart';
import '../../core/services/auth/user_service.dart';
import '../../core/services/theme/theme_service.dart';
import '../../data/models/app_user.dart';
import '../../routes/app_routes.dart';

class ProfileController extends GetxController {
  AuthService get _authService => Get.find<AuthService>();

  ThemeService get themeService => Get.find<ThemeService>();

  /// Reactive: read inside an `Obx` and the header follows every change
  /// made on Edit profile.
  AppUser? get user => Get.find<UserService>().user.value;

  final isSigningOut = false.obs;

  void openEditProfile() => Get.toNamed(AppRoutes.editProfile);

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
