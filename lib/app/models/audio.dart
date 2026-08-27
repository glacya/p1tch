import 'dart:math';

import 'package:flutter_soloud/flutter_soloud.dart';

class Audio {
  final Timbre timbre;
  // AbsoluteSemitone = 12 * log2(freq / 440)
  final double absoluteSemitone;
  final AudioSource source;
  
  Audio(this.timbre, this.absoluteSemitone, this.source);


  double frequency() {
    return 440.0 * pow(2, absoluteSemitone / 12.0);
  }

  double frequencyRatio(Audio other) {
    return frequency() / other.frequency();
  }
}

enum Timbre {
  piano,
  
}