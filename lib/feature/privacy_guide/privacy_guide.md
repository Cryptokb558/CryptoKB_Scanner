# Privacy Guide Module

## Summary
Manual, Android-specific spyware audit checklist. Complements the automated
Security Scan with steps the OS does not let an app verify on its own
(Accessibility, Device Admin, Notification access, Overlay, Battery, Play
Protect). Each step shows the spyware risk and exactly where to go in Settings.

## Structures
- `PrivacyStep` (model/) — id, title, risk (`CheckSeverity`), description,
  instructions.
- `PrivacyGuideView` + `PrivacyGuideViewModel` — StatefulWidget + ViewModel. The
  ViewModel holds the step list and the in-memory checked set + progress.
- `PrivacyStepTile` (widget/) — checklist card with risk badge and instructions.

## Notes
- Check state is in-memory only (resets when the screen closes) — it is a
  guided checklist, not persisted settings.
