import 'package:flutter/material.dart';

/// Severity level of a security rule check.
enum CheckSeverity {
  low('Low', Color(0xFF34C759)),
  medium('Medium', Color(0xFFFFCC00)),
  high('High', Color(0xFFFF3B30));

  const CheckSeverity(this.label, this.color);

  /// Human-readable label shown in the UI.
  final String label;

  /// Accent color used for badges/indicators.
  final Color color;
}
