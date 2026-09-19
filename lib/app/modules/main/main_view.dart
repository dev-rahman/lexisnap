import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:get/get.dart';

import '../../core/widgets/app_bottom_nav_bar.dart';
import '../home/home_view.dart';
import '../profile/profile_view.dart';
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
                children: const [HomeView(), ProfileView()],
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
                onProfileTap: () => controller.changeTab(1),
                onScanTap: controller.openScan,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
