# Iron Soul Dungeon Scripts

Roblox Lua scripts for Iron Soul dungeon automation experiments.

## Active Script

Use `holygrail/script-v5-full-run-dg.lua` for current full dungeon automation.

Keep this path stable because external loaders/raw URLs may reference it.

## Repository Layout

| Path | Purpose |
| --- | --- |
| `auto-load.lua` | Cloud loader bootstrap. |
| `holygrail/script-v5-full-run-dg.lua` | Current active full-run dungeon script. |
| `scripts/base/` | Older base script line. |
| `scripts/archive/auto-farm/` | Older auto-farm variants. |
| `scripts/archive/holygrail/` | Older holygrail versions. |
| `scripts/archive/raw/` | Raw/decompiled reference scripts. |
| `scripts/scratch/` | Scratch experiments and one-off helpers. |
| `tools/checks/` | PowerShell checks for script invariants. |
| `research/dump/` | Decompiled modules, UI dumps, probes, notes. |
| `docs/` | Design notes and specs. |

## Current Target Assumptions

- Egg path: `workspace.DragonEgg`.
- Chest paths: direct workspace children named `Chest1`, `Chest2`, `Chest3`, etc.
- Dungeon match-room opener uses `workspace.MatchRoom.Room1`-`Room4` touch portals.
- Active auto-start target is `World3`, difficulty `10`, party size `1/1`.

## Testing Checklist

1. Run `holygrail/script-v5-full-run-dg.lua` in executor.
2. Keep `SCRIPT: ON` and `AUTO REPLAY: YES`.
3. Confirm enemy farm still works.
4. Confirm portal progression advances stages, not repeated same portal loops.
5. Confirm full backpack returns to lobby, sells, touches free match-room portal, then creates `1/1` dungeon.

## Local Checks

Syntax-check active script:

```powershell
cmd /c npx -y luaparse holygrail/script-v5-full-run-dg.lua > nul && echo syntax-ok
```

Run legacy base-script checks:

```powershell
.\tools\checks\check-safe-lobby.ps1
.\tools\checks\check-ui-layout.ps1
```

Use the same `luaparse` command for other Lua files when editing them.
