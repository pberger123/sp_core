// sp_core - public API barrel file.
//
// Consuming apps (this reference app, and any other team's UI wrapper)
// should import ONLY this file, not anything under lib/src/ directly.
// Internals under lib/src/ may be refactored between versions without
// notice - this barrel is the stable contract other projects depend on
// when pulling sp_core as a git dependency.
library sp_core;

export 'src/sensors/sensor_source.dart';
export 'src/sensors/m5stick_sensor.dart';
export 'src/config/config.dart';
export 'src/session/steadypoint_session.dart';

// Metrics, visualization, and sonification exports will be added here as
// each is implemented in future increments (see lib/src/metrics/,
// lib/src/visualization/, lib/src/sonification/ for their current status).
