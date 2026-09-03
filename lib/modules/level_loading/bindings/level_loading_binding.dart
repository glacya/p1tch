import 'package:get/get.dart';
import 'package:p2tch/app/services/level_service.dart';

import '../controllers/level_loading_controller.dart';

class LevelLoadingBinding extends Bindings {
  @override
  void dependencies() {
    final arguments = Get.arguments;
    String? category;
    int? id;

    if (arguments is Map) {
      final rawCategory = arguments['category'];
      final rawId = arguments['id'];
      if (rawCategory is String) category = rawCategory;
      if (rawId is int) id = rawId;
    }

    Get.lazyPut<LevelLoadingController>(
      () => LevelLoadingController(
        category: category,
        id: id,
        levelService: Get.find<LevelService>(),
      ),
    );
  }
}
