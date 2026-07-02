import 'package:cryptokb_scanner/product/const/app_paddings.dart';
import 'package:cryptokb_scanner/product/enum/risk_level.dart';
import 'package:flutter/material.dart';

/// Headline "is my phone being watched?" verdict, aggregating the spyware-
/// relevant checks (accessibility, notification access, device admin, user CA,
/// root, VPN, proxy) into a single LOW / MEDIUM / HIGH banner.
class StalkerwareBanner extends StatelessWidget {
  const StalkerwareBanner({
    required this.risk,
    required this.indicatorCount,
    super.key,
  });

  final RiskLevel risk;
  final int indicatorCount;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final color = risk.color;

    final (icon, message) = switch (risk) {
      RiskLevel.low => (
        Icons.verified_user_rounded,
        'No surveillance indicators found.',
      ),
      RiskLevel.medium => (
        Icons.gpp_maybe_rounded,
        '$indicatorCount indicator(s) found — review the flagged checks below.',
      ),
      RiskLevel.high => (
        Icons.gpp_bad_rounded,
        '$indicatorCount suspicious indicators found — your device may be '
            'monitored. Review the flagged checks below.',
      ),
    };

    return Container(
      width: double.infinity,
      padding: AppPaddings.allL,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(width: AppPaddings.l),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Stalkerware Risk',
                      style: textTheme.labelMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: AppPaddings.s),
                    _RiskPill(risk: risk),
                  ],
                ),
                const SizedBox(height: AppPaddings.xs),
                Text(message, style: textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RiskPill extends StatelessWidget {
  const _RiskPill({required this.risk});

  final RiskLevel risk;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppPaddings.s, vertical: 2),
      decoration: BoxDecoration(
        color: risk.color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        risk.label.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
