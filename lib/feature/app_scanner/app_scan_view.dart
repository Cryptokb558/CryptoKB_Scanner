import 'package:akillisletme/feature/app_scanner/service/app_scan_service.dart';
import 'package:akillisletme/feature/app_scanner/state/app_scan_cubit.dart';
import 'package:akillisletme/feature/app_scanner/widget/risky_app_tile.dart';
import 'package:akillisletme/product/const/app_paddings.dart';
import 'package:akillisletme/product/widget/app_primary_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AppScanView extends StatelessWidget {
  const AppScanView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AppScanCubit(service: AppScanService()),
      child: const _AppScanContent(),
    );
  }
}

class _AppScanContent extends StatelessWidget {
  const _AppScanContent();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Risky Apps')),
      body: BlocBuilder<AppScanCubit, AppScanState>(
        builder: (context, state) {
          return ListView(
            padding: AppPaddings.allL,
            children: [
              Text(
                'Scans installed apps for risky capabilities — accessibility '
                'access, device-admin rights, notification access, drawing over '
                'other apps, and installs from outside an app store.',
                style: textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
              ),
              const SizedBox(height: AppPaddings.l),
              AppPrimaryButton(
                label: state.isScanning ? 'Scanning…' : 'Scan Apps',
                icon: Icons.apps_rounded,
                onPressed: state.isScanning
                    ? null
                    : () => context.read<AppScanCubit>().scan(),
              ),
              const SizedBox(height: AppPaddings.l),
              if (state.isScanning)
                const Center(child: Padding(
                  padding: EdgeInsets.all(AppPaddings.xl),
                  child: CircularProgressIndicator(),
                ))
              else if (state.hasScanned) ...[
                _Summary(high: state.highCount, medium: state.mediumCount),
                const SizedBox(height: AppPaddings.l),
                if (state.apps.isEmpty)
                  Text(
                    'No apps to review.',
                    style: textTheme.bodyMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  )
                else
                  ...state.apps.map((app) => RiskyAppTile(app: app)),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.high, required this.medium});

  final int high;
  final int medium;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      spacing: AppPaddings.l,
      children: [
        _Chip(
          label: '$high high risk',
          color: const Color(0xFFFF3B30),
        ),
        _Chip(
          label: '$medium medium',
          color: const Color(0xFFFFCC00),
        ),
        _Chip(
          label: 'reviewed',
          color: cs.primary,
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppPaddings.m,
        vertical: AppPaddings.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: color),
      ),
    );
  }
}
