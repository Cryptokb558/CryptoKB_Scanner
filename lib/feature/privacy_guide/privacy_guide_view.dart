import 'package:akillisletme/feature/privacy_guide/privacy_guide_view_model.dart';
import 'package:akillisletme/feature/privacy_guide/widget/privacy_step_tile.dart';
import 'package:akillisletme/product/const/app_paddings.dart';
import 'package:flutter/material.dart';

class PrivacyGuideView extends StatefulWidget {
  const PrivacyGuideView({super.key});

  @override
  State<PrivacyGuideView> createState() => _PrivacyGuideViewState();
}

class _PrivacyGuideViewState extends PrivacyGuideViewModel {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final done = checkedIds.length;

    return Scaffold(
      appBar: AppBar(title: const Text('Privacy Guide')),
      body: ListView(
        padding: AppPaddings.allL,
        children: [
          Text(
            'Manual Spyware Audit',
            style: textTheme.headlineSmall,
          ),
          const SizedBox(height: AppPaddings.s),
          Text(
            'Some checks cannot be automated due to OS security limits. Work '
            'through these Android settings yourself.',
            style: textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: AppPaddings.m),
          LinearProgressIndicator(
            value: steps.isEmpty ? 0 : done / steps.length,
            borderRadius: BorderRadius.circular(8),
            minHeight: 8,
          ),
          const SizedBox(height: AppPaddings.xs),
          Text(
            '$done of ${steps.length} completed',
            style: textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: AppPaddings.l),
          ...steps.asMap().entries.map(
            (entry) => PrivacyStepTile(
              step: entry.value,
              index: entry.key + 1,
              checked: isChecked(entry.value.id),
              onChanged: (v) => toggle(entry.value.id, value: v),
            ),
          ),
        ],
      ),
    );
  }
}
