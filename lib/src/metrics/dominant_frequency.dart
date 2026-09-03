// sp_core - metrics/dominant_frequency.dart
//
// NOT YET IMPLEMENTED. Will mirror sp_stdout.py's compute_fft() /
// dominant_frequency() / EMA smoothing (FREQ_SMOOTHING_ALPHA) once ported.
//
// Intended contract once implemented:
// - Resample a window of AccelSample onto a uniform time grid (irregular
//   BLE notification timing means raw samples aren't evenly spaced, same
//   issue solved in Python via np.interp before FFT)
// - Run an FFT, find the peak-magnitude bin excluding DC (0 Hz)
// - Clamp/map into [SpCoreConfig.frequencyMinHz, frequencyMaxHz]
// - Smooth the result across samples (EMA), same pattern as ema_smooth()
//   in sp_stdout.py

import '../sensors/sensor_source.dart';

class DominantFrequencyEstimator {
  DominantFrequencyEstimator();

  /// Current smoothed dominant frequency (Hz), or null if not enough
  /// samples have been seen yet.
  double? get value =>
      throw UnimplementedError('DominantFrequencyEstimator: ported in a future increment.');

  void addSample(AccelSample sample) =>
      throw UnimplementedError('DominantFrequencyEstimator: ported in a future increment.');
}
