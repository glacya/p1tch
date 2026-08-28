import 'dart:math';

import 'package:flutter_soloud/flutter_soloud.dart';

class Audio {
  final Timbre timbre;
  // RelativeSemitone = 12 * log2(freq / 440)
  final double relativeSemitone;
  final String keyName;
  AudioSource? source;
  
  Audio(this.timbre, this.relativeSemitone, this.keyName);

  static double _rstToFreq(double relativeSemitone) {
    return 440.0 * pow(2, relativeSemitone / 12.0);
  }

  double frequency() {
    return _rstToFreq(relativeSemitone);
  }

  double frequencyRatio(double relativeSemitone) {
    return _rstToFreq(relativeSemitone) / _rstToFreq(this.relativeSemitone);
  }
}

enum Timbre {
  piano,
}