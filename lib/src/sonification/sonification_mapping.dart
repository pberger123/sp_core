// sp_core - sonification/sonification_mapping.dart
//
// NOT YET IMPLEMENTED. Will hold PURE mapping logic, no audio engine
// dependencies - mirrors sp_stdout.py's map_to_audible() and the AC-RMS
// level -> volume mapping:
//
//   audible_hz = map(dominant_hz, [frequencyMinHz, frequencyMaxHz]
//                                -> [AUDIBLE_FREQ_MIN_HZ, AUDIBLE_FREQ_MAX_HZ])
//   volume     = level / 100 * AUDIO_VOLUME_MAX
//
// This is the reusable half of sonification - any team can use this to
// compute what tone to play, then plug in their own audio engine/platform
// APIs rather than being tied to sonification_player.dart's specific
// implementation.
