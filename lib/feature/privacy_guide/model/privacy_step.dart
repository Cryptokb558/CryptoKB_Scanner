import 'package:akillisletme/product/enum/check_severity.dart';

/// A single manual privacy-audit step the user performs in Android Settings.
class PrivacyStep {
  const PrivacyStep({
    required this.id,
    required this.title,
    required this.risk,
    required this.description,
    required this.instructions,
  });

  final String id;
  final String title;
  final CheckSeverity risk;

  /// Why this matters from a spyware perspective.
  final String description;

  /// Where to go in Settings and what to do.
  final String instructions;
}
