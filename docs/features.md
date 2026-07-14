# Feature Overview

Brief behavior notes for `holygrail/script-v6-full-run-dg.lua`.

## Native Control Panel

- Draggable panel uses header `Iron Soul Script by Bugon` and footer `© 2026 Bugon. All rights reserved.`
- Main tabs separate `Farm` controls from `Utility` shop and sell configuration.
- Minimize hides the panel behind a draggable floating `B` restore icon.
- `Script` toggles main automation; disabling it clears target and moves character upward.
- `Underground Mode`, `Auto Replay`, and height slider preserve previous farm behavior.
- `Perfect Forge`, `Auto Buy`, `Auto Sell`, and `Season Buy` toggles persist to `IronSoulConfig/YasirConfigV3.json`.

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
- Farm overlay shows `CHEST DESTROYED`, `EGG TRIGGERED`, and live `ORE: current/max` backpack usage.
- Ore usage is read locally once per second and redraws only when current ore or capacity changes.

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
- Lobby sell calls `ForgeRF:InvokeServer("Sell", SellList)` for configured ores.
- `Sell Max Rarity` controls which `AUTO` ores qualify.
- Every ore definition has `AUTO`, `SELL`, and `KEEP` modes; `KEEP` wins over all other rules.
- Default protected ores remain `Blackhole`, `BloodHeart`, `Apocalypse`, and `DarkBlossom`.
- Confirms sell by re-reading ore counts; if ownership does not change, sell stays pending.

## Auto Restart Dungeon

- After confirmed sell clears backpack pressure, script queues dungeon restart.
- It selects an empty `workspace.MatchRoom.Room1`-`Room4` where `PlayersCount == 0` and `RoomState` is empty.
- It touches that room portal to open real `ScreenMatch` state.
- Post-sell restart uses the saved Dungeon selector world and difficulty, then creates a solo `1/1` room.
- Retry loop keeps trying while auto farm, auto replay, and no sell pending are true.

## Auto-Start Dungeon Selector

- Utility → Dungeon selects the dungeon and translated difficulty name used after successful lobby auto-sell.
- Locked dungeons and difficulties remain visible as `LOCKED` but cannot be selected.
- Selecting a dungeon automatically chooses its highest unlocked difficulty.
- Internal difficulty numbers stay hidden; saved config keeps the internal world ID and difficulty level.
- Normal victory replay remains `Play Again`; selector does not queue from lobby or add a manual start action.
- Auto-start remains solo `1/1` and requires Auto Farm plus Auto Replay.

## Shops

- `Grocery` lists the full Gold pool through executor upvalues and falls back to current shop snapshot.
- `Season` lists all `ResSeasonShop` definitions.
- Searchable checkboxes choose which item IDs Auto Buy and Season Buy may purchase.
- Selection tables persist in the same JSON config.
- Runtime purchase loops still buy only selected items whose current slot state permits purchase.
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
