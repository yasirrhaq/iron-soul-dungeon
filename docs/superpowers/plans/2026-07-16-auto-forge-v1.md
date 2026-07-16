# Auto Forge V1 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Do not dispatch subagents unless user explicitly requests delegation.

**Goal:** Add a persisted V6 Auto Forge page that validates per-craft ore composition, supports optional Fist relics, clamps batch count to inventory, and completes forge sessions directly without forge UI interaction.

**Architecture:** Keep feature inside existing V6 entrypoint. Add pure recipe/inventory calculation helpers, one guarded direct-forge runner, and one compact Utility page. Validate behavior through a dedicated PowerShell contract check before production edits.

**Tech Stack:** Roblox Luau, existing Framework `ForgeUtil`/`DataUtil`, `ForgeRF`, native Roblox GUI, PowerShell static checks, `luaparse`.

## Global Constraints

- Modify `holygrail/script-v6-full-run-dg.lua`; never modify V5.
- Use direct forge APIs; never click forge GUI or move character to forge.
- One craft consumes exact selected composition plus optional one relic.
- Resume QTE from server `Times`; fetch fresh UUID for every remaining QTE.
- Accept random result; no result-based retry.
- Run only in lobby, outside rejoin recovery and active auto-sell call.
- Enabling Auto Forge does not consume materials; user must press Start.
- No new dependency.
- Do not commit or push Auto Forge until user explicitly requests it.

---

### Task 1: Add Auto Forge Contract Check

**Files:**
- Create: `tools/checks/check-v6-auto-forge.ps1`
- Test: `holygrail/script-v6-full-run-dg.lua`

**Interfaces:**
- Consumes: V6 source text.
- Produces: `v6-auto-forge-ok` when config, recipes, calculations, runner, guards, and menu contracts exist.

- [ ] **Step 1: Create failing static check**

Use same `Assert-Contains`/`Assert-NotContains` pattern as other V6 checks. Assert these exact contracts:

```powershell
Assert-Contains 'AutoForge\s*=\s*false' 'Auto Forge must default off'
Assert-Contains 'AutoForgeRecipeId\s*=\s*"WeaponSword"' 'Missing default recipe'
Assert-Contains 'WeaponSword\s*=\s*\{[^}]*Category\s*=\s*"Weapon"[^}]*OreCount\s*=\s*3' 'Missing Sword recipe'
Assert-Contains 'WeaponFistCommon\s*=\s*\{[^}]*OreCount\s*=\s*18[^}]*RelicId\s*=\s*"FistRelic_1"' 'Missing Common Fist recipe'
Assert-Contains 'WeaponFistLuxury\s*=\s*\{[^}]*OreCount\s*=\s*18[^}]*RelicId\s*=\s*"FistRelic_2"' 'Missing Luxury Fist recipe'
Assert-Contains 'ArmorHeavyArmor\s*=\s*\{[^}]*Category\s*=\s*"Armor"[^}]*OreCount\s*=\s*22' 'Missing Heavy Armor recipe'
Assert-Contains 'local\s+function\s+CalculateAutoForgeLimit\(' 'Missing batch limit helper'
Assert-Contains 'math\.floor\(OwnedCount\s*/\s*PerCraft\)' 'Ore limit must use owned/per-craft floor'
Assert-Contains 'KeyString\.EquipmentUtil\.Crystals' 'Relics must use Crystals inventory path'
Assert-Contains 'ForgeUtil:IsRelicUsable' 'Relic usability must be validated'
Assert-Contains 'InvokeServer\("DropOres",\s*Composition,\s*Recipe\.Category,\s*Recipe\.RelicId\)' 'Missing direct DropOres payload'
Assert-Contains 'ForgeData\.QTE\.Times' 'QTE must resume completed steps'
Assert-Contains 'ForgeUtil:GetQTE\(LocalPlayer\)' 'QTE must fetch server UUID'
Assert-Contains 'Rating\s*=\s*15' 'QTE must submit perfect rating'
Assert-Contains 'ForgeUtil:ForgeFinish\(LocalPlayer\)' 'Missing forge finish'
Assert-Contains 'InvokeServer\("ForgeResult",\s*true\)' 'Missing result acknowledgement'
Assert-Contains 'AutoForgeState\.Running' 'Missing single-runner lock'
Assert-Contains 'IsInLobby\(\)' 'Auto Forge must be lobby-only'
Assert-Contains 'not\s+AutoSellBusy' 'Auto Forge must avoid active sell call'
Assert-Contains 'AutoForgePage' 'Missing Auto Forge page'
Assert-Contains 'StartAutoForgeBatch' 'Missing Start action'
Assert-NotContains 'script-v5-full-run-dg' 'Check must target V6 only'
```

