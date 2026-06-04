import 'package:akillisletme/feature/security/service/security_service.dart';
import 'package:akillisletme/feature/security/state/security_cubit.dart';
import 'package:akillisletme/feature/security/widget/circular_gauge.dart';
import 'package:akillisletme/feature/security/widget/security_rule_tile.dart';
import 'package:akillisletme/feature/security/widget/stalkerware_banner.dart';
import 'package:akillisletme/product/const/app_paddings.dart';
import 'package:akillisletme/product/navigation/app_router.dart';
import 'package:akillisletme/product/widget/app_primary_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SecurityView extends StatelessWidget {
  const SecurityView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SecurityCubit(service: SecurityService()),
      child: const _SecurityContent(),
    );
  }
}

class _SecurityContent extends StatelessWidget {
  const _SecurityContent();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Security Scan'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded),
            tooltip: 'Security timeline',
            onPressed: () => const SecurityTimelineRoute().push<void>(context),
          ),
        ],
      ),
      body: BlocBuilder<SecurityCubit, SecurityState>(
        builder: (context, state) {
          return ListView(
            padding: AppPaddings.allL,
            children: [
              const SizedBox(height: AppPaddings.s),
              Center(
                child: CircularGauge(score: state.score.toDouble()),
              ),
              const SizedBox(height: AppPaddings.l),
              if (state.hasScanned) ...[
                StalkerwareBanner(
                  risk: state.stalkerwareRisk,
                  indicatorCount: state.stalkerwareIndicators.length,
                ),
                const SizedBox(height: AppPaddings.l),
                _ResultSummary(
                  passed: state.passedCount,
                  issues: state.issueCount,
                ),
              ],
              const SizedBox(height: AppPaddings.l),
              AppPrimaryButton(
                label: state.isScanning ? 'Scanning…' : 'Start Scan',
                icon: Icons.shield_outlined,
                onPressed: state.isScanning
                    ? null
                    : () => context.read<SecurityCubit>().scan(),
              ),
              const SizedBox(height: AppPaddings.l),
              Text(
                'Checks',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppPaddings.s),
              ...state.rules.map(
                (rule) => SecurityRuleTile(
                  rule: rule,
                  isScanning: state.isScanning,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ResultSummary extends StatelessWidget {
  const _ResultSummary({required this.passed, required this.issues});

  final int passed;
  final int issues;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      spacing: AppPaddings.l,
      children: [
        _Chip(
          icon: Icons.check_circle_rounded,
          label: '$passed passed',
          color: Theme.of(context).colorScheme.primary,
        ),
        _Chip(
          icon: Icons.warning_amber_rounded,
          label: '$issues issues',
          color: Theme.of(context).colorScheme.error,
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.icon, required this.label, required this.color});

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: AppPaddings.xs,
      children: [
        Icon(icon, color: color, size: 18),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: color),
        ),
      ],
    );
  }
}
