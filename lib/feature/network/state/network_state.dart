part of 'network_cubit.dart';

@freezed
abstract class NetworkState with _$NetworkState {
  const factory NetworkState({
    @Default(<int?>[]) List<int?> latencyHistory,
    @Default(<NetworkLogEvent>[]) List<NetworkLogEvent> logEvents,
    @Default(false) bool isMonitoring,
    @Default(false) bool isInternetAvailable,
    int? currentLatency,
    @Default('—') String connectionType,
  }) = _NetworkState;
}
