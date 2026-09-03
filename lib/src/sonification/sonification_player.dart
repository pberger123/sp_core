// sp_core - sonification/sonification_player.dart
//
// NOT YET IMPLEMENTED. Will hold the actual audio engine - a continuous-
// phase sine oscillator mirroring sp_stdout.py's audio_callback(), which
// avoids audible clicks/pops when frequency/volume update between frames.
//
// Flutter has no built-in low-level raw-PCM-streaming audio API the way
// Python's sounddevice does - this will likely need a plugin capable of
// streaming raw samples (e.g. flutter_soloud, or a platform channel to
// each OS's native audio API) rather than a package meant for playing
// audio files. Worth evaluating options carefully before implementing,
// since this is the piece most likely to need different approaches per
// platform.
