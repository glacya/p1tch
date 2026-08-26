import 'dart:typed_data';

import 'pitch_player.dart';

PitchPlayer createPeriodExactPlayer() => _StubPeriodExactPlayer();

class _StubPeriodExactPlayer implements PitchPlayer {
  @override
  Future<void> playPitched(
    ByteBuffer wavBytes,
    double pitchRatio, {
    StretchTuning? tuning,
  }) {
    throw UnsupportedError(
      'PeriodExactPlayer playback is only implemented for Web so far '
      '(the shift math itself is portable, only decode/playback isn\'t).',
    );
  }
}
