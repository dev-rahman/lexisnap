import 'package:get/get.dart';

import '../decks/decks_controller.dart';
import '../home/home_controller.dart';
import 'main_controller.dart';

class MainBinding extends Bindings {
  @override
  void dependencies() {
    Get.put<MainController>(MainController());
    Get.put<DecksController>(DecksController());
    Get.put<HomeController>(HomeController());
  }
}
