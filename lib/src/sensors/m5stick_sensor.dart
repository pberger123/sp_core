// sp_core - sensors/m5stick_sensor.dart
//
// BLE implementation of SensorSource for the M5StickC Plus running the
// SteadyPoint firmware. This is the piece to swap out (or add alongside)
// when the M5Stick is eventually replaced - everything else in the
// pipeline depends only on the SensorSource interface, not on this class.

import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

import 'sensor_source.dart';

// ══════════════════════════════════════════════════════
// CONSTANTS - BLE identity of the M5Stick firmware
// ══════════════════════════════════════════════════════
const String kM5DeviceName = 'TremorMonitor';
final Guid kM5ServiceUuid = Guid('6e400001-b5a3-f393-e0a9-e50e24dcca9e');
final Guid kM5CharUuid = Guid('6e400003-b5a3-f393-e0a9-e50e24dcca9e');
final Guid kM5CmdUuid = Guid('6e400004-b5a3-f393-e0a9-e50e24dcca9e');

// flutter_blue_plus (v2.0.0+) requires declaring which license tier applies
// to your use at connect() time. License.nonprofit covers personal,
// hobbyist, research, nonprofit, and educational use. If this ever becomes
// a for-profit product, this needs to change to a paid commercial license
// per the package's LICENSE.md.
const License kFbpLicense = License.nonprofit;

class M5StickSensor implements SensorSource {
  BluetoothDevice? _device;
  BluetoothCharacteristic? _dataChar;
  BluetoothCharacteristic? _cmdChar;

  StreamSubscription<List<int>>? _valueSub;
  StreamSubscription<BluetoothConnectionState>? _connSub;

  SensorConnectionState _state = SensorConnectionState.disconnected;

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

  void _setState(SensorConnectionState s) {
    _state = s;
    _connectionStateController.add(s);
  }

  void _setStatus(String s) => _statusController.add(s);
  void _appendLog(String line) => _logController.add(line);

  Future<bool> _ensurePermissions() async {
    // permission_handler has no native implementation on Linux/Windows -
    // Bluetooth access there is governed by system-level permissions
    // (bluez/polkit), not an in-app dialog - skip it entirely on desktop.
    if (!(Platform.isAndroid || Platform.isIOS)) {
      return true;
    }

    final statuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.locationWhenInUse,
    ].request();

    final allGranted =
        statuses.values.every((s) => s.isGranted || s.isLimited);
    if (!allGranted) {
      _setStatus('Bluetooth/location permission denied - check app settings.');
    }
    return allGranted;
  }

  @override
  Future<void> connect() async {
    if (_state != SensorConnectionState.disconnected) {
      _appendLog('Already connected.');
      return;
    }

    final ok = await _ensurePermissions();
    if (!ok) return;

    _setStatus('Scanning for "$kM5DeviceName"...');

    try {
      final completer = Completer<BluetoothDevice?>();
      late StreamSubscription sub;

      sub = FlutterBluePlus.onScanResults.listen((results) {
        for (final r in results) {
          if (r.device.platformName == kM5DeviceName) {
            completer.complete(r.device);
            sub.cancel();
            FlutterBluePlus.stopScan();
            break;
          }
        }
      });

      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 15));

      final foundDevice = await completer.future.timeout(
        const Duration(seconds: 16),
        onTimeout: () => null,
      );
      await FlutterBluePlus.stopScan();

      if (foundDevice == null) {
        _setStatus('Could not find a device named "$kM5DeviceName".');
        return;
      }

      _setStatus('Found ${foundDevice.remoteId}, connecting...');
      _device = foundDevice;

      _connSub = foundDevice.connectionState.listen((state) {
        if (state == BluetoothConnectionState.disconnected) {
          _dataChar = null;
          _cmdChar = null;
          _setState(SensorConnectionState.disconnected);
          _setStatus('Device disconnected.');
        }
      });

      await foundDevice.connect(
        license: kFbpLicense,
        timeout: const Duration(seconds: 15),
      );

      final services = await foundDevice.discoverServices();
      final service = services.firstWhere(
        (s) => s.uuid == kM5ServiceUuid,
        orElse: () =>
            throw Exception('Service $kM5ServiceUuid not found on device'),
      );

      _dataChar = service.characteristics.firstWhere(
        (c) => c.uuid == kM5CharUuid,
        orElse: () =>
            throw Exception('Data characteristic $kM5CharUuid not found'),
      );

      try {
        _cmdChar = service.characteristics.firstWhere((c) => c.uuid == kM5CmdUuid);
      } catch (_) {
        _cmdChar = null;
        _appendLog('No command characteristic found - START may not be available.');
      }

      await _dataChar!.setNotifyValue(true);
      _valueSub = _dataChar!.lastValueStream.listen(_handleNotification);

      _setState(SensorConnectionState.connected);
      _setStatus('Connected - subscribed. Call startStreaming() to begin.');
    } catch (e) {
      _setStatus('Connection error: $e');
      _device = null;
    }
  }

  void _handleNotification(List<int> value) {
    final raw = utf8.decode(value, allowMalformed: true);
    _appendLog('RAW: $raw');

    final parts = raw.split(',');
    if (parts.length >= 3) {
      final nums = parts.take(3).map((p) => double.tryParse(p.trim())).toList();
      if (nums.every((n) => n != null)) {
        final sample = AccelSample(
          x: nums[0]!,
          y: nums[1]!,
          z: nums[2]!,
          timestamp: DateTime.now(),
        );
        _samplesController.add(sample);
        _appendLog(
          '${(sample.timestamp.millisecondsSinceEpoch / 1000).toStringAsFixed(3)}'
          '|${sample.timestamp.toLocal()}|${sample.x} ${sample.y} ${sample.z}',
        );
        return;
      }
    }
    _appendLog('  -> did not parse as 3 numbers, skipped');
  }

  @override
  Future<void> startStreaming() async {
    if (_state == SensorConnectionState.disconnected ||
        _state == SensorConnectionState.connecting) {
      _appendLog('Not connected yet - call connect() first.');
      return;
    }
    if (_state == SensorConnectionState.streaming) {
      _appendLog('Already streaming.');
      return;
    }
    if (_cmdChar == null) {
      _appendLog('No command characteristic available - device may stream automatically.');
      return;
    }
    try {
      await _cmdChar!.write(utf8.encode('START'), withoutResponse: false);
      _setState(SensorConnectionState.streaming);
      _setStatus('Connected - sent START - streaming');
    } catch (e) {
      _appendLog('START failed: $e');
    }
  }

  @override
  Future<void> disconnect() async {
    // Best-effort STOP, mirrors START symmetrically. Unconfirmed against
    // the actual M5Stick firmware - flagged since it may simply be
    // unsupported, in which case this fails harmlessly and is logged.
    if (_cmdChar != null) {
      try {
        await _cmdChar!.write(utf8.encode('STOP'), withoutResponse: false);
      } catch (e) {
        _appendLog('STOP command failed or unsupported: $e');
      }
    }
    await _valueSub?.cancel();
    await _connSub?.cancel();
    if (_device != null) {
      try {
        await _device!.disconnect();
      } catch (_) {}
    }
    _dataChar = null;
    _cmdChar = null;
    _device = null;
    _setState(SensorConnectionState.disconnected);
    _setStatus('Not connected');
    _appendLog('Disconnected.');
  }

  @override
  void dispose() {
    _valueSub?.cancel();
    _connSub?.cancel();
    _samplesController.close();
    _connectionStateController.close();
    _statusController.close();
    _logController.close();
  }
}
