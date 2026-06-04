import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// The kind of change a timeline entry represents (drives icon + color).
enum TimelineChange {
  baseline(Icons.flag_rounded, Color(0xFF8E8E93)),
  issueAppeared(Icons.warning_amber_rounded, Color(0xFFFF3B30)),
  issueResolved(Icons.check_circle_rounded, Color(0xFF34C759)),
  scoreUp(Icons.trending_up_rounded, Color(0xFF34C759)),
  scoreDown(Icons.trending_down_rounded, Color(0xFFFFCC00));

  const TimelineChange(this.icon, this.color);

  final IconData icon;
  final Color color;
}

/// A single rendered entry on the security timeline.
class SecurityTimelineEvent extends Equatable {
  const SecurityTimelineEvent({
    required this.timestamp,
    required this.change,
    required this.message,
  });

  final DateTime timestamp;
  final TimelineChange change;
  final String message;

  @override
  List<Object?> get props => [timestamp, change, message];
}
