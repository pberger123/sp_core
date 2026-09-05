// sp_core - sonification/sonification_player.dart
//
// NOT YET IMPLEMENTED. Will hold the actual audio engine - a continuous-
// phase sine oscillator mirroring sp_stdout.py's audio_callback(), which
// avoids audible clicks/pops when frequency/volume update between frames.
//
// Unlike visualization (where only chart_state.dart's data prep lives in
// sp_core, and actual rendering lives in the separate reference-app repo),
// sonification's actual audio OUTPUT lives here in sp_core too. Playing a
// sound isn't a UI/rendering choice the way a chart widget is - "produce
// sonification" was explicitly part of what sp_core is meant to provide.
//
// Flutter has no built-in low-level raw-PCM-streaming audio API the way
// Python's sounddevice does - this will likely need a plugin capable of
// streaming raw samples (e.g. flutter_soloud, or a platform channel to
// each OS's native audio API) rather than a package meant for playing
// audio files. Worth evaluating options carefully before implementing,
// since this is the piece most likely to need different approaches per
// platform.
