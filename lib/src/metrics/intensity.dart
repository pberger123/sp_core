// sp_core - metrics/intensity.dart
//
// NOT YET IMPLEMENTED. Will mirror sp_stdout.py's compute_oscillation_
// amplitude() / compute_ac_rms() / map_ac_rms_to_level(), implementing
// Scoring_Algorithms.docx exactly:
//
//   ac_rms = sqrt(std_x^2 + std_y^2 + std_z^2)
//   if ac_rms <= noise_floor_g: level = 0
//   else: level = clamp(((ac_rms - noise_floor_g) /
//                        (full_scale_g - noise_floor_g)) * 100, 0, 100)
//
// Thresholds come from SpCoreConfig.intensityNoiseFloorG / .intensityFullScaleG.
//
// Per the lesson learned in the Python version: this should be computed
// fresh per-sample over a short, TIME-based window (not a fixed sample
// count) - a window shorter than one full oscillation cycle produces
// misleading readings depending on where its phase happens to land. See
// sp_stdout.py's INTENSITY_WINDOW_SECONDS derivation for the reasoning.

import '../config/config.dart';
import '../sensors/sensor_source.dart';

class IntensityEstimator {
  final SpCoreConfig config;

  IntensityEstimator({this.config = const SpCoreConfig()});

  /// Raw AC-RMS (g), or null if not enough samples yet.
  double? get acRms =>
      throw UnimplementedError('IntensityEstimator: ported in a future increment.');

  /// AC-RMS mapped to a 0-100 intensity level, or null if not enough
  /// samples yet.
  double? get level =>
      throw UnimplementedError('IntensityEstimator: ported in a future increment.');

  void addSample(AccelSample sample) =>
      throw UnimplementedError('IntensityEstimator: ported in a future increment.');
}
