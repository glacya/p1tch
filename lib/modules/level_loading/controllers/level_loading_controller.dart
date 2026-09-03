import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:p2tch/app/models/level.dart';
import 'package:p2tch/app/routes/app_routes.dart';
import 'package:p2tch/app/services/level_service.dart';

class LevelLoadingController extends GetxController {
  LevelLoadingController({
    required this.category,
    required this.id,
    required this._levelService,
  });

  final String? category; // null means missing/malformed nav arguments
  final int? id;
  final LevelService _levelService;

  static const _minDisplayDuration = Duration(milliseconds: 1500);
  static const _timeout = Duration(seconds: 10);
  static const _fadeOutHoldDuration = Duration(milliseconds: 500);

  bool isFadingOut = false;

  @override
  void onInit() {
    super.onInit();
    _load();
  }

  Future<void> _load() async {
    if (category == null || id == null) {
      // Deny deep linking
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (isClosed) return;
        Get.offAllNamed(Routes.home);
      });
      return;
    }

    final stopwatch = Stopwatch()..start();

    LevelData? data;
    try {
      data = await _levelService.loadLevelData(category!, id!).timeout(_timeout);
    } catch (_) {
      data = null;
    }

    if (isClosed) return;

    if (data == null) {
      Get.offNamed(
        Routes.levelSelect,
        arguments: <String, dynamic>{'categoryId': category},
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showLoadFailedDialog();
      });
      return;
    }

    final remaining = _minDisplayDuration - stopwatch.elapsed;
    if (remaining > Duration.zero) {
      await Future.delayed(remaining);
    }
    if (isClosed) return;

    isFadingOut = true;
    update();

    await Future.delayed(_fadeOutHoldDuration);
    if (isClosed) return;

    Get.offNamed(
      Routes.levelPlay,
      arguments: <String, dynamic>{
        'category': category,
        'id': id,
        'preloadedLevelData': data,
      },
    );
  }

  void _showLoadFailedDialog() {
    Get.dialog<void>(
      Dialog(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Failed to load the level.'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Get.back(),
                child: const Text('OK'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
