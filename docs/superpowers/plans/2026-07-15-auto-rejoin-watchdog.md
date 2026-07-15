# Auto-Rejoin Watchdog Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a persisted V6 `AUTO REJOIN` watchdog that diagnoses long teleport loading, recovers to the stored lobby when possible, waits for required auto-sell, then resumes selected solo dungeon auto-start.

**Architecture:** Keep runtime in `script-v6-full-run-dg.lua`. Add one `RejoinWatchdog` table to contain state and methods, minimizing top-level Luau registers. Persist recovery state through existing JSON config; Delta AutoExec reloads V6 after successful teleport.

**Tech Stack:** Roblox Luau, `TeleportService`, executor file APIs, Roblox GUI APIs, PowerShell static checks, `luaparse`, Luau compiler.

## Global Constraints

- Modify V6 only; V5 remains unchanged.
- Default `AUTO REJOIN` is `ON`.
- Loading timeout is exactly 60 seconds.
- Recovery attempts wait 15, 30, then 60 seconds.
- Allow at most three attempts in ten minutes.
- Store lobby `PlaceId`, never `JobId`.
- Do not add `queue_on_teleport`; Delta AutoExec owns reload.
- Backpack full recovery must auto-sell before auto-start.
- No external BlueStacks or ADB watchdog.

---

### Task 1: Add Failing Watchdog Contract Check

**Files:**
- Create: `tools/checks/check-v6-auto-rejoin.ps1`

**Interfaces:**
- Consumes: V6 source text.
- Produces: one runnable static contract check ending with `v6-auto-rejoin-ok`.

- [ ] **Step 1: Write the failing check**

Create assertions for exact contracts:

```powershell
$ErrorActionPreference = 'Stop'
$root = Resolve-Path (Join-Path $PSScriptRoot '..\..')
$v5Path = Join-Path $root 'holygrail\script-v5-full-run-dg.lua'
$v6Path = Join-Path $root 'holygrail\script-v6-full-run-dg.lua'
$content = Get-Content -Raw -LiteralPath $v6Path

function Assert-Contains($pattern, $message) {
    if ($content -notmatch $pattern) { throw $message }
}

& git -C $root diff HEAD --quiet -- 'holygrail/script-v5-full-run-dg.lua'
if ($LASTEXITCODE -ne 0) { throw 'script-v5 must remain unchanged' }

Assert-Contains 'local\s+TeleportService\s*=\s*game:GetService\("TeleportService"\)' 'Missing TeleportService'
Assert-Contains 'AutoRejoin\s*=\s*true' 'Auto Rejoin must default on'
Assert-Contains 'Config\.AutoRejoin\s*=\s*_G\.AutoRejoin' 'Auto Rejoin must persist'
Assert-Contains 'LoadingTimeout\s*=\s*60' 'Loading timeout must be 60 seconds'
Assert-Contains 'RetryDelays\s*=\s*\{15,\s*30,\s*60\}' 'Retry delays changed'
Assert-Contains 'AttemptWindow\s*=\s*600' 'Attempt window must be ten minutes'
Assert-Contains 'MaxAttempts\s*=\s*3' 'Attempt limit must be three'
Assert-Contains 'Config\.LobbyPlaceId\s*=\s*game\.PlaceId' 'Lobby PlaceId must be captured'
Assert-Contains 'TeleportService:Teleport\(Config\.LobbyPlaceId, LocalPlayer\)' 'Missing lobby teleport'
Assert-Contains 'Bugon-teleport-log\.txt' 'Missing diagnostic journal'
Assert-Contains 'CreateToggleRow\(FarmTab,\s*"Auto Rejoin"' 'Missing menu toggle'
Assert-Contains 'RecoveryPending' 'Missing recovery persistence'
Assert-Contains 'REJOIN:' 'Missing watchdog status'
Assert-Contains 'Config\.RecoveryPending\s+and\s+IsInLobby\(\)' 'Missing post-rejoin lobby flow'

'v6-auto-rejoin-ok'
```

- [ ] **Step 2: Run check and verify failure**

Run: `pwsh -File tools/checks/check-v6-auto-rejoin.ps1`

Expected: FAIL at `Missing TeleportService`.

- [ ] **Step 3: Commit test contract with implementation batch**

Do not commit red state alone; keep it for Task 4 final commit.

---

### Task 2: Add Persisted Recovery State and Watchdog

**Files:**
- Modify: `holygrail/script-v6-full-run-dg.lua:4`
- Modify: `holygrail/script-v6-full-run-dg.lua:48`
- Modify: `holygrail/script-v6-full-run-dg.lua:105`
- Modify: `holygrail/script-v6-full-run-dg.lua:140`
- Modify: `holygrail/script-v6-full-run-dg.lua:187`

**Interfaces:**
- Produces: `RejoinWatchdog.Status`, `RejoinWatchdog.BlocksAutomation()`, `RejoinWatchdog.Tick()`, and persisted config fields.
- Consumes: existing `SaveConfig()`, `IsInLobby`, executor file APIs, `LocalPlayer`, and GUI services.

- [ ] **Step 1: Add service and config defaults**

Add `TeleportService`, `CoreGui`, and these config values:

```lua
AutoRejoin = true,
LobbyPlaceId = 0,
RecoveryPending = false,
RejoinAttemptTimestamps = {},
```

Normalize booleans, numeric lobby ID, and timestamp table during `LoadConfig()`. Save `_G.AutoRejoin` and watchdog-owned persisted fields in `SaveConfig()`.

- [ ] **Step 2: Add one watchdog namespace**

Use one table instead of many top-level locals:

