import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:p2tch/app/constants/audio_constants.dart';
import 'package:p2tch/app/constants/cache_constants.dart';
import 'package:p2tch/app/models/audio.dart';

class AudioCache {
  final Map<Timbre, AudioCacheLine> _cache = {};
  int _loaded = 0;

  bool get isFull => _loaded == maxAudioCached;

  Future<void> init() {
    if (_cache.isEmpty) {
      return _init();
    }

    return Future.value();
  }

  Future<void> _init() async {
    for (Timbre timbre in Timbre.values) {
      _cache[timbre] = AudioCacheLine(timbre);
    }

    Iterable<Future<void>> futures = _cache.values.map((cl) => cl.initSample());

    await Future.wait(futures);
  }

  Future<Audio> findNearestEntry(Timbre timbre, double relativeSemitone) async {
    assert(_cache.containsKey(timbre));

    AudioCacheLine cacheLine = _cache[timbre]!;

    AudioCacheEntry targetAudio = cacheLine.findNearestEntry(relativeSemitone);

    return Future.value(targetAudio.audio);
  }

  bool evict() {
    List<AudioCacheEntry> victims = _cache.values.map((line) => line.findVictim()).nonNulls.toList();

    // Evict should never be called when the cache is completely empty.
    assert(victims.isNotEmpty);

    AudioCacheEntry victim = victims.fold(victims.first, (acc, next) => next.lastAccessed < acc.lastAccessed ? next : acc);

    if (victim.audio.source != null) {
      victim.audio.source = null;
      _loaded--;
    }

    return victim.audio.source == null;
  }

  void save(Timbre timbre, String keyName, AudioSource source) {
    assert(_cache.containsKey(timbre));
    AudioCacheLine cacheLine = _cache[timbre]!;

    // This would fail if there is no entry with that keyName.
    AudioCacheEntry entry = cacheLine.entries.firstWhere((e) => e.audio.keyName == keyName);

    if (entry.audio.source != null) {
      return;
    }

    entry.audio.source = source;
    entry.access();
    _loaded++;
  }

  static int findNearestSampleIndex(double relativeSemitone) {
    if (relativeSemitone >= maxSemitoneValue) {
      return samplePerTimbre - 1;
    }
    
    if (relativeSemitone <= minSemitoneValue) {
      return 0;
    }
    
    // Now.. find the best sample.
    int integerSemitone = relativeSemitone.floor();
    int step = sampleSemitoneDiff;
    integerSemitone = (integerSemitone - integerSemitone % step);
    
    int index = (integerSemitone - minSemitoneValue) ~/ step;

    if (relativeSemitone - integerSemitone > integerSemitone + step - relativeSemitone) {
      index += 1;
    }

    assert(index * step >= minSemitoneValue && index * step <= maxSemitoneValue);

    return index;
  }
}

class AudioCacheLine {
  final Timbre timbre;
  final List<AudioCacheEntry> entries = [];

  static const String _keys = "f2 a2 c3s f3 a3 c4s f4 a4 c5s f5 a5 c6s f6 a6 c7s";

  AudioCacheLine(this.timbre);

  Future<void> initSample() async {
    entries.clear();
    
    int expectedSamples = (maxSemitoneValue - minSemitoneValue) ~/ sampleSemitoneDiff + 1;
    
    assert((maxSemitoneValue - minSemitoneValue) % sampleSemitoneDiff == 0 
      && (maxSemitoneValue - minSemitoneValue) ~/ sampleSemitoneDiff + 1 == samplePerTimbre);

    List<String> keys = _keys.split(' ');

    for (int i = 0; i < samplePerTimbre; i++) {
      int tone = minSemitoneValue + i * sampleSemitoneDiff;

      Audio audio = Audio(timbre, tone.toDouble(), keys[i]);
      AudioCacheEntry entry = AudioCacheEntry(audio);
      entries.add(entry);
    }

    assert(entries.length == expectedSamples);
  }

  /// Finds the Audio object with the nearest frequency.
  AudioCacheEntry findNearestEntry(double relativeSemitone) {
    assert(entries.isNotEmpty);

    int index = AudioCache.findNearestSampleIndex(relativeSemitone);
    AudioCacheEntry entry = entries[index];

    return entry.access();
  }

  AudioCacheEntry? findVictim() {
    final List<AudioCacheEntry> validEntries = entries.where((e) => e.audio.source != null).toList();

    if (validEntries.isEmpty) {
      return null;
    }

    return validEntries.fold(validEntries.first, (acc, next) => next.lastAccessed < acc!.lastAccessed ? next : acc);
  }
}

class AudioCacheEntry {
  static int _order = 0;
  final Audio audio;
  int lastAccessed = 0;

  AudioCacheEntry(this.audio);

  AudioCacheEntry access() {
    lastAccessed = _order++;
    return this;
  }
}