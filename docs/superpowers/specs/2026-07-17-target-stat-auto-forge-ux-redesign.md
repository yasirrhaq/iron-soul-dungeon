# Target-Stat Auto Forge UX Redesign

Date: 2026-07-17
Status: Draft approved in chat, not implemented

## Goal

Make Target Forge understandable without reading internal logic names.

Current confusion source:

- `Any` is read like "any stat mix".
- Current UI actually uses `Any` only for total slot count.
- Per-stat count rows look like mandatory quotas even when user only wants a loose offensive pool.
- `Specific`, `TotalGroup`, `AdditionalGroup`, and `AllSlotsGroup` are implementation words, not user words.

New UX must match user mental model first, then map to implementation second.

## Core Mental Model

Each profile answers one question:

```text
What forged result should count as good enough to keep and stop on?
```

Each profile is made from small building blocks:

1. Total slot condition.
2. Pool of allowed or preferred stats.
3. Pool-based rule.
4. Optional specific stat minimums.

Profiles are user-created building blocks. No hardcoded `early game`, `mid game`, `end game`, or `min-max` modes in UI.

## Enabled Profile Behavior

- Multiple profiles may be enabled at once.
- Enabled profiles are checked from top to bottom.
- First enabled matching profile wins.
- When a profile matches, result is accepted and Auto Forge stops.

UI must show this clearly:

```text
Enabled profiles are checked top-to-bottom.
First match wins.
```

Profile order is part of configuration and must remain user-editable.

## New Terms

Replace internal terms with user-facing terms.

| Old/Internal | New UX Label |
| --- | --- |
| `Specific` | `Require Stat` |
| `TotalGroup` | `At Least N From Pool` |
| `AdditionalGroup` | removed from primary UX |
| `AllSlotsGroup` | `Only From Pool` |
| `Any` slot mode | `Any Total Slots` |

`AdditionalGroup` is removed from primary UX because user expectation is better served by explicit pool rules plus optional stat minimums.

## Profile Structure

Each profile contains:

```lua
{
    Id = "stable-id",
    Name = "user label",
    Enabled = true,
    SlotMode = "Any" | "Exact" | "AtLeast",
    SlotCount = number?,
    PoolPreset = "Offensive" | "Custom",
    PoolStats = { "AtkBonus", "CHDmgBonus", "CHIRate", "SkillDmgBonus" },
    Rules = {
        { Kind = "PoolAtLeast", MinCount = 3 },
        { Kind = "RequireStat", StatId = "CHDmgBonus", MinCount = 2 }
    }
}
```

## Slot Rule Semantics

### Any Total Slots

Ignore total slot count entirely.

Meaning:

```text
Any number of slots is acceptable.
Other rules still apply.
```

This label must not be shortened to just `Any` in editor summary.

### Exact N Slots

Result must have exactly `N` attribute slots.

### At Least N Slots

Result must have at least `N` attribute slots.

## Pool Model

Pool is a per-profile stat set.

Hybrid behavior:

- User picks a preset first.
- Preset pre-fills the pool.
- User may then edit the pool manually for that profile.

This means `Offensive` acts as a starter template, not a locked global definition.

### Default Presets

V1 preset list:

- `Offensive`
- `Custom Empty`

`Offensive` initially includes:

- `AtkBonus`
- `CHDmgBonus`
- `CHIRate`
- `SkillDmgBonus`

Future presets may be added later, but redesign must not depend on them.

### Pool Editing

After preset selection, profile editor shows a checklist of stats in pool.

User may:

- keep preset defaults;
- remove some stats from pool;
- add other stats to pool.

Pool contents are saved inside each profile, not globally.

## Rule Types

### At Least N From Pool

Minimum `N` slots in result must belong to the profile pool.

Remaining slots may contain anything.

Example:

```text
Total Slots: Any Total Slots
Pool: Offensive
Rule: At Least 3 From Pool
```

Valid result:

```text
Crit Damage
Crit Rate
Skill Damage
Health Bonus
```

### Only From Pool

Every slot in result must belong to the profile pool.

Example:

