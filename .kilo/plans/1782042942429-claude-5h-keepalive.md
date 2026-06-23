# Plan: Claude 5-Hour Keep-Alive "Hi" Ping

**Goal**  
Every 5 hours, for the active profile only, send an authenticated "Hi" message to Claude using the existing incognito conversation flow. On success, trigger a usage refresh so the 5-hour session window resets visibly in the UI. Survive app restarts via UserDefaults timestamp. Always-on, no user toggle.

**Key Decisions**
- New dedicated singleton `ClaudeKeepAliveService` (clean separation from `AutoStartSessionService`).
- Reuse `ClaudeAPIService.createIncognitoConversationAndSendHi()` + immediate delete (already implemented).
- Active profile only.
- Last successful ping timestamp stored in `UserDefaults` as `keepalive.lastPing.<profileUUID>`.
- After successful ping: call `MenuBarManager.refreshUsage()` (or equivalent) so UI updates.
- Always-on: started unconditionally from `AppDelegate` (like `HeartbeatService`).
- 5-hour interval (`Constants.sessionWindow`).
- Timer tolerance ~10% for energy efficiency.
- No new UI or settings.

**Ordered Implementation Tasks**
1. Create `ClaudeKeepAliveService.swift` (new file) modeled on `HeartbeatService.swift`.
   - Singleton, `@MainActor`.
   - `start()`: send immediately if 5h elapsed, schedule repeating `Timer` (interval = `Constants.sessionWindow`).
   - `sendKeepAliveIfNeeded()`: check `UserDefaults` timestamp for active profile; if eligible, call `ClaudeAPIService` incognito "Hi", update timestamp on success, then trigger usage refresh.
2. Add `ClaudeAPIService` helper if missing: expose `sendIncognitoHi()` (or reuse existing private methods used by `AutoStartSessionService`).
3. Wire into `AppDelegate.swift`: call `ClaudeKeepAliveService.shared.start()` after other services (near `HeartbeatService`).
4. Add constant if needed: `Constants.KeepAlive.interval` (reuse `sessionWindow`).
5. Update `Constants.swift` only if new key is required; otherwise keep minimal.

**Risks / Edge Cases**
- No credentials on active profile → silently skip (same pattern as refresh).
- Profile switched while timer running → next tick uses new active profile's timestamp.
- App sleep/wake → timer drifts tolerated; no special wake handling required (5h granularity).
- Multiple rapid launches → `sendIfNeeded` guard prevents duplicate pings.
- Network failure → log, do not update timestamp, retry on next cycle.
- Incognito delete fails → still count as successful keep-alive (history pollution risk is low; existing code already does this).

**Validation Steps**
- Build succeeds with zero errors.
- Manual test: set active profile with valid Claude.ai key, wait/force 5h interval, confirm "Hi" appears in network logs, conversation is created+deleted, usage refresh fires, 5-hour ring resets.
- App restart: timestamp persists, next cycle respects elapsed time.
- Switch profiles: only active profile's timestamp is consulted.
- No visible chat history left in Claude account.

**Open Questions**  
None — all design decisions resolved.
