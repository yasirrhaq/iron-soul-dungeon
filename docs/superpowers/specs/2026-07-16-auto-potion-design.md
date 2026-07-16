# Auto Potion Design

## Scope

Add persisted Auto Potion controls to the V6 Dungeon page. Users select any known normal buff potions. While a dungeon is active, the script consumes exactly one selected potion when its corresponding buff is inactive, then waits until that buff expires before consuming another of the same type.

Only V6 changes during implementation. V5 remains unchanged.

## Verified Game Contract

Dungeon-side use was verified with:

```lua
ReplicatedStorage.Framework.Features.PotionSystem.PotionRE:FireServer(
    "UsePotion",
    "DropPotion_1",
    1,
    nil
)
```

The request works without opening inventory UI. During the verified test, `LocalPlayer.PlayerAttrEntry:GetAttribute("DropRateBoost")` changed from `0` to `1`.

Use the native client wrapper in production:

```lua
PotionUtil:UsePotion(LocalPlayer, PotionId, 1, nil)
```

`PotionUtil` validates IDs and owned amount, then sends the same remote request.

## Goals

- Consume one potion at a time per selected potion type.
- Refresh each selected potion independently after its own buff expires.
- Avoid one-second polling and unnecessary server requests.
- Build the UI from all known `ResPotion` normal buff definitions.
- Display translated potion names, owned counts, and current active state.
- Work inside dungeons without inventory UI or proximity interaction.
- Stop all potion scanning and event work when Auto Potion is disabled.

## Non-Goals

- No Friendship/Bond potion automation.
- No partner selection UI.
- No multi-use quantity greater than one.
- No potion purchasing from the Auto Potion page.
- No fabricated remaining-duration countdown when the game exposes only active-state attributes.

## Supported Potion Definitions

Build the catalog from `ReplicatedStorage.Configs.ResPotion`.

Include definitions where:

```text
PotionType == "Buff"
```

This includes normal combat/economy buffs such as Drop, Luck, EXP, Gold, Attack, HP, and Critical Hit potions when present in `ResPotion`.

Exclude definitions where:

```text
PotionType == "BondIntimacy"
```

Friendship/Bond potions require a valid `{Partner = Player}` payload and a registered bond partner. They are outside Auto Potion V1.

## Catalog Entries

For every included potion, retain:

- Stable potion ID.
- Translated display name.
- Icon when available.
- Every `BuffIdN` and corresponding `DurationN` pair.
- Current owned amount from `PotionUtil:GetOwnedAmount(LocalPlayer, PotionId)`.

Iterate numbered fields until either the next `BuffIdN` or `DurationN` is missing. Ignore empty-string pairs.

The catalog is sorted by translated display name. Persist selections by potion ID, never by translated label.

## Active-State Detection

Potion buffs are represented by attributes on:

```text
LocalPlayer.PlayerAttrEntry
```

Examples confirmed or exposed by game data include:

- `DropRateBoost`
- `EXPBoost`
- `GoldBoost`
- `Luck`

`ResPotion.BuffIdN` values are internal buff IDs, not always direct player attribute names. Resolve IDs shaped like `Buff_<Attribute>_<Tier>` to `<Attribute>` while retaining the original ID as a compatibility candidate. For example, `Buff_DropRateBoost_1` resolves to `DropRateBoost`.

A resolved buff attribute is active when its numeric value is greater than zero. Missing, nil, or non-positive attributes are inactive.

For a potion with multiple configured Buff IDs:

- Treat the potion as active only when every configured buff attribute is active.
- Queue one potion when any required buff attribute becomes inactive.
- Treat owned amount decrease only as proof that the server accepted the request. Keep the potion activation-latched until every configured buff attribute becomes active.

## Event-Driven Refresh

Primary refresh uses:

```lua
PlayerAttrEntry:GetAttributeChangedSignal(BuffId)
```

Create one shared connection per unique selected Buff ID, not one duplicate connection per potion row.

When an observed attribute changes:

1. Re-evaluate only selected potions referencing that Buff ID.
2. Ignore active potions.
3. Queue inactive potions for sequential use.

When selections change, rebuild only affected signal connections. When Auto Potion turns off, disconnect all Auto Potion attribute connections.

## Sanity Scan

Run a lightweight fallback scan every 15 seconds while Auto Potion is enabled.

The scan:

- Checks current dungeon eligibility.
- Refreshes owned counts used by runtime decisions.
- Queues selected inactive potions not already pending.
- Recovers from missed attribute signals or delayed replication.

No scan runs while Auto Potion is disabled. No one-second polling loop is allowed.

## Dungeon Eligibility

Potion requests are allowed only while the script recognizes an active dungeon run.

Block consumption when any of these conditions apply:

- Player is in lobby.
- Workspace or player loading state is active.
- Settlement/victory result screen is active.
- Teleport/rejoin recovery blocks automation.
- Character or PlayerAttrEntry is unavailable.

After every blocked state, Auto Potion waits for a 30-second dungeon-ready grace period before evaluating selected potions. The grace clock starts only after all eligibility checks pass, including `LoadingEnd == true`, and therefore never advances during loading.

