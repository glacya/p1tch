import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:p2tch/app/constants/audio_constants.dart';
import 'package:p2tch/app/models/audio.dart';

class AudioCache {
  static final AudioCache _instance = AudioCache._internal();
  
  factory AudioCache() => _instance;

  final Map<Timbre, AudioCacheLine> _cache = {};

  AudioCache._internal();

  Future<void> init() async {
    for (Timbre timbre in Timbre.values) {
      _cache[timbre] = AudioCacheLine(timbre);
    }

    Iterable<Future<void>> futures = _cache.values.map((cl) => cl.initSample());

    await Future.wait(futures);
  }

  Audio? findNearestSample(Timbre timbre, double absoluteSemitone) {
    if (!_cache.containsKey(timbre)) {
      return null;
    }

    AudioCacheLine cacheLine = _cache[timbre]!;

    return cacheLine.findNearestSample(absoluteSemitone);
  }
}

class AudioCacheLine {
  final Timbre timbre;
  final List<Audio> samples = [];

  static const String _keys = "F2 A2 C3# F3 A3 C4# F4 A4 C5# F5 A5 C6# F6 A6 C7#";

  AudioCacheLine(this.timbre);

  Future<void> initSample() async {
    samples.clear();
    
    int expectedSamples = (maxSemitoneValue - minSemitoneValue) ~/ sampleSemitoneDiff + 1;
    
    assert((maxSemitoneValue - minSemitoneValue) % sampleSemitoneDiff == 0);

    List<String> keys = _keys.split(' ');

    Iterable<Future<AudioSource>> futures = keys.map((key) async {
      String fileName = '$key.wav';
      final data = await rootBundle.load('assets/audio/${timbre.name}/$fileName');
      final source = await SoLoud.instance.loadMem(fileName, data.buffer.asUint8List());
      return source;
    });

    List<AudioSource> finalSources = await Future.wait(futures);
    assert(finalSources.length == expectedSamples);

    for (int tone = -minSemitoneValue, i = 0; 
        tone <= maxSemitoneValue; 
        tone += sampleSemitoneDiff, i++) {
      
      Audio audio = Audio(timbre, tone.toDouble(), finalSources[i]);
      samples.add(audio);
    }

    assert(samples.length == expectedSamples);
  }

  Audio findNearestSample(double absoluteSemitone) {
    assert(samples.isNotEmpty);

    if (absoluteSemitone >= maxSemitoneValue) {
      return samples.last;
    }
    
    if (absoluteSemitone <= minSemitoneValue) {
      return samples.first;
    }
    
    int integerSemitone = absoluteSemitone.floor();
    int step = sampleSemitoneDiff;
    integerSemitone = (integerSemitone - integerSemitone % step);
    
    int index = (integerSemitone - minSemitoneValue) ~/ step;

    if (absoluteSemitone - integerSemitone < integerSemitone + step - absoluteSemitone) {
      index += 1;
    }

    assert(index * step >= minSemitoneValue && index * step <= maxSemitoneValue);

    return samples[index];
  }
}