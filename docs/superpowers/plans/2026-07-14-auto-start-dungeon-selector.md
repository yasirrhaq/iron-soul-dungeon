# Auto-Start Dungeon Selector Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add persisted dungeon and named difficulty selectors to V6, used only when auto-starting a solo dungeon after successful lobby auto-sell.

**Architecture:** Extend existing JSON config and auto-start locals, then build local world/difficulty catalogs from `ResWorld` and `Framework.Modules.WorldUtil`. Add one `Dungeon` Utility page using existing native Roblox UI helpers; selector changes remain client-side until existing post-sell `SelectWorld` and `CreatRoom` calls run.

**Tech Stack:** Roblox Lua, executor file APIs, Roblox `ScreenGui`, game `Framework` modules, PowerShell static checks, `luaparse`.

## Global Constraints

- Modify `holygrail/script-v6-full-run-dg.lua`; keep `holygrail/script-v5-full-run-dg.lua` unchanged.
- Keep V6 as one runtime Lua file with no external UI dependency.
- Utility sub-tabs are `Dungeon`, `Grocery`, `Season`, and `Auto Sell`.
- Show translated dungeon and difficulty names; hide internal difficulty numbers completely.
- Show locked entries with `LOCKED` and prevent selecting them.
- Selecting a dungeon chooses its highest unlocked difficulty.
- Persist `AutoStartWorldId` and `AutoStartDifficulty` in `IronSoulConfig/YasirConfigV3.json`.
- Auto-start remains post-auto-sell only and party size remains `1/1`.
- Do not change replay, backpack, auto-sell, portal, cooldown, or remote behavior.

---

### Task 1: Persist Auto-Start Selection

**Files:**
- Modify: `tools/checks/check-v6-menu.ps1`
- Modify: `holygrail/script-v6-full-run-dg.lua:43`
- Modify: `holygrail/script-v6-full-run-dg.lua:48`
- Modify: `holygrail/script-v6-full-run-dg.lua:100`
- Modify: `holygrail/script-v6-full-run-dg.lua:133`
- Modify: `holygrail/script-v6-full-run-dg.lua:224`

**Interfaces:**
- Produces: string `AutoStartWorldId`, integer `AutoStartDifficulty`, and matching `Config` fields.
- Consumes: existing `LoadConfig()` and `SaveConfig()` lifecycle.

- [ ] **Step 1: Add failing persistence assertions**

Append these checks after current config assertions in `tools/checks/check-v6-menu.ps1`:

```powershell
Assert-Contains 'AutoStartWorldId\s*=\s*"World3"' 'Missing default auto-start world config'
Assert-Contains 'AutoStartDifficulty\s*=\s*10' 'Missing default auto-start difficulty config'
Assert-Contains 'Config\.AutoStartWorldId\s*=\s*AutoStartWorldId' 'Auto-start world must persist'
Assert-Contains 'Config\.AutoStartDifficulty\s*=\s*AutoStartDifficulty' 'Auto-start difficulty must persist'
Assert-Contains 'local\s+AutoStartWorldId\s*=\s*Config\.AutoStartWorldId' 'Runtime world must load from config'
Assert-Contains 'local\s+AutoStartDifficulty\s*=\s*Config\.AutoStartDifficulty' 'Runtime difficulty must load from config'
```

- [ ] **Step 2: Run check and confirm failure**

Run:

```powershell
powershell -ExecutionPolicy Bypass -File tools/checks/check-v6-menu.ps1
```

Expected: FAIL with `Missing default auto-start world config`.

- [ ] **Step 3: Add config defaults and normalization**

Add selection locals beside existing configurable catalog state:

```lua
local AutoStartWorldId = nil
local AutoStartDifficulty = nil
```

Extend `Config`:

```lua
AutoStartWorldId = "World3",
AutoStartDifficulty = 10,
OreSellModes = CopyMap(DefaultOreSellModes)
```

Normalize decoded primitive values at end of `LoadConfig()`:

```lua
Config.AutoStartWorldId = type(Config.AutoStartWorldId) == "string" and Config.AutoStartWorldId or "World3"
Config.AutoStartDifficulty = math.max(1, math.floor(tonumber(Config.AutoStartDifficulty) or 10))
```

Assign runtime values immediately after `LoadConfig()`:

