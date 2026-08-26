// dart.library.io must be checked before dart.library.js_interop: native
// (VM) targets can also satisfy dart.library.js_interop, so checking io
// first is what correctly routes native platforms to the stub.
export 'pitch_player_stub.dart'
    if (dart.library.io) 'pitch_player_stub.dart'
    if (dart.library.js_interop) 'pitch_player_web.dart';
