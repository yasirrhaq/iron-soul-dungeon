# Auto Pet Expedition Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add persisted V6 Auto Expedition and Auto Claim controls with configurable slot order, highest-affinity pet selection, and confirmed one-action execution.

**Architecture:** Extend existing single-file V6 config and native Utility menu. Add one `AutoPetExpedition` runtime namespace using `Framework.Modules.PetsExpeditionUtil`, replicated slot state, `CanDispatch`, and one background runner that claims before dispatching.

**Tech Stack:** Roblox Luau, existing Framework modules, native Roblox GUI, PowerShell static checks, `luaparse`.

## Global Constraints

- Modify `holygrail/script-v6-full-run-dg.lua` only for production behavior; V5 remains unchanged.
- Default dispatch order is `2,3,4`; Auto Claim scans all slots.
- Use remaining daily chances immediately and select highest-affinity eligible pets.
- Never fire overlapping expedition requests.
- Add no dependency and no expedition GUI clicking.

---

### Task 1: Expedition Runtime Contract

**Files:**
- Create: `tools/checks/check-v6-auto-pet-expedition.ps1`
- Modify: `holygrail/script-v6-full-run-dg.lua`

**Interfaces:**
- Consumes: `GetFrameworkModule()`, `RejoinWatchdog.BlocksAutomation()`, `SaveConfig()`, `LocalPlayer`.
- Produces: `AutoPetExpedition.NormalizeSlotOrder`, `FormatSlotOrder`, `GetRemaining`, `FindEmptySlot`, `FindBestPet`, `SetEnabled`, `RunCycle`, and `Status`.

- [ ] **Step 1: Write failing static contract check**

Check exact defaults, persistence, normalization, remote payloads, remaining calculation, `CanDispatch`, affinity-first sort, all-slot claim loop, one-action confirmation waits, and rejoin pause. End with `v6-auto-pet-expedition-ok`.

- [ ] **Step 2: Run check and verify RED**

Run: `pwsh -File tools/checks/check-v6-auto-pet-expedition.ps1`

Expected: FAIL at missing `AutoPetExpedition` default or namespace.

- [ ] **Step 3: Add minimal runtime**

Add config fields and runtime namespace. Normalize slot lists against `Config.SlotCount`; load/save `_G.AutoPetExpedition` and `_G.AutoClaimPetExpedition`. Resolve Framework modules lazily. Claim first completed slot across all slots, otherwise dispatch highest-affinity valid pet into first empty configured slot. Wait up to five seconds for replicated confirmation before next request.

- [ ] **Step 4: Run check and verify runtime contract advances**

Run: `pwsh -File tools/checks/check-v6-auto-pet-expedition.ps1`

Expected: FAIL only at missing menu controls.

### Task 2: Utility Menu and Validation

**Files:**
- Modify: `holygrail/script-v6-full-run-dg.lua`
- Modify: `tools/checks/check-v6-auto-pet-expedition.ps1`
- Modify: `docs/features.md`

**Interfaces:**
- Consumes: `CreateToggleRow`, `CreateText`, `Theme`, `SaveConfig`, runtime refresh callback.
- Produces: `AutoPetExpeditionToggle`, `AutoClaimPetExpeditionToggle`, `PetExpeditionSlotOrderInput`, `PetExpeditionChanceLabel`, and `PetExpeditionStatusLabel`.

- [ ] **Step 1: Add Utility controls**

Add two compact toggle rows below current Utility toggles, a `Slot Order` TextBox defaulting to canonical `2,3,4`, and chance/status labels. On `FocusLost`, normalize comma-separated input, save, and rewrite canonical text.

- [ ] **Step 2: Verify GREEN**

Run: `pwsh -File tools/checks/check-v6-auto-pet-expedition.ps1`

Expected: `v6-auto-pet-expedition-ok`.

- [ ] **Step 3: Document behavior**

Add concise feature notes for immediate remaining-chance use, all-slot claiming, highest-affinity priority, and configurable dispatch order.

- [ ] **Step 4: Run focused and broad validation**

Run:

```powershell
pwsh -File tools/checks/check-v6-auto-pet-expedition.ps1
pwsh -File tools/checks/check-v6-menu.ps1
cmd /c npx -y luaparse holygrail/script-v6-full-run-dg.lua
git diff --check
```

Expected: both checks print success markers, parser exits zero, and diff check is clean.