```lua
AutoStartWorldId = Config.AutoStartWorldId
AutoStartDifficulty = Config.AutoStartDifficulty
```

- [ ] **Step 4: Persist runtime selections**

Add before JSON encoding in `SaveConfig()`:

```lua
Config.AutoStartWorldId = AutoStartWorldId or Config.AutoStartWorldId
Config.AutoStartDifficulty = AutoStartDifficulty or Config.AutoStartDifficulty
```

Replace fixed auto-start locals near existing cooldown state:

```lua
local AutoStartMaxPlayers = 1
```

Remove duplicate fixed declarations:

```lua
local AutoStartWorldId = "World3"
local AutoStartDifficulty = 10
```

- [ ] **Step 5: Run static check and syntax parser**

Run:

```powershell
powershell -ExecutionPolicy Bypass -File tools/checks/check-v6-menu.ps1
cmd /c "npx -y luaparse holygrail\script-v6-full-run-dg.lua > NUL && echo syntax-ok"
```

Expected: `v6-menu-ok` and `syntax-ok`.

- [ ] **Step 6: Commit persistence change**

```powershell
git add holygrail/script-v6-full-run-dg.lua tools/checks/check-v6-menu.ps1
git commit -m "Persist auto-start dungeon selection"
```

### Task 2: Build World And Difficulty Catalogs

**Files:**
- Modify: `tools/checks/check-v6-menu.ps1`
- Modify: `holygrail/script-v6-full-run-dg.lua:439`
- Modify: `holygrail/script-v6-full-run-dg.lua:484`
- Modify: `holygrail/script-v6-full-run-dg.lua:869`

**Interfaces:**
- Produces: `GetDungeonCatalog(ForceRefresh)`, `GetDifficultyCatalog(WorldId, ForceRefresh)`, `ValidateAutoStartSelection(PreferHighest)`, `SelectAutoStartWorld(WorldId)`, and `SelectAutoStartDifficulty(DiffLevel)`.
- Dungeon entry shape: `{WorldId: string, DisplayName: string, Sort: number, Unlocked: boolean, Info: table}`.
- Difficulty entry shape: `{Level: number, DisplayName: string, Unlocked: boolean, Info: table}`.
- Consumes: `GetFrameworkModule()`, `LocalPlayer`, `SaveConfig()`, and persisted auto-start values from Task 1.

- [ ] **Step 1: Add failing catalog assertions**

Append to `tools/checks/check-v6-menu.ps1`:

```powershell
Assert-Contains 'local\s+function\s+GetDungeonCatalog\(' 'Missing dungeon catalog helper'
Assert-Contains 'Configs.*World.*ResWorld' 'Dungeon catalog must use ResWorld'
Assert-Contains 'WorldUtil:IsUnlockWorld' 'Dungeon catalog must mark locked entries'
Assert-Contains 'local\s+function\s+GetDifficultyCatalog\(' 'Missing difficulty catalog helper'
Assert-Contains 'WorldUtil:GetWorldDiffInfo' 'Difficulty catalog must use WorldUtil data'
Assert-Contains 'WorldUtil:GetWorldStyleList' 'Difficulty catalog must include Hell mappings'
Assert-Contains 'RarityTiers:GetDifficultyName' 'Difficulty labels must use game names'
Assert-Contains 'local\s+function\s+ValidateAutoStartSelection\(' 'Missing auto-start validation helper'
Assert-Contains 'local\s+function\s+SelectAutoStartWorld\(' 'Missing dungeon selection helper'
Assert-Contains 'local\s+function\s+SelectAutoStartDifficulty\(' 'Missing difficulty selection helper'
```

- [ ] **Step 2: Run check and confirm failure**

Run:

```powershell
powershell -ExecutionPolicy Bypass -File tools/checks/check-v6-menu.ps1
```

Expected: FAIL with `Missing dungeon catalog helper`.

- [ ] **Step 3: Add cached config access and translated-name helpers**

Add beside current catalog caches:

```lua
local CachedDungeonCatalog = nil
local CachedDifficultyCatalogs = {}

local function GetWorldConfig()
    return require(ReplicatedStorage:WaitForChild("Configs"):WaitForChild("World"):WaitForChild("ResWorld"))
end

local function TranslateConfigName(NameKey, Fallback)
    local DisplayName = nil
    pcall(function()
        DisplayName = GetFrameworkModule().Modules.TranslationUtil:TranslateByKey(NameKey)
    end)
    if type(DisplayName) == "string" and DisplayName ~= "" and DisplayName ~= NameKey then
        return DisplayName
    end
    return tostring(Fallback or NameKey or "Unknown")
end
```

- [ ] **Step 4: Implement dungeon catalog**

Add before `GetGoldShopCatalog()`:

```lua
local function GetDungeonCatalog(ForceRefresh)
    if CachedDungeonCatalog and not ForceRefresh then
        return CachedDungeonCatalog
    end

    local ResWorld = GetWorldConfig()
    local WorldUtil = GetFrameworkModule().Modules.WorldUtil
    local Result = {}
    for _, WorldKey in ipairs(ResWorld.__index or {}) do
        local Info = ResWorld[WorldKey]
        if type(Info) == "table" and Info.Mode ~= "Lobby" then
            local WorldId = tostring(Info.Id or WorldKey)
            local Unlocked = false
            pcall(function()
                Unlocked = WorldUtil:IsUnlockWorld(LocalPlayer, WorldId, 1) == true
            end)
            table.insert(Result, {
                WorldId = WorldId,
                DisplayName = TranslateConfigName(Info.Name, WorldId),
                Sort = tonumber(Info.Sort) or math.huge,
                Unlocked = Unlocked,
                Info = Info
            })
        end
    end
    table.sort(Result, function(A, B)
        if A.Sort == B.Sort then
            return A.WorldId < B.WorldId
        end
        return A.Sort < B.Sort
    end)
    CachedDungeonCatalog = Result
    return Result
end
```

- [ ] **Step 5: Implement named difficulty catalog**

Add after `GetDungeonCatalog()`:

```lua
local function GetDifficultyCatalog(WorldId, ForceRefresh)
    if CachedDifficultyCatalogs[WorldId] and not ForceRefresh then
        return CachedDifficultyCatalogs[WorldId]
    end

    local Framework = GetFrameworkModule()
    local WorldUtil = Framework.Modules.WorldUtil
    local RarityTiers = Framework.Modules.RarityTiers
    local Result = {}
    local Seen = {}

    local function AddDifficulty(DiffLevel)
        DiffLevel = tonumber(DiffLevel)
        if not DiffLevel or Seen[DiffLevel] then
            return
        end
        local Success, DiffInfo = pcall(function()
            return WorldUtil:GetWorldDiffInfo(WorldId, DiffLevel)
        end)
        if not Success or type(DiffInfo) ~= "table" then
            return
        end
        Seen[DiffLevel] = true
        local DifficultyName = tostring(DiffInfo.Difficulty or DiffLevel)
        pcall(function()
            DifficultyName = RarityTiers:GetDifficultyName(DiffInfo.Difficulty)
        end)
        if DiffInfo.Style == "Hell" then
            DifficultyName = "Hell (" .. DifficultyName .. ")"
        end
        local Unlocked = false
        pcall(function()
            Unlocked = WorldUtil:IsUnlockWorld(LocalPlayer, WorldId, DiffLevel) == true
        end)
        table.insert(Result, {
            Level = DiffLevel,
            DisplayName = DifficultyName,
            Unlocked = Unlocked,
            Info = DiffInfo
        })
    end

    for DiffLevel = 1, 5 do
        AddDifficulty(DiffLevel)
    end
    local Success, HellList = pcall(function()
        return WorldUtil:GetWorldStyleList(WorldId, "Hell")
    end)
    if Success then
        for _, HellInfo in ipairs(HellList or {}) do
            AddDifficulty(HellInfo.DiffLevel)
        end
    end
    table.sort(Result, function(A, B)
        return A.Level < B.Level
    end)
    CachedDifficultyCatalogs[WorldId] = Result
    return Result
end
```

- [ ] **Step 6: Implement validation and selection helpers**

Add after difficulty catalog:

```lua
local function FindDungeonEntry(WorldId, ForceRefresh)
    for _, Entry in ipairs(GetDungeonCatalog(ForceRefresh)) do
        if Entry.WorldId == WorldId then
            return Entry
        end
    end
end

local function FindHighestUnlockedDifficulty(WorldId, ForceRefresh)
    local Selected = nil
    for _, Entry in ipairs(GetDifficultyCatalog(WorldId, ForceRefresh)) do
        if Entry.Unlocked and (not Selected or Entry.Level > Selected.Level) then
            Selected = Entry
        end
    end
    return Selected
end

local function ValidateAutoStartSelection(PreferHighest)
    local Changed = false
    local Dungeon = FindDungeonEntry(AutoStartWorldId, true)
    if not Dungeon or not Dungeon.Unlocked then
        Dungeon = nil
        for _, Entry in ipairs(GetDungeonCatalog()) do
            if Entry.Unlocked then
                Dungeon = Entry
                break
            end
        end
        if not Dungeon then
            return false
        end
        AutoStartWorldId = Dungeon.WorldId
        Changed = true
    end

    local Difficulty = nil
    if not PreferHighest then
        for _, Entry in ipairs(GetDifficultyCatalog(AutoStartWorldId, true)) do
            if Entry.Level == AutoStartDifficulty and Entry.Unlocked then
                Difficulty = Entry
                break
            end
        end
    end
    Difficulty = Difficulty or FindHighestUnlockedDifficulty(AutoStartWorldId)
    if not Difficulty then
        return false
    end
    if AutoStartDifficulty ~= Difficulty.Level then
        AutoStartDifficulty = Difficulty.Level
        Changed = true
    end
    if Changed then
        SaveConfig()
    end
    return true
end

local function SelectAutoStartWorld(WorldId)
    local Entry = FindDungeonEntry(WorldId, true)
    if not Entry or not Entry.Unlocked then
        return false
    end
    AutoStartWorldId = Entry.WorldId
    if not ValidateAutoStartSelection(true) then
        return false
    end
    SaveConfig()
    return true
end

local function SelectAutoStartDifficulty(DiffLevel)
    for _, Entry in ipairs(GetDifficultyCatalog(AutoStartWorldId, true)) do
        if Entry.Level == DiffLevel and Entry.Unlocked then
            AutoStartDifficulty = Entry.Level
            SaveConfig()
            return true
        end
    end
    return false
end
```

- [ ] **Step 7: Validate immediately before existing remote calls**

In `TryAutoStartSoloDungeon()`, insert before logging and firing remotes:

```lua
if not ValidateAutoStartSelection(false) then
    print("[AutoStart] No unlocked dungeon target")
    return false
end
```

Keep existing remote order and party size unchanged:

```lua
GetWorldRemoteEvent():FireServer("SelectWorld", AutoStartWorldId, AutoStartDifficulty)
task.wait(0.35)
GetGameMatchRemoteEvent():FireServer("CreatRoom", AutoStartWorldId, AutoStartDifficulty, AutoStartMaxPlayers)
```

- [ ] **Step 8: Run checks and commit catalogs**

Run:

```powershell
powershell -ExecutionPolicy Bypass -File tools/checks/check-v6-menu.ps1
cmd /c "npx -y luaparse holygrail\script-v6-full-run-dg.lua > NUL && echo syntax-ok"
```

Expected: `v6-menu-ok` and `syntax-ok`.

Commit:

```powershell
git add holygrail/script-v6-full-run-dg.lua tools/checks/check-v6-menu.ps1
git commit -m "Add dungeon and difficulty catalogs"
```

### Task 3: Add Dungeon Utility Page

**Files:**
- Modify: `tools/checks/check-v6-menu.ps1`
- Modify: `holygrail/script-v6-full-run-dg.lua:3032`
- Modify: `holygrail/script-v6-full-run-dg.lua:3119`
- Modify: `holygrail/script-v6-full-run-dg.lua:3380`

**Interfaces:**
- Consumes: catalog and selection helpers from Task 2 plus existing `CreateButton`, `CreateText`, `AddCorner`, `AddStroke`, `SaveConfig`, and `Theme` helpers.
- Produces: `DungeonPage`, four Utility tabs, named dropdowns, locked rows, and read-only solo/trigger status.

- [ ] **Step 1: Add failing UI assertions**

Append to `tools/checks/check-v6-menu.ps1`:

```powershell
Assert-Contains 'DungeonTabButton\.Activated:Connect' 'Dungeon sub-tab must use Activated input'
Assert-Contains 'DungeonPage' 'Missing Dungeon utility page'
Assert-Contains 'DungeonDropdown' 'Missing dungeon dropdown'
Assert-Contains 'DifficultyDropdown' 'Missing difficulty dropdown'
Assert-Contains 'SOLO 1/1' 'Missing fixed solo party status'
Assert-Contains 'AFTER AUTO-SELL' 'Missing post-sell trigger status'
Assert-Contains 'AUTO SELL' 'Auto Sell tab label must contain a space'
Assert-Contains 'LOCKED' 'Locked dungeon and difficulty rows must be labeled'
```

- [ ] **Step 2: Run check and confirm failure**

Run:

```powershell
powershell -ExecutionPolicy Bypass -File tools/checks/check-v6-menu.ps1
```

Expected: FAIL with `Dungeon sub-tab must use Activated input`.

- [ ] **Step 3: Expand Utility navigation to four tabs**

Replace current three-button navigation with:

```lua
local DungeonTabButton = CreateButton(UtilityNavigation, "DUNGEON")
DungeonTabButton.Size = UDim2.new(0.25, -4, 1, 0)
local GroceryTabButton = CreateButton(UtilityNavigation, "GROCERY")
GroceryTabButton.Position = UDim2.new(0.25, 2, 0, 0)
GroceryTabButton.Size = UDim2.new(0.25, -4, 1, 0)
local SeasonTabButton = CreateButton(UtilityNavigation, "SEASON")
SeasonTabButton.Position = UDim2.new(0.5, 4, 0, 0)
SeasonTabButton.Size = UDim2.new(0.25, -4, 1, 0)
local AutoSellTabButton = CreateButton(UtilityNavigation, "AUTO SELL")
AutoSellTabButton.Position = UDim2.new(0.75, 6, 0, 0)
AutoSellTabButton.Size = UDim2.new(0.25, -6, 1, 0)
```

- [ ] **Step 4: Add reusable selector dropdown**

Inside `BuildV6Menu()`, before page creation, add:

```lua
local function CreateSelectorDropdown(Parent, Name, PositionY)
    local Button = CreateButton(Parent, "")
    Button.Name = Name .. "Dropdown"
    Button.Position = UDim2.fromOffset(0, PositionY)
    Button.Size = UDim2.new(1, 0, 0, 34)
    Button.TextXAlignment = Enum.TextXAlignment.Left

    local Options = Instance.new("ScrollingFrame")
    Options.Name = Name .. "Options"
    Options.Position = UDim2.fromOffset(0, PositionY + 38)
    Options.Size = UDim2.new(1, 0, 0, 0)
    Options.BackgroundColor3 = Theme.Surface
    Options.BorderSizePixel = 0
    Options.ScrollBarThickness = 3
    Options.ScrollBarImageColor3 = Theme.Accent
    Options.AutomaticCanvasSize = Enum.AutomaticSize.Y
    Options.CanvasSize = UDim2.fromOffset(0, 0)
    Options.Visible = false
    Options.ZIndex = 30
    Options.Parent = Parent
    AddCorner(Options, 6)
    AddStroke(Options, Theme.Accent)
    local Padding = Instance.new("UIPadding")
    Padding.PaddingTop = UDim.new(0, 5)
    Padding.PaddingBottom = UDim.new(0, 5)
    Padding.PaddingLeft = UDim.new(0, 5)
    Padding.PaddingRight = UDim.new(0, 5)
    Padding.Parent = Options
    local Layout = Instance.new("UIListLayout")
    Layout.Padding = UDim.new(0, 4)
    Layout.Parent = Options

    Button.Activated:Connect(function()
        Options.Visible = not Options.Visible
    end)
    return Button, Options
end
```

- [ ] **Step 5: Build Dungeon page and selector rows**

Create page before catalog pages:

```lua
local DungeonPage = Instance.new("Frame")
DungeonPage.Name = "DungeonPage"
DungeonPage.Size = UDim2.fromScale(1, 1)
DungeonPage.BackgroundTransparency = 1
DungeonPage.Parent = UtilityPages

local DungeonLabel = CreateText(DungeonPage, "Dungeon", 11, Theme.Muted)
DungeonLabel.Size = UDim2.new(1, 0, 0, 20)
local DungeonButton, DungeonOptions = CreateSelectorDropdown(DungeonPage, "Dungeon", 22)

local DifficultyLabel = CreateText(DungeonPage, "Difficulty", 11, Theme.Muted)
DifficultyLabel.Position = UDim2.fromOffset(0, 104)
DifficultyLabel.Size = UDim2.new(1, 0, 0, 20)
local DifficultyButton, DifficultyOptions = CreateSelectorDropdown(DungeonPage, "Difficulty", 126)

local PartyStatus = CreateText(DungeonPage, "Party Size   SOLO 1/1", 12)
PartyStatus.Position = UDim2.fromOffset(10, 210)
PartyStatus.Size = UDim2.new(1, -20, 0, 30)
local TriggerStatus = CreateText(DungeonPage, "Trigger      AFTER AUTO-SELL", 12)
TriggerStatus.Position = UDim2.fromOffset(10, 246)
TriggerStatus.Size = UDim2.new(1, -20, 0, 30)
```

Add option cleanup and rendering:

```lua
local function ClearSelectorOptions(Options)
    for _, Child in ipairs(Options:GetChildren()) do
        if Child:IsA("GuiButton") then
            Child:Destroy()
        end
    end
end

local function AddSelectorOption(Options, Text, Unlocked, OnSelect)
    local Option = CreateButton(Options, Unlocked and Text or (Text .. "  LOCKED"))
    Option.Size = UDim2.new(1, 0, 0, 28)
    Option.ZIndex = 31
    Option.TextColor3 = Unlocked and Theme.Text or Theme.Muted
    Option.Activated:Connect(function()
        if Unlocked then
            Options.Visible = false
            OnSelect()
        end
    end)
end
```

- [ ] **Step 6: Bind selectors to validated state**

Add page refresh functions:

```lua
local function FindSelectedDifficultyName()
    for _, Entry in ipairs(GetDifficultyCatalog(AutoStartWorldId)) do
        if Entry.Level == AutoStartDifficulty then
            return Entry.DisplayName
        end
    end
    return "Unavailable"
end

local function BuildDifficultyOptions(ForceRefresh)
    ClearSelectorOptions(DifficultyOptions)
    for _, Entry in ipairs(GetDifficultyCatalog(AutoStartWorldId, ForceRefresh)) do
        AddSelectorOption(DifficultyOptions, Entry.DisplayName, Entry.Unlocked, function()
            if SelectAutoStartDifficulty(Entry.Level) then
                DifficultyButton.Text = "  " .. Entry.DisplayName .. "  ▼"
            end
        end)
    end
    DifficultyOptions.Size = UDim2.new(1, 0, 0, math.min(180, #GetDifficultyCatalog(AutoStartWorldId) * 32 + 10))
    DifficultyButton.Text = "  " .. FindSelectedDifficultyName() .. "  ▼"
end

local function BuildDungeonPage(ForceRefresh)
    ValidateAutoStartSelection(false)
    ClearSelectorOptions(DungeonOptions)
    local SelectedName = AutoStartWorldId
    local Catalog = GetDungeonCatalog(ForceRefresh)
    for _, Entry in ipairs(Catalog) do
        if Entry.WorldId == AutoStartWorldId then
            SelectedName = Entry.DisplayName
        end
        AddSelectorOption(DungeonOptions, Entry.DisplayName, Entry.Unlocked, function()
            if SelectAutoStartWorld(Entry.WorldId) then
                BuildDungeonPage(true)
            end
        end)
    end
    DungeonOptions.Size = UDim2.new(1, 0, 0, math.min(180, #Catalog * 32 + 10))
    DungeonButton.Text = "  " .. SelectedName .. "  ▼"
    BuildDifficultyOptions(ForceRefresh)
end
```

Because `BuildDungeonPage()` calls itself only after a click callback runs, closure construction completes before recursion.

- [ ] **Step 7: Wire Utility page switching**

Replace `SetUtilityPage()` and tab connections with:

