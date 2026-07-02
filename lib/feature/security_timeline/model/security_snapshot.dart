import 'package:cryptokb_scanner/product/enum/risk_level.dart';
import 'package:equatable/equatable.dart';

/// A persisted summary of one security scan, used to build the timeline and to
/// diff against the previous scan ("a new Device Admin app appeared", etc.).
class SecuritySnapshot extends Equatable {
  const SecuritySnapshot({
    required this.timestamp,
    required this.score,
    required this.risk,
    required this.failedRuleIds,
  });

  factory SecuritySnapshot.fromJson(Map<String, dynamic> json) {
    return SecuritySnapshot(
      timestamp: DateTime.parse(json['timestamp'] as String),
      score: (json['score'] as num?)?.toInt() ?? 0,
      risk: RiskLevel.values.firstWhere(
        (e) => e.name == json['risk'],
        orElse: () => RiskLevel.low,
      ),
      failedRuleIds:
          (json['failedRuleIds'] as List?)?.map((e) => e.toString()).toList() ??
          const [],
    );
  }

  final DateTime timestamp;
  final int score;
  final RiskLevel risk;

  /// Ids of the rules that failed in this scan (the device's "issue set").
  final List<String> failedRuleIds;

  Map<String, dynamic> toJson() => {
    'timestamp': timestamp.toIso8601String(),
    'score': score,
    'risk': risk.name,
    'failedRuleIds': failedRuleIds,
  };

  @override
  List<Object?> get props => [timestamp, score, risk, failedRuleIds];
}
