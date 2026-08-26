import 'package:get/get.dart';

import '../controllers/level_play_controller.dart';

class LevelPlayBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<LevelPlayController>(() => LevelPlayController());
  }
}
