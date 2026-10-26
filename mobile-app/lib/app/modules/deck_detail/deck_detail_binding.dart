import 'package:get/get.dart';

import 'deck_detail_controller.dart';

class DeckDetailBinding extends Bindings {
  @override
  void dependencies() {
    Get.put<DeckDetailController>(DeckDetailController());
  }
}
