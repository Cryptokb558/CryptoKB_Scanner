import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:akillisletme/feature/network/model/network_log_event.dart';
import 'package:akillisletme/product/enum/network_event_type.dart';
import 'package:akillisletme/product/service/service_locator.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// Live network-stability engine.
///
/// Every [_pingInterval] it opens a TCP socket to a public DNS resolver
/// (Cloudflare `1.1.1.1:53`) to verify real end-to-end connectivity (a TCP
/// handshake instead of ICMP ping). Drops and recoveries are logged and
/// persisted via `SharedCache`. Feature-specific — not registered in the
/// locator; owned by `NetworkCubit`.
class NetworkMonitorService {
  static const int historyLength = 30;
  static const int maxLogLength = 100;
  static const String targetHost = '1.1.1.1';
  static const int targetPort = 53;
  static const Duration _pingInterval = Duration(seconds: 2);
  static const Duration _pingTimeout = Duration(milliseconds: 1800);

  final Connectivity _connectivity = Connectivity();
  final StreamController<void> _updates = StreamController<void>.broadcast();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  Timer? _pingTimer;

  List<int?> _latencyHistory = List<int?>.filled(historyLength, null);
  List<NetworkLogEvent> _logEvents = [];
  bool _isMonitoring = false;
  bool _isInternetAvailable = false;
  bool _wasLastPingSuccessful = true;
  DateTime? _disconnectTime;
  ConnectivityResult _lastConnectivity = ConnectivityResult.none;

  /// Fires whenever any observable value changes.
  Stream<void> get updates => _updates.stream;

  List<int?> get latencyHistory => _latencyHistory;
  List<NetworkLogEvent> get logEvents => _logEvents;
  bool get isMonitoring => _isMonitoring;
  bool get isInternetAvailable => _isInternetAvailable;
  int? get currentLatency => _latencyHistory.lastWhere(
    (v) => v != null,
    orElse: () => null,
  );
  String get connectionType => _format(_lastConnectivity);

  Future<void> init() async {
    _loadLogs();
    try {
      final result = await _connectivity.checkConnectivity();
      _lastConnectivity = _primary(result);
    } on Object catch (_) {}
    _connectivitySub = _connectivity.onConnectivityChanged.listen(
      (results) => _handleConnectivityChange(_primary(results)),
    );
  }

  void start() {
    if (_isMonitoring) return;
    _isMonitoring = true;
    _pingTimer = Timer.periodic(_pingInterval, (_) => _performPing());
    _notify();
  }

  void stop() {
    _pingTimer?.cancel();
    _pingTimer = null;
    _isMonitoring = false;
    _notify();
  }

  Future<void> clearLogs() async {
    _logEvents = [];
    await locator.sharedCache.setNetworkLogs(const []);
    _notify();
  }

  void dispose() {
    _pingTimer?.cancel();
    _connectivitySub?.cancel();
    _updates.close();
  }

  // ── Internals ───────────────────────────────────────────────

  ConnectivityResult _primary(List<ConnectivityResult> results) {
    if (results.isEmpty) return ConnectivityResult.none;
    return results.firstWhere(
      (r) => r != ConnectivityResult.none,
      orElse: () => ConnectivityResult.none,
    );
  }

  void _notify() {
    if (!_updates.isClosed) _updates.add(null);
  }

  void _handleConnectivityChange(ConnectivityResult result) {
    if (result == _lastConnectivity) return;
    final oldType = _format(_lastConnectivity);
    final newType = _format(result);
    _lastConnectivity = result;

    _addLog(
      NetworkLogEvent(
        timestamp: DateTime.now(),
        type: NetworkEventType.typeChanged,
        connectionType: newType,
        details: 'Connection switched from $oldType to $newType.',
      ),
    );

    if (result == ConnectivityResult.none) {
      _handleDisconnect('Network interface went down.');
    } else {
      _performPing();
    }
  }

  Future<void> _performPing() async {
    if (!_isMonitoring) return;
    final stopwatch = Stopwatch()..start();
    var success = false;
    int? latency;

    try {
      final socket = await Socket.connect(
        targetHost,
        targetPort,
        timeout: _pingTimeout,
      );
      stopwatch.stop();
      latency = stopwatch.elapsedMilliseconds;
      await socket.close();
      success = true;
    } on Object catch (_) {
      stopwatch.stop();
    }

    _isInternetAvailable = success;
    final newHistory = List<int?>.from(_latencyHistory)
      ..removeAt(0)
      ..add(success ? latency : null);
    _latencyHistory = newHistory;

    if (success) {
      if (!_wasLastPingSuccessful) _handleReconnect();
      _wasLastPingSuccessful = true;
    } else {
      if (_wasLastPingSuccessful) {
        _handleDisconnect('Active internet access lost (ping failed).');
      }
      _wasLastPingSuccessful = false;
    }
    _notify();
  }

  void _handleDisconnect(String details) {
    if (_disconnectTime != null) return;
    _disconnectTime = DateTime.now();
    _addLog(
      NetworkLogEvent(
        timestamp: _disconnectTime!,
        type: NetworkEventType.disconnected,
        connectionType: _format(_lastConnectivity),
        details: details,
      ),
    );
  }

  void _handleReconnect() {
    if (_disconnectTime == null) return;
    final now = DateTime.now();
    final duration = now.difference(_disconnectTime!);
    _disconnectTime = null;
    _addLog(
      NetworkLogEvent(
        timestamp: now,
        type: NetworkEventType.reconnected,
        connectionType: _format(_lastConnectivity),
        details: 'Connection restored. Outage lasted ${_duration(duration)}.',
      ),
    );
  }

  void _addLog(NetworkLogEvent event) {
    _logEvents = [event, ..._logEvents];
    if (_logEvents.length > maxLogLength) {
      _logEvents = _logEvents.sublist(0, maxLogLength);
    }
    _saveLogs();
    _notify();
  }

  void _loadLogs() {
    try {
      final raw = locator.sharedCache.networkLogs;
      _logEvents = raw
          .map((e) => NetworkLogEvent.fromJson(jsonDecode(e) as Map<String, dynamic>))
          .toList();
    } on Object catch (e) {
      if (kDebugMode) debugPrint('Failed to load network logs: $e');
    }
  }

  Future<void> _saveLogs() async {
    try {
      final raw = _logEvents.map((e) => jsonEncode(e.toJson())).toList();
      await locator.sharedCache.setNetworkLogs(raw);
    } on Object catch (e) {
      if (kDebugMode) debugPrint('Failed to save network logs: $e');
    }
  }

  String _duration(Duration d) {
    if (d.inMinutes > 0) return '${d.inMinutes}m ${d.inSeconds % 60}s';
    return '${d.inSeconds}s';
  }

  String _format(ConnectivityResult result) {
    return switch (result) {
      ConnectivityResult.wifi => 'Wi-Fi',
      ConnectivityResult.mobile => 'Mobile Data',
      ConnectivityResult.ethernet => 'Ethernet',
      ConnectivityResult.bluetooth => 'Bluetooth',
      ConnectivityResult.vpn => 'VPN',
      ConnectivityResult.satellite => 'Satellite',
      ConnectivityResult.other => 'Other',
      ConnectivityResult.none => 'No Connection',
    };
  }
}
