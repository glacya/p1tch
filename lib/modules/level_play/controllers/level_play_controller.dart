import 'package:flutter/widgets.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:get/get.dart';
import 'package:p2tch/app/models/level.dart';
import 'package:p2tch/app/routes/app_routes.dart';
import 'package:p2tch/app/services/level_service.dart';

class LevelPlayController extends GetxController {
  LevelPlayController({
    required this.category,
    required this.id,
    required this._levelService,
  });

  final String? category; // null means missing/malformed nav arguments
  final int? id;
  final LevelService _levelService;

  Level? level;
  bool isLoading = true;
  String? errorMessage;

  @override
  void onInit() {
    super.onInit();
    _load();
  }

  Future<void> _load() async {
    if (category == null || id == null) {
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
      final data = await _levelService.loadLevelData(category!, id!);
      if (isClosed) return;
      level = Level()..init(data);
      isLoading = false;
      update();
    } catch (e) {
      if (isClosed) return;
      isLoading = false;
      errorMessage = 'Failed to load level: $e';
      update();
    }
  }

  void retry() => _load();

  /// A plain tap/click on any tile (fixed or not) just plays its sound.
  void onTileTap(int tileId) {
    final currentLevel = level;
    if (currentLevel == null) return;

    final cell = currentLevel.cells[tileId]!;
    SoLoud.instance.play(
      cell.sample.source!,
      scale: cell.sample.frequencyRatio(cell.relativeSemitone),
    );
  }

  /// A tile was dragged from [draggedId] and dropped onto [targetId] - swaps
  /// their board positions. [Level.swap] already no-ops for a same-id drop
  /// or a fixed endpoint, so no extra guard is needed here.
  void onTileDrop(int draggedId, int targetId) {
    final currentLevel = level;
    if (currentLevel == null) return;

    currentLevel.swap(draggedId, targetId);
    if (currentLevel.checkCompleteness()) {
      currentLevel.completed = true;
    }
    update();
  }
}
