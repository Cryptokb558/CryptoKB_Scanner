# Android Security Scanner — Project Notes (Handoff)

> Read this together with `doc/project.md`. This file explains what this app is
> and what was added on top of the starter template, so the next session can
> continue smoothly.

## What this app is

An **Android-focused device security & network-stability** app. It was started
because a device kept dropping its internet connection and there was a suspicion
of spyware/unauthorized monitoring. Two goals:

1. **Security Scan** — heuristic, on-device checks for tampering indicators
   (root/jailbreak, active VPN/tunnel, system proxy, emulator, debug mode,
   suspicious system files) → a weighted 0–100 safety score.
2. **Network Monitor** — live TCP "ping" to `1.1.1.1:53` every 2s, a latency
   chart of the last 30 samples, and a persisted log of drops / recoveries /
   connection-type changes.
3. **Privacy Guide** — a manual Android audit checklist for things the OS does
   not let an app verify automatically (Accessibility services, Device Admin,
   Notification access, Overlay, Battery exceptions, Play Protect).

> The automated checks are **heuristics** — they cannot detect well-hidden
> stalkerware. That is intentionally complemented by the manual Privacy Guide.

## How it maps onto the template

This was built by porting an older flat `services/widgets/screens` Flutter app
into this template's architecture (Cubit + Freezed + GoRouter + GetIt). UI uses
Material 3 theme colors; the two CustomPainters keep a small neon accent palette.

| Feature | Location | State | Notes |
|---|---|---|---|
| Security | `lib/feature/security/` | `SecurityCubit` + Freezed `SecurityState` (local BlocProvider) | `SecurityService` (feature service, not in locator) |
| Network | `lib/feature/network/` | `NetworkCubit` + Freezed `NetworkState` (local BlocProvider) | `NetworkMonitorService` exposes a broadcast `updates` stream; cubit mirrors it; `dispose()` on close |
| Privacy Guide | `lib/feature/privacy_guide/` | StatefulWidget + ViewModel (in-memory checklist) | no persistence |

Each feature has a `<feature>.md` describing it.

### Shared / infra changes
- `lib/product/enum/check_severity.dart` — `CheckSeverity` (low/medium/high + color).
- `lib/product/enum/network_event_type.dart` — `NetworkEventType` (+ icon/color).
- `SharedKeys.networkLogs` + `SharedCache.networkLogs` getter/setter
  (`List<String>` of JSON-encoded `NetworkLogEvent`s) for offline log persistence.
- Routes added under `HomeRoute` in `app_router.dart`:
  `SecurityRoute` (`/security`), `NetworkRoute` (`/network`),
  `PrivacyGuideRoute` (`/privacy-guide`).
- `home_view.dart` repurposed as a dashboard with 3 feature cards.
- `pubspec.yaml` deps added: `connectivity_plus: ^6.1.0`, `device_info_plus: ^11.1.0`.

## Decisions / caveats

- **Localization:** per the owner's request, the new feature UI uses **plain
  English strings** (no `LocaleKeys`/translations yet). The template's existing
  screens still use `LocaleKeys`.
- **`easy_localization:generate` gotcha:** the generator derives keys from the
  **alphabetically first** file in `--source-dir`, which is `ar.json` (it is
  missing the newer `androidModules`/`settings` keys). Regenerate from `en.json`
  only, e.g.:
  ```bash
  mkdir -p /tmp/loc_en && cp assets/translations/en.json /tmp/loc_en/
  flutter pub run easy_localization:generate -O lib/product/init/language \
    -f keys -o locale_keys.g.dart --source-dir /tmp/loc_en
  ```
- The demo screens (`material_widgets`, `cupertino_widgets`, `android_modules`)
  and their routes are still present but no longer linked from Home. They can be
  deleted if not needed.
- Dart package name is still `akillisletme` (imports use `package:akillisletme/`).
  Renaming is an optional, separate step.

## Native deep-scan (added)
A `device_security` MethodChannel (`scan` method) is now wired in
`MainActivity.kt`; the logic lives in
`android/.../security/SecurityScanner.kt` (read-only, best-effort). The Dart
`SecurityService` fetches this report once per scan and exposes it as rules:
- **Accessibility services** enabled — top stalkerware keylogging vector.
- **Notification listeners** — apps reading all notifications / OTP codes.
- **Device-admin apps** — spyware that resists uninstall.
- **User-added CA certificates** — MITM / HTTPS interception (`AndroidCAStore`,
  `user:` aliases).
- **Developer options / ADB-over-Wi-Fi** — remote attack surface.
- Authoritative **VPN** (transport-based) + executable **`su`** check that
  strengthen the existing root/VPN rules.

The report is Android-only; on other platforms those rules pass with a
"not available" note.

## Stalkerware Risk + Risky Apps Scanner (added)
- **Stalkerware Risk banner** (`feature/security/widget/stalkerware_banner.dart`):
  aggregates the spyware-relevant checks (accessibility, notification, device
  admin, user CA, root, VPN, proxy) into one Low/Medium/High verdict shown atop
  the Security screen after a scan. Logic lives in `SecurityState`
  (`stalkerwareIndicators` / `stalkerwareRisk`).
- **Risky Apps Scanner** (`feature/app_scanner/`, new route `/app-scan`, home
  card): enumerates installed apps and scores each (accessibility, device admin,
  notification, overlay, sideloaded, recent install) → Low/Medium/High, with
  granted dangerous permissions listed. Native side:
  `SecurityScanner.scanInstalledApps` (`scanApps` channel method); needs
  `QUERY_ALL_PACKAGES` (added to manifest). See `feature/app_scanner/app_scanner.md`.
- Shared `RiskLevel` enum in `product/enum/risk_level.dart`.

## Security Timeline (added)
`feature/security_timeline/` — read-only history of past scans. `SecurityCubit`
records a `SecuritySnapshot` after each scan (persisted under
`SharedKeys.securityHistory`, last 50). `SecurityHistoryService.buildTimeline()`
diffs consecutive snapshots into events ("Device administrator app detected",
"User-added certificate resolved", "Safety score dropped 94 → 82"). Reached via
the history icon on the Security screen (`/security-timeline`). See
`feature/security_timeline/security_timeline.md`.

## App name
Launcher / task-switcher name is set via `android:label="Security Scanner"` in
`AndroidManifest.xml`. (Dart package id is still `akillisletme` — cosmetic.)

## Status
- `dart run build_runner build --delete-conflicting-outputs` ✅
- `flutter analyze` → **No issues found** ✅
- `flutter build apk --debug` → **built** ✅ (native Kotlin compiles)
- Still verifying scan behavior on real hardware.

## Ideas for next (finer still)
- Enumerate installed apps holding overlay (`SYSTEM_ALERT_WINDOW`) permission and
  flag sideloaded ones (needs `QUERY_ALL_PACKAGES` — Play policy implications).
- Play Integrity attestation instead of file-path/`su` root heuristics.
- Frida/hooking detection (scan `/proc/self/maps`, port 27042) — fragile but
  catches active instrumentation.
- Per-app battery/data usage anomalies (`UsageStatsManager`, needs user grant).
