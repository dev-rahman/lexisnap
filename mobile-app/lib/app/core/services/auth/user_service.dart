import 'dart:async';

import 'package:get/get.dart';

import '../../../data/models/app_user.dart';
import 'auth_service.dart';

/// The signed-in user as reactive state.
///
/// [AuthService.currentUser] is a plain getter, so a widget that read it
/// kept showing whatever was true when it was built: a new photo or name
/// didn't reach the shell's avatar until something unrelated rebuilt it.
/// Anything that shows the user should read [user] inside an `Obx`.
class UserService extends GetxService {
  final user = Rxn<AppUser>();

  StreamSubscription<AppUser?>? _subscription;

  AuthService get _authService => Get.find<AuthService>();

  @override
  void onInit() {
    super.onInit();
    user.value = _authService.currentUser;
    _subscription = _authService.authStateChanges.listen(
      (next) => user.value = next,
    );
  }

  @override
  void onClose() {
    _subscription?.cancel();
    super.onClose();
  }
}