Lobby, loading, settlement, rejoin recovery, missing character, or missing/replaced `PlayerAttrEntry` resets the grace clock and invalidates any delayed scan from the previous dungeon context. When the current grace period expires, its generation token triggers one immediate scan. A stale timer from an older dungeon cannot queue a potion.

## Sequential Use Queue

`PotionUtil` enforces a per-player server lock and rejects requests sent within approximately 0.5 seconds of the previous potion request.

Use one queue with these rules:

- One worker only.
- Quantity is always `1`.
- Minimum spacing between different potion requests is `0.65` seconds.
- A potion ID may appear at most once in the queue.
- A potion already awaiting confirmation cannot be queued again.
- Queue order follows the visible selected-potion catalog order.

## Request Confirmation

Before sending:

1. Confirm Auto Potion is still enabled.
2. Confirm dungeon eligibility.
3. Confirm potion remains selected.
4. Confirm `PotionType == "Buff"`.
5. Confirm owned amount is greater than zero.
6. Confirm at least one required buff attribute is inactive.

After sending:

1. Mark the potion pending.
2. Record owned amount decrease as request acceptance, but continue waiting up to five seconds for all required buff attributes to become active.
3. Clear pending after active attributes confirm success.
4. If ownership decreased but attributes remain inactive, keep an activation latch and do not send another potion until those attributes are observed active or Auto Potion is reset.
5. If ownership did not decrease and attributes remain inactive, let the next 15-second sanity scan decide whether another request is needed.

This limits one failed request to at most one retry per sanity interval.

## Independent Potion Behavior

Each selected potion type operates independently.

Example with only Drop Potion selected:

```text
DropRateBoost = 0 -> consume one DropPotion_1
DropRateBoost = 1 -> no request
DropRateBoost returns to 0 -> consume one DropPotion_1
```

Example with Drop and Luck selected:

- Drop expiration queues only Drop Potion.
- Luck expiration queues only Luck Potion.
- If both are inactive, consume them sequentially with the server-safe delay.

## User Interface

Place Auto Potion inside the existing `DUNGEON` utility page.

### Controls

- `AUTO POTION: ON/OFF` master toggle.
- Search input for potion names and IDs.
- Refresh button for catalog and owned counts.
- Scrollable checkbox list of all supported buff potions.

### Potion Row

Each row displays:

```text
[checkbox] translated potion name | state | owned count
```

State values:

- `Active`
- `Inactive`
- `Pending`
- `Out of Stock`
- `Unavailable`

Do not display a fake countdown. If a future verified getter exposes authoritative remaining duration, countdown display can be added separately without changing consumption logic.

Friendship/Bond potions do not appear in this list.

## Persistence

Persist:

- Auto Potion toggle.
- Selected potion IDs.

Safe defaults:

- Auto Potion: off.
- Selected potions: empty.

Old V6 configs load without migration errors. Unknown persisted potion IDs are ignored and removed on the next save.

## Reload And Rejoin Behavior

On script reload:

- Tear down the previous Auto Potion token, worker, and attribute connections.
- Rebuild runtime state from persisted selection.
- Do not send potion requests until dungeon eligibility is confirmed.

On rejoin:

- Auto Potion remains dormant through loading and lobby recovery.
- Entering the next active dungeon triggers immediate selected-buff evaluation.

## Status And Diagnostics

Required concise logs/statuses include:

- `AUTO POTION READY`
- `USED <PotionId> x1`
- `ACTIVE <PotionId>`
- `OUT OF STOCK <PotionId>`
- `USE TIMEOUT <PotionId>`
- `BLOCKED - LOBBY`
- `BLOCKED - LOADING`
- `BLOCKED - SETTLEMENT`

Do not log every 15-second successful no-op scan.

## Safety And Performance

- No request while buff is active.
- No request when owned amount is zero.
- No duplicate queue entries.
- No overlapping potion workers.
- No quantity above one.
- No Friendship/Bond payload.
- No scan or attribute connections while disabled.
- Preserve Auto Forge, Auto Sell, Auto Buy, Auto Rejoin, and dungeon automation behavior.

## Verification

Static and runnable checks must verify:

- V5 remains unchanged.
- Remote path and `UsePotion` argument order are exact.
- Quantity is fixed to one.
- Catalog includes only `PotionType == "Buff"`.
- Friendship/Bond potions are excluded.
- Gold Potion is not excluded from normal buff cataloging.
- Owned counts use `PotionUtil:GetOwnedAmount` or `GetAllOwned`.
- Attribute change signals drive primary refresh.
- Fallback scan interval is 15 seconds, not one second.
- Queue spacing is at least 0.65 seconds.
- Pending IDs cannot be queued twice.
- Lobby, loading, settlement, and rejoin guards block requests.
- V6 parses with `luaparse` and existing menu, layout, safe-lobby, Auto Forge, and Auto Rejoin checks remain green.

A small table-driven self-check must cover one selected potion, multiple independent selected potions, a multi-buff potion, out-of-stock handling, missed-signal recovery, and Friendship/Bond exclusion.
