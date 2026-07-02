import 'dart:io';

import 'package:cryptokb_scanner/feature/security/model/security_rule_check.dart';
import 'package:cryptokb_scanner/product/enum/check_severity.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Heuristic, on-device security scanning engine.
///
/// Feature-specific service (not registered in the locator). Only consumed by
/// `SecurityCubit`. All checks are best-effort heuristics — they cannot detect
/// a well-hidden spyware, but they surface common tampering indicators.
///
/// The Dart-only checks are complemented by a native Android report fetched
/// over the `device_security` MethodChannel (see `SecurityScanner.kt`), which
/// reaches platform APIs the Flutter sandbox cannot (accessibility services,
/// device admins, notification listeners, user CA certs, …).
class SecurityService {
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  static const MethodChannel _channel = MethodChannel('device_security');

  /// Native report for the current scan, fetched once at the start of
  /// [runAllChecks]. `null` on non-Android platforms or if the channel fails.
  Map<String, dynamic>? _nativeReport;

  /// The full rule catalogue, in scan order, before any result is attached.
  List<SecurityRuleCheck> getInitialRules() {
    return const [
      SecurityRuleCheck(
        id: 'root_check',
        title: 'Root / Jailbreak Detection',
        description: 'Checks whether the device system locks have been removed.',
        explanation:
            'A rooted device lets attackers gain full system access and '
            'disable security controls. Spyware commonly relies on root '
            'privileges.',
        severity: CheckSeverity.high,
        category: 'System',
      ),
      SecurityRuleCheck(
        id: 'vpn_check',
        title: 'Active VPN / Tunnel',
        description: 'Checks whether traffic is routed through a VPN or tunnel.',
        explanation:
            'A VPN can be legitimate, but a tunnel running without your '
            'knowledge may redirect your traffic (passwords, messages) to an '
            "attacker's servers.",
        severity: CheckSeverity.medium,
        category: 'Network',
      ),
      SecurityRuleCheck(
        id: 'emulator_check',
        title: 'Emulator Detection',
        description: 'Checks whether the app runs on real hardware.',
        explanation:
            'Analysis tools and spyware are often tested on emulators. On a '
            'real device this should pass. If a physical device is reported as '
            'an emulator, the OS may be heavily manipulated.',
        severity: CheckSeverity.medium,
        category: 'System',
      ),
      SecurityRuleCheck(
        id: 'debug_check',
        title: 'Debug Mode',
        description: 'Checks whether the app is running under a debugger.',
        explanation:
            'If an app is attached to a debugger, memory and variables can be '
            'read externally. Secure builds should run in release mode.',
        severity: CheckSeverity.low,
        category: 'System',
      ),
      SecurityRuleCheck(
        id: 'proxy_check',
        title: 'System Proxy',
        description: 'Checks whether a proxy server is configured.',
        explanation:
            'A proxy can route all of your web traffic through a listening '
            'server (man-in-the-middle).',
        severity: CheckSeverity.high,
        category: 'Network',
      ),
      SecurityRuleCheck(
        id: 'suspicious_files_check',
        title: 'Suspicious System Files',
        description: 'Scans for file paths commonly used by malicious tools.',
        explanation:
            'Files left behind by superuser managers or unauthorized access '
            'tools indicate the device was or is being tampered with.',
        severity: CheckSeverity.high,
        category: 'File System',
      ),
      // ── Native (Android platform API) checks ──────────────────
      SecurityRuleCheck(
        id: 'accessibility_check',
        title: 'Accessibility Service Abuse',
        description: 'Lists apps with Accessibility access.',
        explanation:
            'Around 90% of commercial spyware abuses Accessibility services to '
            'log keystrokes and read everything on your screen — including '
            'messages and passwords — without needing root. Any app here that '
            'you did not knowingly enable is a strong spyware indicator.',
        severity: CheckSeverity.high,
        category: 'Spyware',
      ),
      SecurityRuleCheck(
        id: 'notification_access_check',
        title: 'Notification Access',
        description: 'Lists apps that can read all notifications.',
        explanation:
            'An app with notification access can read every incoming message '
            'and one-time code. Stalkerware uses this for continuous '
            'monitoring.',
        severity: CheckSeverity.high,
        category: 'Spyware',
      ),
      SecurityRuleCheck(
        id: 'device_admin_check',
        title: 'Device Administrator Apps',
        description: 'Lists apps holding device-admin rights.',
        explanation:
            'Spyware grants itself device-admin rights so it cannot be '
            'uninstalled normally. Revoke admin for any app you do not '
            'recognize before removing it.',
        severity: CheckSeverity.high,
        category: 'Spyware',
      ),
      SecurityRuleCheck(
        id: 'ca_cert_check',
        title: 'User-Added Certificates (MITM)',
        description: 'Checks for manually installed trust certificates.',
        explanation:
            'A Certificate Authority you did not install yourself lets someone '
            'decrypt and read your HTTPS traffic (man-in-the-middle). This is a '
            'common interception setup.',
        severity: CheckSeverity.high,
        category: 'Network',
      ),
      SecurityRuleCheck(
        id: 'developer_options_check',
        title: 'Developer Options / ADB',
        description: 'Checks developer options and USB/Wi-Fi debugging.',
        explanation:
            'Wireless debugging (ADB over Wi-Fi) is a remote attack surface. '
            'Unless you are actively developing, these should be off.',
        severity: CheckSeverity.medium,
        category: 'System',
      ),
    ];
  }

