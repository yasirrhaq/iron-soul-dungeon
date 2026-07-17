# Target-Stat Auto Forge UX Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace confusing Target Forge rule UX with pool-based rules that match user mental model, while preserving safe Auto Forge runtime behavior.

**Architecture:** Keep implementation inside existing `holygrail/script-v6-full-run-dg.lua` instead of splitting files. Replace old target-profile rule model and editor labels with a new per-profile pool model, then adapt matcher, summaries, persistence defaults, and runtime checks to the new semantics. Protect V5 and existing non-forge features with focused static checks plus parser verification.

**Tech Stack:** Roblox Lua in single-file script, PowerShell static checks, `luaparse`, existing V6 menu/build helpers

## Global Constraints

- Do not modify `holygrail/script-v5-full-run-dg.lua`.
- Keep `FARM | UTILITY | FORGE` main tabs unchanged.
- Keep Auto Forge lobby-only.
- Keep multiple enabled profiles with top-to-bottom, first-match-wins behavior.
- No hardcoded progression labels like `Early Game` or `End Game`.
- No global pool that edits every profile at once.
- No forced per-stat quotas unless user explicitly adds `Require Stat`.
- New UX terms: `Any Total Slots`, `Exact N Slots`, `At Least N Slots`, `At Least N From Pool`, `Only From Pool`, `Require Stat`.
- Pool must be preset-backed and editable per profile.
- Target-mode runtime correctness is not yet proven in live game; add self-checks for new semantics before claiming feature complete.

---

## File Map

- Modify: `holygrail/script-v6-full-run-dg.lua`
  - Replace old target-profile data shape, defaults, validation, summaries, editor UI, and matcher logic.
  - Keep all non-target-forge systems untouched.
- Modify: `tools/checks/check-v6-auto-forge.ps1`
  - Replace old rule-shape assertions with pool-model assertions.
- Modify: `README.md`
  - Update feature summary wording for Target Forge UX.
- Modify: `docs/features.md`
  - Update user-facing feature explanation for Forge tab.
- Modify: `docs/superpowers/specs/2026-07-16-target-stat-auto-forge-design.md`
  - Mark old rule semantics superseded or point to redesign spec.
- Modify: `docs/superpowers/specs/2026-07-17-target-stat-auto-forge-ux-redesign.md`
  - Keep in sync if implementation reveals a verified contract correction.

### Task 1: Replace target-profile data model and matcher self-checks

**Files:**
- Modify: `holygrail/script-v6-full-run-dg.lua`
- Test: `tools/checks/check-v6-auto-forge.ps1`

**Interfaces:**
- Consumes: existing `AutoForge.ValidateProfile(Profile)`, `AutoForge.FindMatchingProfile(ResultCopy)`, `AutoForge.BuildResultSummary(ResultCopy)`, `AutoForge.NormalizeAttrId(AttrId)` patterns in `holygrail/script-v6-full-run-dg.lua`
- Produces:
  - `AutoForge.CreateDefaultProfile(): table`
  - `AutoForge.NormalizeProfile(Profile): table`
  - `AutoForge.ValidateProfile(Profile): (boolean, string?)`
  - `AutoForge.MatchProfile(Profile, ResultData): (boolean, string?)`
  - `AutoForge.BuildProfileSummary(Profile): string`
  - `AutoForge.RunTargetProfileSelfChecks(): ()`

- [ ] **Step 1: Write the failing static checks**
- [ ] **Step 2: Run check to verify it fails**
- [ ] **Step 3: Write minimal matcher and profile-model implementation**
- [ ] **Step 4: Add runnable self-checks for new semantics**
- [ ] **Step 5: Run check to verify it passes**
- [ ] **Step 6: Commit**

Check snippet:

```powershell
Assert-Contains 'PoolPreset\s*=\s*"Offensive"' 'Missing default pool preset'
Assert-Contains 'PoolStats\s*=\s*\{' 'Missing per-profile pool stats'
Assert-Contains 'Kind\s*=\s*"PoolAtLeast"' 'Missing pool-at-least rule'
Assert-Contains 'Kind\s*=\s*"PoolOnly"' 'Missing pool-only rule'
Assert-Contains 'Kind\s*=\s*"RequireStat"' 'Missing require-stat rule'
Assert-NotContains 'AdditionalGroup' 'Old AdditionalGroup UX must be removed from primary flow'
```

Matcher snippet:

```lua
function AutoForge.MatchProfile(Profile, ResultData)
    local Slots = AutoForge.BuildNormalizedResultSlots(ResultData)
    if not AutoForge.MatchSlotMode(Profile, #Slots) then return false, "slot count" end
    local PoolLookup = AutoForge.BuildPoolLookup(Profile.PoolStats)
    for _, Rule in ipairs(Profile.Rules or {}) do
        if Rule.Kind == "PoolAtLeast" and AutoForge.CountSlotsInPool(Slots, PoolLookup) < Rule.MinCount then
            return false, "pool minimum"
        elseif Rule.Kind == "PoolOnly" and not AutoForge.AllSlotsInPool(Slots, PoolLookup) then
            return false, "pool only"
        elseif Rule.Kind == "RequireStat" and AutoForge.CountSlotsByStat(Slots, Rule.StatId) < Rule.MinCount then
            return false, "required stat"
        end
    end
    return true, "match"
end
```