```lua
local function SetUtilityPage(Name)
    DungeonPage.Visible = Name == "Dungeon"
    GroceryPage.Page.Visible = Name == "Grocery"
    SeasonPage.Page.Visible = Name == "Season"
    AutoSellPage.Page.Visible = Name == "AutoSell"
    DungeonTabButton.BackgroundColor3 = Name == "Dungeon" and Theme.Accent or Theme.Surface
    GroceryTabButton.BackgroundColor3 = Name == "Grocery" and Theme.Accent or Theme.Surface
    SeasonTabButton.BackgroundColor3 = Name == "Season" and Theme.Accent or Theme.Surface
    AutoSellTabButton.BackgroundColor3 = Name == "AutoSell" and Theme.Accent or Theme.Surface
    if Name == "Dungeon" then
        pcall(BuildDungeonPage, true)
    end
end
DungeonTabButton.Activated:Connect(function() SetUtilityPage("Dungeon") end)
GroceryTabButton.Activated:Connect(function() SetUtilityPage("Grocery") end)
SeasonTabButton.Activated:Connect(function() SetUtilityPage("Season") end)
AutoSellTabButton.Activated:Connect(function() SetUtilityPage("AutoSell") end)
SetUtilityPage("Dungeon")
```

Place `SetUtilityPage()` after `BuildDungeonPage()` so function scope is valid. Keep existing Grocery, Season, and Auto Sell builders unchanged.

- [ ] **Step 8: Run checks and commit UI**

Run:

```powershell
powershell -ExecutionPolicy Bypass -File tools/checks/check-v6-menu.ps1
cmd /c "npx -y luaparse holygrail\script-v6-full-run-dg.lua > NUL && echo syntax-ok"
```

Expected: `v6-menu-ok` and `syntax-ok`.

Commit:

```powershell
git add holygrail/script-v6-full-run-dg.lua tools/checks/check-v6-menu.ps1
git commit -m "Add auto-start dungeon selectors"
```

### Task 4: Document And Verify Selector Flow

**Files:**
- Modify: `docs/features.md`
- Verify: `holygrail/script-v5-full-run-dg.lua`

**Interfaces:**
- Produces: concise user documentation and repository-wide validation evidence.

- [ ] **Step 1: Document selector behavior**

Add this section to `docs/features.md`:

```markdown
## Auto-Start Dungeon Selector

- Utility → Dungeon selects the dungeon and translated difficulty name used after successful lobby auto-sell.
- Locked dungeons and difficulties remain visible as `LOCKED` but cannot be selected.
- Selecting a dungeon automatically chooses its highest unlocked difficulty.
- Internal difficulty numbers stay hidden; saved config keeps the internal world ID and difficulty level.
- Normal victory replay remains `Play Again`; selector does not queue from lobby or add a manual start action.
- Auto-start remains solo `1/1` and requires Auto Farm plus Auto Replay.
```

- [ ] **Step 2: Run focused validation**

Run:

```powershell
powershell -ExecutionPolicy Bypass -File tools/checks/check-v6-menu.ps1
cmd /c "npx -y luaparse holygrail\script-v6-full-run-dg.lua > NUL && echo syntax-ok"
git diff --check
```

Expected: `v6-menu-ok`, `syntax-ok`, and no `git diff --check` output.

- [ ] **Step 3: Run legacy regression checks**

Run:

```powershell
Get-ChildItem tools/checks/*.ps1 | ForEach-Object {
    & powershell -ExecutionPolicy Bypass -File $_.FullName
    if ($LASTEXITCODE -ne 0) { throw "Check failed: $($_.Name)" }
}
```

Expected output includes:

```text
auto-skill-g-ok
chest-portal-lock-ok
lag-guards-ok
safe-lobby-ok
ui-config-sliders-ok
ui-layout-ok
v6-menu-ok
walkspeed-guard-ok
```

- [ ] **Step 4: Verify V5 unchanged**

Run:

```powershell
git diff HEAD --quiet -- holygrail/script-v5-full-run-dg.lua
if ($LASTEXITCODE -ne 0) { throw "script-v5 changed" }
```

Expected: no output.

- [ ] **Step 5: Commit documentation**

```powershell
git add docs/features.md
git commit -m "Document dungeon selector flow"
```

- [ ] **Step 6: Review final history and diff**

Run:

```powershell
git status --short
git log -4 --oneline
git diff HEAD~3 --stat
```

Expected: clean working tree; three feature commits plus prior design/plan history; changes limited to V6, V6 checker, and feature documentation.
