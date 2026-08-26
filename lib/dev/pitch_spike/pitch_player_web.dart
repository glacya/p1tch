import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:web/web.dart' as web;

import 'pitch_player.dart';

PitchPlayer createPitchPlayer() => _WebPitchPlayer();

/// Loads a WAV into the Web Audio API and routes it through the SoundTouchJS
/// AudioWorklet processor (served from web/soundtouch-processor.js, registered
/// under the name "soundtouch-processor") to shift its pitch without changing
/// duration - setting only the `pitch` AudioParam leaves `playbackRate`/`tempo`
/// at their defaults, which is what keeps duration constant.
///
/// The pitch/duration transform itself runs continuously on the audio render
/// thread while the sound plays, so it isn't a discrete step we can time from
/// here - what the benchmarking below measures is Dart/main-thread setup
/// latency (decode + graph wiring), which is what a caching strategy would
/// actually be trying to avoid paying on every play.
class _WebPitchPlayer implements PitchPlayer {
  web.AudioContext? _context;
  Future<void>? _workletReady;

  Future<web.AudioContext> _ensureContext() async {
    final context = _context ??= web.AudioContext();
    _workletReady ??= context.audioWorklet
        .addModule('soundtouch-processor.js')
        .toDart
        .then((_) => debugPrint('soundtouch-processor.js module added'))
        .catchError((e) {
          debugPrint('addModule failed: $e');
          throw e;
        });
    await _workletReady;
    return context;
  }

  @override
  Future<void> playPitched(
    ByteBuffer wavBytes,
    double pitchRatio, {
    StretchTuning? tuning,
  }) async {
    final bench = Stopwatch()..start();
    final context = await _ensureContext();
    debugPrint('[bench] context/worklet ready: ${bench.elapsedMilliseconds}ms');

    final audioBuffer = await context.decodeAudioData(wavBytes.toJS).toDart;
    debugPrint('[bench] decodeAudioData: ${bench.elapsedMilliseconds}ms');

    final source = context.createBufferSource();
    source.buffer = audioBuffer;

    final worklet = web.AudioWorkletNode(context, 'soundtouch-processor');
    worklet.onprocessorerror = (web.Event event) {
      debugPrint('soundtouch-processor errored: $event');
    }.toJS;

    // AudioParamMap is a JS Map-like: its entries live behind real .get()/
    // .has() methods, not as plain object properties, so this must go
    // through callMethod rather than getProperty/has (dart:js_interop_unsafe's
    // package:web binding for AudioParamMap is an empty JSObject wrapper).
    final hasPitch = worklet.parameters
        .callMethod<JSBoolean>('has'.toJS, 'pitch'.toJS)
        .toDart;
    if (!hasPitch) {
      throw StateError(
        'AudioWorkletNode has no "pitch" param - the processor did not '
        'register correctly. Check the DevTools Network tab for the request '
        'to soundtouch-processor.js (status + Content-Type) and the Console '
        'for a separate processorerror/registration warning.',
      );
    }
    final pitchParam = worklet.parameters.callMethod<web.AudioParam>(
      'get'.toJS,
      'pitch'.toJS,
    );
    pitchParam.value = pitchRatio;

    if (tuning != null) {
      worklet.port.postMessage(_stretchParametersMessage(tuning));
    }

    source.connect(worklet);
    worklet.connect(context.destination);
    source.start();
    debugPrint('[bench] graph wired + start() called: '
        '${bench.elapsedMilliseconds}ms (total)');
  }

  /// Builds `{ type: 'set-stretch-parameters', params: {...} }`, matching the
  /// message shape SoundTouchProcessorBase.port.onmessage expects (see
  /// web/soundtouch-processor.js). Only non-null [tuning] fields are set, so
  /// the rest stay at whatever SoundTouch currently has them at.
  JSObject _stretchParametersMessage(StretchTuning tuning) {
    final params = JSObject();
    if (tuning.sequenceMs != null) {
      params.setProperty('sequenceMs'.toJS, tuning.sequenceMs!.toJS);
    }
    if (tuning.seekWindowMs != null) {
      params.setProperty('seekWindowMs'.toJS, tuning.seekWindowMs!.toJS);
    }
    if (tuning.overlapMs != null) {
      params.setProperty('overlapMs'.toJS, tuning.overlapMs!.toJS);
    }
    if (tuning.quickSeek != null) {
      params.setProperty('quickSeek'.toJS, tuning.quickSeek!.toJS);
    }

    final message = JSObject();
    message.setProperty('type'.toJS, 'set-stretch-parameters'.toJS);
    message.setProperty('params'.toJS, params);
    return message;
  }
}
