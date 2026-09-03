import 'package:get/get.dart';
import 'package:p2tch/app/models/level.dart';
import 'package:p2tch/app/services/level_service.dart';

import '../controllers/level_play_controller.dart';

class LevelPlayBinding extends Bindings {
  @override
  void dependencies() {
    final arguments = Get.arguments;
    String? category;
    int? id;
    LevelData? preloadedData;

    if (arguments is Map) {
      final rawCategory = arguments['category'];
      final rawId = arguments['id'];
      final rawPreloaded = arguments['preloadedLevelData'];
      if (rawCategory is String) category = rawCategory;
      if (rawId is int) id = rawId;
      if (rawPreloaded is LevelData) preloadedData = rawPreloaded;
    }

    // Get.lazyPut() is a no-op if a LevelPlayController is already
    // registered (e.g. navigating level_play -> level_play again for the
    // "Next Level" button) - it won't rebuild with the new arguments unless
    // the stale instance is removed first.
    if (Get.isRegistered<LevelPlayController>()) {
      Get.delete<LevelPlayController>();
    }

    Get.lazyPut<LevelPlayController>(
      () => LevelPlayController(
        category: category,
        id: id,
        levelService: Get.find<LevelService>(),
        preloadedData: preloadedData,
      ),
    );
  }
}
