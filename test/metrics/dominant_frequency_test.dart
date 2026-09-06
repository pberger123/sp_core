// sp_core - test/metrics/dominant_frequency_test.dart
//
// Feeds a synthetic sine wave at a known frequency through
// DominantFrequencyEstimator and verifies it recovers that frequency -
// this is the kind of test worth having for anything downstream teams
// depend on for correctness, per the same reasoning as the intensity
// scoring implementation once it lands.

import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:sp_core/sp_core.dart';

void main() {
  test('recovers a known sine wave frequency', () {
    const knownFrequencyHz = 4.0; // within the default 0.5-20 Hz range
    const sampleRateHz = 50.0; // synthetic BLE notification rate
    const durationSeconds = 5.0;

    final estimator = DominantFrequencyEstimator();

    final sampleCount = (durationSeconds * sampleRateHz).round();
    final base = DateTime(2026, 1, 1);

    DominantFrequencyResult? lastResult;
    for (var i = 0; i < sampleCount; i++) {
      final t = i / sampleRateHz;
      final value = math.sin(2 * math.pi * knownFrequencyHz * t);
      final sample = AccelSample(
        x: value,
        y: value,
        z: value,
        timestamp: base.add(Duration(milliseconds: (t * 1000).round())),
      );
      lastResult = estimator.addSample(sample);
    }

    expect(lastResult, isNotNull);
    expect(lastResult!.x, isNotNull);
    // FFT bin resolution over a 5s window / 128-point resample means exact
    // equality isn't realistic - allow a reasonable tolerance.
    expect(lastResult.x!, closeTo(knownFrequencyHz, 0.5));
    expect(lastResult.average!, closeTo(knownFrequencyHz, 0.5));
  });

  test('returns nulls before enough samples arrive', () {
    final estimator = DominantFrequencyEstimator();
    final result = estimator.addSample(
      AccelSample(x: 0, y: 0, z: 1, timestamp: DateTime(2026, 1, 1)),
    );
    expect(result.x, isNull);
    expect(result.average, isNull);
  });

  test('clamps to the configured frequency range', () {
    // A very high true frequency should still be reported within the
    // configured max, since the estimator clamps rather than extrapolating
    // outside the physically expected range.
    const config = SpCoreConfig(frequencyMinHz: 0.5, frequencyMaxHz: 10.0);
    final estimator = DominantFrequencyEstimator(config: config);

    const highFrequencyHz = 40.0;
    const sampleRateHz = 100.0;
    final base = DateTime(2026, 1, 1);

    DominantFrequencyResult? lastResult;
    for (var i = 0; i < 250; i++) {
      final t = i / sampleRateHz;
      final value = math.sin(2 * math.pi * highFrequencyHz * t);
      lastResult = estimator.addSample(AccelSample(
        x: value,
        y: value,
        z: value,
        timestamp: base.add(Duration(milliseconds: (t * 1000).round())),
      ));
    }

    expect(lastResult!.x, lessThanOrEqualTo(10.0));
  });
}
