# Auto Forge V1 Design

## Scope

Add persisted Auto Forge controls to V6 only. Let user choose one forge recipe, define exact ore composition per craft, choose craft count, and run forge directly through game forge APIs without opening or clicking forge UI. Preserve V5 and existing auto-farm, auto-sell, auto-buy, replay, auto-start, and auto-rejoin behavior.

## Chosen Approach

Use direct `ForgeRF` and `ForgeUtil` calls. Do not automate forge GUI buttons or character interaction.

Rejected alternatives:

- GUI automation: slower, resolution-sensitive, and depends on forge interaction.
- Raw remote-only QTE guessing: unnecessary because `ForgeUtil:GetForgeData()` and `ForgeUtil:GetQTE()` expose authoritative session state and UUID.

## Recipes

Weapon recipes:

| Recipe | Ore Count | Relic | Display Chance |
|---|---:|---|---:|
| Sword | 3 | None | 100% |
| Staff | 10 | None | 80% |
| Axe/Hammer | 16 | None | 100% |
| Fist | 18 | None | 5% |
| Fist + Common Relic | 18 | `FistRelic_1` | 20% |
| Bow + Bow Relic | 18 | `BowRelic_1` | 20% |
| Fist + Luxury Relic | 18 | `FistRelic_2` | 58% |

Armor recipes:

| Recipe | Ore Count | Relic | Display Chance |
|---|---:|---|---:|
| Light Helmet | 3 | None | 100% |
| Light Armor | 10 | None | 80% |
| Heavy Helmet | 15 | None | 80% |
| Heavy Armor | 22 | None | 100% |

Forge output remains random. Auto Forge accepts every result and does not retry based on item type, rarity, stats, or output quality.

## Persisted Configuration

Add these values to existing V6 JSON config:

- `AutoForge`: toggle, default `false`.
- `AutoForgeRecipeId`: selected recipe, default `WeaponSword`.
- `AutoForgeOreComposition`: ore counts per craft, default empty.
- `AutoForgeRequestedCrafts`: requested craft count, default `1`.

Normalize invalid recipe IDs, non-string ore IDs, non-positive ore counts, and craft counts below one. Runtime count may clamp below requested count when inventory is insufficient; persisted requested count remains user input so it can become available after inventory changes.

## Inventory Sources

Read ore counts from:

```lua
DataUtil:GetValue(LocalPlayer, {"Ores"})
```

Read relic counts from:

```lua
DataUtil:GetValue(LocalPlayer, {
    KeyString.EquipmentUtil.Crystals,
})
```

Read relic definitions from `Configs.ResCrystals`. Only definitions with `Type == "Relic"` qualify. Before relic craft, require `ForgeUtil:IsRelicUsable(LocalPlayer, RelicId)`.

## Composition Rules

- Show all known ore definitions, including owned count zero.
- Disable adding an ore when owned count is zero.
- Composition represents one craft, not total batch consumption.
- Sum of composition counts must exactly equal selected recipe ore count.
- Changing recipe clears composition to prevent accidental mismatched requirements.
- Start button remains disabled while composition total is invalid.

For each selected ore:

```text
Ore Crafts = floor(Owned Ore / Ore Per Craft)
```

Batch maximum is minimum of every selected ore limit and, when applicable, owned relic count:

```text
Max Crafts = min(All Ore Crafts, Owned Relic)
```

If requested count exceeds maximum, runtime count automatically clamps to maximum and menu shows the limiting material:

```text
Adjusted 10 to 3 - Limited by Rotten Lotus
```

If maximum is zero, disable Start Forge.

## Direct Forge Flow

Run one craft at a time. Re-read ore and relic inventory before each craft.

1. Call `ForgeRF:InvokeServer("DropOres", Composition, Category, RelicId)`.
2. Resume an existing pending QTE on the first attempt, otherwise poll `ForgeUtil:GetForgeData(LocalPlayer)` until a fresh `QTE` state exposes the expected ore count and a new UUID.
3. Read QTE configuration with `ForgeUtil:GetForgeQTE(ForgeData.OresNum)`.
4. Resume from `ForgeData.QTE.Times + 1`; never replay completed QTE steps.
5. For each remaining step, read fresh `ForgeUtil:GetQTE(LocalPlayer).UUID` and submit `Rating = 15` through `ForgeUtil:QTE()`.
6. Call `ForgeUtil:ForgeFinish(LocalPlayer)` once.
7. Wait briefly for result state, then acknowledge with `ForgeRF:InvokeServer("ForgeResult", true)`.
8. Recalculate inventory and continue until clamped batch count completes, inventory becomes insufficient, toggle turns off, or an error occurs.

Use bounded waits and one active runner lock. Never start overlapping forge sessions.

## Menu

Add an `AUTO FORGE` utility tab/page to existing V6 menu with:

- Auto Forge toggle.
- Recipe dropdown with category, target, ore requirement, relic variant, chance, and internal recipe ID.
- Requested craft count numeric input.
- Searchable all-known-ore list.
- Per-ore decrement, selected count, increment, and owned count.
- Composition summary: selected total versus recipe requirement.
- Relic availability line for relic recipes.
- Computed maximum and clamp reason.
- Start/Stop Forge action and concise status text.

Do not expose raw QTE UUID or remote internals in normal menu text.

## Trigger Behavior

Auto Forge is user-started from its page. Enabling toggle alone does not immediately consume materials. Start action launches calculated batch. Turning toggle off stops after current safe remote step.

Auto Forge runs only while:

- player is in lobby;
- rejoin watchdog does not block automation;
- no auto-sell operation is active;
- no previous Auto Forge runner owns forge session.

Auto Forge does not automatically trigger after auto-sell or dungeon completion in V1.

## Error Handling

- Invalid composition: no remote call.
- Insufficient inventory: clamp or disable start.
- Missing/invalid relic: disable relic recipe start.
- Fresh QTE data timeout: stop batch and report status without opening native Forge UI.
- Missing QTE UUID: stop current batch without guessing.
- Remote/module error: stop batch, unlock runner, retain user selections, and print concise warning.
- Toggle disabled mid-run: finish no additional crafts after current safe step.

No automatic retry after an unknown forge-state error.

## Validation

Add focused static checks before implementation for:

- V6-only config fields and defaults.
- Complete recipe table and exact ore requirements.
- Composition exact-total validation.
- Ore/relic maximum calculation and requested-count clamp.
- Direct `DropOres` payload including relic argument.
- QTE resume from existing `Times` with fresh UUID per step and rating 15.
- Single-runner lock, lobby/rejoin/auto-sell gates, bounded timeouts, and stop behavior.
- Menu labels and controls.

Run actual Luau compilation, `luaparse`, existing PowerShell checks, `git diff --check`, and verify V5 remains unchanged.

## Non-Goals

- No result-based reroll loop.
- No target rarity, stat, weapon subtype, or armor subtype enforcement.
- No automatic ore composition optimization.
- No automatic purchase or farming of missing materials.
- No forge GUI clicking or movement to forge NPC.
- No changes to V5.
