import 'package:cryptokb_scanner/feature/app_scanner/model/risky_app.dart';
import 'package:cryptokb_scanner/feature/app_scanner/service/app_scan_service.dart';
import 'package:cryptokb_scanner/product/enum/risk_level.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_scan_cubit.freezed.dart';
part 'app_scan_state.dart';

/// Scans installed apps and exposes them sorted by risk.
class AppScanCubit extends Cubit<AppScanState> {
  AppScanCubit({required AppScanService service})
    : _service = service,
      super(const AppScanState());

  final AppScanService _service;

  Future<void> scan() async {
    if (state.isScanning) return;
    emit(state.copyWith(isScanning: true));
    final apps = await _service.scan();
    emit(
      state.copyWith(apps: apps, isScanning: false, hasScanned: true),
    );
  }
}