### Task 2: Rewrite Forge Targets page editor and profile list wording

**Files:**
- Modify: `holygrail/script-v6-full-run-dg.lua:4821`
- Test: `tools/checks/check-v6-auto-forge.ps1`

**Interfaces:**
- Consumes: `AutoForge.CreateDefaultProfile`, `AutoForge.NormalizeProfile`, `AutoForge.BuildProfileSummary`, `AutoForge.ValidateProfile`
- Produces: updated `AutoForge.BuildTargetsPage(Context)` with per-profile pool preset picker, per-profile pool checklist UI, and top-to-bottom first-match-wins hint

- [ ] **Step 1: Write the failing UI assertions**
- [ ] **Step 2: Run check to verify it fails**
- [ ] **Step 3: Write minimal UI rewrite**
- [ ] **Step 4: Add pool checklist interactions**
- [ ] **Step 5: Run check to verify it passes**
- [ ] **Step 6: Commit**

UI assertions snippet:

```powershell
Assert-Contains 'Any Total Slots' 'Missing Any Total Slots label'
Assert-Contains 'At Least N From Pool' 'Missing pool minimum label'
Assert-Contains 'Only From Pool' 'Missing pool-only label'
Assert-Contains 'Require Stat' 'Missing require-stat label'
Assert-Contains 'Pool Preset' 'Missing pool preset label'
Assert-Contains 'Pool Stats' 'Missing pool stats label'
Assert-Contains 'First match wins' 'Missing first-match-wins hint'
```

### Task 3: Migrate persistence and preserve multi-profile runtime behavior

**Files:**
- Modify: `holygrail/script-v6-full-run-dg.lua`
- Test: `tools/checks/check-v6-auto-forge.ps1`

**Interfaces:**
- Consumes: config load/save helpers already used by V6, `AutoForge.Profiles`, `AutoForge.FindMatchingProfile`
- Produces: migration from old rule shape to new rule shape, preserved top-to-bottom enabled profile evaluation, stable per-profile pool persistence

- [ ] **Step 1: Write the failing migration assertions**
- [ ] **Step 2: Run check to verify it fails**
- [ ] **Step 3: Write minimal migration logic**
- [ ] **Step 4: Keep runtime ordering exact**
- [ ] **Step 5: Run check to verify it passes**
- [ ] **Step 6: Commit**

Migration snippet:

```lua
if Copy.Rules and Copy.Rules[1] and Copy.Rules[1].Kind == "Specific" then
    Copy.PoolPreset = Copy.PoolPreset or "Offensive"
    Copy.PoolStats = Copy.PoolStats or {"AtkBonus", "CHDmgBonus", "CHIRate", "SkillDmgBonus"}
    -- map Specific -> RequireStat, TotalGroup -> PoolAtLeast, AllSlotsGroup -> PoolOnly
end
```

### Task 4: Update docs to match new UX and verification limits

**Files:**
- Modify: `README.md`
- Modify: `docs/features.md`
- Modify: `docs/superpowers/specs/2026-07-16-target-stat-auto-forge-design.md`
- Modify: `docs/superpowers/specs/2026-07-17-target-stat-auto-forge-ux-redesign.md`

**Interfaces:**
- Consumes: approved redesign spec and final implemented behavior from Tasks 1-3
- Produces: aligned user-facing docs with accurate verification caveat

- [ ] **Step 1: Write doc updates inline**
- [ ] **Step 2: Run focused doc sanity check**
- [ ] **Step 3: Commit**

Doc snippet:

```markdown
- Auto Forge supports editable per-profile stat pools, pool-only rules, pool minimum rules, and optional required-stat minimums.
- Enabled Target Forge profiles are checked top-to-bottom; first match wins.
```

### Task 5: Run final verification for implementation branch

**Files:**
- Modify: none
- Test: `tools/checks/check-v6-target-stat-forge.ps1`
- Test: `tools/checks/check-v6-auto-forge.ps1`
- Test: `tools/checks/check-v6-auto-potion.ps1`
- Test: `tools/checks/check-v6-auto-rejoin.ps1`
- Test: `tools/checks/check-v6-menu.ps1`
- Test: `tools/checks/check-safe-lobby.ps1`
- Test: `tools/checks/check-ui-layout.ps1`

**Interfaces:**
- Consumes: completed Tasks 1-4
- Produces: verified branch ready for runtime test handoff

- [ ] **Step 1: Run full static verification**
- [ ] **Step 2: Record runtime caveat explicitly**
- [ ] **Step 3: Commit**

Final verification commands:

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

## Self-Review

- Spec coverage: covers vocabulary rewrite, pool presets plus per-profile editing, slot rules, pool rules, require-stat rules, enabled-profile ordering, docs, and verification caveat.
- Placeholder scan: no `TODO`, `TBD`, or unnamed commands remain.
- Type consistency: new rule kinds are `PoolAtLeast`, `PoolOnly`, and `RequireStat`; pool storage uses `PoolPreset` and `PoolStats` everywhere in plan.

## Execution Handoff

Plan complete and saved to `docs/superpowers/plans/2026-07-17-target-stat-auto-forge-ux-redesign.md`. Two execution options:

**1. Subagent-Driven (recommended)** - I dispatch a fresh subagent per task, review between tasks, fast iteration

**2. Inline Execution** - Execute tasks in this session using executing-plans, batch execution with checkpoints

Which approach?