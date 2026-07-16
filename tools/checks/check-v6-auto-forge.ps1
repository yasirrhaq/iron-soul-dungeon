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

Assert-Contains 'AutoForge\s*=\s*false' 'Auto Forge must default off'
Assert-Contains 'AutoForgeRecipeId\s*=\s*"WeaponSword"' 'Missing default recipe'
Assert-Contains 'WeaponSword\s*=\s*\{[^}]*Category\s*=\s*"Weapon"[^}]*OreCount\s*=\s*3' 'Missing Sword recipe'
Assert-Contains 'WeaponFistCommon\s*=\s*\{[^}]*OreCount\s*=\s*18[^}]*RelicId\s*=\s*"FistRelic_1"' 'Missing Common Fist recipe'
Assert-Contains 'WeaponFistLuxury\s*=\s*\{[^}]*OreCount\s*=\s*18[^}]*RelicId\s*=\s*"FistRelic_2"' 'Missing Luxury Fist recipe'
Assert-Contains 'ArmorHeavyArmor\s*=\s*\{[^}]*Category\s*=\s*"Armor"[^}]*OreCount\s*=\s*22' 'Missing Heavy Armor recipe'
Assert-Contains 'function\s+AutoForge\.CalculateLimit\(' 'Missing batch limit helper'
Assert-Contains 'math\.floor\(OwnedCount\s*/\s*PerCraft\)' 'Ore limit must use owned/per-craft floor'
Assert-Contains 'KeyString\.EquipmentUtil\.Crystals' 'Relics must use Crystals inventory path'
Assert-Contains 'ForgeUtil:IsRelicUsable' 'Relic usability must be validated'
Assert-Contains 'InvokeServer\("DropOres",\s*Composition,\s*Recipe\.Category,\s*Recipe\.RelicId\)' 'Missing direct DropOres payload'
Assert-Contains 'ForgeData\.QTE\.Times' 'QTE must resume completed steps'
Assert-Contains 'ForgeUtil:GetQTE\(LocalPlayer\)' 'QTE must fetch server UUID'
Assert-Contains 'Rating\s*=\s*15' 'QTE must submit perfect rating'
Assert-Contains 'ForgeUtil:ForgeFinish\(LocalPlayer\)' 'Missing forge finish'
Assert-Contains 'InvokeServer\("ForgeResult",\s*true\)' 'Missing result acknowledgement'
Assert-Contains 'AutoForge\.State\.Running' 'Missing single-runner lock'
Assert-Contains 'IsInLobby\(\)' 'Auto Forge must be lobby-only'
Assert-Contains 'if\s+AutoSellBusy\s+or\s+SellPending\s+then' 'Auto Forge must avoid active sell call'
Assert-Contains 'AutoForgePage' 'Missing Auto Forge page'
Assert-Contains 'AutoForge\.StartBatch' 'Missing Start action'
Assert-NotContains 'script-v5-full-run-dg' 'Auto Forge source must not reference V5'

'v6-auto-forge-ok'
