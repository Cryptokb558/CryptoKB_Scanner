part of 'security_cubit.dart';

@freezed
abstract class SecurityState with _$SecurityState {
  const factory SecurityState({
    @Default(<SecurityRuleCheck>[]) List<SecurityRuleCheck> rules,
    @Default(false) bool isScanning,
    @Default(false) bool hasScanned,
    @Default(0) int score,
  }) = _SecurityState;

  const SecurityState._();

  /// Number of checks that found an issue.
  int get issueCount => rules.where((r) => r.isPassed == false).length;

  /// Number of checks that passed.
  int get passedCount => rules.where((r) => r.isPassed ?? false).length;

  /// Rules whose failure is a spyware/surveillance indicator, in priority order.
  static const _stalkerwareRuleIds = <String>{
    'accessibility_check',
    'notification_access_check',
    'device_admin_check',
    'ca_cert_check',
    'root_check',
    'vpn_check',
    'proxy_check',
  };

  /// The spyware-relevant checks that found an issue.
  List<SecurityRuleCheck> get stalkerwareIndicators => rules
      .where((r) => _stalkerwareRuleIds.contains(r.id) && r.isPassed == false)
      .toList();

  /// Aggregate "is my phone being watched?" verdict from the indicators above.
  /// 0 → low, 1–2 → medium, 3+ → high.
  RiskLevel get stalkerwareRisk {
    final n = stalkerwareIndicators.length;
    if (n >= 3) return RiskLevel.high;
    if (n >= 1) return RiskLevel.medium;
    return RiskLevel.low;
  }
}
