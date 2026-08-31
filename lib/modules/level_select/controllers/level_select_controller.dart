import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:p2tch/app/models/category.dart';
import 'package:p2tch/app/routes/app_routes.dart';
import 'package:p2tch/app/services/level_service.dart';

class LevelSelectController extends GetxController {
  LevelSelectController({
    required this.categoryId,
    required this._levelService,
  });

  final String? categoryId; // null means missing/malformed nav arguments
  final LevelService _levelService;

  Category? category;
  bool isLoading = true;
  String? errorMessage;

  @override
  void onInit() {
    super.onInit();
    _load();
  }

  Future<void> _load() async {
    if (categoryId == null) {
      // No deep linking: an invalid/missing nav argument means this route
      // wasn't reached through the app's own navigation, so send the user
      // back to the start instead of showing an error here. Deferred to
      // after the first frame since onInit() runs before this page has
      // even been pushed - navigating away synchronously here would race
      // the in-flight route transition.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (isClosed) return;
        Get.offAllNamed(Routes.home);
      });
      return;
    }

    isLoading = true;
    errorMessage = null;
    update();

    try {
      final categories = await _levelService.loadCategories();
      if (isClosed) return;
      category = categories.firstWhere((c) => c.categoryId == categoryId);
      isLoading = false;
      update();
    } catch (e) {
      if (isClosed) return;
      isLoading = false;
      errorMessage = 'Failed to load levels: $e';
      update();
    }
  }

  void retry() => _load();
}
