# Security Timeline Module

## Summary
A read-only history of past security scans. After each scan the `SecurityCubit`
records a snapshot; the timeline diffs consecutive snapshots into human-readable
events — "Device administrator app detected", "User-added certificate resolved",
"Safety score dropped 94 → 82" — grouped by day, most recent first.

## How it works
- `SecuritySnapshot` (model/) — `{timestamp, score, risk, failedRuleIds}`,
  JSON-serializable. Persisted as a `List<String>` under
  `SharedKeys.securityHistory` (mirrors the network-logs pattern).
- `SecurityHistoryService` (service/):
  - `record(...)` — called by `SecurityCubit.scan()` on completion; trims to the
    last 50 entries.
  - `buildTimeline()` — diffs each snapshot against the previous one (newly
    failed rules = "detected", newly passed = "resolved", plus score moves) and
    returns `SecurityTimelineEvent`s newest-first. The first snapshot is a
    "First scan" baseline.
  - `clear()` — wipes history (exposed via the app-bar trash action).
- `SecurityTimelineEvent` + `TimelineChange` (model/) — message + icon/color.
- `SecurityTimelineView` — day-grouped list with an empty state.

## Access
- App-bar history icon on the Security screen (`SecurityTimelineRoute`,
  `/security-timeline`).

## Notes
- No new dependency: month names are formatted inline (no `intl`).
- Stores only summaries (ids + score), never per-app or personal data.
