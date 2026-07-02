import 'package:cryptokb_scanner/product/enum/risk_level.dart';
import 'package:equatable/equatable.dart';

/// One installed app plus the signals used to judge how risky it is.
///
/// The risk score is computed here (not natively) so the weighting can be
/// tuned without a rebuild. Granted dangerous permissions are surfaced for
/// transparency but do not by themselves raise the score — almost every app
/// holds some — whereas sensitive *capabilities* (accessibility, device admin,
/// notification access, overlay) and a sideloaded source do.
class RiskyApp extends Equatable {
  const RiskyApp({
    required this.packageName,
    required this.label,
    required this.installer,
    required this.sideloaded,
    required this.system,
    required this.firstInstall,
    required this.accessibility,
    required this.deviceAdmin,
    required this.notificationAccess,
    required this.overlay,
    required this.permissions,
  });

  factory RiskyApp.fromMap(Map<Object?, Object?> map) {
    final firstInstallMs = (map['firstInstall'] as num?)?.toInt() ?? 0;
    return RiskyApp(
      packageName: map['package']?.toString() ?? '',
      label: map['label']?.toString() ?? map['package']?.toString() ?? '',
      installer: map['installer']?.toString() ?? '',
      sideloaded: map['sideloaded'] == true,
      system: map['system'] == true,
      firstInstall: firstInstallMs > 0
          ? DateTime.fromMillisecondsSinceEpoch(firstInstallMs)
          : null,
      accessibility: map['accessibility'] == true,
      deviceAdmin: map['deviceAdmin'] == true,
      notificationAccess: map['notificationAccess'] == true,
      overlay: map['overlay'] == true,
      permissions: (map['permissions'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }

  final String packageName;
  final String label;
  final String installer;
  final bool sideloaded;
  final bool system;
  final DateTime? firstInstall;
  final bool accessibility;
  final bool deviceAdmin;
  final bool notificationAccess;
  final bool overlay;
  final List<String> permissions;

  /// Installed within the last 30 days (recent installs deserve a second look).
  bool get recentlyInstalled {
    final t = firstInstall;
    if (t == null) return false;
    return DateTime.now().difference(t).inDays <= 30;
  }

  /// Weighted risk points from the sensitive signals.
  int get riskScore {
    var score = 0;
    if (accessibility) score += 3;
    if (deviceAdmin) score += 2;
    if (notificationAccess) score += 2;
    if (overlay) score += 1;
    if (sideloaded) score += 2;
    if (recentlyInstalled) score += 1;
    return score;
  }

  RiskLevel get riskLevel {
    final s = riskScore;
    if (s >= 5) return RiskLevel.high;
    if (s >= 2) return RiskLevel.medium;
    return RiskLevel.low;
  }

  /// Human-readable reasons behind the score, for the UI.
  List<String> get reasons {
    return [
      if (accessibility) 'Accessibility access',
      if (deviceAdmin) 'Device administrator',
      if (notificationAccess) 'Reads notifications',
      if (overlay) 'Draws over other apps',
      if (sideloaded) 'Installed from outside an app store',
      if (recentlyInstalled) 'Installed in the last 30 days',
    ];
  }

  @override
  List<Object?> get props => [
    packageName,
    label,
    installer,
    sideloaded,
    system,
    firstInstall,
    accessibility,
    deviceAdmin,
    notificationAccess,
    overlay,
    permissions,
  ];
}
