# Iron Soul Dungeon Scripts

Roblox Lua scripts for Iron Soul dungeon automation experiments.

## Main Script

Use `base-script-v2.lua` for current testing.

Current features:

- Auto farm enemies with skill spam (`Q`, `E`, `R`) and melee clicks.
- Underground / above-monster positioning toggle.
- Auto stage portal progress with cooldown and enemy-empty delay.
- Auto replay gated by visible `VICTORY` UI.
- Dragon egg support from `workspace.DragonEgg`.
- Chest support from `workspace.Chest*` (`Chest1`, `Chest2`, `Chest3`, etc.).
- Dragon egg prompt trigger via `fireproximityprompt` when executor supports it.
- Fallback egg interaction via `ProximityPrompt:InputHoldBegin()` / `InputHoldEnd()`.
- UI counters for `CHEST DESTROYED` and `EGG TRIGGERED`.

## Script Map

| File | Purpose |
| --- | --- |
| `base-script-v2.lua` | Current active test script with replay, chest, and dragon egg handling. |
| `base-script.lua` | Older base script reference. |
| `raw-script.lua` | Older raw reference with safer portal behavior. |
| `raw-script-v14.lua` | V14 raw reference. |
| `auto-farm.lua` | Older auto farm script that worked for lobby/portal behavior. |
| `auto-farm-v37.lua` | Dungeon-focused auto farm reference. |
| `auto-farm-dungeon.lua` | Dungeon auto farm variant. |
| `auto-farm-unified.lua` | Experimental Dungeon / Endless mode toggle script. |
| `auto-load.lua` | Cloud loader bootstrap. |
| `current-working-script.lua` | Working scratch/reference file. |
| `experiment.lua` | Scratch experiment file. |

## Current Target Assumptions

- Egg path: `workspace.DragonEgg`.
- Chest paths: direct workspace children named `Chest1`, `Chest2`, `Chest3`, etc.
- Egg activation is confirmed by `DragonEgg:GetAttribute("Active")`.
- Egg broken state is checked with `DragonEgg:GetAttribute("Broken")`.
- Egg damage is exposed through `DragonEgg:GetAttribute("HitDamage")` in the game client script.

## Testing Checklist

1. Run `base-script-v2.lua` in executor.
2. Keep `SCRIPT: ON`.
3. Confirm enemy farm still works.
4. Confirm chest target increments `CHEST DESTROYED` only when a chest disappears.
5. Confirm dragon egg target moves to ground and triggers prompt.
6. Confirm `EGG TRIGGERED` increments only after `DragonEgg.Active` becomes true.
7. Confirm replay clicks only after `VICTORY` UI appears.

## Local Syntax Check

```powershell
cmd /c npx -y luaparse base-script-v2.lua > nul && echo syntax-ok
```

Use the same command for other Lua files when editing them.
