# Native D3D-Style Menu Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Create `holygrail/script-v6-full-run-dg.lua` with a draggable native menu, configurable Grocery and Season targets, and tri-state AutoSell rules while preserving v5 automation behavior.

**Architecture:** Copy v5 into a new v6 entrypoint, extend its existing JSON config and selection tables, then replace only the UI construction block. Runtime loops continue using existing remotes and delays; UI catalogs are local cached data.

**Tech Stack:** Roblox Lua, executor file APIs, Roblox `ScreenGui`, `UserInputService`, PowerShell static checks, `luaparse`.

## Global Constraints

- Keep `holygrail/script-v5-full-run-dg.lua` unchanged.
- Keep v6 as one runtime Lua file with no external UI dependency.
- Header is `Iron Soul Script by Bugon`.
- Footer is `© 2026 Bugon. All rights reserved.`
- AutoSell remains lobby-only.
- Do not change remote paths, purchase timing, replay, portal, or dungeon restart behavior.

---

### Task 1: Create V6 And Config Model

**Files:**
- Create: `holygrail/script-v6-full-run-dg.lua`
- Create: `tools/checks/check-v6-menu.ps1`

**Interfaces:**
- Produces: `AutoBuyWantedItemIds`, `AutoSeasonBuyWantedItemIds`, `OreSellModes`, and numeric `SellMaxRarity` loaded from `Config`.

- [ ] **Step 1: Add failing static check**

Check v6 exists, v5 hash is unchanged, branding exists, and config fields `AutoBuyWantedItemIds`, `AutoSeasonBuyWantedItemIds`, `OreSellModes`, and `SellMaxRarity` exist.

- [ ] **Step 2: Run check and confirm failure**

Run: `powershell -ExecutionPolicy Bypass -File tools/checks/check-v6-menu.ps1`
Expected: failure because v6 does not exist.

- [ ] **Step 3: Copy v5 to v6 and extend config**

Default selections:

```lua
AutoBuyWantedItemIds = {LuckPotion_1 = true, DropPotion_1 = true}
AutoSeasonBuyWantedItemIds = {SeasonTicket = true}
SellMaxRarity = 5
OreSellModes = {
    Corundum = "SELL", Heatshell = "SELL", Gwindel = "SELL",
    Blackhole = "KEEP", BloodHeart = "KEEP", Apocalypse = "KEEP", DarkBlossom = "KEEP"
}
```

Validate decoded selection tables and modes before use. Save new fields through existing `SaveConfig()`.

- [ ] **Step 4: Run static check**

Expected: config and branding assertions pass; later UI assertions may still fail.

### Task 2: Connect Dynamic Catalogs And Selection Logic

**Files:**
- Modify: `holygrail/script-v6-full-run-dg.lua`
- Modify: `tools/checks/check-v6-menu.ps1`

**Interfaces:**
- Produces: `GetGoldShopCatalog()`, `GetSeasonShopCatalog()`, `GetOreCatalog()`, and `ShouldSellOre(OreId, Def)`.

- [ ] **Step 1: Extend static check**

Assert full Gold pool reads `getupvalues`, Season reads `ResSeasonShop`, ore catalog reads `DataUtil` plus `ForgeUtil:GetDef`, and sell logic recognizes `AUTO`, `SELL`, and `KEEP`.

- [ ] **Step 2: Run check and confirm failure**

Expected: failure on missing catalog helpers.

- [ ] **Step 3: Implement minimal catalog helpers**

- Gold: read `getupvalues(ShopUtil.BuyItem)[2].Gold`; fallback to current Gold snapshot.
- Season: iterate `ResSeasonShop`, skip `__index`, dedupe by `ItemId`.
- Ore: iterate every `Ores` key including zero counts and attach definition rarity.
- Sort catalogs client-side and cache them.

- [ ] **Step 4: Replace hardcoded targeting**

Grocery and Season buy loops read saved selection tables. AutoSell uses:

```lua
if Mode == "KEEP" then return false end
if Mode == "SELL" then return true end
return SellMaxRarity > 0 and Def and Def.Rarity <= SellMaxRarity
```

- [ ] **Step 5: Run static check and syntax parser**

Run: `powershell -ExecutionPolicy Bypass -File tools/checks/check-v6-menu.ps1`
Run: `cmd /c npx -y luaparse holygrail\script-v6-full-run-dg.lua > NUL && echo syntax-ok`
Expected: checks pass and `syntax-ok` prints.

### Task 3: Replace Button Stack With Native Panel

**Files:**
- Modify: `holygrail/script-v6-full-run-dg.lua`
- Modify: `tools/checks/check-v6-menu.ps1`

**Interfaces:**
- Consumes: existing `_G` toggles, `SaveConfig()`, catalog helpers, and `UpdateStatsLabel()`.
- Produces: draggable panel, floating restore icon, main tabs, utility sub-tabs, search lists, rarity dropdown, and ore tri-state rows.

- [ ] **Step 1: Add UI assertions**

Assert header/footer strings, `Farm` and `Utility` tabs, `Grocery`, `Season`, and `AutoSell` sub-tabs, search inputs, floating `B` icon, and toggle/list helper functions.

- [ ] **Step 2: Run check and confirm failure**

Expected: failure because v5 button stack remains.

- [ ] **Step 3: Build shared UI helpers**

Create local helpers for rounded frames, labels, buttons, toggle rows, draggable objects, tab selection, search filtering, catalog rows, and scrolling canvas sizing. Use `UICorner`, `UIStroke`, `UIListLayout`, and `UIPadding`; no external library.

- [ ] **Step 4: Build Farm tab**

Connect Script, mode, Auto Replay, height slider, and live stats to existing state and behavior.

- [ ] **Step 5: Build Utility tab**

Add Perfect Forge, Auto Buy, Auto Sell, and Season Buy switches. Add sub-tabs and cached searchable lists. Grocery/Season rows toggle selected IDs. AutoSell rows cycle `AUTO -> SELL -> KEEP -> AUTO`; rarity dropdown cycles detected choices including `OFF`.

- [ ] **Step 6: Add minimize and restore behavior**

Minimize hides panel and shows draggable `B`; clicking `B` restores panel. Support mouse and touch.

- [ ] **Step 7: Run static check and syntax parser**

Expected: all v6 assertions pass and parser prints `syntax-ok`.

### Task 4: Document And Verify V6

**Files:**
- Modify: `README.md`
- Modify: `docs/features.md`

**Interfaces:**
- Produces: discoverable v6 entrypoint and concise UI configuration documentation.

- [ ] **Step 1: Update docs**

Mark `holygrail/script-v6-full-run-dg.lua` as active UI-configurable script. Keep v5 listed as previous stable version. Document catalog sources, persisted selections, rarity dropdown, and tri-state semantics.

- [ ] **Step 2: Run all relevant checks**

Run v6 static check, `luaparse`, `git diff --check`, and existing PowerShell checks that do not hardcode v5 as active behavior.

- [ ] **Step 3: Review final diff**

Confirm v5 has no diff, only v6/check/docs/plan changed, and no remote delays or paths changed.
