# Native D3D-Style Menu Design

## Scope

Replace separate hard-positioned buttons in `holygrail/script-v5-full-run-dg.lua` with one compact Roblox-native control panel. Keep farming, combat, dungeon, shop, sell, and replay behavior unchanged except that shop and ore target lists become user-configurable.

## Branding

- Header text: `Iron Soul Script by Bugon`.
- Footer text: `© 2026 Bugon. All rights reserved.`
- Minimized floating icon text: `B`.

## Window

- Use Roblox `ScreenGui` instances only; do not depend on Drawing API or external UI libraries.
- Use a dark D3D-style panel sized for mobile executors and desktop clients.
- Support mouse and touch dragging through `UserInputService`.
- Minimize hides panel and shows a draggable floating `B` icon.
- Clicking the floating icon restores the panel.
- Preserve `ScreenGui.ResetOnSpawn = false` and replace any existing `IronSoulDualMenu` instance on load.

## Navigation

- Main tabs: Farm and Utility.
- Utility contains sub-tabs: Grocery, Season, and AutoSell.
- Each item sub-tab has a client-side search field and scrolling list.
- Changing tabs or filtering lists must not call server remotes.

## Farm Tab

- Main script toggle backed by _G.AutoFarm.
- Underground/above-monster mode backed by _G.UndergroundMode.
- Auto replay toggle backed by _G.AutoReplay.
- Height slider backed by _G.TinggiMelayang; continue updating _G.KillAuraRadius.
- Live chest and egg statistics using existing StatsLabel updates.

## Utility Controls

- Perfect Forge toggle backed by _G.PerfectForge.
- Grocery Auto Buy toggle backed by _G.AutoBuy.
- Auto Sell toggle backed by _G.AutoSell.
- Season Buy toggle backed by _G.AutoSeasonBuy.
- Toggle rows use compact switches rather than full-width colored buttons.

## Grocery Catalog

- Load the full Gold shop pool from getupvalues(ShopUtil.BuyItem)[2].Gold when executor upvalue access is available.
- Fall back to ShopUtil:GetShopSnapshot(LocalPlayer, "Gold").Items when the full pool cannot be read.
- Normalize and deduplicate entries by ItemId because purchase targeting remains item-ID based.
- Display item ID, item type, price, and stock range when available.
- Each row has a checkbox controlling membership in AutoBuyWantedItemIds.
- Existing defaults remain selected on first run: LuckPotion_1 and DropPotion_1.

## Season Catalog

- Load every table entry from Configs.ResSeasonShop, excluding __index and invalid entries.
- Normalize and deduplicate selectable targets by ItemId; current rotation matching still resolves through each active ShopId.
- Display item ID, item type, price, item count, purchase limit, and special status when available.
- Each row has a checkbox controlling membership in AutoSeasonBuyWantedItemIds.
- Existing default remains selected on first run: `SeasonTicket`.

## AutoSell Catalog

- Build ore list from all keys returned by `DataUtil:GetValue(LocalPlayer, {"Ores"})`, including zero-count ores.
- Read metadata through `ForgeUtil:GetDef(OreId)` and rarity labels through `RarityTiers`.
- Sort ores by rarity, then item ID.
- Add `Sell Max Rarity` dropdown. `OFF` maps to `0`; other options derive from detected rarity levels and names.
- Each ore row cycles through three modes:
  - `AUTO`: sell only when ore rarity is at or below `SellMaxRarity`.
  - `SELL`: always include ore in sell attempts.
  - `KEEP`: never include ore in sell attempts.
- Selection priority is `KEEP`, then `SELL`, then rarity-based `AUTO`.
- Existing defaults migrate on first run:
  - `SellMaxRarity = 5`.
  - `Corundum`, `Heatshell`, and `Gwindel` use `SELL`.
  - `Blackhole`, `BloodHeart`, `Apocalypse`, and `DarkBlossom` use `KEEP`.

## Persistence

- Continue using `IronSoulConfig/YasirConfigV3.json` through existing executor file APIs.
- Persist Grocery selected item IDs, Season selected item IDs, `SellMaxRarity`, and per-ore mode overrides.
- Validate decoded values before applying them.
- Missing new fields use migration defaults; existing toggle and height values remain compatible.
- Save after a toggle, checkbox, dropdown, tri-state, or slider interaction completes.

## Runtime Behavior

- Auto Buy loops read saved Grocery and Season selection tables instead of hardcoded target tables.
- Auto Sell computes each ore decision from saved tri-state mode and max rarity.
- Auto Sell remains lobby-only.
- Catalog construction and search are local operations and add no remote traffic.
- Existing purchase limits, shop cooldown handling, sell confirmation, replay, portal, and dungeon restart logic remain unchanged.

## Implementation Shape

- Replace only current UI construction and event-handler block.
- Add small local helpers for panel rows, toggles, tabs, scrolling lists, dropdowns, and drag behavior.
- Keep active script as one file; add no dependency or separate runtime module.
- Cache normalized catalogs and refresh them only when user presses a local refresh button or reloads script.

## Non-Goals

- No Drawing API UI.
- No external UI framework.
- No changes to remote paths or purchase timing.
- No automatic buying of unchecked items.
- No virtualization; current catalog sizes fit standard `ScrollingFrame` lists.
