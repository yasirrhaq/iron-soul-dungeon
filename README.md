# Iron Soul Dungeon Scripts

Roblox Lua scripts for Iron Soul dungeon automation experiments.

## Active Script

Use `holygrail/script-v6-full-run-dg.lua` for current full dungeon automation and configurable native menu.

`holygrail/script-v5-full-run-dg.lua` remains the previous stable button-menu version.

Feature behavior summary lives in `docs/features.md`.

## Feature Summary

- Farm enemies with orbit movement, melee clicks, tool activation, skill spam, and weapon switching.
- Handle Dragon Egg, chest targets, wave triggers, and stage portals.
- Auto replay on victory, or return to lobby when ore backpack is full.
- Auto sell ores in lobby, then restart solo dungeon through an empty match-room portal.
- Auto buy selected Gold shop and Season shop items.
- Configure full Grocery, Season, and ore catalogs through searchable UI lists.
- Set AutoSell max rarity and per-ore `AUTO`, `SELL`, or `KEEP` overrides.
- Perfect Forge forces forge rating payloads to `15` when enabled.
- Auto Forge runs selected weapon/armor recipes from exact ore composition, optional Fist relics, and inventory-clamped batch count without forge UI clicks.
- Utility guards cover anti-AFK, semi-god state, noclip, anti-fall, and lobby pause behavior.

## Repository Layout

| Path | Purpose |
| --- | --- |
| `auto-load.lua` | Cloud loader bootstrap. |
| `holygrail/script-v6-full-run-dg.lua` | Current active script with Bugon native menu. |
| `holygrail/script-v5-full-run-dg.lua` | Previous stable button-menu script. |
| `docs/features.md` | Brief explanation of each active feature. |
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

1. Run `holygrail/script-v6-full-run-dg.lua` in executor.
2. Keep `Script` and `Auto Replay` enabled in the `Farm` tab.
3. Confirm enemy farm still works.
4. Confirm portal progression advances stages, not repeated same portal loops.
5. Confirm full backpack returns to lobby, sells, touches free match-room portal, then creates `1/1` dungeon.

## Local Checks

Syntax-check active script:

```powershell
cmd /c npx -y luaparse holygrail/script-v6-full-run-dg.lua > nul && echo syntax-ok
.\tools\checks\check-v6-menu.ps1
```

Run legacy base-script checks:

```powershell
.\tools\checks\check-safe-lobby.ps1
.\tools\checks\check-ui-layout.ps1
```

Use the same `luaparse` command for other Lua files when editing them.
