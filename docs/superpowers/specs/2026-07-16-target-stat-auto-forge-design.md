# Target-Stat Auto Forge Design

## Scope

Extend V6 Auto Forge with editable target profiles. Profiles describe acceptable forge attribute-slot combinations. Normal Auto Forge automatically accepts every result. Target mode evaluates each result before acknowledgement, accepts and stops on a match, and handles non-matches according to an `Auto Delete Non-Match` toggle.

Implementation changes `holygrail/script-v6-full-run-dg.lua`, target-stat checks, `README.md`, and `docs/features.md`. V5 remains unchanged.

## Goals

- Remove manual Accept/Delete requirements from normal Auto Forge.
- Let users create, edit, enable, disable, duplicate, and delete target profiles.
- Match specific attribute-slot counts such as at least two Crit Damage slots.
- Match offensive group requirements, including total, additional, and all-slot modes.
- Support multiple enabled profiles with OR semantics.
- Stop safely before another `DropOres` call when equipment storage is full.
- Preserve failed non-matching equipment for later sale when auto-delete is disabled.
- Show a persistent Bugon target-found modal after accepting a matching item.

## Non-Goals

- No numeric percentage thresholds in V1. Matching counts attribute slots, not displayed percent values.
- No arbitrary boolean-expression editor.
- No defensive or utility groups in V1. Only the Offensive group is required.
- No automatic equipment selling inside Auto Forge.
- No target-result history across script reloads or rejoins.

## Forge Result Contract

`ForgeRF:InvokeServer("ForgeFinish")` returns a success flag and result table before acknowledgement. Relevant result fields are:

- `ID`: forged equipment definition ID.
- `SClass`: equipment class.
- `Rating`: forge quality rating.
- `Attr`: map containing one entry per attribute slot.
- `AttrFactor`: multiplier used by the game when displaying attribute values.

Target matching reads `Attr` only. The result table must be copied before calling `ForgeResult`, because Accept or Delete clears `Forge.Result` and `Forge.ForgeState` on the server.

## Attribute Normalization

The game result screen normalizes attribute keys with `string.split(AttributeKey, "_")[1]`. Target matching uses the same rule.

Examples:

```text
CHDmgBonus_1 -> CHDmgBonus
CHDmgBonus_2 -> CHDmgBonus
CHDmgBonus_Hell -> CHDmgBonus
```

Each original `Attr` entry remains one slot. Normalization changes the stat identifier used for counting but never merges slots before counting them.

Unknown attribute keys remain selectable as specific stats when discovered at runtime. Unknown keys do not count as Offensive and cause `All Slots Offensive` to fail until the Offensive catalog explicitly includes them.

## Stat Catalog

Build the specific-stat dropdown from runtime game data rather than a fixed four-stat list:

1. Read attribute identifiers exposed by `GameEnum.AttrEntry`.
2. Add normalized identifiers observed in current forge results or owned equipment data.
3. Translate labels through `TranslationUtil` using the same translation-key convention used by the game UI.
4. Sort translated labels alphabetically while persisting stable internal IDs.

The Offensive group uses an explicit internal-ID set validated against the runtime stat catalog. Implementation must log ignored or unknown configured IDs once per script load. It must never classify unknown stats as Offensive by name guessing.

## Profile Model

Each profile is persisted with this logical shape:

```lua
{
    Id = "stable-generated-id",
    Name = "Double Crit Offensive",
    Enabled = true,
    SlotMode = "Exact", -- Any, Exact, AtLeast
    SlotCount = 4,
    Rules = {
        {
            Kind = "Specific",
            StatId = "CHDmgBonus",
            MinCount = 2
        },
        {
            Kind = "AdditionalGroup",
            GroupId = "Offensive",
            MinCount = 2
        }
    }
}
```

Profile IDs are generated once and remain stable when names change. Names are user-editable display text.

## Rule Types

### Specific

Requires at least `MinCount` slots of one normalized stat.

```text
Crit Damage >= 2
```

### Total Group

Requires at least `MinCount` slots belonging to a group. Specific slots may also count toward this total.

