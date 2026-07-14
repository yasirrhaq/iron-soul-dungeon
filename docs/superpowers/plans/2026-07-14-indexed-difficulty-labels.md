# Indexed Difficulty Labels Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Show `[index] difficulty name` in V6 Dungeon selectors and reliably discover standard difficulty levels `1` through `10`.

**Architecture:** Extend current `DungeonCatalog.GetDifficultyCatalog()` candidate loop from `1..5` to `1..10`, retain Hell-style list discovery for additional mappings, and prefix the already translated display name with its internal level. Existing selector rendering automatically uses the updated `DisplayName`.

**Tech Stack:** Roblox Lua/Luau, Framework `WorldUtil`, PowerShell checks, actual Luau compiler, `luaparse`.

## Global Constraints

- Keep V5 unchanged.
- Probe standard difficulty levels `1` through `10` directly.
- Retain `GetWorldStyleList(WorldId, "Hell")` as supplementary discovery.
- Display labels as `[<level>] <game name>` in rows and selected value.
- Keep locked entries visible and nonselectable.
- Do not fabricate invalid levels or hardcode translated names.
- Change no remotes, saved values, fallback order, auto-start, auto-sell, replay, portal, or party behavior.

---

### Task 1: Add Indexed Difficulty Discovery

**Files:**
- Modify: `tools/checks/check-v6-menu.ps1`
- Modify: `holygrail/script-v6-full-run-dg.lua:555`

**Interfaces:**
- Consumes: current `AddDifficulty(DiffLevel)` validation and `Entry.DisplayName` selector rendering.
- Produces: valid difficulty entries whose `DisplayName` includes `[Level]`.

- [ ] **Step 1: Add failing assertions**

Append near existing difficulty assertions:

```powershell
Assert-Contains 'for\s+DiffLevel\s*=\s*1\s*,\s*10\s+do' 'Difficulty catalog must probe standard levels 1 through 10'
Assert-NotContains 'for\s+DiffLevel\s*=\s*1\s*,\s*5\s+do' 'Difficulty catalog must not stop at level 5'
Assert-Contains 'DifficultyName\s*=\s*"\["\s*\.\.\s*tostring\(DiffLevel\)\s*\.\.\s*"\]\s"\s*\.\.\s*DifficultyName' 'Difficulty labels must include their numeric index'
```

- [ ] **Step 2: Run checker and confirm RED**

Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools/checks/check-v6-menu.ps1
```

Expected: FAIL with `Difficulty catalog must probe standard levels 1 through 10`.

- [ ] **Step 3: Probe standard levels 1 through 10**

Replace:

```lua
for DiffLevel = 1, 5 do
    AddDifficulty(DiffLevel)
end
```

with:

```lua
for DiffLevel = 1, 10 do
    AddDifficulty(DiffLevel)
end
```

Keep the existing Hell list loop afterward; `Seen[DiffLevel]` prevents duplicates.

- [ ] **Step 4: Prefix validated display name**

After optional Hell wrapping and before lock lookup, add:

```lua
DifficultyName = "[" .. tostring(DiffLevel) .. "] " .. DifficultyName
```

Do not change `Entry.Level`; persistence and remotes continue using the numeric value.

- [ ] **Step 5: Run GREEN checks**

Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools/checks/check-v6-menu.ps1
cmd /d /c "npx -y luaparse holygrail\script-v6-full-run-dg.lua > NUL && echo syntax-ok"
git diff --check
```

Expected: `v6-menu-ok`, `syntax-ok`, no diff-check output. V6 checker performs actual Luau compilation.

- [ ] **Step 6: Commit implementation**

```powershell
git add holygrail/script-v6-full-run-dg.lua tools/checks/check-v6-menu.ps1
git commit -m "Add indexed difficulty labels"
```

### Task 2: Update Documentation And Verify

**Files:**
- Modify: `docs/features.md:72`
- Verify: `holygrail/script-v5-full-run-dg.lua`

**Interfaces:**
- Produces: documentation matching indexed selector behavior and full regression evidence.

- [ ] **Step 1: Replace stale hidden-number text**

Replace the current internal-number bullet with:

```markdown
- Difficulty rows and selected value show their internal index, such as `[10] Hell (Nightmare)`; saved config and remotes use the same numeric level.
```

- [ ] **Step 2: Run full verification**

Run:

```powershell
Get-ChildItem tools/checks/*.ps1 | ForEach-Object {
    & powershell -NoProfile -ExecutionPolicy Bypass -File $_.FullName
    if ($LASTEXITCODE -ne 0) { throw "Check failed: $($_.Name)" }
}
cmd /d /c "npx -y luaparse holygrail\script-v6-full-run-dg.lua > NUL && echo syntax-ok"
git diff --check
git diff HEAD --quiet -- holygrail/script-v5-full-run-dg.lua
if ($LASTEXITCODE -ne 0) { throw "script-v5 changed" }
```

Expected: all checks pass, `syntax-ok`, no diff-check output, V5 unchanged.

- [ ] **Step 3: Commit documentation**

```powershell
git add docs/features.md
git commit -m "Document indexed difficulty labels"
```

- [ ] **Step 4: Review final state**

```powershell
git status --short
git log -3 --oneline
```

Expected: clean working tree with two feature commits.
