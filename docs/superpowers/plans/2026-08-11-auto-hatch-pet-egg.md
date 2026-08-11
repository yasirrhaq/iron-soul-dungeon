# Auto Hatch Pet Egg Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Claim completed pet hatches and fill all empty hatch slots with highest-priority owned eggs without idle polling.

**Architecture:** Add an `AutoPetHatch` state machine beside existing pet expedition automation. Framework data listeners queue one deferred reconciliation; each pass claims or starts at most one item, then waits for replicated data or one bounded retry before becoming dormant.

**Tech Stack:** Roblox Luau, existing Framework `DataUtil`/`PetsHatchUtil`, native Utility Pets UI, PowerShell contract checks, `luaparse`.

## Global Constraints

- Default `Auto Hatch Egg` to off and persist it.
- Claim completed slots before starting eggs.
- Fill slots `1..3` using rarity descending, configuration sort ascending, then UUID.
- Perform no polling or remote calls while no eggs exist or all slots are actively hatching.
- Perform at most one server-changing action per reconciliation.
- Retry an unconfirmed action once, then wait for a real data event.
- Pause during rejoin recovery.
- Modify V6 only; keep V5 unchanged.

---

### Task 1: Add Failing Auto Hatch Check

**Files:**
- Create: `tools/checks/check-v6-auto-pet-hatch.ps1`

**Interfaces:**
- Consumes: `holygrail/script-v6-full-run-dg.lua` as raw text.
- Produces: `v6-auto-pet-hatch-ok` when config, priority, event, action, retry, idle, and UI contracts exist.

- [ ] **Step 1: Write contract assertions**

Assert default/persistence for `AutoPetHatch`, `GetOwnedEggs`, `GetEggCfg`, rarity/sort ordering, slot scan `1..3`, `IsCompleted`, `Claim`, `StartHatch`, one-action returns, `DataUtil:ListenFor` for both hatch paths, bounded `task.delay`, rejoin pause, and `AutoPetHatchToggle`/status UI. Isolate the feature body and reject `Heartbeat`, `RenderStepped`, and `while true`.

- [ ] **Step 2: Run check and verify RED**

Run:

```powershell
pwsh -NoProfile -File tools/checks/check-v6-auto-pet-hatch.ps1
```

Expected: failure `Auto Hatch must default off`.

---

### Task 2: Implement Event-Driven Hatch Reconciliation

**Files:**
- Modify: `holygrail/script-v6-full-run-dg.lua`
- Test: `tools/checks/check-v6-auto-pet-hatch.ps1`

**Interfaces:**
- Consumes: `PetsHatchUtil:GetOwnedEggs`, `GetEggCfg`, `GetSlotData`, `IsCompleted`, `Claim`, `StartHatch`, and `DataUtil:ListenFor`.
- Produces: `AutoPetHatch.Queue`, `Reconcile`, `GetEggs`, `GetSignature`, `SetEnabled`, and status refresh.

- [ ] **Step 1: Add config and runtime state**

Add `AutoPetHatch = false`, normalize it, persist `_G.AutoPetHatch`, and initialize `_G.AutoPetHatch` from config. State tracks `Queued`, `Pending`, `RetryCount`, `PendingSignature`, `Generation`, `Status`, and `ConfirmTimeout = 3`.

- [ ] **Step 2: Build deterministic egg list**

Read owned egg map, resolve configs, and sort candidates by `Rarity` descending, `Sort` ascending, then string UUID ascending.

- [ ] **Step 3: Reconcile one action**

When enabled and not blocked by rejoin: scan slots `1..3`, claim first completed slot and return. Otherwise find first empty slot; if no egg set `NO EGGS`, if no empty slot set `HATCHING`, else call `StartHatch` with first candidate and return.

- [ ] **Step 4: Add bounded confirmation**

Capture a signature of owned eggs and slot EggIds/StartTimes before action. Queue one `task.delay(3, ...)`; unchanged signature retries once, then sets `WAITING EVENT`. Any hatch data event clears pending retry state and queues a new deferred pass.

- [ ] **Step 5: Connect data listeners and toggle**

Listen to `{ "PetHatch", "Egg" }` and `{ "PetHatch", "Slots" }`. Enabling queues one pass; disabling increments generation, clears pending state, and sets `OFF`.

- [ ] **Step 6: Add Utility Pets UI**

Add `AutoPetHatchToggle` below expedition controls and `PetHatchStatusLabel`. Extend `RefreshPetExpeditionUI()` to redraw hatch status without adding a new page or loop.

- [ ] **Step 7: Run check and verify GREEN**

Run:

```powershell
pwsh -NoProfile -File tools/checks/check-v6-auto-pet-hatch.ps1
```

Expected: `v6-auto-pet-hatch-ok`.

---

### Task 3: Document And Verify

**Files:**
- Modify: `docs/features.md`
- Test: `tools/checks/check-v6-auto-pet-hatch.ps1`
- Test: `tools/checks/check-v6-auto-pet-expedition.ps1`

**Interfaces:**
- Consumes: completed auto hatch flow.
- Produces: behavior documentation and regression evidence.

- [ ] **Step 1: Document behavior**

Document automatic claim/refill, priority, event-only idle behavior, one-action reconciliation, bounded retry, and rejoin pause.

- [ ] **Step 2: Run validation**

Run:

```powershell
pwsh -NoProfile -File tools/checks/check-v6-auto-pet-hatch.ps1
pwsh -NoProfile -File tools/checks/check-v6-auto-pet-expedition.ps1
pwsh -NoProfile -File tools/checks/check-v6-menu.ps1
npx -y luaparse holygrail/script-v6-full-run-dg.lua
git diff --check
```

Expected: all checks print their `*-ok` marker; parser and diff checks exit zero.