```text
Total Offensive >= 3
```

### Additional Group

Requires at least `MinCount` group slots after reserving the minimum slots needed by all Specific rules. This prevents double-counting.

```text
Crit Damage >= 2
Additional Offensive >= 2
```

The two reserved Crit Damage slots cannot satisfy the Additional Offensive rule even though Crit Damage belongs to the Offensive group.

### All Slots Group

Requires every result slot to belong to the selected group.

```text
All Slots Offensive
```

## Rule Validation

- `MinCount` must be an integer from `1` through the supported maximum attribute-slot count.
- `Exact` and `AtLeast` slot modes require a positive `SlotCount`.
- `Any` ignores `SlotCount`.
- A profile must contain at least one rule.
- A profile may contain multiple Specific rules for different stats.
- Duplicate Specific rules for the same stat are merged by keeping the highest minimum.
- A profile may contain at most one Total, one Additional, and one All Slots rule for the same group.
- Invalid profiles remain visible with an error label but cannot be enabled.

## Matching Algorithm

Evaluate one result against one profile in this order:

1. Build a slot list from every `ResultData.Attr` entry.
2. Normalize each slot identifier.
3. Validate total slot mode:
   - `Any`: no total-slot restriction.
   - `Exact`: slot count must equal `SlotCount`.
   - `AtLeast`: slot count must be at least `SlotCount`.
4. Count normalized stat occurrences and evaluate every Specific rule.
5. Count all slots belonging to each group and evaluate Total Group rules.
6. Reserve exactly the minimum number of matching slots required by Specific rules.
7. Evaluate Additional Group rules using only unreserved slots.
8. Evaluate All Slots Group rules against the complete slot list.

All rules inside one profile use AND semantics. Enabled profiles use OR semantics. The first enabled matching profile in displayed order becomes the matched profile shown in the target-found modal.

## Examples

### At Least N Offensive

```text
Slot Mode: Any
Rules:
- Total Offensive >= 3
```

Specific offensive stats may contribute to the total.

### Two Crit Damage Plus Two Other Offensive

```text
Slot Mode: Exact 4
Rules:
- Crit Damage >= 2
- Additional Offensive >= 2
```

The Crit Damage slots are reserved and cannot satisfy the Additional rule.

### Two Crit Rate, Remaining Slots Unrestricted

```text
Slot Mode: Exact 4
Rules:
- Crit Rate >= 2
```

The other two slots may contain any attributes.

### All Offensive

```text
Slot Mode: Exact 4
Rules:
- All Slots Offensive
```

Any unknown, defensive, or utility slot causes the profile to fail.

## Runtime Modes

### Normal Auto Forge

When target mode is disabled:

1. Forge result through the existing direct no-proximity flow.
2. Cache a short last-result summary for status text.
3. Call `ForgeResult(true)` automatically.
4. Continue until requested craft count, material limit, stop request, or equipment-storage limit is reached.

Normal mode does not open the native result screen for each craft.

### Target Mode Match

When any enabled profile matches:

1. Copy result data and matched profile information.
2. Call `ForgeResult(true)` automatically.
3. Stop the forge runner.
4. Show the target-found notification.
5. Open the persistent Bugon target-found modal.

### Target Mode Non-Match With Auto Delete Enabled

1. Call `ForgeResult(false)`.
2. Continue to the next attempt if materials and attempt limit remain.

### Target Mode Non-Match With Auto Delete Disabled

1. Call `ForgeResult(true)` so the equipment enters inventory for later sale.
2. Check `EquipmentUtil:CheckCanAdd(LocalPlayer)` before the next attempt.
3. Stop with `STOPPED - EQUIPMENT BAG FULL` if storage cannot accept another item.
4. Never call `DropOres` after the storage check fails.

## Attempt And Resource Limits

Existing `Craft Count` becomes the maximum attempt count in target mode. Matching may stop the runner earlier.

The runner also stops when:

