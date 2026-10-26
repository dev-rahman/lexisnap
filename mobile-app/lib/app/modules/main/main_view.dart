import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:get/get.dart';

import '../../core/widgets/app_bottom_nav_bar.dart';
import '../../core/widgets/app_shell_buttons.dart';
import '../../core/widgets/scan_source_sheet.dart';
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
              // IndexedStack keeps both tabs mounted, and it does not mute
              // tickers - so Home's scan-line would keep animating (and
              // drawing frames) while the user is on Decks. TickerMode
              // silences every ticker below the hidden tab.
              child: IndexedStack(
                index: controller.tabIndex.value,
                children: [
                  TickerMode(
                    enabled: controller.tabIndex.value == 0,
                    child: const HomeView(),
                  ),
                  TickerMode(
                    enabled: controller.tabIndex.value == 1,
                    child: const DecksView(),
                  ),
                ],
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
                onScanTap: () => startScanFlow(context),
              ),
            ),
            const AppProfileButton(),
          ],
        ),
      ),
    );
  }
}
