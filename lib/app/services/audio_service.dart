import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:get/get.dart';
import 'package:p2tch/app/models/audio.dart';
import 'package:p2tch/app/models/audio_cache.dart';

/// Owns the audio sample cache so controllers don't touch it directly.
/// Registered once via [Get.putAsync] in main() and looked up with
/// `Get.find<AudioService>()`. Assumes the SoLoud engine is already
/// initialized by the caller.
class AudioService extends GetxService {
  final AudioCache _cache = AudioCache();

  Future<AudioService> init() async {
    await _cache.init();
    return this;
  }

  Future<Audio> findNearestEntry(Timbre timbre, double relativeSemitone) async {
    Audio audio = await _cache.findNearestEntry(timbre, relativeSemitone);
    await loadAudioSource(audio);

    return Future.value(audio);
  }

  Future<void> loadAudioSource(Audio audio) async {
    if (audio.source != null) {
      return;
    }

    if (_cache.isFull) {
      _cache.evict();
    }

    // TODO: Considering Web environment, change the file format to compressed one such as opus.
    String fileName = '${audio.timbre.name}/${audio.keyName}.wav';

    // This line would rarely fail in native platform. But in web, it can fail due to network.
    // The caller should take care of failure cases; including sending the player back to level-select screen.
    final data = await rootBundle.load('assets/audio/$fileName');
    final source = await SoLoud.instance.loadMem(fileName, data.buffer.asUint8List());

    _cache.save(audio.timbre, audio.keyName, source);
    
    audio.source = source;
  }
}
