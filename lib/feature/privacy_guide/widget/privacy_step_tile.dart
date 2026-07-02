import 'package:cryptokb_scanner/feature/privacy_guide/model/privacy_step.dart';
import 'package:cryptokb_scanner/product/const/app_paddings.dart';
import 'package:flutter/material.dart';

/// Checklist card for one manual privacy-audit step.
class PrivacyStepTile extends StatelessWidget {
  const PrivacyStepTile({
    required this.step,
    required this.index,
    required this.checked,
    required this.onChanged,
    super.key,
  });

  final PrivacyStep step;
  final int index;
  final bool checked;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      margin: const EdgeInsets.only(bottom: AppPaddings.m),
      child: Padding(
        padding: AppPaddings.allL,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Checkbox(
                  value: checked,
                  onChanged: (v) => onChanged(v ?? false),
                ),
                const SizedBox(width: AppPaddings.xs),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$index. ${step.title}',
                        style: textTheme.titleMedium?.copyWith(
                          decoration: checked ? TextDecoration.lineThrough : null,
                          color: checked ? cs.onSurfaceVariant : cs.onSurface,
                        ),
                      ),
                      const SizedBox(height: AppPaddings.xs),
                      _RiskBadge(label: '${step.risk.label} risk', color: step.risk.color),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppPaddings.s),
            Text(step.description, style: textTheme.bodyMedium),
            const SizedBox(height: AppPaddings.s),
            Container(
              padding: AppPaddings.allM,
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.arrow_right_alt_rounded, color: cs.primary, size: 18),
                  const SizedBox(width: AppPaddings.xs),
                  Expanded(
                    child: Text(
                      step.instructions,
                      style: textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RiskBadge extends StatelessWidget {
  const _RiskBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppPaddings.s, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