```lua
local RejoinWatchdog = {
    LoadingTimeout = 60,
    RetryDelays = {15, 30, 60},
    AttemptWindow = 600,
    MaxAttempts = 3,
    Status = "IDLE",
    LoadingSince = nil,
    RecoverySource = nil,
    NextAttemptAt = nil,
    HardStuck = false
}
```

Implement methods for visible GUI ancestry, teleport text search, reconnect button search, timestamp pruning, diagnostic append, recovery start, attempt scheduling, direct lobby teleport, and `TeleportInitFailed` handling.

- [ ] **Step 3: Add watchdog loop after lobby detection exists**

Every second:

```lua
if IsInLobby() and Config.LobbyPlaceId ~= game.PlaceId then
    Config.LobbyPlaceId = game.PlaceId
    SaveConfig()
end
RejoinWatchdog.Tick()
```

Detect continuous visible `Teleporting` text for 60 seconds. Treat visible reconnect prompt as immediate recovery signal. Keep logging active while `_G.AutoRejoin` is off, but do not click or teleport.

- [ ] **Step 4: Run focused check**

Run: `pwsh -File tools/checks/check-v6-auto-rejoin.ps1`

Expected: progresses past config and watchdog assertions; post-rejoin/menu assertions may still fail.

---

### Task 3: Gate Automation and Resume Post-Rejoin

**Files:**
- Modify: `holygrail/script-v6-full-run-dg.lua:1084`
- Modify: `holygrail/script-v6-full-run-dg.lua:1216`
- Modify: `holygrail/script-v6-full-run-dg.lua:1584`
- Modify: `holygrail/script-v6-full-run-dg.lua:1973`
- Modify: `holygrail/script-v6-full-run-dg.lua:2420`
- Modify: `holygrail/script-v6-full-run-dg.lua:2471`

**Interfaces:**
- Consumes: `RejoinWatchdog.BlocksAutomation()` and existing auto-sell/auto-start helpers.
- Produces: no overlapping portal, movement, skill, replay, or auto-start calls during recovery.

- [ ] **Step 1: Gate active automation**

Add `not RejoinWatchdog.BlocksAutomation()` to auto-start retry, skill, jump, stage progression, movement, collision mutation, replay, and portal entry conditions. `HARD STUCK` remains blocked.

- [ ] **Step 2: Add post-rejoin lobby continuation**

In watchdog tick after lobby readiness:

```lua
if Config.RecoveryPending and IsInLobby() then
    local Current, Max = GetOreBackpackUsage()
    if Max > 0 and Current >= Max then
        SellPending = true
        SellPendingReason = "rejoin backpack full"
        RejoinWatchdog.Status = "WAIT AUTO SELL"
    else
        QueueAutoStartSoloDungeon()
    end
end
```

Allow the lobby auto-sell loop to run when `Config.RecoveryPending` is true, even if the regular Auto Sell toggle is off. Existing sale confirmation calls `QueueAutoStartSoloDungeon()`.

- [ ] **Step 3: Clear recovery flag on successful queue**

Inside `QueueAutoStartSoloDungeon()` clear and persist `Config.RecoveryPending`, then log `AUTO_START_QUEUED`. Do not clear the flag before the queue exists.

- [ ] **Step 4: Run focused check**

Run: `pwsh -File tools/checks/check-v6-auto-rejoin.ps1`

Expected: only menu/status assertions may remain.

---

### Task 4: Add Menu Toggle, Status, Docs, and Validate

**Files:**
- Modify: `holygrail/script-v6-full-run-dg.lua:1277`
- Modify: `holygrail/script-v6-full-run-dg.lua:3138`
- Modify: `holygrail/script-v6-full-run-dg.lua:3223`
- Modify: `tools/checks/check-v6-menu.ps1`
- Modify: `docs/features.md`

**Interfaces:**
- Consumes: `_G.AutoRejoin`, `RejoinWatchdog.Status`, and `SaveConfig()`.
- Produces: persisted Farm-tab toggle and fourth stats line.

- [ ] **Step 1: Add menu toggle**

Add after Auto Replay:

```lua
CreateToggleRow(FarmTab, "Auto Rejoin", function()
    return _G.AutoRejoin
end, function(Value)
    _G.AutoRejoin = Value
    SaveConfig()
end)
```

- [ ] **Step 2: Add status line**

Append:

```lua
"\nREJOIN: " .. tostring(RejoinWatchdog.Status)
```

Increase `V6StatsLabel` height from `78` to `96`. Update `check-v6-menu.ps1` expected height and add `AUTO REJOIN` assertions.

- [ ] **Step 3: Document behavior**

Add a brief `Auto Rejoin` feature entry to `docs/features.md`: detection, best-effort lobby teleport, retry limits, forced recovery auto-sell, AutoExec dependency, and hard-stuck limitation.

- [ ] **Step 4: Run focused and broad validation**

Run:

```powershell
pwsh -File tools/checks/check-v6-auto-rejoin.ps1
pwsh -File tools/checks/check-v6-menu.ps1
Get-ChildItem tools/checks/*.ps1 | ForEach-Object { pwsh -File $_.FullName }
cmd /c npx -y luaparse holygrail/script-v6-full-run-dg.lua
git diff --check
git diff HEAD --quiet -- holygrail/script-v5-full-run-dg.lua
```

Expected: all checks print success markers, parser exits `0`, diff check is clean, and V5 diff exits `0`.

- [ ] **Step 5: Commit implementation**

```bash
git add holygrail/script-v6-full-run-dg.lua tools/checks/check-v6-auto-rejoin.ps1 tools/checks/check-v6-menu.ps1 docs/features.md docs/superpowers/plans/2026-07-15-auto-rejoin-watchdog.md
git commit -m "Add auto-rejoin watchdog"
```
