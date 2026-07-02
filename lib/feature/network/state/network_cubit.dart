import 'dart:async';

import 'package:cryptokb_scanner/feature/network/model/network_log_event.dart';
import 'package:cryptokb_scanner/feature/network/service/network_monitor_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'network_cubit.freezed.dart';
part 'network_state.dart';

/// Owns the [NetworkMonitorService] lifecycle and mirrors its data into state.
class NetworkCubit extends Cubit<NetworkState> {
  NetworkCubit({required NetworkMonitorService service})
    : _service = service,
      super(const NetworkState());

  final NetworkMonitorService _service;
  StreamSubscription<void>? _sub;

  Future<void> start() async {
    _sub = _service.updates.listen((_) => _sync());
    await _service.init();
    _service.start();
    _sync();
  }

  void toggleMonitoring() {
    if (_service.isMonitoring) {
      _service.stop();
    } else {
      _service.start();
    }
  }

  Future<void> clearLogs() => _service.clearLogs();

  void _sync() {
    if (isClosed) return;
    emit(
      state.copyWith(
        latencyHistory: _service.latencyHistory,
        logEvents: _service.logEvents,
        isMonitoring: _service.isMonitoring,
        isInternetAvailable: _service.isInternetAvailable,
        currentLatency: _service.currentLatency,
        connectionType: _service.connectionType,
      ),
    );
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    _service.dispose();
    return super.close();
  }
}