  /// Runs every rule sequentially and returns the rules with results attached.
  ///
  /// [onProgress] fires after each individual check completes, so the UI can
  /// animate results in one by one.
  Future<List<SecurityRuleCheck>> runAllChecks({
    void Function(SecurityRuleCheck result)? onProgress,
  }) async {
    final results = <SecurityRuleCheck>[];

    // One native round-trip per scan; all native checks read this cache.
    _nativeReport = await _loadNativeReport();

    for (final rule in getInitialRules()) {
      // Small delay so the scanning animation reads naturally.
      await Future<void>.delayed(const Duration(milliseconds: 300));

      var isPassed = true;
      var detailMessage = 'No issue detected.';
      var apps = const <AppRef>[];

      try {
        switch (rule.id) {
          case 'root_check':
            final root = await _checkRootStatus();
            final suFound = _nativeBool('suBinaryFound');
            isPassed = !root.isTriggered && !suFound;
            detailMessage = suFound
                ? 'Root indicator: an "su" binary is executable on this device.'
                : root.message;
          case 'vpn_check':
            // Native transport check is authoritative; fall back to interface
            // name scanning when the native report is unavailable.
            final vpn = _nativeReport != null
                ? _nativeBool('vpnActive')
                : await _checkVpnStatus();
            isPassed = !vpn;
            detailMessage = vpn
                ? 'An active VPN / tunnel interface was found. If you did not '
                      'enable it, investigate.'
                : 'No active tunnel/VPN connection detected.';
          case 'emulator_check':
            final emulator = await _checkEmulatorStatus();
            isPassed = !emulator;
            detailMessage = emulator
                ? 'The app is running on a virtual device (emulator).'
                : 'The app is running on physical hardware.';
          case 'debug_check':
            isPassed = !kDebugMode;
            detailMessage = kDebugMode
                ? 'The app is running in developer debug mode.'
                : 'The app is running in secure release mode.';
          case 'proxy_check':
            final proxy = _checkProxyStatus();
            isPassed = !proxy;
            detailMessage = proxy
                ? 'An active proxy is configured for system traffic!'
                : 'No active proxy server is configured.';
          case 'suspicious_files_check':
            final files = await _checkSuspiciousFiles();
            isPassed = !files.isTriggered;
            detailMessage = files.message;
          case 'accessibility_check':
            apps = _nativeApps('accessibilityServices');
            isPassed = apps.isEmpty;
            detailMessage = apps.isEmpty
                ? 'No accessibility services are enabled.'
                : '${apps.length} app(s) have accessibility access — '
                      'tap each to review.';
          case 'notification_access_check':
            apps = _nativeApps('notificationListeners');
            isPassed = apps.isEmpty;
            detailMessage = apps.isEmpty
                ? 'No app can read your notifications.'
                : '${apps.length} app(s) can read all notifications — '
                      'tap each to review.';
          case 'device_admin_check':
            apps = _nativeApps('deviceAdmins');
            isPassed = apps.isEmpty;
            detailMessage = apps.isEmpty
                ? 'No app holds device-administrator rights.'
                : '${apps.length} app(s) hold device-admin rights — '
                      'tap each to review.';
          case 'ca_cert_check':
            final r = _nativeList('userCaCerts');
            isPassed = r.isEmpty;
            detailMessage = r.isEmpty
                ? 'No user-added trust certificates found.'
                : 'User-added certificate(s) — possible MITM:\n• '
                      '${r.join('\n• ')}';
          case 'developer_options_check':
            final adbWifi = _nativeBool('adbWifiEnabled');
            final adb = _nativeBool('adbEnabled');
            final dev = _nativeBool('developerOptionsEnabled');
            // Wireless debugging is the real risk; plain dev options is minor.
            isPassed = !adbWifi;
            if (adbWifi) {
              detailMessage = 'Wireless debugging (ADB over Wi-Fi) is ON — a '
                  'remote attack surface. Turn it off if not developing.';
            } else if (adb || dev) {
              detailMessage = 'Developer options / USB debugging is enabled. '
                  'Fine while developing, otherwise turn it off.';
            } else {
              detailMessage = 'Developer options and debugging are off.';
            }
        }
      } on Object catch (e) {
        isPassed = true;
        detailMessage = 'Check skipped due to an error: $e';
      }

      final result = rule.copyWith(
        isPassed: isPassed,
        detailMessage: detailMessage,
        apps: apps,
      );
      results.add(result);
      onProgress?.call(result);
    }

    return results;
  }

