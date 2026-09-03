// sp_core - reference app.
//
// This is deliberately thin: it assembles a SteadyPointSession with the
// M5Stick sensor and a bare-bones UI (connect/start/status/log). Any other
// team building their own UI wrapper should look structurally the same -
// construct a SteadyPointSession with whatever SensorSource they need, and
// build their own UI on top of it - by importing package:sp_core/sp_core.dart
// rather than copying this file.

import 'dart:async';

import 'package:flutter/material.dart';

import 'sp_core.dart';

// ══════════════════════════════════════════════════════
// VERSION - bump this each time new code is handed off.
// Continues the same v2.x series established when this project started.
// ══════════════════════════════════════════════════════
const String kVersion = 'v2.3';

const int kMaxLogLines = 500; // cap on-screen log growth, same spirit as the deque buffers in Python

void main() {
  runApp(const SteadyPointApp());
}

class SteadyPointApp extends StatelessWidget {
  const SteadyPointApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'sp_core',
      theme: ThemeData(brightness: Brightness.dark, useMaterial3: true),
      home: SteadyPointHomePage(
        session: SteadyPointSession(sensor: M5StickSensor()),
      ),
    );
  }
}

class SteadyPointHomePage extends StatefulWidget {
  final SteadyPointSession session;

  const SteadyPointHomePage({super.key, required this.session});

  @override
  State<SteadyPointHomePage> createState() => _SteadyPointHomePageState();
}

class _SteadyPointHomePageState extends State<SteadyPointHomePage> {
  final List<String> _log = [];
  final ScrollController _logScrollController = ScrollController();

  SensorConnectionState _connectionState = SensorConnectionState.disconnected;
  String _status = 'Not connected';

  late final StreamSubscription<String> _statusSub;
  late final StreamSubscription<SensorConnectionState> _connSub;
  late final StreamSubscription<String> _logSub;

  @override
  void initState() {
    super.initState();
    _statusSub = widget.session.status.listen((s) => setState(() => _status = s));
    _connSub = widget.session.connectionState
        .listen((s) => setState(() => _connectionState = s));
    _logSub = widget.session.log.listen(_appendLog);
  }

  void _appendLog(String line) {
    debugPrint(line);
    setState(() {
      _log.add(line);
      if (_log.length > kMaxLogLines) {
        _log.removeAt(0);
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_logScrollController.hasClients) {
        _logScrollController.jumpTo(_logScrollController.position.maxScrollExtent);
      }
    });
  }

  @override
  void dispose() {
    _statusSub.cancel();
    _connSub.cancel();
    _logSub.cancel();
    _logScrollController.dispose();
    widget.session.dispose();
    super.dispose();
  }

  bool get _isConnected =>
      _connectionState == SensorConnectionState.connected ||
      _connectionState == SensorConnectionState.streaming;
  bool get _isStreaming => _connectionState == SensorConnectionState.streaming;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('sp_core  •  $kVersion')),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                ElevatedButton(
                  onPressed: _isConnected
                      ? widget.session.disconnect
                      : widget.session.connect,
                  child: Text(_isConnected ? 'Disconnect' : 'Connect M5Stick'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: (_isConnected && !_isStreaming)
                      ? widget.session.startStreaming
                      : null,
                  child: const Text('Start streaming'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(_status, style: const TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 8),
            Expanded(
              child: Container(
                color: Colors.black,
                padding: const EdgeInsets.all(8),
                child: ListView.builder(
                  controller: _logScrollController,
                  itemCount: _log.length,
                  itemBuilder: (context, i) => Text(
                    _log[i],
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      color: Colors.greenAccent,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
