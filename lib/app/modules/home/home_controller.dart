import 'package:get/get.dart';

import '../../core/services/auth/auth_service.dart';
import '../../data/models/app_user.dart';
import '../../routes/app_routes.dart';

class HomeController extends GetxController {
  AuthService get _authService => Get.find<AuthService>();

  AppUser? get user => _authService.currentUser;

  String get greetingName {
    final user = this.user;
    if (user?.fullName?.isNotEmpty == true) {
      return user!.fullName!.split(' ').first;
    }
    return user?.email?.split('@').first ?? 'there';
  }

  void goToScan() => Get.toNamed(AppRoutes.scan);
}
