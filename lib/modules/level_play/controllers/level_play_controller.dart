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

  /// Whether a new drag can start right now.
  bool canDrag = true;

  /// Tiles still mid-slide after the most recent swap (swap always moves
  /// exactly 2 tiles to different coordinates, so a successful swap starts
  /// this at 2). canDrag stays locked until this reaches 0.
  int _animatingCount = 0;

  /// Whether the completion celebration sequence has already been started
  /// for this completion. Lives here for the same reason as
  /// canDrag/_animatingCount.
  bool completionSequenceStarted = false;

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
      canDrag = true;
      _animatingCount = 0;
      completionSequenceStarted = false;
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

  /// A plain tap/click on any tile (fixed or not) plays its sound - but not
  /// once the level is completed, since the completion sequence takes over
  /// tile playback from that point (and dragging is already locked via
  /// canDrag by then).
  void onTileTap(int tileId) {
    final currentLevel = level;
    if (currentLevel == null || currentLevel.completed) return;
    playTileSound(tileId);
  }

  /// Plays [tileId]'s sound unconditionally - used by onTileTap and by the
  /// view's completion celebration sequence (which must still play sounds
  /// after completed is already true).
  void playTileSound(int tileId) {
    final currentLevel = level;
    if (currentLevel == null) return;
    final cell = currentLevel.cells[tileId]!;
    SoLoud.instance.play(
      cell.sample.source!,
      scale: cell.sample.frequencyRatio(cell.relativeSemitone),
    );
  }

  void onDragStarted() {
    canDrag = false;
    update();
  }

  void onDragCanceled() {
    final currentLevel = level;
    if (currentLevel == null || currentLevel.completed) return;
    canDrag = true;
    update();
  }

  /// A tile was dragged from [draggedId] and dropped onto [targetId] - swaps
  /// their board positions. [Level.swap] already no-ops for a same-id drop
  /// or a fixed endpoint, so no extra guard is needed here.
  void onTileDrop(int draggedId, int targetId) {
    final currentLevel = level;
    if (currentLevel == null) return;

    final moved = currentLevel.swap(draggedId, targetId);
    if (moved) {
      _animatingCount = 2;
      if (currentLevel.checkCompleteness()) {
        currentLevel.completed = true;
      }
    } else {
      // onWillAcceptWithDetails already filters these out, so this
      // shouldn't normally be reached - but if it is, release the lock
      // onDragStarted set, since no animation will follow to release it.
      canDrag = !currentLevel.completed;
    }
    update();
  }

  /// A tile's AnimatedPositioned finished sliding into place after a swap.
  void onTileMoveAnimationEnd() {
    final currentLevel = level;
    if (currentLevel == null) return;

    if (_animatingCount > 0) _animatingCount--;
    if (_animatingCount == 0 && !currentLevel.completed) {
      canDrag = true;
    }
    update();
  }
}
