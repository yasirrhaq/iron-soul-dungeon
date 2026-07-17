# Target-Stat Auto Forge Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans. Do not dispatch subagents unless user explicitly requests delegation.

**Goal:** Auto-acknowledge forge results, match editable target-stat profiles, stop safely on matches or full equipment storage, and move Forge into a clean third main tab.

**Architecture:** Extend the existing single `AutoForge` namespace with normalized profile persistence, pure matching helpers, and one result-decision path. Reuse the direct forge/QTE flow, replace native result-screen waiting with Accept/Delete acknowledgement, and mount existing craft UI plus target-profile UI under a new main `FORGE` tab.

**Tech Stack:** Roblox Luau, existing Framework `ForgeUtil`/`EquipmentUtil`/`WindowUtil`/`TranslationUtil`, `ForgeRF`, native Roblox GUI, PowerShell contract checks, `luaparse`.

## Global Constraints

- V5 remains unchanged.
- Main navigation is exactly `FARM | UTILITY | FORGE` with equal widths.
- Utility contains only `DUNGEON | GROCERY | SEASON | AUTO SELL`.
- Forge contains `CRAFT | TARGETS` subviews.
- Normal Auto Forge accepts every result automatically.
- Target match accepts and stops.
- Target non-match accepts or deletes according to `Auto Delete Non-Match`.
- Matching counts normalized attribute slots, never displayed percentages.
- Offensive membership uses explicit stable IDs only: `AtkBonus`, `CHDmgBonus`, `CHIRate`, and `SkillDmgBonus`, retaining only IDs present in runtime catalog.
- No automatic equipment selling.
- No new dependency.

---

### Task 1: Add Target-Stat And Main-Tab Contract Checks

**Files:**
- Create: `tools/checks/check-v6-target-stat-forge.ps1`
- Modify: `tools/checks/check-v6-menu.ps1`
- Test: `holygrail/script-v6-full-run-dg.lua`

**Interfaces:**
- Consumes V6 source text.
- Produces `v6-target-stat-forge-ok` and updated `v6-menu-ok`.

- [ ] **Step 1: Write failing target-stat check**

Assert safe defaults and persistence for:

```lua
AutoForgeTargetMode = false
AutoForgeAutoDeleteNonMatch = false
AutoForgeProfiles = {}
```

Require `NormalizeStatId`, `NormalizeProfiles`, `ValidateProfile`, `BuildResultSummary`, `MatchProfile`, `FindMatchingProfile`, `CheckEquipmentStorage`, result Accept/Delete branches, target-found modal state, and table-driven self-check labels for every design example.

- [ ] **Step 2: Write failing menu assertions**

Require three equal main buttons, `ForgeTab`, `ForgeCraftPage`, `ForgeTargetsPage`, `CRAFT`, and `TARGETS`. Reject `AutoForgeTabButton` under Utility navigation and require four quarter-width Utility buttons.

- [ ] **Step 3: Verify RED**

Run:

```powershell
.\tools\checks\check-v6-target-stat-forge.ps1
.\tools\checks\check-v6-menu.ps1
```

Expected: both fail because target profiles and third main tab do not exist.

---

### Task 2: Add Profile Persistence And Pure Matching

**Files:**
- Modify: `holygrail/script-v6-full-run-dg.lua`

**Interfaces:**
- Produces `AutoForge.TargetMode`, `AutoForge.AutoDeleteNonMatch`, `AutoForge.Profiles`, `AutoForge.StatCatalog`, `AutoForge.Groups`, and pure matching helpers.

- [ ] **Step 1: Add state and config defaults**

Extend `AutoForge` with target settings, profile list, discovered-stat cache, target-found data, and modal refresh callback. Normalize old config safely and persist all profile fields.

- [ ] **Step 2: Normalize profiles**

`AutoForge.NormalizeProfiles(Value)` must copy only valid scalar fields, generate missing stable IDs with `HttpService:GenerateGUID(false)`, clamp counts to `1..10`, preserve order, merge duplicate Specific rules using highest minimum, and force invalid profiles disabled while preserving their validation error.

- [ ] **Step 3: Build runtime stat catalog**

Read values from `GetGameEnum().AttrEntry`, normalize each identifier using `string.split(AttributeKey, "_")[1]`, add normalized IDs from result data, translate with `K_` + uppercase ID, and sort labels. Build Offensive membership from the four explicit IDs only when present; log ignored configured IDs once.

- [ ] **Step 4: Implement matching helpers**

`AutoForge.BuildResultSummary(ResultData)` returns ordered slots, per-stat counts, total slots, and group counts. `AutoForge.MatchProfile(Profile, Summary)` applies slot mode, Specific, TotalGroup, reserved-slot AdditionalGroup, and AllSlotsGroup rules. `AutoForge.FindMatchingProfile(ResultData)` returns the first enabled valid matching profile plus summary.

- [ ] **Step 5: Run table-driven self-check**

Cover:

- Total Offensive >= 3.
- Exact 4 with CHDmgBonus >= 2 plus Additional Offensive >= 2.
- Exact 4 with CHIRate >= 2 and unrestricted remaining slots.
- Exact 4 with All Slots Offensive.
- Duplicate normalized `CHDmgBonus_*` keys.
- Unknown stat failing Offensive membership.
- First-match ordering across multiple profiles.

