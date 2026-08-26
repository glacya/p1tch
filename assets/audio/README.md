# Audio assets

Base WAV samples go here, named by scientific pitch notation for the A note they contain:

- `a2.wav` — 110 Hz
- `a3.wav` — 220 Hz
- `a4.wav` — 440 Hz
- `a5.wav` — 880 Hz
- `a6.wav` — 1760 Hz

The spike screen at `lib/dev/audio_spike_view.dart` looks for these exact filenames and skips any that are missing, so files can be added incrementally.
