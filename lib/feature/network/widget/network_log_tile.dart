import 'package:akillisletme/feature/network/model/network_log_event.dart';
import 'package:akillisletme/product/const/app_paddings.dart';
import 'package:flutter/material.dart';

/// List row for a single persisted network event.
class NetworkLogTile extends StatelessWidget {
  const NetworkLogTile({required this.event, super.key});

  final NetworkLogEvent event;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return ListTile(
      contentPadding: AppPaddings.horizontalL,
      leading: CircleAvatar(
        backgroundColor: event.type.color.withValues(alpha: 0.15),
        child: Icon(event.type.icon, color: event.type.color, size: 20),
      ),
      title: Text(event.type.label, style: textTheme.titleSmall),
      subtitle: Text(event.details, style: textTheme.bodySmall),
      trailing: Text(
        _time(event.timestamp),
        style: textTheme.labelSmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  String _time(DateTime t) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(t.hour)}:${two(t.minute)}:${two(t.second)}';
  }
}
