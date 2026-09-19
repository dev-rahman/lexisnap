import 'package:get/get.dart';

import '../../core/errors/auth_exception.dart';
import '../../core/localization/locale_keys.dart';
import '../../core/services/auth/auth_service.dart';
import '../../core/services/theme/theme_service.dart';
import '../../core/utils/app_snackbar.dart';
import '../../data/models/app_user.dart';
import '../../routes/app_routes.dart';

class ProfileController extends GetxController {
  AuthService get _authService => Get.find<AuthService>();

  ThemeService get themeService => Get.find<ThemeService>();

  AppUser? get user => _authService.currentUser;

  final isSigningOut = false.obs;
  final isUpdatingName = false.obs;

  /// Bumped after a profile update so widgets reading the (non-reactive)
  /// [user] getter know to rebuild.
  final refreshTrigger = 0.obs;

  Future<void> updateName(String fullName) async {
    isUpdatingName.value = true;
    try {
      await _authService.updateProfile(fullName: fullName);
      refreshTrigger.value++;
      Get.back();
      AppSnackbar.success(LocaleKeys.profileNameUpdated.tr);
    } on AppAuthException catch (e) {
      AppSnackbar.error(e.message);
    } finally {
      isUpdatingName.value = false;
    }
  }

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
