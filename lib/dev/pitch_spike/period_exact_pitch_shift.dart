import 'dart:math' as math;
import 'dart:typed_data';

/// Period-exact grain resynthesis pitch shift for a single near-stationary
/// tone whose fundamental frequency is already known (not detected).
///
/// See CLAUDE.md "Audio" section: WSOLA's correlation search is structurally
/// ambiguous on pure periodic content (many near-tied splice candidates
/// spaced by the period), which is what produced audible noise even at tiny
/// shifts with SoundTouch. This sidesteps the search entirely - since the
/// period is known exactly, grains are extracted and replaced at exact
/// period boundaries rather than a "best guess" offset.
///
/// Pure Dart, array math only - no platform/Web dependency. Only the
/// decode/playback around this needs a platform backend.
class PeriodExactPitchShifter {
  /// Repeats one Hann-windowed grain (extracted past the attack transient)
  /// at the target period, for the same total length as [samples], then
  /// reapplies the source's own amplitude envelope so the natural
  /// attack/decay shape survives even though only one grain is reused.
  static Float32List shift({
    required Float32List samples,
    required double sampleRate,
    required double sourceFrequencyHz,
    required double pitchRatio,
  }) {
    if (samples.isEmpty) return samples;

    final sourcePeriod = sampleRate / sourceFrequencyHz;
    final targetPeriod = sourcePeriod / pitchRatio;

    final envelope = _extractEnvelope(samples, sourcePeriod);
    final grain = _extractGrain(samples, sourcePeriod, envelope);

    final output = Float32List(samples.length);
    final coverage = Float32List(samples.length);

    var center = 0.0;
    while (center - grain.length / 2 < samples.length) {
      _addWindowedGrain(output, coverage, grain, center);
      center += targetPeriod;
    }

    // Flatten overlap-add gain ripple, then restore the original envelope.
    for (var i = 0; i < output.length; i++) {
      final flattened = coverage[i] > 1e-6 ? output[i] / coverage[i] : 0.0;
      output[i] = flattened * envelope[i];
    }
    return output;
  }

  /// Extracts one ~2-period grain, windowed with a Hann window so repeated
  /// copies overlap-add smoothly with no phase-alignment search needed.
  ///
  /// The extracted samples are divided by the source's own envelope at that
  /// point first, so the grain is a roughly unit-amplitude "shape" - the
  /// amplitude information lives entirely in [envelope] and gets reapplied
  /// once, in [shift]. Skipping this normalization would mean the raw
  /// samples (which already carry that point's amplitude) get multiplied by
  /// the envelope a second time later, squaring the effective gain.
  static Float32List _extractGrain(
    Float32List samples,
    double sourcePeriod,
    Float32List envelope,
  ) {
    final length = math.max(4, (sourcePeriod * 2).round());
    // Skip past a few periods so the grain is clear of any attack
    // transient; clamp so short samples still produce something.
    final start = math.min(
      (sourcePeriod * 4).round(),
      math.max(0, samples.length - length),
    );
    final referenceEnvelope = start < envelope.length && envelope[start] > 1e-6
        ? envelope[start]
        : 1.0;
    final grain = Float32List(length);
    for (var i = 0; i < length; i++) {
      final srcIndex = start + i;
      final s = srcIndex < samples.length ? samples[srcIndex] : 0.0;
      grain[i] = (s / referenceEnvelope) * _hannWeight(i, length);
    }
    return grain;
  }

  static void _addWindowedGrain(
    Float32List output,
    Float32List coverage,
    Float32List grain,
    double center,
  ) {
    final start = (center - grain.length / 2).round();
    for (var i = 0; i < grain.length; i++) {
      final dst = start + i;
      if (dst < 0 || dst >= output.length) continue;
      output[dst] += grain[i];
      coverage[dst] += _hannWeight(i, grain.length);
    }
  }

  static double _hannWeight(int i, int length) =>
      0.5 - 0.5 * math.cos(2 * math.pi * i / (length - 1));

  /// Coarse amplitude envelope: a moving average of the rectified signal
  /// over a few source periods, so individual cycles average out but the
  /// attack/decay shape survives.
  static Float32List _extractEnvelope(Float32List samples, double period) {
    final window = math.max(1, (period * 3).round());
    final envelope = Float32List(samples.length);
    var sum = 0.0;
    for (var i = 0; i < samples.length; i++) {
      sum += samples[i].abs();
      if (i >= window) sum -= samples[i - window].abs();
      final count = math.min(i + 1, window);
      envelope[i] = sum / count * math.sqrt2; // rough RMS-ish scaling
    }
    return envelope;
  }
}
