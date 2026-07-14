# Ore Backpack Stats Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Show live `ORE: current/max` usage in the V6 Farm stats label, refreshing locally once per second only when ore usage or capacity changes.

**Architecture:** Reuse existing `GetOreBackpackUsage()` and `UpdateStatsLabel()`. Add one compact `OreStats` state table and one lightweight polling loop; keep UI writes change-driven and preserve all automation/remotes.

**Tech Stack:** Roblox Lua/Luau, Roblox `TextLabel`, PowerShell static checks, official/ephemeral Luau compiler, `luaparse`.

## Global Constraints

- Modify `holygrail/script-v6-full-run-dg.lua`; keep V5 unchanged.
- Display exactly `ORE: current/max` as third stats line.
- Poll local ore usage every `1.0` second.
- Update UI only when current ore or capacity changes.
- Keep last valid values when getter fails.
- Add no remote, listener, dependency, or configurable interval.
- Preserve chest/egg immediate refresh and all existing automation behavior.

---

### Task 1: Add Change-Driven Ore Counter

**Files:**
- Modify: `tools/checks/check-v6-menu.ps1`
- Modify: `holygrail/script-v6-full-run-dg.lua:194`
- Modify: `holygrail/script-v6-full-run-dg.lua:1272`
- Modify: `holygrail/script-v6-full-run-dg.lua:3204`

**Interfaces:**
- Consumes: `GetOreBackpackUsage()` and existing `UpdateStatsLabel()` callers.
- Produces: `OreStats = {Current, Max}` and a one-second local polling loop.

- [ ] **Step 1: Add failing static assertions**

Append before `Assert-LuauCompiles` is called in `tools/checks/check-v6-menu.ps1`:

```powershell
Assert-Contains 'local\s+OreStats\s*=\s*\{\s*Current\s*=\s*0\s*,\s*Max\s*=\s*0\s*\}' 'Missing ore stats cache'
Assert-Contains 'ORE:\s*"\s*\.\.\s*tostring\(OreStats\.Current\)\s*\.\.\s*"/"\s*\.\.\s*tostring\(OreStats\.Max\)' 'Stats label must show ORE current/max'
Assert-Contains 'Current\s*~=\s*OreStats\.Current\s+or\s+Max\s*~=\s*OreStats\.Max' 'Ore stats must refresh only when usage changes'
Assert-Contains 'task\.wait\(1\.0\)' 'Ore stats polling interval must be one second'
Assert-Contains 'StatsLabel\.Size\s*=\s*UDim2\.new\(1,\s*0,\s*0,\s*78\)' 'V6 stats label must fit three lines'
```

- [ ] **Step 2: Run check and confirm RED**

Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools/checks/check-v6-menu.ps1
```

Expected: FAIL with `Missing ore stats cache`.

- [ ] **Step 3: Add compact ore state**

Beside existing chest/egg counters, add one top-level state table:

```lua
local OreStats = {
    Current = 0,
    Max = 0
}
```

This adds one top-level local, not separate current/max locals.

- [ ] **Step 4: Add ore line to existing stats text**

Replace `UpdateStatsLabel()` with:

```lua
local function UpdateStatsLabel()
    if StatsLabel then
        StatsLabel.Text = "CHEST DESTROYED: " .. tostring(ChestDestroyedCount) ..
                              "\nEGG TRIGGERED: " .. tostring(EggTriggeredCount) ..
                              "\nORE: " .. tostring(OreStats.Current) .. "/" .. tostring(OreStats.Max)
    end
end
```

Chest and egg callbacks remain unchanged and continue calling this function immediately.

- [ ] **Step 5: Add one-second change-driven poller**

Immediately after `UpdateStatsLabel()`, add:

```lua
task.spawn(function()
    while true do
        local Success, Current, Max = pcall(GetOreBackpackUsage)
        if Success and (Current ~= OreStats.Current or Max ~= OreStats.Max) then
            OreStats.Current = Current
            OreStats.Max = Max
            UpdateStatsLabel()
        end
        task.wait(1.0)
    end
end)
```

On getter failure, cached values remain unchanged and loop retries after one second.

- [ ] **Step 6: Increase V6 stats height**

Change only V6 label size:

```lua
StatsLabel.Size = UDim2.new(1, 0, 0, 78)
```

- [ ] **Step 7: Run GREEN checks**

Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools/checks/check-v6-menu.ps1
cmd /d /c "npx -y luaparse holygrail\script-v6-full-run-dg.lua > NUL && echo syntax-ok"
git diff --check
```

Expected: `v6-menu-ok`, `syntax-ok`, no diff-check output. V6 checker also performs actual Luau compilation.

- [ ] **Step 8: Commit counter**

```powershell
git add holygrail/script-v6-full-run-dg.lua tools/checks/check-v6-menu.ps1
git commit -m "Add live ore backpack stats"
```

### Task 2: Document And Verify Ore Stats

**Files:**
- Modify: `docs/features.md:27`
- Verify: `holygrail/script-v5-full-run-dg.lua`

**Interfaces:**
- Produces: concise user-facing behavior note and final regression evidence.

- [ ] **Step 1: Update feature documentation**

Replace current counter bullet with:

```markdown
- Farm overlay shows `CHEST DESTROYED`, `EGG TRIGGERED`, and live `ORE: current/max` backpack usage.
- Ore usage is read locally once per second and redraws only when current ore or capacity changes.
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

Expected: all eight checks pass, `syntax-ok`, no diff-check output, V5 unchanged.

- [ ] **Step 3: Commit documentation**

```powershell
git add docs/features.md
git commit -m "Document live ore backpack stats"
```

- [ ] **Step 4: Review final state**

Run:

```powershell
git status --short
git log -3 --oneline
```

Expected: clean working tree and two feature commits after plan/spec commits.
