import 'dart:js_interop';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:web/web.dart' as web;

import 'period_exact_pitch_shift.dart';
import 'pitch_player.dart';

/// Fixed for this spike - a4.wav is a 440Hz base sample. See CLAUDE.md
/// "Audio" for the base-sample table (A2..A6).
const _sourceFrequencyHz = 440.0;

PitchPlayer createPeriodExactPlayer() => _PeriodExactWebPlayer();

/// Decodes the WAV, runs [PeriodExactPitchShifter] once (a discrete,
/// non-realtime computation - unlike SoundTouch's AudioWorklet, which
/// processes continuously while the sound plays), builds a fresh AudioBuffer
/// from the result, and plays it directly - no worklet/live filtering
/// involved at playback time. [tuning] is ignored; it's WSOLA-specific.
class _PeriodExactWebPlayer implements PitchPlayer {
  web.AudioContext? _context;

  web.AudioContext _ensureContext() => _context ??= web.AudioContext();

  @override
  Future<void> playPitched(
    ByteBuffer wavBytes,
    double pitchRatio, {
    StretchTuning? tuning,
  }) async {
    final context = _ensureContext();
    final bench = Stopwatch()..start();

    final decoded = await context.decodeAudioData(wavBytes.toJS).toDart;
    debugPrint('[bench] decodeAudioData: ${bench.elapsedMilliseconds}ms');

    final sourceSamples = decoded.getChannelData(0).toDart;

    final shiftStart = bench.elapsedMilliseconds;
    final shifted = PeriodExactPitchShifter.shift(
      samples: sourceSamples,
      sampleRate: decoded.sampleRate,
      sourceFrequencyHz: _sourceFrequencyHz,
      pitchRatio: pitchRatio,
    );
    debugPrint(
      '[bench] PeriodExactPitchShifter.shift: '
      '${bench.elapsedMilliseconds - shiftStart}ms '
      '(${sourceSamples.length} samples)',
    );

    final outputBuffer = context.createBuffer(
      1,
      shifted.length,
      decoded.sampleRate,
    );
    outputBuffer.copyToChannel(shifted.toJS, 0);

    final source = context.createBufferSource();
    source.buffer = outputBuffer;
    source.connect(context.destination);
    source.start();
    debugPrint('[bench] total: ${bench.elapsedMilliseconds}ms');
  }
}
