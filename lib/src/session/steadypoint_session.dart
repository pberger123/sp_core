// sp_core - session/steadypoint_session.dart
//
// Orchestrates a SensorSource: owns the rolling sample buffer (same role
// as the `data` deque in sp_stdout.py) and feeds metrics computations
// (dominant frequency; intensity to follow). This is the layer other
// apps' UIs should build on top of, rather than talking to a SensorSource
// directly - it's where cross-cutting session state lives, independent of
// any UI framework or specific sensor implementation.

import 'dart:async';
import 'dart:collection';

import '../config/config.dart';
import '../metrics/dominant_frequency.dart';
import '../sensors/sensor_source.dart';

class SteadyPointSession {
  final SensorSource sensor;
  final SpCoreConfig config;
  final Duration windowDuration;

  final Queue<AccelSample> _buffer = Queue<AccelSample>();
  final _bufferController = StreamController<List<AccelSample>>.broadcast();
  final _frequencyController =
      StreamController<DominantFrequencyResult>.broadcast();

  late final DominantFrequencyEstimator _frequencyEstimator;
  StreamSubscription<AccelSample>? _sampleSub;

  SteadyPointSession({
    required this.sensor,
    this.config = const SpCoreConfig(),
    this.windowDuration = const Duration(seconds: 5),
  }) {
    _frequencyEstimator = DominantFrequencyEstimator(
      config: config,
      windowDuration: windowDuration,
    );
    _sampleSub = sensor.samples.listen(_onSample);
  }

  // Pass-through streams from the underlying sensor, so consumers only
  // need to hold a SteadyPointSession, not the sensor directly.
  Stream<AccelSample> get samples => sensor.samples;
  Stream<SensorConnectionState> get connectionState => sensor.connectionState;
  Stream<String> get status => sensor.status;
  Stream<String> get log => sensor.log;

  /// Rolling buffer of samples within [windowDuration], most recent last.
  Stream<List<AccelSample>> get bufferSnapshots => _bufferController.stream;

  /// Current buffer contents as of the last received sample.
  List<AccelSample> get currentBuffer => List.unmodifiable(_buffer);

  /// Dominant frequency per axis + average, updated on every new sample.
  Stream<DominantFrequencyResult> get frequencies =>
      _frequencyController.stream;

  void _onSample(AccelSample sample) {
    _buffer.addLast(sample);
    final cutoff = sample.timestamp.subtract(windowDuration);
    while (_buffer.isNotEmpty && _buffer.first.timestamp.isBefore(cutoff)) {
      _buffer.removeFirst();
    }
    _bufferController.add(List.unmodifiable(_buffer));

    final freqResult = _frequencyEstimator.addSample(sample);
    _frequencyController.add(freqResult);
  }

  Future<void> connect() => sensor.connect();
  Future<void> startStreaming() => sensor.startStreaming();
  Future<void> disconnect() => sensor.disconnect();

  void dispose() {
    _sampleSub?.cancel();
    _bufferController.close();
    _frequencyController.close();
    sensor.dispose();
  }
}
