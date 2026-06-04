# Security Module

## Summary
On-device security scan. Runs a set of rules and produces a weighted 0–100
safety score shown on an animated gauge. Two tiers of checks:

- **Dart heuristics** (`dart:io` / `device_info_plus`): root/jailbreak,
  VPN/tunnel, emulator, debug mode, system proxy, suspicious files.
- **Native Android signals** over the `device_security` MethodChannel
  (`SecurityScanner.kt`) — reach platform APIs the Flutter sandbox cannot:
  - **Accessibility services** enabled (top stalkerware keylogging vector).
  - **Notification listeners** (apps reading all notifications / OTP codes).
  - **Device-admin apps** (spyware that resists uninstall).
  - **User-added CA certificates** (man-in-the-middle / traffic interception).
  - **Developer options / ADB-over-Wi-Fi** (remote attack surface).
  - Authoritative **VPN** (transport-based) and executable **`su`** root check,
    which strengthen the corresponding Dart rules.

## Structures
- `SecurityService` (service/) — scan engine. Feature-specific, not in the
  locator. Fetches the native report once per scan; each native rule reads it.
- `SecurityCubit` + `SecurityState` (state/) — runs the scan, streams results in
  one by one, computes the severity-weighted score.
- `SecurityRuleCheck` (model/) — immutable rule + result (Equatable).
- `CheckSeverity` (product/enum/) — low / medium / high with label + color.
- `CircularGauge` (widget/) — animated neon score gauge (CustomPainter).
- `SecurityRuleTile` (widget/) — expandable rule card with status + explanation.

## Notes
- Checks are best-effort; they cannot detect a perfectly hidden spyware. The
  native signals (accessibility/admin/notification/CA) catch the common
  commercial stalkerware that relies on standard Android permissions.
- The native report is Android-only; on other platforms those rules pass with a
  "not available" message and the scan stays heuristic.
- The Privacy Guide feature complements this with a manual audit checklist.
- BlocProvider is local to `SecurityView` (state is not needed elsewhere).
- Native scanner: `android/.../security/SecurityScanner.kt`, wired in
  `MainActivity.kt` (`device_security` channel, `scan` method). Read-only.
