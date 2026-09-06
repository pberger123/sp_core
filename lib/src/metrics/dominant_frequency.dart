// sp_core - metrics/dominant_frequency.dart
//
// Mirrors sp_stdout.py's compute_fft() / dominant_frequency() / EMA
// smoothing. Resamples the rolling window onto a uniform time grid before
// running the FFT - irregular BLE notification timing means raw samples
// aren't evenly spaced, same issue solved in Python via np.interp.
//
// Requires: flutter pub add fftea

import 'package:fftea/fftea.dart';

import '../config/config.dart';
import '../sensors/sensor_source.dart';

/// Dominant frequency per axis (Hz), plus their average - the value
/// actually used to drive sonification pitch. Any field may be null if
/// there isn't enough data yet.
class DominantFrequencyResult {
  final double? x;
  final double? y;
  final double? z;
  final double? average;

  const DominantFrequencyResult({this.x, this.y, this.z, this.average});
}

class DominantFrequencyEstimator {
  final SpCoreConfig config;
  final Duration windowDuration;

  // Uniform resample grid size for the FFT. Power-of-two, for fftea's
  // fast path. sp_stdout.py derived FFT_RESAMPLE_POINTS from
  // WINDOW_SECONDS * FFT_SAMPLE_RATE_HZ - 128 is a comparable fixed size
  // for a similar few-second window; revisit if WINDOW_DURATION changes
  // substantially.
  static const int resamplePoints = 128;

  // EMA smoothing factor, matching sp_stdout.py's FREQ_SMOOTHING_ALPHA.
  static const double smoothingAlpha = 0.2;

  // Minimum raw samples before attempting an FFT at all - an FFT on too
  // few points is meaningless noise, same reasoning as
  // sp_stdout.py's MIN_FFT_SAMPLES.
  static const int minSamples = 4;

  final List<AccelSample> _buffer = [];
  double? _smoothedX;
  double? _smoothedY;
  double? _smoothedZ;

  DominantFrequencyEstimator({
    this.config = const SpCoreConfig(),
    this.windowDuration = const Duration(seconds: 5),
  });

  /// Feed one new sample. Returns the current (possibly still-smoothing)
  /// result immediately - this does NOT wait for a full window before
  /// returning something, though early results will just be nulls/stale
  /// smoothed values until enough data has accumulated.
  DominantFrequencyResult addSample(AccelSample sample) {
    _buffer.add(sample);
    final cutoff = sample.timestamp.subtract(windowDuration);
    _buffer.removeWhere((s) => s.timestamp.isBefore(cutoff));

    if (_buffer.length >= minSamples) {
      final rawX = _dominantFrequencyForAxis((s) => s.x);
      final rawY = _dominantFrequencyForAxis((s) => s.y);
      final rawZ = _dominantFrequencyForAxis((s) => s.z);

      _smoothedX = _ema(_smoothedX, rawX);
      _smoothedY = _ema(_smoothedY, rawY);
      _smoothedZ = _ema(_smoothedZ, rawZ);
    }

    return DominantFrequencyResult(
      x: _smoothedX,
      y: _smoothedY,
      z: _smoothedZ,
      average: _average(),
    );
  }

  double? _average() {
    final vals = [_smoothedX, _smoothedY, _smoothedZ].whereType<double>();
    if (vals.isEmpty) return null;
    return vals.reduce((a, b) => a + b) / vals.length;
  }

  double? _ema(double? prev, double? next) {
    if (next == null) return prev;
    if (prev == null) return next;
    return smoothingAlpha * next + (1 - smoothingAlpha) * prev;
  }

  double? _dominantFrequencyForAxis(double Function(AccelSample) axisOf) {
    final firstMs = _buffer.first.timestamp.millisecondsSinceEpoch;
    final lastMs = _buffer.last.timestamp.millisecondsSinceEpoch;
    final spanSeconds = (lastMs - firstMs) / 1000.0;
    if (spanSeconds <= 0) return null;

    final ts = _buffer
        .map((s) => (s.timestamp.millisecondsSinceEpoch - firstMs) / 1000.0)
        .toList();
    final values = _buffer.map(axisOf).toList();

    // Resample onto a uniform grid via linear interpolation.
    final dt = spanSeconds / (resamplePoints - 1);
    final resampled = List<double>.filled(resamplePoints, 0.0);
    for (var i = 0; i < resamplePoints; i++) {
      resampled[i] = _linearInterp(ts, values, i * dt);
    }

    // Remove DC offset (mean) before the FFT, same as sp_stdout.py.
    final mean = resampled.reduce((a, b) => a + b) / resampled.length;
    for (var i = 0; i < resampled.length; i++) {
      resampled[i] -= mean;
    }

    final fft = FFT(resamplePoints);
    final spectrum = fft.realFft(resampled);

    // Peak-magnitude bin, excluding index 0 (DC).
    var peakIndex = 1;
    var peakMagnitude = 0.0;
    for (var i = 1; i < spectrum.length; i++) {
      final re = spectrum[i].x;
      final im = spectrum[i].y;
      final magnitude = re * re + im * im; // squared magnitude - fine for argmax
      if (magnitude > peakMagnitude) {
        peakMagnitude = magnitude;
        peakIndex = i;
      }
    }

    final hz = peakIndex / (resamplePoints * dt);
    return hz.clamp(config.frequencyMinHz, config.frequencyMaxHz);
  }

  double _linearInterp(List<double> xs, List<double> ys, double x) {
    if (x <= xs.first) return ys.first;
    if (x >= xs.last) return ys.last;
    for (var i = 0; i < xs.length - 1; i++) {
      if (x >= xs[i] && x <= xs[i + 1]) {
        final t = (x - xs[i]) / (xs[i + 1] - xs[i]);
        return ys[i] + t * (ys[i + 1] - ys[i]);
      }
    }
    return ys.last; // unreachable given the bounds checks above
  }
}
