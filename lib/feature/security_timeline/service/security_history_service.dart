import 'dart:convert';

import 'package:akillisletme/feature/security_timeline/model/security_snapshot.dart';
import 'package:akillisletme/feature/security_timeline/model/security_timeline_event.dart';
import 'package:akillisletme/product/enum/risk_level.dart';
import 'package:akillisletme/product/service/service_locator.dart';

/// Persists one [SecuritySnapshot] per completed scan and derives a
/// human-readable timeline by diffing consecutive snapshots
/// ("a new Device Admin app appeared", "VPN turned off", score changes).
class SecurityHistoryService {
  /// Keep the most recent N scans to bound storage.
  static const int _maxEntries = 50;

  /// Friendly names for rule ids surfaced in timeline messages.
  static const Map<String, String> _ruleLabels = {
    'root_check': 'Root / jailbreak',
    'vpn_check': 'Active VPN / tunnel',
    'emulator_check': 'Emulator environment',
    'debug_check': 'Debug mode',
    'proxy_check': 'System proxy',
    'suspicious_files_check': 'Suspicious system files',
    'accessibility_check': 'Accessibility service access',
    'notification_access_check': 'Notification access',
    'device_admin_check': 'Device administrator app',
    'ca_cert_check': 'User-added certificate (MITM)',
    'developer_options_check': 'Developer options / ADB',
  };

  /// Loads stored snapshots, oldest first.
  List<SecuritySnapshot> loadSnapshots() {
    final raw = locator.sharedCache.securityHistory;
    final out = <SecuritySnapshot>[];
    for (final entry in raw) {
      try {
        out.add(
          SecuritySnapshot.fromJson(
            jsonDecode(entry) as Map<String, dynamic>,
          ),
        );
      } on Object catch (_) {
        // Skip a corrupt entry rather than losing the whole history.
      }
    }
    out.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return out;
  }

  /// Appends a snapshot for the scan that just finished (trims to [_maxEntries]).
  Future<void> record({
    required int score,
    required RiskLevel risk,
    required List<String> failedRuleIds,
  }) async {
    final snapshot = SecuritySnapshot(
      timestamp: DateTime.now(),
      score: score,
      risk: risk,
      failedRuleIds: failedRuleIds,
    );
    final raw = List<String>.from(locator.sharedCache.securityHistory)
      ..add(jsonEncode(snapshot.toJson()));
    final trimmed = raw.length > _maxEntries
        ? raw.sublist(raw.length - _maxEntries)
        : raw;
    await locator.sharedCache.setSecurityHistory(trimmed);
  }

  Future<void> clear() async {
    await locator.sharedCache.setSecurityHistory(const []);
  }

  /// Builds the timeline (most recent first) by diffing consecutive snapshots.
  List<SecurityTimelineEvent> buildTimeline() {
    final snapshots = loadSnapshots();
    final events = <SecurityTimelineEvent>[];

    for (var i = 0; i < snapshots.length; i++) {
      final curr = snapshots[i];
      if (i == 0) {
        events.add(
          SecurityTimelineEvent(
            timestamp: curr.timestamp,
            change: TimelineChange.baseline,
            message: 'First scan — score ${curr.score}/100',
          ),
        );
        continue;
      }

      final prev = snapshots[i - 1];
      final prevIssues = prev.failedRuleIds.toSet();
      final currIssues = curr.failedRuleIds.toSet();

      for (final id in currIssues.difference(prevIssues)) {
        events.add(
          SecurityTimelineEvent(
            timestamp: curr.timestamp,
            change: TimelineChange.issueAppeared,
            message: '${_label(id)} detected',
          ),
        );
      }
      for (final id in prevIssues.difference(currIssues)) {
        events.add(
          SecurityTimelineEvent(
            timestamp: curr.timestamp,
            change: TimelineChange.issueResolved,
            message: '${_label(id)} resolved',
          ),
        );
      }
      if (curr.score != prev.score) {
        final up = curr.score > prev.score;
        events.add(
          SecurityTimelineEvent(
            timestamp: curr.timestamp,
            change: up ? TimelineChange.scoreUp : TimelineChange.scoreDown,
            message:
                'Safety score ${up ? 'rose' : 'dropped'} '
                '${prev.score} → ${curr.score}',
          ),
        );
      }
    }

    return events.reversed.toList();
  }

  String _label(String ruleId) => _ruleLabels[ruleId] ?? ruleId;
}
