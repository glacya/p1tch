import 'package:get/get.dart';
import 'package:p2tch/app/services/level_service.dart';

import '../controllers/level_select_controller.dart';

class LevelSelectBinding extends Bindings {
  @override
  void dependencies() {
    final arguments = Get.arguments;
    String? categoryId;

    if (arguments is Map) {
      final rawCategoryId = arguments['categoryId'];
      if (rawCategoryId is String) categoryId = rawCategoryId;
    }

    Get.lazyPut<LevelSelectController>(
      () => LevelSelectController(
        categoryId: categoryId,
        levelService: Get.find<LevelService>(),
      ),
    );
  }
}
