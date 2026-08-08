# Auto-Skill Visual Suppression Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add persisted auto-skill-only suppression for character animation and locally rendered skill VFX while preserving normal skill execution and damage timing.

**Architecture:** Keep animation tracks running and set only their visual weight to zero during script-triggered `Q/E/R/G` casts. Use one state table to scope short suppression sessions, hide allowlisted visual instances created near the local character or current target, restore their original state after cast, and leave manual skills plus enemy-owned descendants untouched.

**Tech Stack:** Luau, Roblox `Animator`/`AnimationTrack`, Roblox visual instances, native Bugon menu, PowerShell static regression checks.

## Global Constraints

- Modify `holygrail/script-v6-full-run-dg.lua`; leave V5 and scratch scripts unchanged.
- Default `Disable Auto Skill Animation` off and persist it in `IronSoulConfig/YasirConfigV3.json`.
- Trigger suppression only from auto-skill `Q`, `E`, `R`, and `G` presses; never manual casts or weapon switch `C`.
- Never call `AnimationTrack:Stop()`, destroy effects, disable scripts/remotes/hitboxes, or invoke damage remotes.
- Fail open when effect ownership cannot be scoped safely.

---

### Task 1: Add Failing Regression Check

**Files:**
- Create: `tools/checks/check-v6-auto-skill-visuals.ps1`

**Interfaces:**
- Consumes: static source text from `holygrail/script-v6-full-run-dg.lua`.
- Produces: executable check returning `auto-skill-visuals-ok` only when config, UI, cast scoping, animation weight, VFX allowlist, restoration, and hard-stop guard exist.

- [ ] **Step 1: Write failing check**

Create assertions for `DisableAutoSkillAnimation = false`, config normalization/save/runtime assignment, Farm toggle label, `AutoSkillVisualSuppression.Begin(Key)` immediately before `PressKey(Key)`, animation `AdjustWeight(0, 0)`, visual classes `ParticleEmitter|Trail|Beam|Smoke|Fire|Sparkles|Highlight`, restoration through `Finish`, and absence of `Track:Stop()` inside suppression methods.

- [ ] **Step 2: Run check and verify RED**

Run: `powershell -ExecutionPolicy Bypass -File tools/checks/check-v6-auto-skill-visuals.ps1`

Expected: FAIL with `Missing Disable Auto Skill Animation default`.

- [ ] **Step 3: Commit regression check with implementation task**

Do not commit RED alone; keep it for Task 2 GREEN commit.

---

### Task 2: Implement Scoped Visual Suppression

**Files:**
- Modify: `holygrail/script-v6-full-run-dg.lua:167`
- Modify: `holygrail/script-v6-full-run-dg.lua:415`
- Modify: `holygrail/script-v6-full-run-dg.lua:478`
- Modify: `holygrail/script-v6-full-run-dg.lua:531`
- Modify: `holygrail/script-v6-full-run-dg.lua:3517`
- Modify: `holygrail/script-v6-full-run-dg.lua:6140`
- Modify: `docs/features.md:27`
- Test: `tools/checks/check-v6-auto-skill-visuals.ps1`

**Interfaces:**
- Consumes: `_G.DisableAutoSkillAnimation`, `LocalPlayer`, `Target`, `workspace`, `Animator.AnimationPlayed`, and existing auto-skill loop.
- Produces: `AutoSkillVisualSuppression.Begin(Key)`, `AutoSkillVisualSuppression.Finish(SessionId)`, `AutoSkillVisualSuppression.BindCharacter(Character)`, and `AutoSkillVisualSuppression.SetEnabled(Value)`.

- [ ] **Step 1: Add persisted setting**

Add `DisableAutoSkillAnimation = false` to `Config`; normalize with `Config.DisableAutoSkillAnimation = Config.DisableAutoSkillAnimation == true`; save from `_G.DisableAutoSkillAnimation`; assign `_G.DisableAutoSkillAnimation = Config.DisableAutoSkillAnimation` after load.

- [ ] **Step 2: Add one suppression state table**

