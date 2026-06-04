import 'dart:io';

import 'package:akillisletme/feature/app_scanner/model/risky_app.dart';
import 'package:flutter/services.dart';

/// Fetches the installed-app risk inventory from the native side over the
/// shared `device_security` channel (`scanApps` method). Android-only.
class AppScanService {
  static const MethodChannel _channel = MethodChannel('device_security');

  /// Returns the scanned apps, highest risk first. Empty on non-Android or
  /// when the channel is unavailable.
  Future<List<RiskyApp>> scan() async {
    if (!Platform.isAndroid) return const [];
    try {
      final raw = await _channel.invokeListMethod<Object?>('scanApps');
      if (raw == null) return const [];
      return raw
          .whereType<Map<Object?, Object?>>()
          .map(RiskyApp.fromMap)
          .toList()
        ..sort((a, b) => b.riskScore.compareTo(a.riskScore));
    } on Object catch (_) {
      return const [];
    }
  }
}
