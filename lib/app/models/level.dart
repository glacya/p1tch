import 'package:p2tch/app/models/audio.dart';
import 'package:p2tch/app/models/category.dart';

class Level {
  late Category category;
  late int id;
  late int width;
  late int height;

  bool completed = false;

  /// Tile content, keyed by a stable per-tile id (its index in
  /// [LevelData.tiles]). Never changes after [init] - only [positions] moves
  /// during a shuffle/swap. This is also the id a widget should key itself
  /// on so implicit position animations (e.g. AnimatedPositioned) track the
  /// right tile across a swap.
  final Map<int, LevelCell> cells = {};

  /// Each tile's current board coordinate, by id. The only thing [swap]
  /// mutates.
  final Map<int, (int, int)> positions = {};

  /// Each tile's target ("solved") coordinate, by id.
  final Map<int, (int, int)> _solution = {};

  Level();

  // NOTE that the board would follow the ordering:
  // (0, 2) (1, 2) (2, 2)
  // (0, 1) (1, 1) (2, 1)
  // (0, 0) (1, 0) (2, 0)
  // even in graphic context.
  // ...
  // But well, actually it doesn't matter though. But setting axes correctly is important.
  //
  // [data] must already carry loaded [Audio] (source != null) per tile - see
  // [LevelCell]'s constructor assertion. This only arranges them; it does not
  // load anything itself.
  void init(LevelData data) {
    cells.clear();
    positions.clear();
    _solution.clear();

    category = data.categoryInfo;
    id = data.id;
    width = data.width;
    height = data.height;

    for (var i = 0; i < data.tiles.length; i++) {
      final tile = data.tiles[i];
      cells[i] = LevelCell(tile.semitone, tile.audio, tile.fixed);
      _solution[i] = (tile.x, tile.y);
    }

    for (var i = 0; i < data.tiles.length; i++) {
      if (data.tiles[i].fixed) {
        positions[i] = _solution[i]!;
      }
    }

    final nonFixedIds = [
      for (var i = 0; i < data.tiles.length; i++)
        if (!data.tiles[i].fixed) i,
    ];
    final nonFixedCoords = nonFixedIds.map((i) => _solution[i]!).toList();
    final shuffledIds = _shuffledIds(nonFixedIds);

    for (var i = 0; i < nonFixedIds.length; i++) {
      positions[shuffledIds[i]] = nonFixedCoords[i];
    }
  }

  /// Shuffles [ids] (a copy - the input list is left untouched), rejecting
  /// any permutation that leaves more than `ids.length ~/ 8` entries at
  /// their original index - i.e. more than that many tiles would start
  /// already on their own solved coordinate.
  ///
  /// For exactly 1 id this bound is 0, which is unsatisfiable (a single-
  /// element shuffle always "lands on itself"). That's a degenerate level
  /// design (nothing to actually solve), so it's left unshuffled rather
  /// than looping forever - flag such levels separately if needed.
  static List<int> _shuffledIds(List<int> ids) {
    final n = ids.length;
    if (n <= 1) {
      return ids;
    }

    final maxAllowedMatches = n ~/ 8;
    final shuffled = List<int>.of(ids);
    do {
      shuffled.shuffle();
    } while (_countMatches(ids, shuffled) > maxAllowedMatches);

    return shuffled;
  }

  static int _countMatches(List<int> original, List<int> shuffled) {
    var count = 0;
    for (var i = 0; i < original.length; i++) {
      if (original[i] == shuffled[i]) {
        count++;
      }
    }
    return count;
  }

  bool checkCompleteness() {
    return positions.entries.every((entry) => entry.value == _solution[entry.key]);
  }

  bool swap(int id1, int id2) {
    assert(positions.containsKey(id1) && positions.containsKey(id2));

    if (id1 == id2) {
      return false;
    }

    if (cells[id1]!.fixed || cells[id2]!.fixed) {
      return false;
    }

    final (a, b) = (positions[id1]!, positions[id2]!);
    positions[id1] = b;
    positions[id2] = a;

    return true;
  }
}

class LevelCell {
  final double relativeSemitone;
  final Audio sample;
  final bool fixed;

  Timbre get timbre => sample.timbre;

  LevelCell(this.relativeSemitone, this.sample, this.fixed) {
    assert(sample.source != null);
  }
}

/// Plain mirror of a level's JSON file (`assets/levels/<category>/<id>.json`)
/// - see that file for the exact shape. [LevelTileData.audio] and
/// [categoryInfo] are not part of the JSON: [LevelService] resolves them
/// (via [AudioService] and its own category cache respectively) while
/// building this, so both are already loaded/available by the time
/// [Level.init] runs.
class LevelData {
  final String category;
  final Category categoryInfo;
  final int id;
  final int width;
  final int height;
  final List<LevelTileData> tiles;

  LevelData({
    required this.category,
    required this.categoryInfo,
    required this.id,
    required this.width,
    required this.height,
    required this.tiles,
  });
}

class LevelTileData {
  final int x;
  final int y;
  final double semitone;
  final Timbre timbre;
  final bool fixed;
  final Audio audio;

  LevelTileData({
    required this.x,
    required this.y,
    required this.semitone,
    required this.timbre,
    required this.fixed,
    required this.audio,
  });
}
