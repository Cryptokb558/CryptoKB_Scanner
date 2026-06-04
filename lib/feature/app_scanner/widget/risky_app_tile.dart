import 'package:akillisletme/feature/app_scanner/model/risky_app.dart';
import 'package:akillisletme/feature/security/service/security_service.dart';
import 'package:akillisletme/product/const/app_paddings.dart';
import 'package:flutter/material.dart';

/// Expandable card for one scanned app: risk pill, reasons and granted
/// dangerous permissions, tappable to open the system "App info" screen.
class RiskyAppTile extends StatelessWidget {
  const RiskyAppTile({required this.app, super.key});

  final RiskyApp app;

  Future<void> _openSettings(BuildContext context) async {
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
    final color = app.riskLevel.color;

    return Card(
      margin: const EdgeInsets.only(bottom: AppPaddings.m),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: AppPaddings.horizontalL,
          childrenPadding: AppPaddings.allL,
          leading: CircleAvatar(
            radius: 18,
            backgroundColor: color.withValues(alpha: 0.15),
            child: Icon(Icons.android_rounded, color: color, size: 20),
          ),
          title: Text(app.label, style: textTheme.titleMedium),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: AppPaddings.xs),
            child: Text(
              app.packageName,
              style: textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
          ),
          trailing: _RiskPill(app: app),
          children: [
            if (app.reasons.isNotEmpty) ...[
              _ChipWrap(
                labels: app.reasons,
                color: color,
              ),
              const SizedBox(height: AppPaddings.m),
            ],
            if (app.permissions.isNotEmpty) ...[
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Granted permissions',
                  style: textTheme.labelMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(height: AppPaddings.s),
              _ChipWrap(labels: app.permissions, color: cs.onSurfaceVariant),
              const SizedBox(height: AppPaddings.m),
            ],
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _openSettings(context),
                icon: const Icon(Icons.open_in_new_rounded, size: 18),
                label: const Text('Open app settings'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RiskPill extends StatelessWidget {
  const _RiskPill({required this.app});

  final RiskyApp app;

  @override
  Widget build(BuildContext context) {
    final color = app.riskLevel.color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppPaddings.s, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '${app.riskLevel.label} risk'.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ChipWrap extends StatelessWidget {
  const _ChipWrap({required this.labels, required this.color});

  final List<String> labels;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppPaddings.s,
      runSpacing: AppPaddings.s,
      children: labels
          .map(
            (l) => Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppPaddings.m,
                vertical: AppPaddings.xs,
              ),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                l,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: color),
              ),
            ),
          )
          .toList(),
    );
  }
}
