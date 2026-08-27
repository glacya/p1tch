import 'package:get/get.dart';

import '../controllers/level_category_controller.dart';

class LevelCategoryBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<LevelCategoryController>(() => LevelCategoryController());
  }
}
