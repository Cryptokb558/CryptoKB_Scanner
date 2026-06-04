part of 'app_scan_cubit.dart';

@freezed
abstract class AppScanState with _$AppScanState {
  const factory AppScanState({
    @Default(<RiskyApp>[]) List<RiskyApp> apps,
    @Default(false) bool isScanning,
    @Default(false) bool hasScanned,
  }) = _AppScanState;

  const AppScanState._();

  int get highCount => apps.where((a) => a.riskLevel == RiskLevel.high).length;

  int get mediumCount =>
      apps.where((a) => a.riskLevel == RiskLevel.medium).length;
}
