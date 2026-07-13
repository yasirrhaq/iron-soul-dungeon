# Feature Overview

Brief behavior notes for `holygrail/script-v5-full-run-dg.lua`.

## Control Panel

- `SCRIPT: ON/OFF` toggles main automation through `_G.AutoFarm`; turning it off clears current target and moves character upward.
- `MODE: UNDERGROUND/ABOVE MONSTER` changes farm position relative to enemy target.
- `AUTO REPLAY: YES/NO` controls victory replay, return-to-lobby sell flow, and post-sell dungeon restart.
- `HEIGHT DISTANCE` slider controls orbit height and updates kill-aura range.
- `PERFECT FORGE`, `AUTO BUY`, `AUTO SELL`, and `SEASON BUY` toggles persist to `IronSoulConfig/YasirConfigV3.json` when supported by executor file APIs.

## Farming And Combat

- Main loop skips lobby, scans dungeon workspace, then targets nearest live humanoid enemy.
- Character orbits target every heartbeat using configured height and radius.
- Melee attacks fire through `VirtualUser` and equipped tool activation when target stays inside kill-aura range.
- Auto skill loop presses `G`, `R`, `E`, then `Q` by priority when UI skill cooldown state says ready.
- Weapon switch presses `C` only when blocking skills are not ready and switch UI is off cooldown.

## Targets

- Enemy targets are live humanoid models with root parts.
- Dragon egg has priority over chests when `workspace.DragonEgg` exists and is not broken.
- Chest targets are workspace children whose names start with `Chest`.
- Breakable and egg counters update `CHEST DESTROYED` and `EGG TRIGGERED` in the overlay.

## Dragon Egg

- Moves to ground near egg before interacting.
- Uses `fireproximityprompt` when available.
- Falls back to holding `F` for roughly three seconds when prompt firing is unavailable.
- Avoids repeated prompt spam with an egg lock window.

## Stage Progression

- When enemies disappear for a short delay, script checks wave triggers first.
- Wave triggers use touch events on `WaveSpawnTouch` parts.
- Portal scanner scores nearby touch/prompt parts by names such as `portal`, `door`, `gate`, `next`, `exit`, and `teleport`.
- Portal entry moves character onto portal, fires touch interest, presses `Shift + F`, then fires touch again.
- Cooldown and same-position checks prevent rapid repeated portal attempts.

## Victory, Death, And Replay

- Victory detection scans visible GUI text for `victory`.
- If backpack is not full, script waits reward-settle delay, then clicks visible Play Again / Replay / Restart UI.
- If backpack is full, script clicks `ResultGui.ScreenSettlement.BtnGroup.ReturnToLobbyBtn` instead of replay.
- Death handling scans for `you died`, then clicks `Give up` when visible.

## Auto Sell Queue

- Ore backpack usage is total ore count compared with `ForgeUtil:GetMax(LocalPlayer)`.
- Full backpack marks sell pending and returns to lobby after victory.
- Lobby sell calls `ForgeRF:InvokeServer("Sell", SellList)` for configured low-rarity ores.
- Keeps protected ores: `Blackhole`, `BloodHeart`, `Apocalypse`, and `DarkBlossom`.
- Confirms sell by re-reading ore counts; if ownership does not change, sell stays pending.

## Auto Restart Dungeon

- After confirmed sell clears backpack pressure, script queues dungeon restart.
- It selects an empty `workspace.MatchRoom.Room1`-`Room4` where `PlayersCount == 0` and `RoomState` is empty.
- It touches that room portal to open real `ScreenMatch` state.
- It selects `World3`, difficulty `10`, then fires `GameMatchRE:FireServer("CreatRoom", "World3", 10, 1)` for solo `1/1` party.
- Retry loop keeps trying while auto farm, auto replay, and no sell pending are true.

## Shops

- `AUTO BUY` scans Gold shop snapshot and buys wanted consumable items when slot state is `normal`.
- `SEASON BUY` first tries `SeasonUtil:GetShopData(LocalPlayer)`, then falls back to GUI slot attributes.
- Season target items are `RaceSpins` and `SeasonTicket`.
- Shop loops skip already-bought/limited items when buy counts or purchased GUI state are available.

## Perfect Forge

- Hooked `ForgeRF` calls are inspected when `PERFECT FORGE` is enabled.
- Any forge argument table containing `Rating` is forced to `15` before remote call continues.

## Safety And Utility

- Anti-AFK captures controller and right-clicks on idle.
- Semi-god mode disables ragdoll/falling/dead humanoid states repeatedly.
- Noclip clears collision on character body parts while farming.
- Invisible anti-fall platform follows the character as a safety floor.
- Lobby guard pauses farm movement, skill spam, jumping, and noclip while in lobby, but still allows sell/restart automation.

## Fixed Assumptions

- Active dungeon target is `World3` difficulty `10`.
- Auto-start party size is `1`.
- Sell is expected to work in lobby, not inside dungeon.
- Match-room portal rooms are `Room1` through `Room4` under `workspace.MatchRoom`.
