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
- Auto Sell ore list is ordered by ore level descending, then rarity, then native game sort order.
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
- Difficulty rows and selected value show their internal index, such as `[10] Hell (Nightmare)`; saved config and remotes use the same numeric level.
- Normal victory replay remains `Play Again`; selector does not queue from lobby or add a manual start action.
- Auto-start remains solo `1/1` and requires Auto Farm plus Auto Replay.

## Auto Rejoin

- Farm tab `Auto Rejoin` toggle persists and defaults to enabled.
- Disabled Auto Rejoin skips GUI detection work entirely.
- Enabled detection caches targets through `PlayerGui` and `RobloxPromptGui` events; a fallback PlayerGui scan runs at most once every 30 seconds instead of every second.
- Reconnect prompt detection binds CoreGui before PlayerGui exists, so loading-screen disconnects can still be caught.
- Visible `Teleporting` loading must remain for 60 seconds before recovery begins; a visible disconnect reconnect button also triggers recovery.
- If V6 starts before character spawn, a 150-second no-`HumanoidRootPart` watchdog rejoins without waiting for PlayerGui/UI.
- Script stores only the latest lobby `PlaceId`, then retries recovery after 15, 30, and 60 seconds with a maximum of three attempts per ten minutes.
- Recovery pauses combat, movement, replay, portal, shop, and auto-start requests only while an active reconnect or teleport attempt is running.
- After Delta AutoExec reloads V6 in lobby, a full backpack runs lobby auto-sell first; otherwise the saved solo dungeon auto-start queues immediately.
- `Bugon-teleport-log.txt` records session, detection, retry, failure, lobby, sell, and restart events when executor file APIs are available.
- `HARD STUCK` stops further recovery requests and clears stale pending state without freezing normal farming. Lua cannot reopen Roblox or BlueStacks after an engine or application-level freeze.

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

## Auto Forge

- Main `FORGE` tab contains separate `CRAFT` and `TARGETS` views. Craft selects weapon or armor recipe, exact per-craft ore composition, and maximum attempt count.
- Forge ore picker list uses same ore ordering as Auto Sell: highest ore level first, then rarity, then native game sort order.
- Weapon recipes include Sword, Staff, Axe/Hammer, Fist, Common Fist Relic, Bow, Bow Relic, and Luxury Fist Relic variants; armor recipes include Light Helmet, Light Armor, Heavy Helmet, and Heavy Armor.
- Relic counts come from Crystals inventory through `KeyString.EquipmentUtil.Crystals`; Common Fist, Bow, and Luxury Fist recipes consume `FistRelic_1`, `BowRelic_1`, and `FistRelic_2` respectively.
- Batch maximum uses the lowest `floor(owned/per-craft)` ore limit and optional relic count. Requested count displays an automatic clamp when inventory supports fewer crafts.
- Auto Forge defaults off and consumes nothing until user enables it and presses `START FORGE` in lobby.
- Direct flow calls `DropOres`, submits server QTE progress with fresh UUID values and rating `15`, and finishes without requiring the forge proximity interaction.
- Normal mode accepts each result automatically without opening the native result screen. Target mode counts normalized attribute slots and evaluates enabled profiles in displayed order.
- Profiles now use human-readable rules: `Any Total Slots`, `Exact N Slots`, `At Least N Slots`, `At Least N From Pool`, `Only From Pool`, and optional `Require Stat >= N`.
- Each profile owns its own editable stat pool. `Offensive` is starter preset content, not locked global meaning. Offensive defaults are `AtkBonus`, `CHDmgBonus`, `CHIRate`, and `SkillDmgBonus`.
- Enabled profiles are checked top-to-bottom; first match wins.
- Matching results are accepted, stop the runner, send a notification, and remain in a Bugon target-found modal until closed. Non-matches are accepted for later sale or deleted according to `AUTO DELETE NON-MATCH`.
- Equipment storage is checked before every attempt; a full bag stops with `STOPPED - EQUIPMENT BAG FULL` before another `DropOres` request.
- Turning Auto Forge off during a batch finishes current craft, then stops before next craft. Auto-sell and rejoin recovery cannot overlap an active forge batch.

## Auto Potion

- Utility → Dungeon contains persisted `AUTO POTION` controls and a searchable list built from every known `ResPotion` entry whose `PotionType` is `Buff`.
- Gold Potion and other normal buff potions appear automatically. Friendship/Bond potions stay excluded because they require a selected partner payload.
- Each checked potion type is independent and always consumes exactly one item through native `PotionUtil:UsePotion(LocalPlayer, PotionId, 1, nil)`.
- Selected potions are used only inside an active dungeon when their resolved player attributes are inactive. Internal IDs such as `Buff_DropRateBoost_1` resolve to `DropRateBoost`; lobby, loading, settlement, and rejoin recovery block requests.
- Endless Tower is always excluded through the existing `workspace.World.Start` marker. Auto Potion may remain enabled, but status becomes `BLOCKED - ENDLESS TOWER` and no potion remote is sent.
- Dungeon transitions use a 10-second grace period that starts only after full eligibility. Loading, lobby, settlement, rejoin recovery, character replacement, or `PlayerAttrEntry` replacement resets the timer and invalidates stale delayed scans.
- `DragonEgg` and `WorldEnemys` spawn/removal still trigger reevaluation but do not restart the grace timer, avoiding repeated delays during one dungeon.
- Buff attribute change signals drive normal refresh. One 15-second fallback scan recovers missed replication; disabled Auto Potion disconnects signals and performs no scans.
- Multiple expired buffs enter one deduplicated queue with 0.65-second request spacing. Inventory decrease proves server acceptance but stays activation-latched until the native buff attribute turns active, preventing repeated consumption during replication delay.
- Potion rows show translated name, owned count, and `Active`, `Inactive`, `Pending`, `Out of Stock`, or `Unavailable`; no guessed countdown is displayed.

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
