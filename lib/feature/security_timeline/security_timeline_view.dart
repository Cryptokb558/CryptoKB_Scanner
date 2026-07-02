import 'package:cryptokb_scanner/feature/security_timeline/model/security_timeline_event.dart';
import 'package:cryptokb_scanner/feature/security_timeline/service/security_history_service.dart';
import 'package:cryptokb_scanner/product/const/app_paddings.dart';
import 'package:flutter/material.dart';

/// Read-only history of past scans: what changed and when (new Device Admin,
/// added CA certificate, VPN toggled, score moves).
class SecurityTimelineView extends StatefulWidget {
  const SecurityTimelineView({super.key});

  @override
  State<SecurityTimelineView> createState() => _SecurityTimelineViewState();
}

class _SecurityTimelineViewState extends State<SecurityTimelineView> {
  final SecurityHistoryService _service = SecurityHistoryService();
  late List<SecurityTimelineEvent> _events = _service.buildTimeline();

  Future<void> _clear() async {
    await _service.clear();
    setState(() => _events = const []);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Security Timeline'),
        actions: [
          if (_events.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded),
              tooltip: 'Clear history',
              onPressed: _clear,
            ),
        ],
      ),
      body: _events.isEmpty
          ? Center(
              child: Padding(
                padding: AppPaddings.allXxl,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.history_rounded, size: 48, color: cs.outline),
                    const SizedBox(height: AppPaddings.l),
                    Text(
                      'No history yet',
                      style: textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppPaddings.s),
                    Text(
                      'Run a security scan a few times — changes between scans '
                      'will appear here.',
                      style: textTheme.bodyMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          : ListView(
              padding: AppPaddings.allL,
              children: _buildGroupedChildren(context),
            ),
    );
  }

  /// Groups events under a day header, preserving the most-recent-first order.
  List<Widget> _buildGroupedChildren(BuildContext context) {
    final children = <Widget>[];
    String? currentDay;
    for (final event in _events) {
      final day = _formatDay(event.timestamp);
      if (day != currentDay) {
        currentDay = day;
        children.add(
          Padding(
            padding: const EdgeInsets.only(
              top: AppPaddings.l,
              bottom: AppPaddings.s,
            ),
            child: Text(
              day,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        );
      }
      children.add(_EventRow(event: event));
    }
    return children;
  }

  static const _months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  String _formatDay(DateTime t) => '${t.day} ${_months[t.month - 1]} ${t.year}';
}

class _EventRow extends StatelessWidget {
  const _EventRow({required this.event});

  final SecurityTimelineEvent event;

  String get _time {
    final h = event.timestamp.hour.toString().padLeft(2, '0');
    final m = event.timestamp.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppPaddings.s),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(event.change.icon, color: event.change.color, size: 22),
          const SizedBox(width: AppPaddings.m),
          Expanded(
            child: Text(event.message, style: textTheme.bodyMedium),
          ),
          const SizedBox(width: AppPaddings.s),
          Text(
            _time,
            style: textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
