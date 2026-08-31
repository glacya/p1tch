import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:get/get.dart';
import 'package:p2tch/app/constants/level_constants.dart';
import 'package:p2tch/app/models/audio.dart';
import 'package:p2tch/app/models/category.dart';
import 'package:p2tch/app/models/level.dart';
import 'package:p2tch/app/services/audio_service.dart';

class LevelService extends GetxService {
  final AudioService _audioService;

  LevelService(this._audioService);

  List<Category>? _categories;

  /// Cached category list, or empty until [loadCategories] has resolved at
  /// least once.
  List<Category> get categories => _categories ?? const [];

  /// Reads `assets/levels/<category>/<id>.json`, and resolves+loads every
  /// tile's [Audio] via [AudioService] so the returned [LevelData] is ready
  /// to hand to [Level.init] directly (which only arranges tiles - it does
  /// not load anything itself).
  Future<LevelData> loadLevelData(String category, int id) async {
    final raw = await rootBundle.loadString(
      'assets/levels/$category/$id.json',
    );
    final json = jsonDecode(raw) as Map<String, dynamic>;

    final categories = await loadCategories();
    final categoryInfo = categories.firstWhere(
      (c) => c.categoryId == category,
    );

    final rawTiles = (json['tiles'] as List).cast<Map<String, dynamic>>();
    final tiles = <LevelTileData>[];
    for (final rawTile in rawTiles) {
      final timbre = Timbre.values.byName(rawTile['timbre'] as String);
      final semitone = (rawTile['semitone'] as num).toDouble();
      final audio = await _audioService.findNearestEntry(timbre, semitone);

      tiles.add(
        LevelTileData(
          x: rawTile['x'] as int,
          y: rawTile['y'] as int,
          semitone: semitone,
          timbre: timbre,
          fixed: rawTile['fixed'] as bool,
          audio: audio,
        ),
      );
    }

    return LevelData(
      category: json['category'] as String,
      categoryInfo: categoryInfo,
      id: json['id'] as int,
      width: json['width'] as int,
      height: json['height'] as int,
      tiles: tiles,
    );
  }

  /// Reads and caches `assets/levels/category.json`. Idempotent - safe to
  /// call from multiple entry points; only reads the
  /// asset once.
  Future<List<Category>> loadCategories() async {
    final cached = _categories;
    if (cached != null) return cached;

    final raw = await rootBundle.loadString('assets/levels/category.json');
    final json = jsonDecode(raw) as List;
    final categories =
        json.cast<Map<String, dynamic>>().map(Category.fromJson).toList()
          ..sort((a, b) => a.categoryOrder.compareTo(b.categoryOrder));

    if (categories.length > maxCategoryCount) {
      throw FormatException(
        'Too many categories (${categories.length} > $maxCategoryCount)',
      );
    }
    for (final category in categories) {
      if (category.levels > maxLevelsPerCategory) {
        throw FormatException(
          'Category ${category.categoryId} has too many levels '
          '(${category.levels} > $maxLevelsPerCategory)',
        );
      }
    }

    _categories = categories;
    return categories;
  }
}