- [ ] **Step 2: Run check and verify RED**

Run:

```powershell
.\tools\checks\check-v6-auto-forge.ps1
```

Expected: exit `1` at first missing Auto Forge contract.

---

### Task 2: Add Persisted Recipes And Pure Calculations

**Files:**
- Modify: `holygrail/script-v6-full-run-dg.lua:28`
- Modify: `holygrail/script-v6-full-run-dg.lua:49`
- Modify: `holygrail/script-v6-full-run-dg.lua:110`
- Modify: `holygrail/script-v6-full-run-dg.lua:160`

**Interfaces:**
- Produces: `AutoForgeRecipes`, `AutoForgeRecipeOrder`, normalized config, `GetAutoForgeInventory()`, `GetCompositionTotal()`, and `CalculateAutoForgeLimit()`.

- [ ] **Step 1: Define complete recipe table**

Add before `Config`:

```lua
local AutoForgeRecipes = {
    WeaponSword = {Label = "Sword", Category = "Weapon", OreCount = 3, Chance = 100},
    WeaponStaff = {Label = "Staff", Category = "Weapon", OreCount = 10, Chance = 80},
    WeaponAxeHammer = {Label = "Axe/Hammer", Category = "Weapon", OreCount = 16, Chance = 100},
    WeaponFist = {Label = "Fist", Category = "Weapon", OreCount = 18, Chance = 5},
    WeaponFistCommon = {Label = "Fist + Common Relic", Category = "Weapon", OreCount = 18, Chance = 20, RelicId = "FistRelic_1"},
    WeaponFistLuxury = {Label = "Fist + Luxury Relic", Category = "Weapon", OreCount = 18, Chance = 58, RelicId = "FistRelic_2"},
    ArmorLightHelmet = {Label = "Light Helmet", Category = "Armor", OreCount = 3, Chance = 100},
    ArmorLightArmor = {Label = "Light Armor", Category = "Armor", OreCount = 10, Chance = 80},
    ArmorHeavyHelmet = {Label = "Heavy Helmet", Category = "Armor", OreCount = 15, Chance = 80},
    ArmorHeavyArmor = {Label = "Heavy Armor", Category = "Armor", OreCount = 22, Chance = 100}
}

local AutoForgeRecipeOrder = {
    "WeaponSword", "WeaponStaff", "WeaponAxeHammer", "WeaponFist", "WeaponFistCommon",
    "WeaponFistLuxury", "ArmorLightHelmet", "ArmorLightArmor", "ArmorHeavyHelmet", "ArmorHeavyArmor"
}
```

- [ ] **Step 2: Add and normalize config**

Add defaults:

```lua
AutoForge = false,
AutoForgeRecipeId = "WeaponSword",
AutoForgeOreComposition = {},
AutoForgeRequestedCrafts = 1,
```

Add a positive integer map normalizer. Invalid recipe falls back to `WeaponSword`; requested crafts clamp to integer `1..999`; toggle is true only for explicit `true`.

Persist runtime values through `SaveConfig()` and initialize `_G.AutoForge` plus local recipe/composition/count variables after `LoadConfig()`.

- [ ] **Step 3: Add inventory and calculation helpers**

Use:

```lua
local KeyString = require(ReplicatedStorage:WaitForChild("Enum"):WaitForChild("KeyString"))
local Crystals = DataUtil:GetValue(LocalPlayer, {KeyString.EquipmentUtil.Crystals}) or {}
```

`GetAutoForgeInventory()` returns current `Ores` and `Crystals` maps. `GetCompositionTotal()` sums positive integer counts.

