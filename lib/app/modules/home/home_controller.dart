import 'package:get/get.dart';

import '../../core/services/auth/auth_service.dart';
import '../../data/models/app_user.dart';
import '../../routes/app_routes.dart';
import '../decks/decks_controller.dart';
import '../main/main_controller.dart';

class HomeController extends GetxController {
  AuthService get _authService => Get.find<AuthService>();

  DecksController get decksController => Get.find<DecksController>();

  AppUser? get user => _authService.currentUser;

  /// The user's first name, if we have one to greet them with. `null`
  /// means the view should fall back to a generic greeting instead of
  /// interpolating a name into the translated greeting string.
  String? get firstName {
    final user = this.user;
    if (user?.fullName?.isNotEmpty == true) {
      return user!.fullName!.split(' ').first;
    }
    return user?.email?.split('@').first;
  }

  void goToScan() => Get.toNamed(AppRoutes.scan);

  void goToDecksTab() => Get.find<MainController>().changeTab(1);
}
