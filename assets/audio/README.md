# Audio assets

Base samples go here, one subfolder per `Timbre` (see `lib/app/models/audio.dart`), one file per key:

```
assets/audio/
  piano/
    f2.wav  a2.wav  c3s.wav  f3.wav  a3.wav  c4s.wav
    f4.wav  a4.wav  c5s.wav  f5.wav  a5.wav  c6s.wav
    f6.wav  a6.wav  c7s.wav  f7.wav  a7.wav  c8s.wav
```

The key names and their exact count/order are the source of truth in
`lib/app/constants/audio_constants.dart` (`audioKeys`, spaced every
`sampleSemitoneDiff` semitones from `minSemitoneValue` to `maxSemitoneValue`
relative to A4 = 440Hz). `AudioService`/`AudioCache` load
`assets/audio/{timbre.name}/{key}.wav` lazily and cache the decoded
`AudioSource` (see `lib/app/models/audio_cache.dart`), evicting the
least-recently-used entry once `maxAudioCached` (`lib/app/constants/cache_constants.dart`)
is reached.

At play time, the nearest cached sample to a tile's target pitch is picked
and played back pitch-shifted via `flutter_soloud`'s `setRelativePlaySpeed`
(varispeed - duration shifts slightly with pitch, same as a classic sampler).
Samples are spaced closely enough (every `sampleSemitoneDiff` semitones) that
the needed shift per note stays small (~half that spacing at most), which is
what keeps the varispeed shift free of the artifacts a wider shift would
produce.

Currently only `piano/a4.wav` exists - the rest are still being recorded/added.

**Format**: WAV for now. Switching to Ogg Opus is under consideration to cut
load size/time on Web - confirmed `flutter_soloud` supports it directly via
`loadMem` (Ogg container with Opus/Vorbis/FLAC, alongside PCM/WAV/MP3), so no
playback-side blocker if/when the switch happens.
