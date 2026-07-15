# Auto-Rejoin Watchdog Design

## Scope

Add an optional executor-side recovery watchdog to V6. Detect prolonged in-game teleport loading or a visible disconnect prompt, record diagnostic events, and attempt to return to the Iron Soul Dungeon lobby. Preserve V5 and existing dungeon, replay, auto-sell, and auto-start behavior.

## Menu

Add one persisted toggle to the existing V6 menu:

```text
AUTO REJOIN    [ON/OFF]
```

- Default: `ON`.
- `ON` enables recovery actions and diagnostic logging.
- `OFF` keeps diagnostic logging active but never clicks reconnect or calls `TeleportService`.
- Farm status may show `REJOIN: IDLE`, `WAITING`, `RETRY 2/3`, or `HARD STUCK`.

## Persisted State

Store these values in the existing config file:

- `AutoRejoin`: user toggle, default `true`.
- `LobbyPlaceId`: latest `game.PlaceId` observed while `IsInLobby()` is true.
- `RecoveryPending`: survives teleport and V6 reload through Delta AutoExec.
- Rejoin attempt timestamps needed to enforce the retry window.

Store only `PlaceId`, never `JobId`. Roblox may therefore select another public lobby server instead of targeting the previous instance.

## Detection

Treat either condition as a recovery signal:

1. A visible GUI text containing `Teleporting` remains continuously visible for at least 60 seconds.
2. A visible Roblox disconnect/error prompt exposes a reconnect button.

Reset the loading timer if the `Teleporting` text disappears. Do not trigger recovery from short normal loading transitions.

## Recovery Flow

When recovery starts:

1. Set `RecoveryPending = true` and persist config.
2. Pause auto-farm movement, skills, replay clicks, stage portal scanning, and auto-start requests.
3. If a reconnect button is visible, click it once using existing GUI input helpers.
4. Otherwise call `TeleportService:Teleport(LobbyPlaceId, LocalPlayer)`.
5. Listen for `TeleportInitFailed`, log the result, and schedule the next allowed attempt.
6. Retry after 15, 30, then 60 seconds.
7. Allow no more than three attempts inside ten minutes.
8. After the limit, enter `HARD STUCK`, stop recovery requests, and preserve logs for inspection.

If `LobbyPlaceId` is unavailable, log the missing destination and do not guess another place ID.

## Post-Rejoin Flow

Delta AutoExec remains responsible for loading V6 after a successful teleport. V6 reads `RecoveryPending` during startup and waits until the lobby, character, `MatchRoom`, and required remotes are ready.

- Backpack full: keep recovery pending, run existing lobby-only auto-sell, then queue existing auto-start after sale confirmation.
- Backpack not full: queue existing auto-start immediately.
- Clear `RecoveryPending` after the auto-start request is queued successfully.

Reuse selected dungeon, difficulty, and solo party size from existing persisted settings.

## Diagnostics

Append concise timestamped records to `Bugon-teleport-log.txt` when executor file APIs are available. Record:

- session start, `PlaceId`, and `JobId`;
- lobby place capture;
- loading detection and timeout;
- disconnect prompt detection;
- recovery source and attempt number;
- reconnect click or direct lobby teleport;
- `TeleportInitFailed` result;
- lobby recovery success, auto-sell wait, auto-start queue, and `HARD_STUCK`.

Logging failures must not stop V6.

## Safety Guards

- One recovery state machine owns reconnect and teleport attempts.
- Existing auto-start retry cannot run while recovery is actively leaving the current session.
- Existing stage portal cooldown cannot expire into another portal interaction while recovery is active.
- Re-running V6 in one DataModel must not create duplicate watchdog loops or event connections.
- Do not add `queue_on_teleport`; Delta AutoExec already reloads the Pastebin/GitHub loader.

## Limitations

This feature is best-effort inside the running Roblox client. It cannot reopen Roblox or BlueStacks after an application crash, process termination, or engine-level freeze that prevents Lua and `TeleportService` from running. External BlueStacks or ADB automation remains outside scope.

## Validation

- Add a focused static check for persisted toggle defaults, 60-second timeout, retry delays, three-attempt limit, lobby-only destination capture, recovery gating, and post-rejoin auto-sell ordering.
- Run actual Luau compilation to catch register-limit or syntax failures.
- Run `luaparse`, existing PowerShell checks, `git diff --check`, and verify V5 remains unchanged.

## Non-Goals

- No public-server HTTP browser.
- No fixed lobby place ID.
- No specific `JobId` targeting.
- No BlueStacks restart, ADB command, OCR, or external watchdog.
- No changes to dungeon combat or portal selection scoring.
