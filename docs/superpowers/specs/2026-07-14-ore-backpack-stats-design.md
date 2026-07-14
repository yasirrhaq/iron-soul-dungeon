# Ore Backpack Stats Design

## Scope

Add live ore backpack usage to the existing V6 Farm statistics label. Preserve current chest and egg counters, automation behavior, remotes, and V5.

## Display

Show three lines in `V6StatsLabel`:

```text
CHEST DESTROYED: 12
EGG TRIGGERED: 3
ORE: 145/200
```

- `145` is current total ore count.
- `200` is current ore backpack capacity.
- Increase label height only enough to fit three lines.

## Data Source

- Reuse existing `GetOreBackpackUsage()`.
- Current count remains the sum of values from `DataUtil:GetValue(LocalPlayer, {"Ores"})`.
- Maximum remains `ForgeUtil:GetMax(LocalPlayer)`.
- Add no remote call and no new server request.

## Refresh Behavior

- Poll ore usage once every `1.0` second.
- Cache last displayed current and maximum values.
- Call `UpdateStatsLabel()` only when current count or capacity changes.
- Ore gains, auto-sell decreases, and capacity upgrades update within one second.
- Chest and egg events continue calling `UpdateStatsLabel()` immediately.
- If ore usage cannot be read, keep last valid displayed values and allow the loop to retry next second.

## Runtime Shape

- Keep state and polling additions minimal to avoid increasing top-level Luau register pressure unnecessarily.
- Start one lightweight `task.spawn` polling loop after `UpdateStatsLabel()` and `GetOreBackpackUsage()` are available.
- Keep V6 as one runtime file.

## Validation

- Extend `tools/checks/check-v6-menu.ps1` to assert the ore stats line, one-second interval, and change-only refresh guard.
- Run actual Luau compilation to catch local-register limits.
- Run `luaparse`, all PowerShell checks, `git diff --check`, and verify V5 is unchanged.

## Non-Goals

- No ore rarity breakdown.
- No separate ore panel.
- No configurable refresh interval.
- No server event hook or remote listener.
- No changes to auto-sell decisions or timing.
