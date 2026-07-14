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

Assert-Contains 'Iron Soul Script by Bugon' 'Missing Bugon header branding'
Assert-Contains '© 2026 Bugon\. All rights reserved\.' 'Missing Bugon footer branding'
Assert-Contains 'AutoBuyWantedItemIds' 'Missing Grocery selection config'
Assert-Contains 'AutoSeasonBuyWantedItemIds' 'Missing Season selection config'
Assert-Contains 'OreSellModes' 'Missing ore tri-state config'
Assert-Contains 'SellMaxRarity' 'Missing rarity config'
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
Assert-Contains 'FloatingIcon' 'Missing floating restore icon'
Assert-Contains 'FarmTab' 'Missing Farm tab'
Assert-Contains 'UtilityTab' 'Missing Utility tab'
Assert-Contains 'GroceryPage' 'Missing Grocery page'
Assert-Contains 'SeasonPage' 'Missing Season page'
Assert-Contains 'AutoSellPage' 'Missing AutoSell page'
Assert-Contains 'AUTO\s*->\s*SELL\s*->\s*KEEP' 'Missing documented tri-state cycle'
Assert-Contains '_G\.AutoSell\s+and\s+IsInLobby\s+and\s+IsInLobby\(\)' 'AutoSell must remain lobby-only'

$loaderContent = Get-Content -Raw -LiteralPath $loaderPath
if ($loaderContent -notmatch 'holygrail/script-v6-full-run-dg\.lua') { throw 'Cloud loader must target script v6' }
if ($loaderContent -match 'pastebin\.com') { throw 'Cloud loader must not depend on stale Pastebin script content' }

'v6-menu-ok'
