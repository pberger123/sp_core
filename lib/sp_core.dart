// sp_core - public API barrel file. (v2.6 - dominant frequency + real config)
//
// Consuming apps (sp_core_reference_app, and any other team's UI wrapper)
// should import ONLY this file, not anything under lib/src/ directly.
// Internals under lib/src/ may be refactored between versions without
// notice - this barrel is the stable contract other projects depend on
// when pulling sp_core as a git dependency.
//
// This package deliberately has no main.dart, no chart-rendering widgets,
// and no platform folders (android/, ios/, etc.) - see SETUP.md for where
// those live now (sp_core_reference_app, a separate repo).
library sp_core;

export 'src/sensors/sensor_source.dart';
export 'src/sensors/m5stick_sensor.dart';
export 'src/config/config.dart';
export 'src/session/steadypoint_session.dart';
export 'src/metrics/dominant_frequency.dart';

// Intensity, visualization data prep, and sonification exports will be
// added here as each is implemented in future increments (see
// lib/src/metrics/, lib/src/visualization/, lib/src/sonification/ for
// their current status).
