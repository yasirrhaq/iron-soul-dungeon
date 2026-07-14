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
Assert-Contains 'local\s+AutoStartWorldId\s*=\s*Config\.AutoStartWorldId' 'Runtime world must load from config'
Assert-Contains 'local\s+AutoStartDifficulty\s*=\s*Config\.AutoStartDifficulty' 'Runtime difficulty must load from config'
Assert-Contains 'local\s+function\s+GetDungeonCatalog\(' 'Missing dungeon catalog helper'
Assert-Contains 'Configs.*World.*ResWorld' 'Dungeon catalog must use ResWorld'
Assert-Contains 'WorldUtil:IsUnlockWorld' 'Dungeon catalog must mark locked entries'
Assert-Contains 'local\s+function\s+GetDifficultyCatalog\(' 'Missing difficulty catalog helper'
Assert-Contains 'WorldUtil:GetWorldDiffInfo' 'Difficulty catalog must use WorldUtil data'
Assert-Contains 'WorldUtil:GetWorldStyleList' 'Difficulty catalog must include Hell mappings'
Assert-Contains 'RarityTiers:GetDifficultyName' 'Difficulty labels must use game names'
Assert-NotContains 'DifficultyName\s*=\s*tostring\([^)]*(?:DiffInfo\.Difficulty|DiffLevel)' 'Difficulty labels must not fall back to internal numbers'
Assert-Contains 'type\(DifficultyName\)\s*~=\s*"string"' 'Difficulty labels must reject non-string names'
Assert-Contains 'tonumber\(DifficultyName\)' 'Difficulty labels must reject numeric names'
Assert-Contains 'local\s+function\s+ValidateAutoStartSelection\(' 'Missing auto-start validation helper'
Assert-Contains 'local\s+function\s+SelectAutoStartWorld\(' 'Missing dungeon selection helper'
Assert-Contains 'local\s+function\s+SelectAutoStartDifficulty\(' 'Missing difficulty selection helper'
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
Assert-Contains 'SOLO 1/1' 'Missing fixed solo party status'
Assert-Contains 'AFTER AUTO-SELL' 'Missing post-sell trigger status'
Assert-Contains 'AUTO SELL' 'Auto Sell tab label must contain a space'
Assert-Contains 'LOCKED' 'Locked dungeon and difficulty rows must be labeled'
Assert-Contains 'GroceryPage' 'Missing Grocery page'
Assert-Contains 'SeasonPage' 'Missing Season page'
Assert-Contains 'AutoSellPage' 'Missing AutoSell page'
Assert-Contains 'AUTO\s*->\s*SELL\s*->\s*KEEP' 'Missing documented tri-state cycle'
Assert-Contains '_G\.AutoSell\s+and\s+IsInLobby\s+and\s+IsInLobby\(\)' 'AutoSell must remain lobby-only'

$loaderContent = Get-Content -Raw -LiteralPath $loaderPath
if ($loaderContent -notmatch 'holygrail/script-v6-full-run-dg\.lua') { throw 'Cloud loader must target script v6' }
if ($loaderContent -match 'pastebin\.com') { throw 'Cloud loader must not depend on stale Pastebin script content' }

'v6-menu-ok'