  // ── Native bridge ───────────────────────────────────────────

  /// Fetches the platform security report. Returns `null` on non-Android
  /// platforms or when the channel is unavailable (so callers stay heuristic).
  Future<Map<String, dynamic>?> _loadNativeReport() async {
    if (!Platform.isAndroid) return null;
    try {
      final raw = await _channel.invokeMapMethod<String, dynamic>('scan');
      return raw;
    } on Object catch (_) {
      return null;
    }
  }

  /// Reads a `List<String>` field from the native report (empty if absent).
  List<String> _nativeList(String key) {
    final value = _nativeReport?[key];
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    return const [];
  }

  /// Reads a `bool` field from the native report (false if absent).
  bool _nativeBool(String key) => _nativeReport?[key] == true;

  /// Reads a `List<{package,label}>` field as typed [AppRef]s (empty if absent).
  List<AppRef> _nativeApps(String key) {
    final value = _nativeReport?[key];
    if (value is! List) return const [];
    return value.whereType<Map<Object?, Object?>>().map((m) {
      final pkg = m['package']?.toString() ?? '';
      final label = m['label']?.toString();
      return AppRef(
        packageName: pkg,
        label: (label == null || label.isEmpty) ? pkg : label,
      );
    }).toList();
  }

  /// Opens the system "App info" screen for [packageName] (Android only).
  /// Returns `true` when the screen was launched.
  static Future<bool> openAppSettings(String packageName) async {
    if (!Platform.isAndroid) return false;
    try {
      final ok = await _channel.invokeMethod<bool>(
        'openAppSettings',
        {'package': packageName},
      );
      return ok ?? false;
    } on Object catch (_) {
      return false;
    }
  }

  // ── Heuristics ──────────────────────────────────────────────

