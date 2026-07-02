import 'package:cryptokb_scanner/product/enum/check_severity.dart';
import 'package:equatable/equatable.dart';

/// An installed app surfaced by a rule (e.g. one holding a risky permission),
/// so the UI can list it and deep-link into its system settings page.
class AppRef extends Equatable {
  const AppRef({required this.packageName, required this.label});

  final String packageName;
  final String label;

  @override
  List<Object?> get props => [packageName, label];
}

/// A single security rule: its metadata and (after a scan) its result.
class SecurityRuleCheck extends Equatable {
  const SecurityRuleCheck({
    required this.id,
    required this.title,
    required this.description,
    required this.explanation,
    required this.severity,
    required this.category,
    this.isPassed,
    this.detailMessage,
    this.apps = const [],
  });

  final String id;
  final String title;
  final String description;
  final String explanation;
  final CheckSeverity severity;
  final String category;

  /// `null` = not scanned yet, `true` = no issue, `false` = issue found.
  final bool? isPassed;
  final String? detailMessage;

  /// Apps this rule flagged for review (tappable → app settings). Empty for
  /// rules that are not about per-app permissions.
  final List<AppRef> apps;

  SecurityRuleCheck copyWith({
    bool? isPassed,
    String? detailMessage,
    List<AppRef>? apps,
  }) {
    return SecurityRuleCheck(
      id: id,
      title: title,
      description: description,
      explanation: explanation,
      severity: severity,
      category: category,
      isPassed: isPassed ?? this.isPassed,
      detailMessage: detailMessage ?? this.detailMessage,
      apps: apps ?? this.apps,
    );
  }

  @override
  List<Object?> get props => [
    id,
    title,
    description,
    explanation,
    severity,
    category,
    isPassed,
    detailMessage,
    apps,
  ];
}
