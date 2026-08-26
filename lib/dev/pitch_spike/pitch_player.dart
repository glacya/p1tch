import 'dart:typed_data';

/// WSOLA timing knobs exposed by SoundTouch's `Stretch` stage
/// (see web/soundtouch-processor.js - `Stretch.setStretchParameters`).
/// Null fields are left at SoundTouch's current/auto value.
class StretchTuning {
  const StretchTuning({
    this.sequenceMs,
    this.seekWindowMs,
    this.overlapMs,
    this.quickSeek,
  });

  final double? sequenceMs;
  final double? seekWindowMs;
  final double? overlapMs;
  final bool? quickSeek;
}

/// Plays a WAV buffer with its pitch shifted by [pitchRatio] (1.0 = original
/// pitch) while preserving duration. Only implemented for Web so far - see
/// CLAUDE.md "Audio" section for why (SoundTouchJS via the Web Audio API).
abstract class PitchPlayer {
  Future<void> playPitched(
    ByteBuffer wavBytes,
    double pitchRatio, {
    StretchTuning? tuning,
  });
}