  Future<_CheckResult> _checkRootStatus() async {
    try {
      if (Platform.isAndroid) {
        final info = await _deviceInfo.androidInfo;
        if (!info.isPhysicalDevice) {
          return const _CheckResult(
            isTriggered: false,
            message: 'Root test passed (emulator detected).',
          );
        }
        if (info.tags.contains('test-keys')) {
          return const _CheckResult(
            isTriggered: true,
            message: 'Root indicator: OS built with test-keys (custom signing).',
          );
        }
      } else if (Platform.isIOS) {
        final info = await _deviceInfo.iosInfo;
        if (!info.isPhysicalDevice) {
          return const _CheckResult(
            isTriggered: false,
            message: 'Jailbreak test passed (simulator detected).',
          );
        }
      }
    } on Object catch (_) {}

    final paths = Platform.isAndroid
        ? const [
            '/system/app/Superuser.apk',
            '/sbin/su',
            '/system/bin/su',
            '/system/xbin/su',
            '/data/local/xbin/su',
            '/data/local/bin/su',
            '/system/sd/xbin/su',
            '/system/bin/failsafe/su',
            '/data/local/su',
            '/su/bin/su',
          ]
        : const [
            '/Applications/Cydia.app',
            '/Library/MobileSubstrate/MobileSubstrate.dylib',
            '/bin/bash',
            '/usr/sbin/sshd',
            '/etc/apt',
            '/private/var/lib/apt/',
          ];

    for (final path in paths) {
      try {
        if (File(path).existsSync()) {
          return _CheckResult(
            isTriggered: true,
            message: 'Root/Jailbreak indicator: suspicious file found: $path',
          );
        }
      } on Object catch (_) {}
    }

    return const _CheckResult(
      isTriggered: false,
      message: 'Device does not appear to be rooted/jailbroken (safe).',
    );
  }

  Future<bool> _checkVpnStatus() async {
    try {
      final interfaces = await NetworkInterface.list();
      for (final interface in interfaces) {
        final name = interface.name.toLowerCase();
        if (name.contains('tun') ||
            name.contains('ppp') ||
            name.contains('tap') ||
            name.contains('p2p') ||
            name.contains('wireguard') ||
            name.contains('wg') ||
            name.contains('vpn')) {
          return true;
        }
      }
    } on Object catch (_) {}
    return false;
  }

  Future<bool> _checkEmulatorStatus() async {
    try {
      if (Platform.isAndroid) {
        final info = await _deviceInfo.androidInfo;
        return !info.isPhysicalDevice;
      } else if (Platform.isIOS) {
        final info = await _deviceInfo.iosInfo;
        return !info.isPhysicalDevice;
      }
    } on Object catch (_) {}
    return false;
  }

  bool _checkProxyStatus() {
    try {
      final proxy = HttpClient.findProxyFromEnvironment(
        Uri.parse('https://google.com'),
      );
      if (proxy != 'DIRECT' && proxy.isNotEmpty) return true;
    } on Object catch (_) {}
    return false;
  }

  Future<_CheckResult> _checkSuspiciousFiles() async {
    final paths = Platform.isAndroid
        ? const [
            '/system/bin/.ext',
            '/system/usr/we-need-root',
            '/system/app/Kinguser.apk',
            '/system/bin/failsafe/su',
            '/data/local/bin/su',
          ]
        : const [
            '/Applications/RockApp.app',
            '/Applications/Icy.app',
            '/usr/bin/sshd',
            '/usr/libexec/sftp-server',
            '/Applications/FakeCarrier.app',
          ];

    for (final path in paths) {
      try {
        if (File(path).existsSync()) {
          return _CheckResult(
            isTriggered: true,
            message: 'Suspicious system file found: $path',
          );
        }
      } on Object catch (_) {}
    }
    return const _CheckResult(
      isTriggered: false,
      message: 'No suspicious files or modified folders found.',
    );
  }
}

@immutable
class _CheckResult {
  const _CheckResult({required this.isTriggered, required this.message});
  final bool isTriggered;
  final String message;
}
