$ErrorActionPreference = 'Stop'

$root = Resolve-Path (Join-Path $PSScriptRoot '..\..')
$v5Path = Join-Path $root 'holygrail\script-v5-full-run-dg.lua'
$v6Path = Join-Path $root 'holygrail\script-v6-full-run-dg.lua'
$loaderPath = Join-Path $root 'auto-load.lua'

if (-not (Test-Path -LiteralPath $v6Path)) { throw 'Missing script-v6-full-run-dg.lua' }
& git -C $root diff HEAD --quiet -- 'holygrail/script-v5-full-run-dg.lua'
if ($LASTEXITCODE -ne 0) { throw 'script-v5 must remain unchanged' }

$content = Get-Content -Raw -LiteralPath $v6Path

function Assert-Contains($pattern, $message) {
    if ($content -notmatch $pattern) { throw $message }
}

function Assert-NotContains($pattern, $message) {
    if ($content -match $pattern) { throw $message }
}

function Assert-LuauCompiles {
    $compiler = Get-Command luau-compile -ErrorAction SilentlyContinue
    if ($compiler) {
        $compileOutput = & $compiler.Source $v6Path 2>&1
        if ($LASTEXITCODE -ne 0) { throw "Luau compile failed:`n$($compileOutput -join "`n")" }
        return
    }

    if (-not (Get-Command npm -ErrorAction SilentlyContinue) -or -not (Get-Command node -ErrorAction SilentlyContinue)) {
        throw 'Luau compile requires luau-compile or npm+node for ephemeral luau-web@1.4.0 fallback'
    }

    $temp = Join-Path ([System.IO.Path]::GetTempPath()) ("check-v6-luau-" + [guid]::NewGuid())
    New-Item -ItemType Directory -Path $temp | Out-Null
    try {
        # Exact fallback package command: npm pack luau-web@1.4.0 --silent --pack-destination <temp>
        $packOutput = & npm pack luau-web@1.4.0 --silent --pack-destination $temp 2>&1
        if ($LASTEXITCODE -ne 0) { throw "Unable to fetch ephemeral Luau compiler:`n$($packOutput -join "`n")" }
        $archive = Get-ChildItem -LiteralPath $temp -Filter '*.tgz' | Select-Object -First 1
        if (-not $archive) { throw 'Ephemeral luau-web package archive missing' }
        & tar -xf $archive.FullName -C $temp
        if ($LASTEXITCODE -ne 0) { throw 'Unable to extract ephemeral luau-web package' }

        $moduleUri = ([uri](Join-Path $temp 'package\src\index.js')).AbsoluteUri | ConvertTo-Json -Compress
        $sourcePath = $v6Path.ToString() | ConvertTo-Json -Compress
        $runner = Join-Path $temp 'compile.mjs'
        @"
import fs from 'node:fs';
const { LuauState } = await import($moduleUri);
const state = await LuauState.createAsync();
const result = state.loadstring(fs.readFileSync($sourcePath, 'utf8'), 'script-v6-full-run-dg.lua');
if (typeof result === 'string') {
    console.error(result);
    state.destroy();
    process.exit(1);
}
state.destroy();
console.log('luau-compile-ok');
"@ | Set-Content -LiteralPath $runner -Encoding utf8

        $compileOutput = & node $runner 2>&1
        if ($LASTEXITCODE -ne 0) {
            $tail = $compileOutput | Select-Object -Last 12
            throw "Luau compile failed via ephemeral luau-web@1.4.0:`n$($tail -join "`n")"
        }
    } finally {
        Remove-Item -Recurse -Force -LiteralPath $temp -ErrorAction SilentlyContinue
    }
}

Assert-Contains 'Iron Soul Script by Bugon' 'Missing Bugon header branding'
Assert-Contains '© 2026 Bugon\. All rights reserved\.' 'Missing Bugon footer branding'
Assert-Contains 'AutoBuyWantedItemIds' 'Missing Grocery selection config'
Assert-Contains 'AutoSeasonBuyWantedItemIds' 'Missing Season selection config'
Assert-Contains 'OreSellModes' 'Missing ore tri-state config'
Assert-Contains 'SellMaxRarity' 'Missing rarity config'
Assert-Contains 'AutoStartWorldId\s*=\s*"World3"' 'Missing default auto-start world config'
Assert-Contains 'AutoStartDifficulty\s*=\s*10' 'Missing default auto-start difficulty config'
Assert-Contains 'Config\.AutoStartWorldId\s*=\s*AutoStartWorldId' 'Auto-start world must persist'
Assert-Contains 'Config\.AutoStartDifficulty\s*=\s*AutoStartDifficulty' 'Auto-start difficulty must persist'
Assert-Contains 'LoadConfig\(\)\s*AutoStartWorldId\s*=\s*Config\.AutoStartWorldId\s*AutoStartDifficulty\s*=\s*Config\.AutoStartDifficulty' 'Runtime auto-start pair must be assigned after config load'
Assert-Contains 'local\s+DungeonCatalog\s*=\s*\(function\(\)' 'Dungeon catalog state must use one top-level namespace'
Assert-NotContains '(?m)^local\s+function\s+(?:GetWorldConfig|TranslateConfigName|GetDungeonCatalog|GetDifficultyCatalog|FindDungeonEntry|FindHighestUnlockedDifficulty|ValidateAutoStartSelection|SelectAutoStartWorld|SelectAutoStartDifficulty)\b' 'Dungeon catalog helpers must not consume top-level registers'
Assert-Contains 'function\s+Catalog\.GetDungeonCatalog\(' 'Missing dungeon catalog helper'
Assert-Contains 'Configs.*World.*ResWorld' 'Dungeon catalog must use ResWorld'
Assert-Contains 'WorldUtil:IsUnlockWorld' 'Dungeon catalog must mark locked entries'
Assert-Contains 'function\s+Catalog\.GetDifficultyCatalog\(' 'Missing difficulty catalog helper'
Assert-Contains 'WorldUtil:GetWorldDiffInfo' 'Difficulty catalog must use WorldUtil data'
Assert-Contains 'WorldUtil:GetWorldStyleList' 'Difficulty catalog must include Hell mappings'
Assert-Contains 'RarityTiers:GetDifficultyName' 'Difficulty labels must use game names'
Assert-Contains 'for\s+DiffLevel\s*=\s*1\s*,\s*10\s+do' 'Difficulty catalog must probe standard levels 1 through 10'
Assert-NotContains 'for\s+DiffLevel\s*=\s*1\s*,\s*5\s+do' 'Difficulty catalog must not stop at level 5'
Assert-Contains 'DifficultyName\s*=\s*"\["\s*\.\.\s*tostring\(DiffLevel\)\s*\.\.\s*"\]\s"\s*\.\.\s*DifficultyName' 'Difficulty labels must include their numeric index'
Assert-NotContains 'DifficultyName\s*=\s*tostring\([^)]*(?:DiffInfo\.Difficulty|DiffLevel)' 'Difficulty labels must not fall back to internal numbers'
Assert-Contains 'type\(DifficultyName\)\s*~=\s*"string"' 'Difficulty labels must reject non-string names'
Assert-Contains 'tonumber\(DifficultyName\)' 'Difficulty labels must reject numeric names'
Assert-Contains 'function\s+Catalog\.ValidateAutoStartSelection\(' 'Missing auto-start validation helper'
Assert-Contains 'function\s+Catalog\.SelectAutoStartWorld\(' 'Missing dungeon selection helper'
Assert-Contains 'function\s+Catalog\.SelectAutoStartDifficulty\(' 'Missing difficulty selection helper'
Assert-Contains '(?s)function\s+Catalog\.ValidateAutoStartSelection\(PreferHighest\).*?local\s+CandidateWorldId\s*=.*?local\s+CandidateDifficulty\s*=.*?if\s+not\s+CandidateDifficulty\s+then\s*return\s+false\s*end.*?AutoStartWorldId\s*,\s*AutoStartDifficulty\s*=\s*CandidateWorldId\s*,\s*CandidateDifficulty\.Level' 'Validation must commit world+difficulty only after both candidates are valid'
Assert-Contains '(?s)function\s+Catalog\.SelectAutoStartWorld\(WorldId\).*?local\s+CandidateDifficulty\s*=.*?if\s+not\s+CandidateDifficulty\s+then\s*return\s+false\s*end.*?AutoStartWorldId\s*,\s*AutoStartDifficulty\s*=\s*Entry\.WorldId\s*,\s*CandidateDifficulty\.Level' 'Dungeon selection must atomically commit an unlocked pair'
Assert-Contains 'GetWorldRemoteEvent\(\):FireServer\("SelectWorld", AutoStartWorldId, AutoStartDifficulty\)\s*task\.wait\(0\.35\)\s*GetGameMatchRemoteEvent\(\):FireServer\("CreatRoom", AutoStartWorldId, AutoStartDifficulty, AutoStartMaxPlayers\)' 'Auto-start remotes or order changed'
Assert-Contains 'local\s+function\s+GetGoldShopCatalog\(' 'Missing Gold catalog helper'
Assert-Contains 'getupvalues' 'Gold catalog must attempt full runtime pool'
Assert-Contains 'local\s+function\s+GetSeasonShopCatalog\(' 'Missing Season catalog helper'
Assert-Contains 'ResSeasonShop' 'Season catalog must use full config'
Assert-Contains 'local\s+function\s+GetOreCatalog\(' 'Missing ore catalog helper'
Assert-Contains 'local\s+function\s+ShouldSellOre\(' 'Missing ore sell rule helper'
Assert-Contains 'Mode\s*==\s*"KEEP"' 'Missing KEEP rule'
Assert-Contains 'Mode\s*==\s*"SELL"' 'Missing SELL rule'
Assert-Contains 'CreateToggleRow' 'Missing compact toggle rows'
Assert-Contains 'local\s+function\s+BuildV6Menu\(' 'V6 menu must use separate function scope'
Assert-Contains 'MakeDraggable' 'Missing mouse/touch drag helper'
Assert-Contains 'local\s+function\s+GetItemDisplayName\(' 'Missing translated item display-name helper'
Assert-Contains 'Row\.Activated:Connect' 'Toggle/list rows must use cross-platform Activated input'
Assert-Contains 'LastToggleAt' 'Toggle rows need duplicate-input debounce'
Assert-Contains 'DungeonTabButton\.Activated:Connect' 'Dungeon sub-tab must use Activated input'
Assert-Contains 'GroceryTabButton\.Activated:Connect' 'Grocery sub-tab must use Activated input'
Assert-Contains 'SeasonTabButton\.Activated:Connect' 'Season sub-tab must use Activated input'
Assert-Contains 'AutoSellTabButton\.Activated:Connect' 'AutoSell sub-tab must use Activated input'
Assert-Contains 'FloatingIcon' 'Missing floating restore icon'
Assert-Contains 'FarmTab' 'Missing Farm tab'
Assert-Contains 'UtilityTab' 'Missing Utility tab'
Assert-Contains 'DungeonPage' 'Missing Dungeon utility page'
Assert-Contains 'DungeonDropdown' 'Missing dungeon dropdown'
Assert-Contains 'DifficultyDropdown' 'Missing difficulty dropdown'
Assert-Contains '(?s)DungeonDropdown\.Activated:Connect\(function\(\)\s*DifficultyOptions\.Visible\s*=\s*false\s*DungeonOptions\.Visible\s*=\s*not\s+DungeonOptions\.Visible\s*end\)' 'Opening dungeon dropdown must close difficulty dropdown'
Assert-Contains '(?s)DifficultyDropdown\.Activated:Connect\(function\(\)\s*DungeonOptions\.Visible\s*=\s*false\s*DifficultyOptions\.Visible\s*=\s*not\s+DifficultyOptions\.Visible\s*end\)' 'Opening difficulty dropdown must close dungeon dropdown'
Assert-Contains '(?s)local\s+function\s+BuildDungeonPage\(ForceRefresh\)\s*DungeonOptions\.Visible\s*=\s*false\s*DifficultyOptions\.Visible\s*=\s*false' 'Dungeon page rebuild must close both dropdowns'
Assert-Contains '(?s)local\s+function\s+SetUtilityPage\(Name\)\s*DungeonOptions\.Visible\s*=\s*false\s*DifficultyOptions\.Visible\s*=\s*false' 'Utility tab switch must close both dropdowns'
Assert-Contains 'SOLO 1/1' 'Missing fixed solo party status'
Assert-Contains 'AFTER AUTO-SELL' 'Missing post-sell trigger status'
Assert-Contains 'AUTO SELL' 'Auto Sell tab label must contain a space'
Assert-Contains 'LOCKED' 'Locked dungeon and difficulty rows must be labeled'
Assert-Contains 'GroceryPage' 'Missing Grocery page'
Assert-Contains 'SeasonPage' 'Missing Season page'
Assert-Contains 'AutoSellPage' 'Missing AutoSell page'
Assert-Contains 'AUTO\s*->\s*SELL\s*->\s*KEEP' 'Missing documented tri-state cycle'
Assert-Contains '_G\.AutoSell\s+and\s+IsInLobby\s+and\s+IsInLobby\(\)' 'AutoSell must remain lobby-only'
Assert-Contains 'local\s+OreStats\s*=\s*\{\s*Current\s*=\s*0\s*,\s*Max\s*=\s*0\s*\}' 'Missing ore stats cache'
Assert-Contains 'ORE:\s*"\s*\.\.\s*tostring\(OreStats\.Current\)\s*\.\.\s*"/"\s*\.\.\s*tostring\(OreStats\.Max\)' 'Stats label must show ORE current/max'
Assert-Contains 'Current\s*~=\s*OreStats\.Current\s+or\s+Max\s*~=\s*OreStats\.Max' 'Ore stats must refresh only when usage changes'
Assert-Contains 'task\.wait\(1\.0\)' 'Ore stats polling interval must be one second'
Assert-Contains 'StatsLabel\.Size\s*=\s*UDim2\.new\(1,\s*0,\s*0,\s*78\)' 'V6 stats label must fit three lines'

$loaderContent = Get-Content -Raw -LiteralPath $loaderPath
if ($loaderContent -notmatch 'holygrail/script-v6-full-run-dg\.lua') { throw 'Cloud loader must target script v6' }
if ($loaderContent -match 'pastebin\.com') { throw 'Cloud loader must not depend on stale Pastebin script content' }

Assert-LuauCompiles

'v6-menu-ok'