Define one global `AutoSkillVisualSuppression` table near auto-skill state with session ID, active deadline, track, original track weight, visual state map, character connection, and timeout of eight seconds. Keep helper methods on table because V6 already sits at Luau's top-level local-register ceiling.

- [ ] **Step 3: Hide body track without stopping it**

Bind current/future character Animator `AnimationPlayed`. While active and inside 0.75-second capture window, match track names containing `skill`, preserve `WeightCurrent`, call `Track:AdjustWeight(0, 0)`, wait for `Stopped`, then finish after 0.25 seconds. Restore prior weight only when toggle disables before track completion.

- [ ] **Step 4: Hide scoped local VFX**

Observe `workspace.DescendantAdded`. Accept only allowlisted visual classes. Suppress descendants of local character/current camera, or effect-named workspace descendants positioned near local root/current target; reject descendants of `workspace.WorldEnemys`. Save original `Enabled`, set false, clear particle emitters, and guard against re-enable during active session.

- [ ] **Step 5: Restore and fail open**

`Finish(SessionId)` ignores stale sessions, marks inactive before restoration, disconnects property guards, clears particle emitters, restores original `Enabled`, and clears state. Wrap visual mutations in `pcall`; never destroy instances.

- [ ] **Step 6: Scope Begin to auto skill only**

Insert `AutoSkillVisualSuppression.Begin(Key)` directly before existing `PressKey(Key)` in auto-skill loop. Do not call it from `PressKey`, manual input paths, or `PressKey("C")`.

- [ ] **Step 7: Add Farm toggle**

Create `Disable Auto Skill Animation` row beside other Farm toggles. Setter updates `_G.DisableAutoSkillAnimation`, calls `AutoSkillVisualSuppression.SetEnabled(Value)`, then `SaveConfig()`.

- [ ] **Step 8: Update feature documentation**

Document toggle default, auto-skill-only scope, zero-weight animation behavior, local VFX allowlist, and possible fail-open visible effects.

- [ ] **Step 9: Run focused checks and verify GREEN**

Run:

```powershell
powershell -ExecutionPolicy Bypass -File tools/checks/check-v6-auto-skill-visuals.ps1
powershell -ExecutionPolicy Bypass -File tools/checks/check-auto-skill-g.ps1
powershell -ExecutionPolicy Bypass -File tools/checks/check-v6-menu.ps1
```

Expected: `auto-skill-visuals-ok`, `auto-skill-g-ok`, and `v6-menu-ok`.

- [ ] **Step 10: Commit focused implementation**

```powershell
git add -- holygrail/script-v6-full-run-dg.lua tools/checks/check-v6-auto-skill-visuals.ps1 docs/features.md docs/superpowers/plans/2026-08-08-auto-skill-visual-suppression.md
git commit --message="feat: suppress auto-skill visuals"
```

---

### Task 3: Verify Repository State

**Files:**
- Verify: `holygrail/script-v6-full-run-dg.lua`
- Verify: `tools/checks/check-v6-*.ps1`

**Interfaces:**
- Consumes: completed implementation and existing repository checks.
- Produces: fresh evidence that focused behavior, menu compilation, syntax, and whitespace checks pass.

- [ ] **Step 1: Run all V6 checks**

Run: `Get-ChildItem tools/checks/check-v6-*.ps1 | ForEach-Object { & $_.FullName }`

Expected: every script exits `0`.

- [ ] **Step 2: Run Lua parser**

Run: `cmd /c npx -y luaparse holygrail/script-v6-full-run-dg.lua > NUL && echo syntax-ok`

Expected: `syntax-ok`.

- [ ] **Step 3: Check patch cleanliness**

Run: `git diff --check HEAD~1..HEAD`

Expected: exit `0` with no output.

- [ ] **Step 4: Confirm unrelated files remain untouched**

Run: `git status --short --branch`

Expected: only pre-existing untracked `holygrail/backup/` and `research/dump/auto-start-and-claim-pet-expedition.md` remain.