```text
Total Slots: Exact 4 Slots
Pool: Offensive
Rule: Only From Pool
```

Valid:

```text
Crit Rate
Crit Damage
Crit Damage
Atk Bonus
```

Invalid:

```text
Crit Rate
Crit Damage
Health Bonus
Atk Bonus
```

### Require Stat

Specific stat must appear at least `N` times.

Example:

```text
Require Crit Damage >= 2
```

This is optional and stacks with pool rules.

## Rule Composition

All rules inside one profile use AND.

Examples:

### Loose pool filter

```text
Any Total Slots
At Least 3 From Pool
```

### Tight offensive 4-slot filter

```text
Exact 4 Slots
Only From Pool
```

### Tight offensive 4-slot plus min-max requirement

```text
Exact 4 Slots
Only From Pool
Require Crit Damage >= 2
```

### Allowed duplicates naturally

If pool contains:

```text
Crit Damage, Crit Rate, Skill Damage, Atk Bonus
```

then this remains valid for `Only From Pool`:

```text
Crit Rate
Crit Damage
Crit Damage
Atk Bonus
```

No per-stat minimum exists unless user explicitly adds `Require Stat`.

## Editor Layout

Profile editor sections, top to bottom:

1. `Profile Name`
2. `Total Slots`
3. `Pool Preset`
4. `Pool Stats` checklist
5. `Rules`
6. `Summary`
7. `Save` / `Cancel`

### Total Slots Section

Controls:

- dropdown: `Any Total Slots`, `Exact N Slots`, `At Least N Slots`
- numeric input shown only when mode is `Exact` or `At Least`

### Pool Section

Controls:

- preset dropdown
- checklist of stats currently included in pool
- helper text:

```text
Preset fills defaults. You can still edit this profile.
```

### Rules Section

Add-rule menu contains only:

- `At Least N From Pool`
- `Only From Pool`
- `Require Stat`

Rules should read like human language, not implementation names.

Examples in row labels:

- `At Least 3 From Pool`
- `Only From Pool`
- `Require Crit Damage >= 2`

## Summary Format

Profile list summary must be human-readable.

Bad:

```text
Any · CHDmgBonus>=2 · TotalGroup>=3
```

Good:

```text
Any Total Slots · At Least 3 From Pool · Require Crit Damage >= 2
```

## Validation

- Profile must contain at least one rule.
- `Require Stat` needs stat selection and positive integer count.
- `At Least N From Pool` needs positive integer count.
- `Only From Pool` needs no count.
- Pool must contain at least one stat if any pool-based rule exists.
- `Exact` and `At Least` slot modes need positive slot count.
- Invalid profile remains visible but cannot be enabled.

## Runtime Behavior

When `Target Mode` is enabled:

1. Forge one result.
2. Evaluate enabled profiles top-to-bottom.
3. First matching profile wins.
4. Result is accepted.
5. Auto Forge stops.
6. Target-found modal shows matched profile and result summary.

When no profile matches:

- if `Auto Delete Non-Match` is on, delete result and continue;
- else accept result and continue until bag/material/attempt limits stop runner.

## Verification Scope

Current state today:

- matching logic has static checks and self-check coverage for old rule model;
- runtime target-mode behavior is not yet fully proven by user playtesting;
- redesign in this document is not implemented yet.

So target status is not "confirmed correct in live game" yet. It is only "designed and partly static-verified".

Implementation must add new self-checks for:

- `Only From Pool` allowing duplicates from same stat;
- `At Least N From Pool` allowing non-pool remainder;
- `Require Stat` stacking with pool rules;
- multiple enabled profiles with first-match-wins ordering;
- per-profile custom-edited pool persistence.

## Non-Goals

- No hardcoded progression labels like `Early Game` or `End Game`.
- No global pool that edits every profile at once.
- No forced per-stat quotas unless user explicitly adds `Require Stat`.

## Recommendation

Implement redesign by replacing current primary profile-rule editor semantics with:

- slot condition;
- editable per-profile pool;
- pool rule;
- optional stat minimums.

Keep advanced old matcher ideas out of UX unless later needed by proven user demand.
