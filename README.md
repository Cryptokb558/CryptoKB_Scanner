# 🛡️ Android Security Scanner

A privacy-first **device security & network-stability** app for Android, built
with Flutter. It scans your phone for tampering and surveillance indicators,
flags risky apps, watches your network for drops, and keeps a timeline of how
your security posture changes over time.

> **Why it exists:** the project started from a real problem — a phone that kept
> dropping its internet connection, with a suspicion of spyware. So it combines
> automated heuristic checks with a manual audit guide and live network
> monitoring.

> **100% on-device.** Every check runs locally. The app has no backend and sends
> nothing off your phone.

---

## ✨ Features

### 🔍 Security Scan
Heuristic + native checks, scored into a weighted **0–100 safety score** on an
animated gauge:
- Root / jailbreak (file paths **and** an executable `su` probe)
- Active VPN / tunnel (transport-based, via `ConnectivityManager`)
- System proxy & emulator / debug detection
- Suspicious system files
- **Accessibility services** — the #1 stalkerware keylogging vector
- **Notification access** — apps reading all your messages / OTP codes
- **Device administrator** apps that resist uninstall
- **User-added CA certificates** — possible HTTPS man-in-the-middle
- **Developer options / ADB-over-Wi-Fi** — remote attack surface

### 🕵️ Stalkerware Risk
Aggregates the spyware-relevant checks into a single **LOW / MEDIUM / HIGH**
verdict — a direct answer to "is my phone being watched?". Flagged apps are
tappable and deep-link straight into the system **App info** screen.

### 📱 Risky Apps Scanner
Enumerates installed apps and assigns each a risk level from its capabilities:
accessibility access, device-admin rights, notification access, drawing over
other apps, **sideloaded source** (installed outside an app store), recent
install, and granted dangerous permissions (camera, mic, location, SMS…).

### 📈 Network Monitor
TCP "ping" to a public DNS resolver every 2s, a **live latency chart**, and a
persisted log of drops, recoveries and connection-type changes.

### 🧭 Security Timeline
Records a snapshot after each scan and **diffs consecutive scans** into a
human-readable history: *"Device administrator app detected"*, *"User-added
certificate resolved"*, *"Safety score dropped 94 → 82"*.

### ✅ Privacy Guide
A manual Android audit checklist for things the OS won't let an app verify
automatically.

---

## 🏗️ Architecture

Feature-first, clean separation:

```
lib/
├── feature/            # each feature: view + state (cubit) + service + model + widget
│   ├── security/       #   + a <feature>.md describing it
│   ├── app_scanner/
│   ├── network/
│   ├── security_timeline/
│   ├── privacy_guide/
│   └── home/
└── product/            # shared: theme, navigation, cache, enums, DI
```

- **State:** `flutter_bloc` (Cubit) + `freezed` immutable states
- **Routing:** `go_router` (typed routes)
- **DI:** `get_it`
- **Persistence:** `shared_preferences`
- **Native bridge:** a `device_security` `MethodChannel`
  (`android/.../security/SecurityScanner.kt`) reaches platform APIs the Flutter
  sandbox cannot.

---

## 🚀 Getting Started

```bash
# 1. Install dependencies
flutter pub get

# 2. Generate code (freezed / json / router are git-ignored and must be built)
dart run build_runner build --delete-conflicting-outputs

# 3. Run on an Android device
flutter run
```

Requirements: Flutter (Dart SDK ≥ 3.10), an Android device or emulator.

> Generated files (`*.g.dart`, `*.freezed.dart`) are intentionally not committed,
> so **step 2 is required** after every clone or after changing a model/route.

---

## 🔐 Permissions & Privacy

- `QUERY_ALL_PACKAGES` — needed to enumerate installed apps for the Risky Apps /
  stalkerware scan (a Play-allowed use for a security/antivirus app).
- `SYSTEM_ALERT_WINDOW`, `FOREGROUND_SERVICE` — for the optional floating overlay.
- All scanning is **read-only** and **on-device**. No analytics, no network
  uploads, no account.

---

## ⚠️ Disclaimer

These checks are **best-effort heuristics**. They surface common tampering and
surveillance indicators but cannot detect a perfectly hidden, well-resourced
implant. Treat this as an awareness tool, not a guarantee — and complement it
with the built-in Privacy Guide. Android-only (iOS is not currently configured).

---

## 📸 Screenshots

> _Add screenshots here_ (e.g. drop images in `app_image/` and link them).

---

## 🤝 Contributing

Issues and PRs are welcome. Please run `flutter analyze` (zero issues) and
`dart run build_runner build` before submitting.

## 📄 License

Released under the MIT License — see [`LICENSE`](LICENSE).
