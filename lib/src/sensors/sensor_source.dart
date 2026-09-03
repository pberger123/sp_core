// sp_core - sensors/sensor_source.dart
//
// Defines the contract any physical sensor device must implement to plug
// into a SteadyPointSession. M5StickSensor is the only implementation
// today; when the M5Stick (now EOL'd) is eventually replaced, a new sensor
// implements this same interface and consuming apps change only which
// SensorSource they construct - nothing else in the pipeline (session,
// metrics, visualization, sonification) needs to know or care.

/// A single accelerometer sample. Units are whatever the sensor
/// implementation reports - M5StickSensor reports g (gravitational units),
/// per the M5 library's getAccelData(). If a future sensor reports in
/// different units, convert to g at the sensor boundary so everything
/// downstream (metrics, in particular Scoring_Algorithms.docx's g-based
/// thresholds) can assume g consistently.
class AccelSample {
  final double x;
  final double y;
  final double z;
  final DateTime timestamp;

  const AccelSample({
    required this.x,
    required this.y,
    required this.z,
    required this.timestamp,
  });

  @override
  String toString() =>
      '${timestamp.toIso8601String()} x=$x y=$y z=$z';
}

/// Connection lifecycle state, shared across all sensor implementations
/// regardless of transport (BLE, USB, etc.).
enum SensorConnectionState {
  disconnected,
  connecting,
  connected,   // linked to the device, not yet streaming data
  streaming,   // actively receiving samples
}

/// Interface a sensor implementation must satisfy to plug into a
/// SteadyPointSession (see session/steadypoint_session.dart).
///
/// All three info streams (status/log/connectionState) are broadcast
/// streams - safe for multiple listeners (e.g. a session AND a debug UI)
/// without needing to worry about single-subscription restrictions.
abstract class SensorSource {
  /// Parsed accelerometer samples, one event per incoming reading.
  Stream<AccelSample> get samples;

  /// Connection lifecycle state changes.
  Stream<SensorConnectionState> get connectionState;

  /// Human-readable, single-line status text (e.g. "Connected - subscribed").
  /// Intended for a UI's single status line, replaced each time (not
  /// accumulated) - contrast with [log] below.
  Stream<String> get status;

  /// Append-only debug/raw log lines (raw packets, errors, protocol
  /// details). Intended for a scrolling debug log, not the primary UI.
  Stream<String> get log;

  Future<void> connect();
  Future<void> startStreaming();
  Future<void> disconnect();

  /// Releases all resources (stream controllers, subscriptions). Must be
  /// safe to call even if never connected.
  void dispose();
}