- Selected ore composition cannot support another craft.
- Required relic stock is exhausted.
- Equipment storage is full and the next result would be accepted.
- Auto Forge is disabled.
- Lobby state, auto-sell state, or rejoin state becomes unsafe.
- A remote, replication, or acknowledgement timeout occurs.

## User Interface

Use three equal-width main tabs:

```text
FARM | UTILITY | FORGE
```

Remove `FORGE` from Utility navigation. Utility retains four equal-width sub-tabs: `DUNGEON`, `GROCERY`, `SEASON`, and `AUTO SELL`.

The main `FORGE` tab contains two subviews:

- `CRAFT`: existing recipe, ore composition, attempt count, Start/Stop, and runtime status controls.
- `TARGETS`: target-mode toggles, profile list, and profile editor entry points.

Switching main tabs or Forge subviews closes any open recipe, stat, slot-mode, rule-type, or group dropdown. Target-found modal remains visible until explicitly closed.

### Mode Controls

- `AUTO FORGE`: existing master toggle on the `CRAFT` subview.
- `TARGET MODE`: enables profile evaluation.
- `AUTO DELETE NON-MATCH`: active only while target mode is enabled.

### Profile List

- `ADD PROFILE` button.
- Enabled checkbox per profile.
- Editable profile name.
- Summary of slot condition and rules.
- `EDIT`, `DUPLICATE`, and `DELETE` actions.
- Profiles retain displayed order; matching uses that order.

### Profile Editor

- Profile-name text input.
- Total-slot mode dropdown: `Any`, `Exact`, `At Least`.
- Slot-count input shown only for `Exact` and `At Least`.
- Rule rows with type dropdown.
- Specific-stat dropdown for Specific rules.
- Group dropdown containing `Offensive` in V1.
- Minimum-count input where applicable.
- Add-rule and delete-rule controls.
- Save and cancel controls.
- Inline validation messages; invalid data cannot be saved as enabled.

### Target-Found Modal

The modal is session-persistent: it remains visible until the user closes it, but it is not restored after script reload or rejoin.

Display:

- `TARGET FOUND` heading.
- Matched profile name.
- Forged item translated name.
- Attempt number.
- Total attribute slots.
- Every normalized stat and slot count.
- Confirmation that the result was automatically accepted.
- `CLOSE` button.

Also send a short Roblox notification containing the matched profile and item name.

## Persistence

Persist:

- Target mode toggle.
- Auto-delete non-match toggle.
- Profile list, order, names, enabled states, slot modes, slot counts, and rules.

New fields default safely:

- Target mode: off.
- Auto-delete non-match: off.
- Profiles: empty.

Old V6 configs load without migration errors. Invalid persisted profiles remain disabled and editable.

## Status Text

Required runtime statuses include:

- `FORGING attempt/max`
- `CHECKING TARGETS`
- `NON-MATCH - ACCEPTED`
- `NON-MATCH - DELETED`
- `TARGET FOUND - profile name`
- `STOPPED - EQUIPMENT BAG FULL`
- `STOPPED - MATERIALS EXHAUSTED`
- `ERROR - reason`

## Safety And Concurrency

- Keep Auto Forge lobby-only.
- Preserve the existing single-runner token.
- Do not overlap Auto Sell, rejoin recovery, or another forge batch.
- Validate storage before every attempt that may accept a result.
- Fetch a fresh QTE UUID for every submitted QTE stage.
- Never reuse a forge result after acknowledgement.
- Never issue both Accept and Delete for one result.
- Time out remote and replication waits with an actionable status.

## Verification

Static checks must verify:

- Normal mode auto-accept path.
- Target match auto-accept and stop path.
- Non-match Accept/Delete branching.
- Equipment-storage guard occurs before the next `DropOres`.
- Profile persistence and safe defaults.
- Specific, Total Group, Additional Group, and All Slots rule support.
- Native V5 remains unchanged.
- V6 parses with `luaparse` and existing menu, lobby, layout, and rejoin checks remain green.

Matching helpers must include runnable table-driven self-checks covering the four examples in this document, duplicate normalized stat keys, unknown Offensive membership, and multiple-profile OR ordering.