---

### Task 3: Replace Manual Result Waiting With Decision Flow

**Files:**
- Modify: `holygrail/script-v6-full-run-dg.lua`

**Interfaces:**
- Consumes `RunCraft`, matching helpers, and profile state.
- Produces one acknowledged result per attempt and `{Stop, MatchedProfile, Summary, Result}` decision data.

- [ ] **Step 1: Add equipment-storage guard**

`AutoForge.CheckEquipmentStorage()` calls `EquipmentUtil:CheckCanAdd(LocalPlayer)` in `pcall`. Before every attempt that may accept a result, stop with `STOPPED - EQUIPMENT BAG FULL` if false. Never call `DropOres` after this guard fails.

- [ ] **Step 2: Return copied result from direct forge**

Keep `DropOres`, fresh UUID QTE stages, `ForgeFinish`, and result replication wait. Copy `ResultData`, including copied `Attr`, before acknowledgement. Do not open `ScreenForgeResult` and do not wait for manual clearing.

- [ ] **Step 3: Decide acknowledgement once**

- Normal mode: `ForgeResult(true)`, status `ACCEPTED - item`.
- Target match: `ForgeResult(true)`, cache target-found data, status `TARGET FOUND - profile`, stop.
- Non-match + auto-delete: `ForgeResult(false)`, status `NON-MATCH - DELETED`.
- Non-match + keep: `ForgeResult(true)`, status `NON-MATCH - ACCEPTED`.

Wait for forge state to clear after acknowledgement. Never issue both decisions.

- [ ] **Step 4: Update batch runner**

Use requested craft count as maximum attempts. Recalculate materials before each attempt, apply storage guard before any accepting path, stop on target match, materials exhaustion, toggle off, unsafe lobby/rejoin/sell state, or timeout. Preserve single runner lock.

- [ ] **Step 5: Add target-found notification**

Use `StarterGui:SetCore("SendNotification", ...)` inside `pcall`. Modal data remains session-only until Close.

---

### Task 4: Build Three Main Tabs And Forge Profile UI

**Files:**
- Modify: `holygrail/script-v6-full-run-dg.lua`

**Interfaces:**
- Produces `FarmTab`, `UtilityTab`, `ForgeTab`, `ForgeCraftPage`, `ForgeTargetsPage`, profile editor overlay, and target-found modal.

- [ ] **Step 1: Split main navigation**

Resize `FarmTabButton` and `UtilityTabButton` to thirds, add `ForgeTabButton`, create `ForgeTab`, and update `SetMainTab()` to show exactly one page. Close Utility and Forge dropdowns on main-tab change.

- [ ] **Step 2: Simplify Utility navigation**

Remove Utility `FORGE` button and page branch. Resize four remaining Utility sub-tabs to quarters. Keep all existing Dungeon, Grocery, Season, Auto Sell, and Auto Potion behavior.

- [ ] **Step 3: Mount craft page**

Create Forge `CRAFT | TARGETS` navigation. Pass `ForgeCraftPage` as parent to `AutoForge.BuildMenuPage`; preserve existing recipe/composition controls and adapt page sizing to full main-tab height.

- [ ] **Step 4: Build target profile list**

Add persisted Target Mode and Auto Delete toggles, `ADD PROFILE`, profile rows with enabled state, summary, Edit, Duplicate, Delete, and first-match displayed order.

- [ ] **Step 5: Build profile editor overlay**

Editor supports name, slot mode, slot count, rule type, stat/group selection, min count, add/delete rule, Save, and Cancel. Invalid profiles display inline error and save disabled. Use modal overlays instead of nested clipped dropdowns.

- [ ] **Step 6: Build target-found modal**

Show profile name, item name, attempt, total slots, sorted stat counts, auto-accepted message, and Close button. Do not clear on tab switch.

---

### Task 5: Update Docs, Verify, Commit, And Push

**Files:**
- Modify: `README.md`
- Modify: `docs/features.md`
- Modify: `docs/superpowers/specs/2026-07-16-target-stat-auto-forge-design.md` only if implementation reveals a verified contract correction

- [ ] **Step 1: Update current feature docs**

Document three main tabs, normal auto-accept, profile rule semantics, non-match handling, equipment-bag stop, and target-found modal. Remove statements saying every craft waits for manual Accept/Delete.

- [ ] **Step 2: Run full verification**

```powershell
.\tools\checks\check-v6-target-stat-forge.ps1
.\tools\checks\check-v6-auto-forge.ps1
.\tools\checks\check-v6-auto-potion.ps1
.\tools\checks\check-v6-auto-rejoin.ps1
.\tools\checks\check-v6-menu.ps1
.\tools\checks\check-safe-lobby.ps1
.\tools\checks\check-ui-layout.ps1
cmd /d /c "npx -y luaparse holygrail\script-v6-full-run-dg.lua > NUL && echo syntax-ok"
git diff --check
git diff --exit-code -- holygrail/script-v5-full-run-dg.lua
```

- [ ] **Step 3: Commit and push**

Commit plan separately, then commit implementation and push `main` to `origin` after every check passes.
