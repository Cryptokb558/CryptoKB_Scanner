# Network Module

## Summary
Live network-stability monitor. Pings a public DNS resolver over TCP every 2s,
charts the last 30 latencies, and logs/persists drops, recoveries and connection
type changes.

## Structures
- `NetworkMonitorService` (service/) — the engine: TCP ping loop, connectivity
  listener, log persistence via `SharedCache.networkLogs`. Exposes a broadcast
  `updates` stream. Feature-specific, not in the locator.
- `NetworkCubit` + `NetworkState` (state/) — owns the service lifecycle and
  mirrors its data into Freezed state. Local BlocProvider in `NetworkView`.
- `NetworkLogEvent` (model/) — persisted event (Equatable, toJson/fromJson).
- `NetworkEventType` (product/enum/) — disconnected / reconnected / typeChanged.
- `LatencyChart` (widget/) — real-time line chart with red drop markers.
- `NetworkLogTile` (widget/) — single event row.

## Notes
- Monitoring starts when the view opens and is disposed when it closes (the
  cubit's `close()` calls `service.dispose()`).
- Uses `connectivity_plus` 6.x which emits `List<ConnectivityResult>`.
