# Feature Overview

Brief behavior notes for `holygrail/script-v6-full-run-dg.lua`.

## Native Control Panel

- Draggable panel uses header `Iron Soul Script by Bugon` and footer `© 2026 Bugon. All rights reserved.`
- Main tabs separate `Farm` controls from `Utility` shop and sell configuration.
- Minimize hides the panel behind a draggable floating `B` restore icon.
- `Script` toggles main automation; disabling it clears target and moves character upward.
- `Underground Mode`, `Auto Replay`, and height slider preserve previous farm behavior.
- `Perfect Forge`, `Auto Buy`, `Auto Sell`, and `Season Buy` toggles persist to `IronSoulConfig/YasirConfigV3.json`.
- `PETS` utility page persists Auto Expedition, Auto Claim Expedition, Auto Hatch Egg, and comma-separated expedition slot priority; default `2,3,4` excludes slot 1.

## Pet Expedition

- Auto Claim scans every expedition slot and claims one completed slot per confirmed cycle, including slots excluded from dispatch priority.
- Auto Expedition immediately consumes any remaining daily chances instead of waiting for a fresh `3/3` reset.
- Dispatch uses first empty slot in configured order and highest-affinity eligible unequipped, non-time-limited pet.
- Slot order accepts unique values from current game slot range; empty order disables dispatch while claims continue.
- Claim and dispatch wait for replicated slot confirmation so shared server lock never receives overlapping requests.

## Pet Egg Hatching

- Auto Hatch claims completed hatch slots before filling empty slots `1-3` with owned eggs.
- Egg priority is higher rarity, lower game sort value, then stable UUID order.
- Owned-egg and hatch-slot data events queue one deferred reconciliation; each pass performs at most one claim or start request.
- Empty egg inventory performs no remote calls. Active hatch slots use one timer aimed at the nearest completion instead of `Heartbeat` or a polling loop.
- Each action waits for replicated hatch data, retries once after a bounded timeout, then sleeps until a real data event.
- Rejoin recovery pauses hatch actions. Auto Hatch does not buy eggs or spend Robux to skip timers.

## Farming And Combat

- Main loop skips lobby, scans dungeon workspace, then targets nearest live humanoid enemy.
- Character orbits target every heartbeat using configured height and radius.
- Melee attacks fire through `VirtualUser` and equipped tool activation when target stays inside kill-aura range.
- Auto skill loop bursts every ready skill in `G`, `R`, `E`, then `Q` priority through original GUI button down/up callbacks, with keyboard fallback when callback firing is unavailable.
- Auto-triggered skills suppress local particles, sound, camera, film, and lighting render methods for an eight-second multi-stage window while leaving bullet dispatch and velocity processing intact.
- Farm UI persists a `3x`-`8x` Skill Network Burst multiplier. Native callback fires once, then each captured Auto Skill `BulletShoot` payload is replayed `multiplier - 1` times at `0.04s` spacing; `SkillAction` is never duplicated.
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
- Auto Giveup checks `LocalPlayer:GetAttribute("RemainLife") <= 0` before target acquisition, then activates `BattleHUD.PlayerRevive.ReviveFrame.Revive.ExitBtn`.
- Auto Giveup death scanning runs independently of Auto Farm and does not use the enemy-folder lobby heuristic after death.
- If the real Exit button does not open settlement, Auto Giveup retries through `Remotes.GamePlayerRE:FireServer("ExitSettlement")`.
- After failed settlement opens, Auto Giveup always clicks `ResultGui.ScreenSettlement.BtnGroup.ReturnToLobbyBtn`.
- When Auto Farm and Auto Replay are enabled, death restart intent persists across lobby teleport/AutoExec and queues the saved solo dungeon again. Full backpacks wait for enabled Auto Sell first.

## Auto Sell Queue

- Ore backpack usage is total ore count compared with `ForgeUtil:GetMax(LocalPlayer)`.
- Full backpack marks sell pending and returns to lobby after victory.
- Lobby sell resolves `Framework.Gameplay.EquipmentSystem.ForgeRF` first, with the previous Features path as fallback.
- Sell payload maps each configured ore ID to its full currently owned count, requesting the maximum available amount per ore.
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

## Auto Join Endless Tower

- Utility → Tower provides a persistent Auto Join toggle, starting-round selector, player-count selector, and live status.
- Starting point can use `Highest Unlocked` or a custom five-floor checkpoint: `1-5`, `6-10`, through `196-200`.
- `WorldUtil:GetWorldRecords(..., "MaxRound", currentSeason)` controls unlocked checkpoints. Progress may exceed round 200, but starting points cap at round 196 for the `196-200` block.
- Auto Join scans the Endless slots `workspace.MatchRoom.Room9` and `Room10`, requiring `PlayersCount == 0` and empty room state.
- It teleports through the selected slot's `Touch` portal, waits for `MainGui.ScreenMatch_Endless`, then sends the create-room payload.
- Room creation uses `GameMatchRE:FireServer("CreatRoom", "Endless1", 1, playerCount, startingRound)` and takes priority over normal dungeon auto-start.
- After teleport, Auto Join detects the visible `Equip Extra Weapon` modal, equips the configured extra weapon, confirms `ExtraWeaponUUID`, then activates `Start` before normal farming continues.
- Extra weapon defaults to `Highest Damage (Auto)`. Utility -> Tower also lists eligible specific weapons as translated name, fortify `+N`, and current `DMG`.
- Primary, secondary, and time-limited weapons are excluded. A missing or newly ineligible saved UUID falls back to current highest damage without deleting the saved preference.
- Extra weapon options refresh only from owned-equipment and equip-slot data events. A bounded timeout retries highest damage once, then starts the run instead of leaving the modal stuck.
- Tower card picker listens only for `WorldBonusCardUtil.RemoteEvent` `ShowCards` events, ranks translated damage/attack/critical and other offensive cards above defensive or utility cards, then uses rarity as tie-breaker.
- Optional paid-card unlock checks `price + minimum gold reserve`, unlocks only the card that will be selected, waits for refreshed card state, and falls back to the best free card after a three-second timeout.
- Repeated `ShowCards` payloads and pending selections are deduplicated; `SelectResult` resets state without any heartbeat or polling loop.
- Normal dungeon restart and Endless Auto Join wait for an eight-second lobby/character loading grace before creating rooms.
- Endless room creation retries at most every ten seconds and stops retrying once `LocalPlayer.EnterRoomId` is assigned.
- Full ore backpacks wait for enabled Auto Sell before another join attempt.

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
