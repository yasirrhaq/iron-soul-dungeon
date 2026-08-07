$ErrorActionPreference = 'Stop'

$root = Resolve-Path (Join-Path $PSScriptRoot '..\..')
$v6Path = Join-Path $root 'holygrail\script-v6-full-run-dg.lua'
$content = Get-Content -Raw -LiteralPath $v6Path

function Assert-Contains($pattern, $message) {
    if ($content -notmatch $pattern) { throw $message }
}

function Assert-NotContains($pattern, $message) {
    if ($content -match $pattern) { throw $message }
}

& git -C $root diff HEAD --quiet -- 'holygrail/script-v5-full-run-dg.lua'
if ($LASTEXITCODE -ne 0) { throw 'script-v5 must remain unchanged' }

Assert-Contains 'FindFirstChild\("Gameplay"\)' 'ForgeRF lookup must inspect new Gameplay path'
Assert-Contains 'FindFirstChild\("EquipmentSystem"\)' 'ForgeRF lookup must inspect new EquipmentSystem path'
Assert-Contains 'FindFirstChild\("Features"\)' 'ForgeRF lookup must retain old Features fallback'
Assert-Contains 'SellList\[OreId\]\s*=\s*Count' 'Sell payload must map each ore ID to full owned count'
Assert-NotContains 'table\.insert\(SellList,\s*OreId\)' 'Sell payload must not remain an ore-ID array'
Assert-Contains 'next\(SellList\)\s*==\s*nil' 'Map payload emptiness must use next'
Assert-Contains 'for\s+OreId\s+in\s+pairs\(SellList\)\s+do' 'Sell confirmation must iterate map keys'
Assert-Contains 'InvokeServer\("Sell",\s*SellList\)' 'Updated map payload must reach ForgeRF Sell'

'v6-auto-sell-api-ok'
