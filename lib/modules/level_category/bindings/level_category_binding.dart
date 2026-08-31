import 'package:get/get.dart';
import 'package:p2tch/app/services/level_service.dart';

import '../controllers/level_category_controller.dart';

class LevelCategoryBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<LevelCategoryController>(
      () => LevelCategoryController(levelService: Get.find<LevelService>()),
    );
  }
}
