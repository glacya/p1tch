import 'package:p2tch/app/models/audio.dart';

abstract class Level {
  bool completed = false;
  // Consider rectangular board only, for now..
  // final LevelLayout layout;
  // final List<(int, int)> fixedPoints;
  final Map<(int, int), LevelCell> cells = {};

  // Level(this.layout, this.fixedPoints);
  Level();

  // NOTE that the board would follow the ordering:
  // (0, 2) (1, 2) (2, 2)
  // (0, 1) (1, 1) (2, 1)
  // (0, 0) (1, 0) (2, 0)
  // even in graphic context.
  // ...
  // But well, actually it doesn't matter though. But setting axes correctly is important.
  void init();

  bool checkCompleteness();

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

class RectangularLevel extends Level {
  final int boardX;
  final int boardY;
  final bool incrementX;
  final bool incrementY;

  RectangularLevel(this.boardX, this.boardY, this.incrementX, this.incrementY, fixedPoints)
    : super();

  @override
  void init() {
    cells.clear();

    // TODO: Load data from json and intialize data.
  }

  @override
  bool checkCompleteness() {
    for (int i = 0; i < boardX; i++) {
      for (int j = 0; j < boardY; j++) {
        // TODO
      }
    }

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

class LevelData {

}

enum LevelLayout {
  rectangular,
}