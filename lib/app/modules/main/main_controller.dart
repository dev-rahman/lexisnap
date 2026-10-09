import 'package:get/get.dart';

class MainController extends GetxController {
  final tabIndex = 0.obs;

  /// Whether the (iOS) liquid tab bar should be in its collapsed,
  /// scroll-minimized state. Ignored on Android, which uses the platform's
  /// fixed-height stock NavigationBar.
  final isNavBarMinimized = false.obs;

  void changeTab(int index) => tabIndex.value = index;

  void setNavBarMinimized(bool minimized) {
    if (isNavBarMinimized.value != minimized) {
      isNavBarMinimized.value = minimized;
    }
  }
}
