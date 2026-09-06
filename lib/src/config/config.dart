// sp_core - config/config.dart
//
// Tunable thresholds, mirroring sp_stdout.py's config.toml. Defaults below
// match that file's current values, for continuity with the Python
// reference implementation.
//
// Deliberately decoupled from HOW the TOML text is sourced (bundled asset,
// local file, network, etc.) - that's the consuming app's job, since it
// differs per platform (e.g. a local config.toml next to the executable
// works great on desktop, but Android/iOS apps can't read arbitrary
// filesystem paths the same way). SpCoreConfig.fromToml() just takes a
// String and parses it - this keeps sp_core testable with plain strings,
// no Flutter asset-loading machinery needed in tests.
//
// Requires: flutter pub add toml

import 'package:toml/toml.dart';

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

  /// Parses TOML text into a SpCoreConfig. Falls back to the default for
  /// any missing key, missing section, wrong type, or parse error - same
  /// per-key-merge-over-defaults behavior as sp_stdout.py's
  /// load_intensity_config(), rather than an all-or-nothing failure.
  ///
  /// Pass null or an empty string to get pure defaults.
  factory SpCoreConfig.fromToml(String? tomlSource) {
    const defaults = SpCoreConfig();
    if (tomlSource == null || tomlSource.trim().isEmpty) {
      return defaults;
    }

    try {
      final doc = TomlDocument.parse(tomlSource).toMap();
      final freq = doc['frequency'] as Map<String, dynamic>? ?? const {};
      final intensity = doc['intensity'] as Map<String, dynamic>? ?? const {};

      double readNum(Map<String, dynamic> section, String key, double fallback) {
        final v = section[key];
        if (v is num) return v.toDouble();
        return fallback;
      }

      return SpCoreConfig(
        frequencyMinHz: readNum(freq, 'min_hz', defaults.frequencyMinHz),
        frequencyMaxHz: readNum(freq, 'max_hz', defaults.frequencyMaxHz),
        intensityNoiseFloorG:
            readNum(intensity, 'noise_floor_g', defaults.intensityNoiseFloorG),
        intensityFullScaleG:
            readNum(intensity, 'full_scale_g', defaults.intensityFullScaleG),
      );
    } catch (_) {
      // Malformed TOML - fall back to defaults entirely, same as
      // sp_stdout.py's behavior on a parse failure.
      return defaults;
    }
  }
}
