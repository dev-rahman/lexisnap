import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../core/services/auth/auth_service.dart';
import 'app_routes.dart';

/// Keeps signed-out users out of authenticated routes, and signed-in users
/// out of the auth flow (so a signed-in user hitting /login is bounced
/// straight to /home).
class AuthMiddleware extends GetMiddleware {
  AuthMiddleware({required this.requiresAuth, int priority = 0})
      : super(priority: priority);

  final bool requiresAuth;

  @override
  RouteSettings? redirect(String? route) {
    final isSignedIn = Get.find<AuthService>().currentUser != null;

    if (requiresAuth && !isSignedIn) {
      return const RouteSettings(name: AppRoutes.login);
    }
    if (!requiresAuth && isSignedIn) {
      return const RouteSettings(name: AppRoutes.home);
    }
    return null;
  }
}
