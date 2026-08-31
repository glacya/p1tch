import 'package:get/get.dart';
import 'package:p2tch/app/models/category.dart';
import 'package:p2tch/app/services/level_service.dart';

class LevelCategoryController extends GetxController {
  LevelCategoryController({required this._levelService});

  final LevelService _levelService;

  List<Category> categories = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void onInit() {
    super.onInit();
    _load();
  }

  Future<void> _load() async {
    isLoading = true;
    errorMessage = null;
    update();

    try {
      final loaded = await _levelService.loadCategories();
      if (isClosed) return;
      categories = loaded;
      isLoading = false;
      update();
    } catch (e) {
      if (isClosed) return;
      isLoading = false;
      errorMessage = 'Failed to load categories: $e';
      update();
    }
  }

  void retry() => _load();
}
