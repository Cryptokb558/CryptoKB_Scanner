import 'package:flutter/material.dart';

/// A coarse risk verdict shown to the user (stalkerware risk, per-app risk).
enum RiskLevel {
  low('Low', Color(0xFF34C759)),
  medium('Medium', Color(0xFFFFCC00)),
  high('High', Color(0xFFFF3B30));

  const RiskLevel(this.label, this.color);

  /// Human-readable label shown in the UI.
  final String label;

  /// Accent color used for badges/banners.
  final Color color;
}
