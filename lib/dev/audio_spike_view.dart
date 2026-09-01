// import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_soloud/flutter_soloud.dart';

/// Throwaway spike to validate resampling-based pitch shifting (via
/// flutter_soloud's play(scale:)) across the pitch range this game actually
/// needs: any target note is within one octave of its nearest base sample,
/// i.e. a ratio in [sqrt(2)/2, sqrt(2)]. Unlike a duration-preserving shift,
/// resampling changes playback duration along with pitch - that trade-off is
/// accepted in favor of SoLoud's built-in, cross-platform implementation
/// over a custom Web-only DSP path.
/// Not part of the shipped module structure - see CLAUDE.md "Audio" section.
/// Delete once the real audio pipeline replaces it.
class AudioSpikeView extends StatefulWidget {
  const AudioSpikeView({super.key});

  @override
  State<AudioSpikeView> createState() => _AudioSpikeViewState();
}

class _AudioSpikeViewState extends State<AudioSpikeView> {
  static const _fileName = 'piano/a4.wav';
  static final double _minRatio = 1 / 8;
  static final double _maxRatio = 8.0;

  var _status = 'Loading...';
  var _ready = false;
  var _pitchRatio = 1.0;
  AudioSource? _source;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      if (!SoLoud.instance.isInitialized) {
        await SoLoud.instance.init();
      }
      final data = await rootBundle.load('assets/audio/$_fileName');
      debugPrint('Loaded $_fileName (${data.lengthInBytes} bytes)');
      final source = await SoLoud.instance.loadMem(
        _fileName,
        data.buffer.asUint8List(),
      );
      setState(() {
        _source = source;
        _status = 'Loaded $_fileName';
        _ready = true;
      });
    } catch (e) {
      debugPrint('Failed to load $_fileName: $e');
      setState(() => _status = 'Failed to load $_fileName: $e');
    }
  }

  void _play() {
    final source = _source;
    if (source == null) return;

    debugPrint('play(pitchRatio: $_pitchRatio)');
    // Player::play() (the native side of SoLoud.play) always creates the
    // voice internally paused, applies `scale` to it while still paused,
    // and only then unpauses - all inside one synchronous native call. So
    // passing the ratio as `scale` here is atomic: the engine can't ever
    // render a frame at the unshifted speed. Calling play() and then a
    // separate setRelativePlaySpeed() afterwards (what this used to do)
    // reintroduces exactly the gap that guarantee is meant to close, and
    // raced unpredictably.
    SoLoud.instance.play(source, scale: _pitchRatio);
  }

  @override
  void dispose() {
    final source = _source;
    if (source != null) {
      SoLoud.instance.disposeSource(source);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Audio Spike')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(_status),
            const SizedBox(height: 16),
            if (_ready) ...[
              Text(
                'Pitch ratio: ${_pitchRatio.toStringAsFixed(3)}'
                ' (range ${_minRatio.toStringAsFixed(3)}'
                ' ~ ${_maxRatio.toStringAsFixed(3)})',
              ),
              Slider(
                value: _pitchRatio,
                min: _minRatio,
                max: _maxRatio,
                onChanged: (value) => setState(() => _pitchRatio = value),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _play,
                child: const Text('Play at this pitch'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
