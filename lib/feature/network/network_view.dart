import 'package:cryptokb_scanner/feature/network/service/network_monitor_service.dart';
import 'package:cryptokb_scanner/feature/network/state/network_cubit.dart';
import 'package:cryptokb_scanner/feature/network/widget/latency_chart.dart';
import 'package:cryptokb_scanner/feature/network/widget/network_log_tile.dart';
import 'package:cryptokb_scanner/product/const/app_paddings.dart';
import 'package:cryptokb_scanner/product/utils/app_messenger.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class NetworkView extends StatelessWidget {
  const NetworkView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => NetworkCubit(service: NetworkMonitorService())..start(),
      child: const _NetworkContent(),
    );
  }
}

class _NetworkContent extends StatelessWidget {
  const _NetworkContent();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Network Monitor'),
        actions: [
          BlocBuilder<NetworkCubit, NetworkState>(
            buildWhen: (a, b) => a.isMonitoring != b.isMonitoring,
            builder: (context, state) => IconButton(
              tooltip: state.isMonitoring ? 'Pause' : 'Resume',
              icon: Icon(
                state.isMonitoring ? Icons.pause_rounded : Icons.play_arrow_rounded,
              ),
              onPressed: () => context.read<NetworkCubit>().toggleMonitoring(),
            ),
          ),
          IconButton(
            tooltip: 'Clear logs',
            icon: const Icon(Icons.delete_outline_rounded),
            onPressed: () async {
              final confirmed = await context.showConfirmDialog(
                title: 'Clear logs?',
                message: 'All recorded network events will be deleted.',
                confirmLabel: 'Clear',
                cancelLabel: 'Cancel',
                isDestructive: true,
              );
              if (confirmed && context.mounted) {
                await context.read<NetworkCubit>().clearLogs();
              }
            },
          ),
        ],
      ),
      body: BlocBuilder<NetworkCubit, NetworkState>(
        builder: (context, state) {
          return ListView(
            padding: AppPaddings.allL,
            children: [
              _StatusHeader(state: state),
              const SizedBox(height: AppPaddings.l),
              Card(
                child: Padding(
                  padding: AppPaddings.allL,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Latency (last ${NetworkMonitorService.historyLength} pings)',
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                      const SizedBox(height: AppPaddings.m),
                      LatencyChart(history: state.latencyHistory),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppPaddings.l),
              Text(
                'Event Log',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppPaddings.s),
              if (state.logEvents.isEmpty)
                Padding(
                  padding: AppPaddings.allL,
                  child: Center(
                    child: Text(
                      'No events recorded yet.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                )
              else
                ...state.logEvents.map((e) => NetworkLogTile(event: e)),
            ],
          );
        },
      ),
    );
  }
}

class _StatusHeader extends StatelessWidget {
  const _StatusHeader({required this.state});

  final NetworkState state;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final online = state.isInternetAvailable;
    final color = online ? cs.primary : cs.error;
    return Card(
      child: Padding(
        padding: AppPaddings.allL,
        child: Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: AppPaddings.m),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    online ? 'Online' : 'Offline',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: color,
                    ),
                  ),
                  Text(
                    state.connectionType,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  state.currentLatency != null ? '${state.currentLatency} ms' : '—',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Text('latency', style: Theme.of(context).textTheme.labelSmall),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
