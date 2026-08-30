import 'package:p2tch/app/models/audio.dart';

class Level {
  late String category;
  late int id;
  late int width;
  late int height;

  bool completed = false;
  final Map<(int, int), LevelCell> cells = {};
  final Map<(int, int), double> _solution = {};

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
    _solution.clear();

    category = data.category;
    id = data.id;
    width = data.width;
    height = data.height;

    for (final tile in data.tiles) {
      _solution[(tile.x, tile.y)] = tile.semitone;
    }

    final fixedTiles = data.tiles.where((t) => t.fixed);
    for (final tile in fixedTiles) {
      cells[(tile.x, tile.y)] = LevelCell(tile.semitone, tile.audio, true);
    }

    final nonFixedTiles = data.tiles.where((t) => !t.fixed).toList();
    final coords = nonFixedTiles.map((t) => (t.x, t.y)).toList();
    final shuffled = _shuffledNonFixedTiles(nonFixedTiles);

    for (var i = 0; i < nonFixedTiles.length; i++) {
      final tile = shuffled[i];
      cells[coords[i]] = LevelCell(tile.semitone, tile.audio, false);
    }
  }

  /// Shuffles [nonFixedTiles]' values among themselves (coordinates are
  /// assigned by the caller in original order - only the values move),
  /// rejecting any shuffle that leaves more than `nonFixedTiles.length ~/ 8`
  /// tiles landing back on their own original index.
  ///
  /// For exactly 1 non-fixed tile this bound is 0, which is unsatisfiable
  /// (a single-element shuffle always "lands on itself"). That's a degenerate
  /// level design (nothing to actually solve), so it's left unshuffled
  /// rather than looping forever - flag such levels separately if needed.
  static List<LevelTileData> _shuffledNonFixedTiles(
    List<LevelTileData> nonFixedTiles,
  ) {
    final n = nonFixedTiles.length;
    if (n <= 1) {
      return nonFixedTiles;
    }

    final maxAllowedMatches = n ~/ 8;
    final shuffled = List<LevelTileData>.of(nonFixedTiles);
    do {
      shuffled.shuffle();
    } while (_countMatches(nonFixedTiles, shuffled) > maxAllowedMatches);

    return shuffled;
  }

  static int _countMatches(
    List<LevelTileData> original,
    List<LevelTileData> shuffled,
  ) {
    var count = 0;
    for (var i = 0; i < original.length; i++) {
      if (identical(original[i], shuffled[i])) {
        count++;
      }
    }
    return count;
  }

  bool checkCompleteness() {
    return _solution.entries.every(
      (entry) => cells[entry.key]?.relativeSemitone == entry.value,
    );
  }

  bool swap((int, int) c1, (int, int) c2) {
    assert(cells.containsKey(c1) && cells.containsKey(c2));

    if (c1 == c2) {
      return false;
    }

    final (a, b) = (cells[c1]!, cells[c2]!);

    if (a.fixed || b.fixed) {
      return false;
    }

    cells[c1] = b;
    cells[c2] = a;

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
/// - see that file for the exact shape. [LevelTileData.audio] is not part of
/// the JSON: [LevelService] resolves it via [AudioService] while building
/// this, so it is already loaded (`source != null`) by the time [Level.init]
/// runs.
class LevelData {
  final String category;
  final int id;
  final int width;
  final int height;
  final List<LevelTileData> tiles;

  LevelData({
    required this.category,
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
