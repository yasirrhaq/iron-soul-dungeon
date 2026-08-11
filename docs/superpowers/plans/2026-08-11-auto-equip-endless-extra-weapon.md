# Auto Equip Endless Extra Weapon Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Equip the highest-damage or user-selected eligible extra weapon before an Endless Tower run starts.

**Architecture:** Add one `AutoEndlessExtraWeapon` state table beside existing Endless state. It reads Framework equipment data on demand, refreshes dropdown options only from equipment data events, sends the existing equipment remote, confirms `ExtraWeaponUUID`, then lets `AutoEndlessTower.TryStartRun` click Start.

**Tech Stack:** Roblox Luau, existing Framework `DataUtil`/`EquipmentUtil`/`TimeLimitUtil`/`TranslationUtil`, native GUI selectors, PowerShell contract checks, `luaparse`.

## Global Constraints

- Default selection is `Highest Damage (Auto)`.
- Exclude primary, secondary, and time-limited weapons.
- Specific missing or ineligible UUID falls back to highest eligible damage.
- Dropdown labels show translated name, displayed fortify, and computed damage.
- Inventory refresh is event-driven; no frame or timed polling.
- Equip confirmation is bounded and cannot leave the Start modal stuck.
- Modify V6 only; keep V5 unchanged.

---

### Task 1: Add Failing Contract Check

**Files:**
- Create: `tools/checks/check-v6-auto-endless-extra-weapon.ps1`

**Interfaces:**
- Consumes: `holygrail/script-v6-full-run-dg.lua` as raw text.
- Produces: `v6-auto-endless-extra-weapon-ok` when all config, selection, event, remote, confirmation, fallback, and UI contracts exist.

- [ ] **Step 1: Write the failing check**

Create assertions for:

```powershell
Assert-Contains 'EndlessExtraWeaponUUID\s*=\s*""' 'Extra weapon must default to automatic selection'
Assert-Contains 'Config\.EndlessExtraWeaponUUID\s*=\s*AutoEndlessExtraWeapon\.SelectedUUID' 'Extra weapon preference must persist'
Assert-Contains 'GetDmgOrHpByInfo' 'Weapon options must use real displayed damage'
Assert-Contains 'Fortify\s+and\s+.*Fortify\s*-\s*1' 'Weapon labels must use displayed fortify'
Assert-Contains 'IsTimeLimited' 'Time-limited weapons must be excluded'
Assert-Contains 'RequestSetExtraWeapon' 'Missing direct extra weapon request'
Assert-Contains 'GetAttribute\("ExtraWeaponUUID"\)' 'Equip must confirm server attribute'
Assert-Contains 'EndlessExtraWeaponDropdown' 'Missing Tower extra weapon dropdown'
Assert-Contains 'DataUtil:ListenFor' 'Inventory refresh must be event-driven'
```

Isolate the extra-weapon helper body and fail if it contains `Heartbeat`, `RenderStepped`, or `while true`.

- [ ] **Step 2: Run check and verify RED**

Run:

```powershell
pwsh -NoProfile -File tools/checks/check-v6-auto-endless-extra-weapon.ps1
```

Expected: failure `Extra weapon must default to automatic selection`.

---

### Task 2: Add Selection, Equip Flow, And UI

**Files:**
- Modify: `holygrail/script-v6-full-run-dg.lua`
- Test: `tools/checks/check-v6-auto-endless-extra-weapon.ps1`

**Interfaces:**
- Consumes: `DataUtil:GetValue`, `DataUtil:ListenFor`, `EquipmentUtil:GetDef`, `EquipmentUtil:GetDmgOrHpByInfo`, `EquipmentUtil:GetOreRarity`, `TimeLimitUtil:IsTimeLimited`, `TranslationUtil:TranslateByKey`, and `Framework.Gameplay.EquipmentSystem.EquipmentRE`.
- Produces: `AutoEndlessExtraWeapon.GetOptions()`, `ResolveSelection()`, `RequestEquip(UUID)`, `Refresh`, and Tower dropdown state.

- [ ] **Step 1: Add config and normalized runtime state**

Add `EndlessExtraWeaponUUID = ""` to defaults. Normalize non-string values to `""`, load it into `AutoEndlessExtraWeapon.SelectedUUID`, and persist it in `SaveConfig()`.

- [ ] **Step 2: Build eligible sorted options**

Implement `GetOptions()` to read owned equipment and equip slots, reject non-weapons, primary/secondary UUIDs, and time-limited entries, then build:

```lua
{
    UUID = UUID,
    Label = DisplayName .. FortifySuffix .. " | DMG " .. tostring(Damage),
    Damage = Damage,
    Rarity = EquipmentUtil:GetOreRarity(Item.MaxOre),
    Sort = Definition.Sort or math.huge
}
```

Sort by damage descending, rarity descending, sort ascending, then UUID for deterministic ties.

- [ ] **Step 3: Resolve saved preference with fallback**

`ResolveSelection()` returns the saved matching option when eligible; otherwise returns first sorted option and marks fallback status. Empty option list returns `nil`.

- [ ] **Step 4: Add bounded remote confirmation**

`RequestEquip(UUID)` skips the remote when `ExtraWeaponUUID == UUID`; otherwise fires:

```lua
EquipmentRE:FireServer("RequestSetExtraWeapon", UUID)
```

Use bounded delayed retries from `TryStartRun`; never block its caller with an unbounded loop.

- [ ] **Step 5: Gate Start behind equip resolution**

Extend `AutoEndlessTower.TryStartRun()` state so it requests the configured option, waits for attribute confirmation, retries once with highest damage after timeout, then clicks Start. If no eligible weapon exists or both confirmations fail, click Start to avoid modal deadlock.

- [ ] **Step 6: Add Tower dropdown and event refresh**

Create `EndlessExtraWeaponDropdown` and options below player count. First row is `Highest Damage (Auto)`; remaining rows use option labels. Save UUID on selection. Register `DataUtil:ListenFor` callbacks for `{ "Equipment", "Owned" }` and `{ "Equipment", "EquipSlots" }` that call `AutoEndlessExtraWeapon.Refresh()` only when data changes.

- [ ] **Step 7: Run focused check and verify GREEN**

Run:

```powershell
pwsh -NoProfile -File tools/checks/check-v6-auto-endless-extra-weapon.ps1
```

Expected: `v6-auto-endless-extra-weapon-ok`.

---

### Task 3: Document And Verify Regression Surface

**Files:**
- Modify: `docs/features.md`
- Test: `tools/checks/check-v6-auto-endless-extra-weapon.ps1`
- Test: `tools/checks/check-v6-auto-endless-tower.ps1`

**Interfaces:**
- Consumes: completed extra-weapon flow.
- Produces: user-facing behavior documentation and full syntax/regression evidence.

- [ ] **Step 1: Update feature documentation**

Document automatic highest-damage default, specific dropdown labels, eligibility exclusions, event-driven refresh, saved UUID fallback, and bounded equip confirmation before Start.

- [ ] **Step 2: Run focused and adjacent checks**

Run:

```powershell
pwsh -NoProfile -File tools/checks/check-v6-auto-endless-extra-weapon.ps1
pwsh -NoProfile -File tools/checks/check-v6-auto-endless-tower.ps1
pwsh -NoProfile -File tools/checks/check-v6-menu.ps1
npx -y luaparse holygrail/script-v6-full-run-dg.lua
git diff --check
```

Expected: all PowerShell checks print their `*-ok` marker, parser exits zero, and `git diff --check` exits zero.
