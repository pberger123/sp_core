// sp_core - config/config.dart
//
// Tunable thresholds, mirroring sp_stdout.py's config.toml. Defaults below
// match that file's current values exactly, for continuity between the
// Python and Flutter reference implementations.
//
// NOT YET IMPLEMENTED: actual file loading. Dart's standard library has no
// built-in TOML parser (unlike Python's tomllib) - when this is ported,
// evaluate the `toml` pub package vs. switching to JSON for cross-platform
// consistency (JSON has zero extra dependencies and Dart has built-in
// support via dart:convert, at the cost of losing TOML's comments).
// load() currently just returns the defaults.

class SpCoreConfig {
  /// Expected low/high end of tremor/movement frequency (Hz), used when
  /// picking the dominant frequency and mapping it to an audible tone.
  final double frequencyMinHz;
  final double frequencyMaxHz;

  /// AC-RMS (g) thresholds, per Scoring_Algorithms.docx.
  final double intensityNoiseFloorG;
  final double intensityFullScaleG;

  const SpCoreConfig({
    this.frequencyMinHz = 0.5,
    this.frequencyMaxHz = 20.0,
    this.intensityNoiseFloorG = 0.006,
    this.intensityFullScaleG = 3.0,
  });

  /// Loads config. NOT YET IMPLEMENTED - returns [SpCoreConfig] defaults
  /// for now. Kept async so callers don't need to change when real file
  /// loading is added.
  static Future<SpCoreConfig> load() async {
    return const SpCoreConfig();
  }
}
