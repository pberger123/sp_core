# sp_core - Setup (v2.0)

This is a new Flutter project, continuing version numbering from the Python
reference series (v1.x) as its own v2.x line.

## 1. Create the project

```bash
flutter create sp_core
cd sp_core
```

## 2. Add dependencies

```bash
flutter pub add flutter_blue_plus
flutter pub add permission_handler
flutter pub add package_info_plus
```

(Not giving pinned version numbers directly - I can't reach pub.dev from my
sandbox to confirm current versions, so let Flutter's own resolver pick
whatever's current and compatible with your SDK.)

## 3. Drop in the code

Replace the `lib/main.dart` that `flutter create` generated with the
`main.dart` in this folder.

## 4. Android permissions (required)

Add these inside the `<manifest>` tag in `android/app/src/main/AndroidManifest.xml`,
above the `<application>` tag:

```xml
<uses-permission android:name="android.permission.BLUETOOTH" android:maxSdkVersion="30" />
<uses-permission android:name="android.permission.BLUETOOTH_ADMIN" android:maxSdkVersion="30" />
<uses-permission android:name="android.permission.BLUETOOTH_SCAN" android:usesPermissionFlags="neverForLocation" />
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
```

Android 12+ (API 31+) needs `BLUETOOTH_SCAN`/`BLUETOOTH_CONNECT` explicitly.
The legacy `BLUETOOTH`/`BLUETOOTH_ADMIN` pair (capped at `maxSdkVersion=30`,
so inert on modern Android) is also required - `permission_handler_android`'s
manifest check looks for these on some code paths and logs "Bluetooth
permission missing in manifest" if they're absent, even when the modern
SCAN/CONNECT permissions are correctly declared. This is a known,
frequently-reported quirk of that plugin, not a placement mistake.

After editing this file, run `flutter clean` before `flutter run` -
manifest changes can get baked into a stale build and a plain hot-restart
won't pick them up.

## 5. iOS permissions (required)

Add these keys to `ios/Runner/Info.plist`, inside the outer `<dict>`:

```xml
<key>NSBluetoothAlwaysUsageDescription</key>
<string>sp_core needs Bluetooth to connect to your M5Stick sensor.</string>
<key>NSBluetoothPeripheralUsageDescription</key>
<string>sp_core needs Bluetooth to connect to your M5Stick sensor.</string>
```

Without these, iOS will silently refuse Bluetooth access - no crash, no
error, connections will just fail or the scan will find nothing.

## 6. Run it

```bash
flutter run
```

Pick a real device (Android or iPhone) - Bluetooth doesn't work in the
simulator/emulator, so this needs physical hardware.

## Project structure (as of v2.3)

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
    visualization/                <- NOT YET IMPLEMENTED (charts)
    sonification/                 <- NOT YET IMPLEMENTED (audio)
lib/main.dart                     <- thin reference app
test/
  session/                        <- unit tests using a fake sensor, no hardware needed
```

`lib/src/` holds implementation details that may change between versions
without notice. Anything meant to be depended on is re-exported from
`lib/sp_core.dart` - that barrel file is the stable contract.

## Consuming sp_core from another project

Since this is a normal Dart package (has a pubspec.yaml + lib/), another
Flutter project can depend on it directly via git, pinned to a version tag:

```yaml
dependencies:
  sp_core:
    git:
      url: https://github.com/yourorg/sp_core.git
      ref: v2.3   # pin to a tag; bump deliberately to pull a newer version
```

Then in their code:

```dart
import 'package:sp_core/sp_core.dart';

final session = SteadyPointSession(sensor: M5StickSensor());
```

They build their own UI on top of `SteadyPointSession` - this project's
`lib/main.dart` is the reference implementation, not something they need
to copy.

## Adding a new sensor (e.g. replacing the EOL'd M5Stick)

Implement `SensorSource` (see `lib/src/sensors/sensor_source.dart`) with a
new class alongside `M5StickSensor`. Nothing else in the pipeline -
`SteadyPointSession`, and eventually metrics/visualization/sonification -
needs to change; consuming code swaps which sensor it constructs:

```dart
final session = SteadyPointSession(sensor: NewSensorImpl());
```



## A note on this sandbox's limits

I can't run `flutter create`, `flutter pub get`, or `flutter run` here - no
Flutter SDK or pub.dev access in my environment. I checked the Dart file's
brace/paren balance as a basic sanity check, but the real build/compile
test has to happen on your machine. If you hit compile errors specifically
around the BLE calls, the most likely cause is `flutter_blue_plus`'s API
having shifted slightly from what I wrote - checking the installed
package's own example code will resolve that quickly.
