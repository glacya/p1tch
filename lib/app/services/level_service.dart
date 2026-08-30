import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:get/get.dart';
import 'package:p2tch/app/models/audio.dart';
import 'package:p2tch/app/models/level.dart';
import 'package:p2tch/app/services/audio_service.dart';

class LevelService extends GetxService {
  final AudioService _audioService;

  LevelService(this._audioService);

  /// Reads `assets/levels/<category>/<id>.json`, and resolves+loads every
  /// tile's [Audio] via [AudioService] so the returned [LevelData] is ready
  /// to hand to [Level.init] directly (which only arranges tiles - it does
  /// not load anything itself).
  Future<LevelData> loadLevelData(String category, int id) async {
    final raw = await rootBundle.loadString(
      'assets/levels/$category/$id.json',
    );
    final json = jsonDecode(raw) as Map<String, dynamic>;

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
      id: json['id'] as int,
      width: json['width'] as int,
      height: json['height'] as int,
      tiles: tiles,
    );
  }
}