`CalculateAutoForgeLimit(Recipe, Composition, Ores, Crystals)` returns:

```lua
MaxCrafts, LimitingItemId, Reason
```

Rules:

- Composition total must equal `Recipe.OreCount`.
- Each selected ore contributes `math.floor(OwnedCount / PerCraft)`.
- Relic recipe contributes owned relic count and requires `ForgeUtil:IsRelicUsable(LocalPlayer, Recipe.RelicId)`.
- Empty/invalid composition returns zero.

- [ ] **Step 4: Run contract check**

Expected: check advances past config/recipe/calculation assertions and fails at missing runner contract.

---

### Task 3: Add Guarded Direct Forge Runner

**Files:**
- Modify: `holygrail/script-v6-full-run-dg.lua:243`
- Modify: `holygrail/script-v6-full-run-dg.lua:1563`
- Modify: `holygrail/script-v6-full-run-dg.lua:1670`

**Interfaces:**
- Produces: `AutoSellBusy`, `AutoForgeState`, `WaitForAutoForgeData()`, `RunAutoForgeCraft()`, and `StartAutoForgeBatch()`.

- [ ] **Step 1: Add runtime state and duplicate-run token**

```lua
local AutoSellBusy = false
local AutoForgeState = {
    Running = false,
    Status = "IDLE",
    Completed = 0,
    Planned = 0,
    Refresh = nil,
    Token = {Alive = true}
}

if _G.BugonAutoForgeToken then
    _G.BugonAutoForgeToken.Alive = false
end
_G.BugonAutoForgeToken = AutoForgeState.Token
```

Set `AutoSellBusy = true` immediately around the existing `pcall(TryAutoSellOresOnce)` and reset it after call.

- [ ] **Step 2: Add bounded pending-data wait**

```lua
local function WaitForAutoForgeData(ForgeUtil, ExpectedOreCount, Timeout)
    local Deadline = os.clock() + Timeout
    repeat
        local Success, ForgeData = pcall(ForgeUtil.GetForgeData, ForgeUtil, LocalPlayer)
        if Success and type(ForgeData) == "table" and ForgeData.OresNum == ExpectedOreCount and
            type(ForgeData.QTE) == "table" then
            return ForgeData
        end
        task.wait(0.1)
    until os.clock() >= Deadline
    return nil
end
```

- [ ] **Step 3: Implement one direct craft**

`RunAutoForgeCraft(Recipe, Composition)` must:

1. Call `ForgeRF:InvokeServer("DropOres", Composition, Recipe.Category, Recipe.RelicId)`.
2. Wait up to five seconds for matching forge data.
3. Read `QTEConfig = ForgeUtil:GetForgeQTE(ForgeData.OresNum)`.
4. Loop from `(ForgeData.QTE.Times or 0) + 1` through `QTEConfig.QT`.
5. Fetch `ForgeUtil:GetQTE(LocalPlayer)` every step; reject missing UUID.
6. Call `ForgeUtil:QTE(LocalPlayer, {UUID = QTEData.UUID, Rating = 15})` with `0.15s` between calls.
7. Call `ForgeUtil:ForgeFinish(LocalPlayer)`.
8. Wait `0.5s`, then call `ForgeRF:InvokeServer("ForgeResult", true)`.

Once `DropOres` succeeds, finish current craft even if toggle switches off, preventing abandoned pending sessions.

- [ ] **Step 4: Implement batch start**

`StartAutoForgeBatch()` rejects:

- existing `AutoForgeState.Running`;
- toggle off;
- non-lobby state;
- `RejoinWatchdog.BlocksAutomation()`;
- `AutoSellBusy` or `SellPending`;
- invalid composition or zero maximum.

Clamp planned crafts with:

```lua
local Planned = math.min(AutoForgeRequestedCrafts, MaxCrafts)
```

Spawn one runner. Before every craft, re-read inventory and recalculate maximum. Stop before starting next craft if toggle turns off or inventory becomes insufficient. Always clear `Running` after completion/error.

- [ ] **Step 5: Run contract check**

Expected: check advances through runner assertions and fails at missing menu contract.

---

### Task 4: Build Compact Auto Forge Utility Page

