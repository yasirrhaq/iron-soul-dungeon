# Auto Potion Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans. Do not dispatch subagents unless user explicitly requests delegation.

**Goal:** Add persisted V6 Auto Potion controls that consume exactly one selected buff potion in active dungeons when its verified buff attributes are inactive.

**Architecture:** Keep feature inside existing V6 entrypoint under one `AutoPotion` namespace. Build catalog from native `ResPotion`, use attribute signals as primary refresh, retain one 15-second recovery scan, and serialize requests through one queue with server-safe spacing.

**Tech Stack:** Roblox Luau, existing Framework `PotionUtil`, `ResPotion`, native Roblox GUI, PowerShell contract checks, `luaparse`.

## Global Constraints

- Modify V6 only; V5 must remain byte-for-byte unchanged.
- Include every known `PotionType == "Buff"` potion, including Gold Potion.
- Exclude Friendship/Bond potion automation.
- Consume quantity `1`; never batch potion use.
- Run only in active dungeon, never lobby/loading/settlement/rejoin recovery.
- Never use potions in Endless Tower detected by `workspace.World.Start`.
- Wait 10 seconds after full dungeon eligibility; blocked or replaced dungeon context resets the grace timer.
- No one-second polling; fallback interval is 15 seconds.
- Disconnect signals and stop scans while toggle is off.
- No new dependency.

---

### Task 1: Add Auto Potion Contract Check

**Files:**
- Create: `tools/checks/check-v6-auto-potion.ps1`
- Test: `holygrail/script-v6-full-run-dg.lua`

- [ ] **Step 1: Create failing check**

Assert persisted defaults, catalog filtering, owned getter, attribute signals, 15-second fallback, 0.65-second queue spacing, fixed quantity, pending dedupe, all runtime guards, and Dungeon UI controls.

- [ ] **Step 2: Add table-driven self-check contract**

Require scenarios for one selected potion, multiple independent potions, multi-buff potion, out-of-stock potion, missed-signal recovery, and Bond exclusion.

- [ ] **Step 3: Verify RED**

Run `.\tools\checks\check-v6-auto-potion.ps1`. Expected: exit `1` because production contracts do not exist.

---

### Task 2: Add Persistence And Catalog Helpers

**Files:**
- Modify: `holygrail/script-v6-full-run-dg.lua`

- [ ] **Step 1: Add safe config defaults**

Add `AutoPotion = false` and `AutoPotionSelected = {}`. Normalize loaded selection to a string-key boolean map, export through `_G`, and persist through existing save flow.

- [ ] **Step 2: Create one namespace**

Create one `AutoPotion` table containing runtime token, catalog, order, selection, pending map, queue, queued map, connections, worker state, status, and UI refresh callback. Tear down previous reload token and connections before replacing it.

- [ ] **Step 3: Build native catalog**

Require `ReplicatedStorage.Configs.ResPotion`. Retain only definitions with `PotionType == "Buff"`. Extract non-empty `BuffIdN`/`DurationN` pairs, translated name, icon, stable ID, and owned count from `PotionUtil:GetOwnedAmount(LocalPlayer, PotionId)`.

Sort by translated display name. Remove unknown persisted IDs on next save. Do not exclude Gold Potion by name or ID.

- [ ] **Step 4: Add pure state helpers and self-check**

Add helpers for active-state evaluation, queue eligibility, and catalog filtering. Run assert-based table checks covering approved scenarios without network calls.

---

### Task 3: Implement Event-Driven Runtime

**Files:**
- Modify: `holygrail/script-v6-full-run-dg.lua`

- [ ] **Step 1: Add dungeon eligibility guard**

Block requests in lobby, loading, settlement/victory, rejoin recovery, missing character, or missing `PlayerAttrEntry`.

- [ ] **Step 2: Add race-safe dungeon grace**

After base eligibility succeeds, start a 10-second grace generation bound to the current character and `PlayerAttrEntry`. Return a blocked grace status until expiry. Any blocked state, context replacement, disable, or shutdown clears the start time and increments the generation so delayed scans from older contexts become no-ops. Trigger one immediate scan when the current generation expires.

- [ ] **Step 3: Manage selected BuffId signals**

Create one `GetAttributeChangedSignal(BuffId)` connection per unique selected Buff ID. Rebuild after selection changes. Disconnect all while disabled.

- [ ] **Step 4: Add deduplicated queue**

Queue selected inactive potion IDs in visible catalog order. Reject already queued or pending IDs. Use one worker and wait at least `0.65` seconds between sends.

- [ ] **Step 5: Send and confirm one potion**

Revalidate all guards, call `PotionUtil:UsePotion(LocalPlayer, PotionId, 1, nil)`, then wait up to five seconds for active attributes or owned decrease. Timeout retries only through next scan.

- [ ] **Step 6: Add 15-second fallback**

Start scan only while enabled. Evaluate immediately on eligible dungeon entry or enable. Scan every 15 seconds. Stop cleanly after disable/reload.

---

### Task 4: Build Dungeon Auto Potion UI

**Files:**
- Modify: `holygrail/script-v6-full-run-dg.lua`

- [ ] **Step 1: Add compact controls**

Add master `AUTO POTION` toggle, search input, Refresh button, and scrollable potion list without changing Utility tab structure.

- [ ] **Step 2: Build supported rows**

Each row shows checkbox, translated name, state, and owned count. Search matches name and ID. States: `Active`, `Inactive`, `Pending`, `Out of Stock`, `Unavailable`.

- [ ] **Step 3: Wire persistence and runtime**

Toggle saves and starts/stops runtime. Selection saves stable IDs, rebuilds signals, and evaluates immediately when eligible. Refresh rebuilds catalog and counts.

- [ ] **Step 4: Preserve layout**

Keep existing dungeon controls accessible and avoid clipped overlays at supported menu scales.

---

### Task 5: Document And Verify

**Files:**
- Modify: `README.md`
- Modify: `docs/features.md`
- Test: repository checks

- [ ] **Step 1: Document behavior**

Describe selected list, one-at-a-time use, buff-expiry refresh, dungeon guard, 15-second recovery, Gold support, and Friendship exclusion.

- [ ] **Step 2: Run verification**

Run Auto Potion, menu, Auto Forge, Auto Rejoin, safe-lobby, layout, Luau syntax, `git diff --check`, and V5 unchanged checks.

- [ ] **Step 3: Commit implementation**

Commit focused Auto Potion changes after checks pass. Push only when explicitly requested.
