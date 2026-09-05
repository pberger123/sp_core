# sp_core - Setup (v2.5)

sp_core is a pure Dart/Flutter **package** - sensor data collection,
metrics computation, and sonification output. It has NO UI and NO
platform folders (no `android/`, `ios/`, `linux/`, etc.) - those belong
to consuming apps, not to this package.

The runnable reference app that demonstrates how to use this package
lives in a separate repo: **sp_core_reference_app**.

## If you're converting THIS existing repo from the old combined structure

The repo previously had `android/`, `ios/`, `linux/` folders (and possibly
`macos/`, `windows/`) left over from when this was created via
`flutter create` (an app template). Those need to go - a package doesn't
own platform folders; permissions, `applicationId`, etc. are the
consuming app's responsibility now (see sp_core_reference_app's SETUP.md).

```bash
git rm -r android ios linux macos windows web 2>/dev/null
git commit -m "Remove platform folders - sp_core is now a pure package (see sp_core_reference_app)"
```

Also remove `package_info_plus` from `pubspec.yaml` if present - it was
only ever used by `main.dart` for the version-display feature, and
`main.dart` has moved to sp_core_reference_app along with that dependency.

## Project structure

```
lib/
  sp_core.dart                    <- public API barrel - import ONLY this
  src/
    sensors/
      sensor_source.dart          <- abstract interface + AccelSample model
      m5stick_sensor.dart         <- current BLE implementation
    metrics/                      <- NOT YET IMPLEMENTED (dominant freq, intensity)
    config/
      config.dart                 <- tunable thresholds (defaults only so far)
    session/
      steadypoint_session.dart    <- orchestration: owns the rolling buffer
    visualization/
      chart_state.dart            <- data prep ONLY, no widgets, no chart rendering
    sonification/
      sonification_mapping.dart   <- NOT YET IMPLEMENTED (pure freq/volume math)
      sonification_player.dart    <- NOT YET IMPLEMENTED (actual audio engine)
test/
  session/                        <- unit tests using a fake sensor, no hardware needed
```

Note what's deliberately absent: no `charts.dart`, no chart-rendering
widgets, no `main.dart`, no platform folders. Chart rendering lives in
sp_core_reference_app instead - see that repo's `lib/charts.dart` and its
own comment header for why.

`lib/src/` holds implementation details that may change between versions
without notice. Anything meant to be depended on is re-exported from
`lib/sp_core.dart` - that barrel file is the stable contract.

## Consuming sp_core from another project

Since this is a normal Dart package (has a `pubspec.yaml` + `lib/`),
another Flutter project can depend on it directly via git, pinned to a
version tag:

```yaml
dependencies:
  sp_core:
    git:
      url: https://github.com/pberger123/sp_core.git
      ref: v2.5   # pin to a tag; bump deliberately to pull a newer version
```

Then in their code:

```dart
import 'package:sp_core/sp_core.dart';

final session = SteadyPointSession(sensor: M5StickSensor());
```

They build their own UI (charts, sonification playback triggers, layout)
on top of `SteadyPointSession` - sp_core_reference_app is exactly this,
just also serving as the maintained reference example.

## Adding a new sensor (e.g. replacing the EOL'd M5Stick)

Implement `SensorSource` (see `lib/src/sensors/sensor_source.dart`) with a
new class alongside `M5StickSensor`. Nothing else in the pipeline needs to
change; consuming code swaps which sensor it constructs:

```dart
final session = SteadyPointSession(sensor: NewSensorImpl());
```

## A note on this sandbox's limits

I can't run `flutter pub get` or `flutter test` here - no Flutter SDK or
pub.dev access in my environment. I checked each Dart file's brace/paren
balance as a basic sanity check, but the real build/compile/test has to
happen on your machine.
