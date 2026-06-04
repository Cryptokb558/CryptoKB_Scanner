import 'package:akillisletme/feature/security/model/security_rule_check.dart';
import 'package:akillisletme/feature/security/service/security_service.dart';
import 'package:akillisletme/product/const/app_paddings.dart';
import 'package:akillisletme/product/enum/check_severity.dart';
import 'package:flutter/material.dart';

/// Expandable card showing a single rule's status, detail and explanation.
class SecurityRuleTile extends StatelessWidget {
  const SecurityRuleTile({required this.rule, this.isScanning = false, super.key});

  final SecurityRuleCheck rule;
  final bool isScanning;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final (leading, statusColor) = switch (rule.isPassed) {
      null => (_pendingLeading(cs), cs.outline),
      true => (Icon(Icons.check_circle_rounded, color: cs.primary), cs.primary),
      false => (
        Icon(Icons.warning_amber_rounded, color: rule.severity.color),
        rule.severity.color,
      ),
    };

    return Card(
      margin: const EdgeInsets.only(bottom: AppPaddings.m),
      child: Theme(
        // Remove the default ExpansionTile divider lines for a cleaner look.
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: leading,
          tilePadding: AppPaddings.horizontalL,
          childrenPadding: AppPaddings.allL,
          title: Text(rule.title, style: textTheme.titleMedium),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: AppPaddings.xs),
            child: Text(
              rule.detailMessage ?? rule.description,
              style: textTheme.bodySmall?.copyWith(color: statusColor),
            ),
          ),
          trailing: _SeverityBadge(severity: rule.severity),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                rule.explanation,
                style: textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
              ),
            ),
            if (rule.apps.isNotEmpty) ...[
              const SizedBox(height: AppPaddings.m),
              ...rule.apps.map((app) => _AppRow(app: app)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _pendingLeading(ColorScheme cs) {
    if (isScanning) {
      return SizedBox(
        width: 22,
        height: 22,
        child: CircularProgressIndicator(strokeWidth: 2, color: cs.primary),
      );
    }
    return Icon(Icons.radio_button_unchecked, color: cs.outline);
  }
}

/// A tappable flagged-app row that deep-links into the system "App info"
/// screen, where the user can review permissions or uninstall the app.
class _AppRow extends StatelessWidget {
  const _AppRow({required this.app});

  final AppRef app;

  Future<void> _open(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await SecurityService.openAppSettings(app.packageName);
    if (!ok) {
      messenger.showSnackBar(
        SnackBar(content: Text('Could not open settings for ${app.label}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return InkWell(
      onTap: () => _open(context),
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppPaddings.s),
        child: Row(
          children: [
            Icon(Icons.android_rounded, color: cs.onSurfaceVariant, size: 20),
            const SizedBox(width: AppPaddings.m),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(app.label, style: textTheme.bodyMedium),
                  Text(
                    app.packageName,
                    style: textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.open_in_new_rounded, color: cs.primary, size: 18),
          ],
        ),
      ),
    );
  }
}

class _SeverityBadge extends StatelessWidget {
  const _SeverityBadge({required this.severity});

  final CheckSeverity severity;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppPaddings.s, vertical: 2),
      decoration: BoxDecoration(
        color: severity.color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        severity.label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: severity.color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
