import 'dart:typed_data';

import 'pitch_player.dart';

PitchPlayer createPitchPlayer() => _StubPitchPlayer();

class _StubPitchPlayer implements PitchPlayer {
  @override
  Future<void> playPitched(
    ByteBuffer wavBytes,
    double pitchRatio, {
    StretchTuning? tuning,
  }) {
    throw UnsupportedError('PitchPlayer is only implemented for Web so far.');
  }
}
