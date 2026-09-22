import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:get/get.dart';

import '../../core/services/auth/auth_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/initials.dart';
import '../../core/widgets/app_bottom_nav_bar.dart';
import '../../routes/app_routes.dart';
import '../decks/decks_view.dart';
import '../home/home_view.dart';
import 'main_controller.dart';

class MainView extends GetView<MainController> {
  const MainView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(
        () => Stack(
          children: [
            NotificationListener<UserScrollNotification>(
              onNotification: (notification) {
                switch (notification.direction) {
                  case ScrollDirection.reverse:
                    controller.setNavBarMinimized(true);
                  case ScrollDirection.forward:
                    controller.setNavBarMinimized(false);
                  case ScrollDirection.idle:
                    break;
                }
                return false;
              },
              child: IndexedStack(
                index: controller.tabIndex.value,
                children: const [HomeView(), DecksView()],
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: AppBottomNavBar(
                currentIndex: controller.tabIndex.value,
                isMinimized: controller.isNavBarMinimized.value,
                onHomeTap: () => controller.changeTab(0),
                onDecksTap: () => controller.changeTab(1),
                onScanTap: controller.openScan,
              ),
            ),
            const _ProfileButton(),
          ],
        ),
      ),
    );
  }
}

/// Floating avatar button in the top-right corner of the app shell, over
/// both tabs, opening the account/settings screen that used to be the
/// Profile tab.
class _ProfileButton extends StatelessWidget {
  const _ProfileButton();

  @override
  Widget build(BuildContext context) {
    final user = Get.find<AuthService>().currentUser;
    final name = user?.fullName?.isNotEmpty == true ? user!.fullName : null;
    final initials = initialsFor(name, user?.email);

    return Positioned(
      top: MediaQuery.of(context).padding.top + AppSpacing.sm,
      right: AppSpacing.lg,
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () => Get.toNamed(AppRoutes.profile),
          child: Container(
            height: 40,
            width: 40,
            decoration: const BoxDecoration(
              color: AppColors.ink,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                initials,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
