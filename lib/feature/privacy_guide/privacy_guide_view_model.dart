import 'package:akillisletme/feature/privacy_guide/model/privacy_step.dart';
import 'package:akillisletme/feature/privacy_guide/privacy_guide_view.dart';
import 'package:akillisletme/product/enum/check_severity.dart';
import 'package:flutter/material.dart';

abstract class PrivacyGuideViewModel extends State<PrivacyGuideView> {
  /// Ids of steps the user has marked as done.
  final Set<String> checkedIds = {};

  void toggle(String id, {required bool value}) {
    setState(() {
      if (value) {
        checkedIds.add(id);
      } else {
        checkedIds.remove(id);
      }
    });
  }

  bool isChecked(String id) => checkedIds.contains(id);

  /// Android-specific manual audit steps, ordered by risk.
  final List<PrivacyStep> steps = const [
    PrivacyStep(
      id: 'accessibility',
      title: 'Accessibility Services',
      risk: CheckSeverity.high,
      description:
          'Keyloggers and screen-monitoring spyware abuse this permission to '
          'read your passwords and messages.',
      instructions:
          'Settings > Accessibility > Installed/Downloaded services. Do NOT '
          'grant this to any app you do not fully trust; revoke unknown ones.',
    ),
    PrivacyStep(
      id: 'device_admin',
      title: 'Device Admin Apps',
      risk: CheckSeverity.high,
      description:
          'Apps with device-admin rights can stop you from uninstalling them, '
          'lock the screen, or wipe data.',
      instructions:
          'Settings > Security > Device admin apps. Revoke anything suspicious '
          'except Google Play Protect and Find My Device.',
    ),
    PrivacyStep(
      id: 'notification_access',
      title: 'Notification Access & SMS',
      risk: CheckSeverity.medium,
      description:
          'Spyware that wants your banking / 2FA codes will try to read your '
          'notifications.',
      instructions:
          'Settings > Apps > Special app access > Notification access. Allow '
          'only trusted system services.',
    ),
    PrivacyStep(
      id: 'overlay',
      title: 'Display Over Other Apps',
      risk: CheckSeverity.medium,
      description:
          'Malicious apps can draw a fake screen (overlay) on top of your real '
          'banking app to steal your password.',
      instructions:
          'Settings > Apps > Special app access > Display over other apps. '
          'Review and disable for unknown apps.',
    ),
    PrivacyStep(
      id: 'battery',
      title: 'Battery Optimization Exceptions',
      risk: CheckSeverity.low,
      description:
          'Spyware exempts itself from battery saving to stay alive in the '
          'background — which also drains battery and disrupts connectivity.',
      instructions:
          'Settings > Apps > Special app access > Battery optimization. '
          'Restrict unnecessary background apps.',
    ),
    PrivacyStep(
      id: 'play_protect',
      title: 'Google Play Protect Scan',
      risk: CheckSeverity.low,
      description:
          'Play Protect scans installed apps for known malware and stalkerware.',
      instructions:
          'Play Store > Profile > Play Protect > Scan. Review any flagged or '
          'sideloaded (unknown-source) apps.',
    ),
  ];
}
