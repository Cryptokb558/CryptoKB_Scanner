# App Scanner (Risky Apps) Module

## Summary
Enumerates installed apps and assigns each a **Low / Medium / High** risk level,
so the user can spot stalkerware and over-privileged apps. Each app is tappable
and deep-links into the system "App info" screen to review or uninstall.

## Signals (collected natively)
Per app, from `SecurityScanner.scanInstalledApps` over the `device_security`
channel (`scanApps` method):
- **Accessibility access** (+3) — top stalkerware keylogging vector.
- **Device administrator** (+2) — resists uninstall.
- **Notification access** (+2) — reads all messages / OTP codes.
- **Overlay** / draws over other apps (+1).
- **Sideloaded** — installed from outside a trusted app store (+2).
- **Recently installed** — within the last 30 days (+1).
- Granted **dangerous permissions** (camera, mic, location, SMS, …) — shown for
  transparency, not scored (almost every app holds some).

Risk score → level: `>= 5` High, `>= 2` Medium, else Low. Stock system apps with
no sensitive capability are skipped natively to keep the list focused.

## Structures
- `RiskyApp` (model/) — app + signals; computes `riskScore` / `riskLevel` /
  `reasons` in Dart so weighting is tunable without a rebuild.
- `AppScanService` (service/) — calls the native channel, maps + sorts by risk.
- `AppScanCubit` + `AppScanState` (state/) — runs the scan, exposes counts.
- `RiskyAppTile` (widget/) — expandable card: risk pill, reason/permission chips,
  "Open app settings" button (reuses `SecurityService.openAppSettings`).
- `RiskLevel` (product/enum/) — Low/Medium/High with label + color.

## Notes
- Requires `QUERY_ALL_PACKAGES` (Play-allowed for a security/antivirus app),
  declared in `AndroidManifest.xml`.
- Android-only; returns an empty list elsewhere.
- BlocProvider is local to `AppScanView`.
