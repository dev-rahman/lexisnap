import 'package:get/get.dart';

import 'splash_controller.dart';

class SplashBinding extends Bindings {
  @override
  void dependencies() {
    // Eager `put`, not `lazyPut`: SplashView never reads `controller` in its
    // build method (it's a static spinner), so a lazyPut would never be
    // instantiated and the redirect logic in onReady() would never run.
    Get.put<SplashController>(SplashController());
  }
}
