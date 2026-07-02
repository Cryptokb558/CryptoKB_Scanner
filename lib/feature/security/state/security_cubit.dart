import 'package:cryptokb_scanner/feature/security/model/security_rule_check.dart';
import 'package:cryptokb_scanner/feature/security/service/security_service.dart';
import 'package:cryptokb_scanner/feature/security_timeline/service/security_history_service.dart';
import 'package:cryptokb_scanner/product/enum/check_severity.dart';
import 'package:cryptokb_scanner/product/enum/risk_level.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'security_cubit.freezed.dart';
part 'security_state.dart';

/// Drives the security scan: runs the rules and computes the safety score.
class SecurityCubit extends Cubit<SecurityState> {
  SecurityCubit({
    required SecurityService service,
    SecurityHistoryService? historyService,
  }) : _service = service,
       _historyService = historyService ?? SecurityHistoryService(),
       super(SecurityState(rules: SecurityService().getInitialRules()));

  final SecurityService _service;
  final SecurityHistoryService _historyService;

  /// Runs every check, streaming results into the state one by one.
  Future<void> scan() async {
    if (state.isScanning) return;

    emit(
      state.copyWith(
        isScanning: true,
        hasScanned: false,
        rules: _service.getInitialRules(),
      ),
    );

    final collected = <SecurityRuleCheck>[];
    final all = await _service.runAllChecks(
      onProgress: (result) {
        collected.add(result);
        // Merge the new result into the rule list, keeping order.
        final merged = state.rules.map((rule) {
          return rule.id == result.id ? result : rule;
        }).toList();
        emit(state.copyWith(rules: merged, score: _score(merged)));
      },
    );

    emit(
      state.copyWith(
        rules: all,
        isScanning: false,
        hasScanned: true,
        score: _score(all),
      ),
    );

    // Persist a snapshot so the Security Timeline can track changes over time.
    await _historyService.record(
      score: state.score,
      risk: state.stalkerwareRisk,
      failedRuleIds: all
          .where((r) => r.isPassed == false)
          .map((r) => r.id)
          .toList(),
    );
  }

  /// Score = weighted pass ratio (high severity counts more).
  int _score(List<SecurityRuleCheck> rules) {
    final scored = rules.where((r) => r.isPassed != null).toList();
    if (scored.isEmpty) return 0;

    var earned = 0.0;
    var total = 0.0;
    for (final rule in scored) {
      final weight = switch (rule.severity) {
        CheckSeverity.high => 3.0,
        CheckSeverity.medium => 2.0,
        CheckSeverity.low => 1.0,
      };
      total += weight;
      if (rule.isPassed ?? false) earned += weight;
    }
    return ((earned / total) * 100).round();
  }
}
