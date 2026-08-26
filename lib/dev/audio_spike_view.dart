import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import 'pitch_spike/period_exact_player_factory.dart';
import 'pitch_spike/pitch_player.dart';
import 'pitch_spike/pitch_player_factory.dart';

enum _Engine { soundTouch, periodExact }

/// Throwaway spike to validate duration-preserving pitch shifting (via
/// SoundTouchJS over the Web Audio API - see pitch_spike/) across the pitch
/// range this game actually needs: any target note is within one octave of
/// its nearest base sample, i.e. a ratio in [sqrt(2)/2, sqrt(2)]. Also lets
/// the WSOLA timing knobs (sequence/seekWindow/overlap/quickSeek) be tuned
/// live, since defaults are sized for music-length material, not a short
/// blip sample.
/// Not part of the shipped module structure - see CLAUDE.md "Audio" section.
/// Delete once the real audio pipeline replaces it.
class AudioSpikeView extends StatefulWidget {
  const AudioSpikeView({super.key});

  @override
  State<AudioSpikeView> createState() => _AudioSpikeViewState();
}

class _AudioSpikeViewState extends State<AudioSpikeView> {
  static const _fileName = 'a4.wav';
  static final _minRatio = math.sqrt2 / 2;
  static final _maxRatio = math.sqrt2;

  // 440Hz's own period. Used as the starting point for seekWindowMs/
  // overlapMs so the WSOLA search space is bounded to ~1 period instead of
  // the auto-computed ~15-20ms default, which spans many periods and is
  // exactly what made the correlation search ambiguous on this material.
  static const _a4PeriodMs = 8000 / 440;

  final PitchPlayer _soundTouchPlayer = createPitchPlayer();
  final PitchPlayer _periodExactPlayer = createPeriodExactPlayer();
  var _engine = _Engine.soundTouch;

  var _status = 'Loading...';
  var _ready = false;
  var _pitchRatio = 1.0;
  Uint8List? _wavBytes;

  var _sequenceMs = _a4PeriodMs * 6;
  var _seekWindowMs = _a4PeriodMs;
  var _overlapMs = _a4PeriodMs;
  var _quickSeek = false;

  void _snapToA4Period() {
    setState(() {
      _sequenceMs = _a4PeriodMs * 6;
      _seekWindowMs = _a4PeriodMs;
      _overlapMs = _a4PeriodMs;
    });
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await rootBundle.load('assets/audio/$_fileName');
      debugPrint('Loaded $_fileName (${data.lengthInBytes} bytes)');
      setState(() {
        _wavBytes = data.buffer.asUint8List();
        _status = 'Loaded $_fileName';
        _ready = true;
      });
    } catch (e) {
      debugPrint('Failed to load $_fileName: $e');
      setState(() => _status = 'Failed to load $_fileName: $e');
    }
  }

  Future<void> _play() async {
    final bytes = _wavBytes;
    if (bytes == null) return;

    final player = switch (_engine) {
      _Engine.soundTouch => _soundTouchPlayer,
      _Engine.periodExact => _periodExactPlayer,
    };
    final tuning = _engine == _Engine.soundTouch
        ? StretchTuning(
            sequenceMs: _sequenceMs,
            seekWindowMs: _seekWindowMs,
            overlapMs: _overlapMs,
            quickSeek: _quickSeek,
          )
        : null;
    debugPrint('play(engine: $_engine, pitchRatio: $_pitchRatio)');
    try {
      // A fresh copy per play, since Web Audio's decodeAudioData detaches
      // (consumes) the ArrayBuffer it's given.
      final copy = Uint8List.fromList(bytes);
      await player.playPitched(copy.buffer, _pitchRatio, tuning: tuning);
    } catch (e) {
      debugPrint('playPitched failed: $e');
      setState(() => _status = 'playPitched failed: $e');
    }
  }

  Widget _tuningSlider({
    required String label,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 150,
          child: Text('$label: ${value.toStringAsFixed(1)}ms'),
        ),
        Expanded(
          child: Slider(
            value: value,
            min: min,
            max: max,
            onChanged: onChanged,
          ),
        ),
      ],
    );
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
              SegmentedButton<_Engine>(
                segments: const [
                  ButtonSegment(
                    value: _Engine.soundTouch,
                    label: Text('SoundTouch (WSOLA)'),
                  ),
                  ButtonSegment(
                    value: _Engine.periodExact,
                    label: Text('Period-exact (custom)'),
                  ),
                ],
                selected: {_engine},
                onSelectionChanged: (selection) =>
                    setState(() => _engine = selection.first),
              ),
              const SizedBox(height: 16),
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
              if (_engine == _Engine.soundTouch) ...[
                const Divider(height: 32),
                const Text('WSOLA tuning (Stretch.setStretchParameters)'),
                OutlinedButton(
                  onPressed: _snapToA4Period,
                  child: Text(
                    'Snap seekWindow/overlap to 1 period '
                    '(${_a4PeriodMs.toStringAsFixed(3)}ms @ 440Hz)',
                  ),
                ),
                _tuningSlider(
                  label: 'sequenceMs',
                  value: _sequenceMs,
                  min: 2,
                  max: 150,
                  onChanged: (v) => setState(() => _sequenceMs = v),
                ),
                _tuningSlider(
                  label: 'seekWindowMs',
                  value: _seekWindowMs,
                  min: 0.5,
                  max: 30,
                  onChanged: (v) => setState(() => _seekWindowMs = v),
                ),
                _tuningSlider(
                  label: 'overlapMs',
                  value: _overlapMs,
                  min: 0.5,
                  max: 20,
                  onChanged: (v) => setState(() => _overlapMs = v),
                ),
                SwitchListTile(
                  title: const Text('quickSeek (off = exhaustive search)'),
                  value: _quickSeek,
                  onChanged: (v) => setState(() => _quickSeek = v),
                ),
              ],
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