**Files:**
- Modify: `holygrail/script-v6-full-run-dg.lua:3715`
- Modify: `holygrail/script-v6-full-run-dg.lua:3740`
- Modify: `holygrail/script-v6-full-run-dg.lua:3965`
- Modify: `holygrail/script-v6-full-run-dg.lua:4231`

**Interfaces:**
- Produces: fifth Utility `FORGE` tab, `AutoForgePage`, recipe dropdown, craft count input, searchable ore rows, Start/Stop action, and live status refresh.

- [ ] **Step 1: Add fifth Utility tab**

Resize existing four buttons to `0.2` widths and add:

```lua
local AutoForgeTabButton = CreateButton(UtilityNavigation, "FORGE")
AutoForgeTabButton.Position = UDim2.new(0.8, 6, 0, 0)
AutoForgeTabButton.Size = UDim2.new(0.2, -6, 1, 0)
```

Extend `SetUtilityPage()` to show `AutoForgePage`, color button, and close all selector popups on page switch.

- [ ] **Step 2: Build fixed compact controls**

Create `AutoForgePage` as full-size frame. Fit controls above a scrollable ore list:

- Y `0`: Auto Forge toggle row, height `30`.
- Y `34`: recipe dropdown, height `30`.
- Y `68`: craft count input and Start/Stop button, height `30`.
- Y `102`: two-line summary/status, height `32`.
- Y `138`: ore search box, height `28`.
- Y `170`: ore `ScrollingFrame`, remaining height.

Recipe rows display:

```text
Weapon - Fist + Common Relic - 18 Ore - 20%
```

Changing recipe clears composition and saves config.

- [ ] **Step 3: Build ore composition rows**

Each all-known ore row shows translated name, owned count, minus button, selected per-craft count, and plus button. Increment is disabled when owned is zero or composition already meets recipe total. Decrement removes zero entries from persisted map.

Search matches display name and item ID. Refresh rebuilds `GetOreCatalog(true)` and recalculates limits.

- [ ] **Step 4: Add live summary and controls**

Summary examples:

```text
ORE 18/18 | MAX 3 | RELIC 3
Adjusted 10 to 3 - Limited by Fist Relic
```

Start button calls `StartAutoForgeBatch()`. While running, button reads `STOP AFTER CRAFT`; pressing it sets `_G.AutoForge = false`. Toggle OFF also stops before next craft and persists config.

Assign `AutoForgeState.Refresh` to UI refresh function so runner status updates do not poll every frame.

- [ ] **Step 5: Run menu and Auto Forge checks**

Run:

```powershell
.\tools\checks\check-v6-menu.ps1
.\tools\checks\check-v6-auto-forge.ps1
```

Expected: `v6-menu-ok` and `v6-auto-forge-ok`.

---

### Task 5: Document And Verify V6

**Files:**
- Modify: `README.md:13`
- Modify: `docs/features.md`
- Test: all repository checks

**Interfaces:**
- Produces: user-facing Auto Forge behavior summary and verification evidence.

- [ ] **Step 1: Update concise feature documentation**

Add README bullet describing recipe/composition/batch Auto Forge. Add `## Auto Forge` section to `docs/features.md` covering direct UI bypass, recipe list, relic inventory, exact composition, clamp behavior, lobby-only Start action, perfect QTE, and random-result acceptance.

- [ ] **Step 2: Run full verification**

```powershell
.\tools\checks\check-v6-auto-forge.ps1
.\tools\checks\check-v6-menu.ps1
.\tools\checks\check-v6-auto-rejoin.ps1
.\tools\checks\check-safe-lobby.ps1
.\tools\checks\check-ui-layout.ps1
cmd /d /c "npx -y luaparse holygrail\script-v6-full-run-dg.lua > NUL && echo syntax-ok"
git diff --check
git diff --exit-code -- holygrail/script-v5-full-run-dg.lua
```

Expected: every PowerShell check exits `0`, `syntax-ok`, no diff-check output, and V5 diff is empty.

- [ ] **Step 3: Leave Auto Forge changes uncommitted**

Report changed files and validation results. Wait for explicit user request before commit or push.
