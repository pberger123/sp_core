// sp_core - test/session/steadypoint_session_test.dart
//
// Establishes the testing pattern for this package: a fake SensorSource
// (no BLE/hardware needed) drives a SteadyPointSession, so buffer logic
// can be verified deterministically. Future metrics tests (dominant
// frequency, intensity) should follow this same shape - feed known
// samples through a fake sensor, assert on the computed output, since
// correctness there matters most once other teams depend on it.

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:sp_core/sp_core.dart';

class FakeSensor implements SensorSource {
  final _samplesController = StreamController<AccelSample>.broadcast();
  final _connectionStateController =
      StreamController<SensorConnectionState>.broadcast();
  final _statusController = StreamController<String>.broadcast();
  final _logController = StreamController<String>.broadcast();

  @override
  Stream<AccelSample> get samples => _samplesController.stream;
  @override
  Stream<SensorConnectionState> get connectionState =>
      _connectionStateController.stream;
  @override
  Stream<String> get status => _statusController.stream;
  @override
  Stream<String> get log => _logController.stream;

  void emit(AccelSample sample) => _samplesController.add(sample);

  @override
  Future<void> connect() async {}
  @override
  Future<void> startStreaming() async {}
  @override
  Future<void> disconnect() async {}

  @override
  void dispose() {
    _samplesController.close();
    _connectionStateController.close();
    _statusController.close();
    _logController.close();
  }
}

void main() {
  test('buffer keeps only samples within windowDuration', () async {
    final fake = FakeSensor();
    final session = SteadyPointSession(
      sensor: fake,
      windowDuration: const Duration(seconds: 5),
    );

    final base = DateTime(2026, 1, 1, 0, 0, 0);

    fake.emit(AccelSample(x: 0, y: 0, z: 1, timestamp: base));
    fake.emit(AccelSample(x: 0, y: 0, z: 1, timestamp: base.add(const Duration(seconds: 2))));
    // This third sample is 6s after the first - the first should fall
    // outside the 5s window once this arrives.
    fake.emit(AccelSample(x: 0, y: 0, z: 1, timestamp: base.add(const Duration(seconds: 6))));

    // Let the broadcast stream events propagate.
    await Future.delayed(Duration.zero);

    expect(session.currentBuffer.length, 2);
    expect(
      session.currentBuffer.first.timestamp,
      base.add(const Duration(seconds: 2)),
    );

    session.dispose();
  });

  test('empty buffer before any samples arrive', () {
    final fake = FakeSensor();
    final session = SteadyPointSession(sensor: fake);

    expect(session.currentBuffer, isEmpty);

    session.dispose();
  });
}
