import 'package:flutter/material.dart';

/// Type of a logged network event.
enum NetworkEventType {
  disconnected('Disconnected', Icons.wifi_off_rounded, Color(0xFFFF3B30)),
  reconnected('Reconnected', Icons.wifi_rounded, Color(0xFF00E5A8)),
  typeChanged('Connection Changed', Icons.swap_horiz_rounded, Color(0xFFFFCC00));

  const NetworkEventType(this.label, this.icon, this.color);

  final String label;
  final IconData icon;
  final Color color;
}
