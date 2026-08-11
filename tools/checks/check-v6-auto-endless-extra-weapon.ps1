$ErrorActionPreference = 'Stop'

$root = Resolve-Path (Join-Path $PSScriptRoot '..\..')
$scriptPath = Join-Path $root 'holygrail\script-v6-full-run-dg.lua'
$content = Get-Content -Raw -LiteralPath $scriptPath

function Assert-Contains($pattern, $message) {
    if ($content -notmatch $pattern) { throw $message }
}

& git -C $root diff HEAD --quiet -- 'holygrail/script-v5-full-run-dg.lua'
if ($LASTEXITCODE -ne 0) { throw 'script-v5 must remain unchanged' }

Assert-Contains 'EndlessExtraWeaponUUID\s*=\s*""' 'Extra weapon must default to automatic selection'
Assert-Contains 'Config\.EndlessExtraWeaponUUID\s*=\s*AutoEndlessExtraWeapon\.SelectedUUID' 'Extra weapon preference must persist'
Assert-Contains 'AutoEndlessExtraWeapon\.SelectedUUID\s*=\s*Config\.EndlessExtraWeaponUUID' 'Runtime preference must load from config'
Assert-Contains 'function\s+AutoEndlessExtraWeapon\.GetOptions\(' 'Missing eligible weapon option builder'
Assert-Contains 'GetDmgOrHpByInfo' 'Weapon options must use real displayed damage'
Assert-Contains 'Fortify\s+and\s+[^\r\n]*Fortify\s*-\s*1' 'Weapon labels must use displayed fortify'
Assert-Contains 'IsTimeLimited' 'Time-limited weapons must be excluded'
Assert-Contains 'EquipSlots\.Weapon|EquipSlots\["Weapon"\]' 'Primary weapon must be excluded'
Assert-Contains 'EquipSlots\.Weapon2|EquipSlots\["Weapon2"\]' 'Secondary weapon must be excluded'
Assert-Contains 'function\s+AutoEndlessExtraWeapon\.ResolveSelection\(' 'Missing saved-selection fallback resolver'
Assert-Contains 'function\s+AutoEndlessExtraWeapon\.RequestEquip\(' 'Missing bounded extra weapon request helper'
Assert-Contains 'FireServer\("RequestSetExtraWeapon",\s*UUID\)' 'Missing direct extra weapon request'
Assert-Contains 'GetAttribute\("ExtraWeaponUUID"\)' 'Equip must confirm server attribute'
Assert-Contains 'EndlessExtraWeaponDropdown' 'Missing Tower extra weapon dropdown'
Assert-Contains 'Highest Damage \(Auto\)' 'Dropdown must expose automatic highest-damage selection'
Assert-Contains 'DataUtil:ListenFor\(LocalPlayer,\s*\{\s*"Equipment",\s*"Owned"\s*\}' 'Owned equipment refresh must be event-driven'
Assert-Contains 'DataUtil:ListenFor\(LocalPlayer,\s*\{\s*"Equipment",\s*"EquipSlots"\s*\}' 'Equip slot refresh must be event-driven'

$flow = [regex]::Match($content, '(?s)function\s+AutoEndlessExtraWeapon\.GetOptions\(\).*?function\s+AutoEndlessExtraWeapon\.Connect\(\).*?\r?\nend')
if (-not $flow.Success) { throw 'Unable to isolate AutoEndlessExtraWeapon flow' }
if ($flow.Value -match 'Heartbeat|RenderStepped|while\s+true') { throw 'Extra weapon refresh must not poll continuously' }

$startFlow = [regex]::Match($content, '(?s)function\s+AutoEndlessTower\.TryStartRun\(\)(?<body>.*?)\r?\nend\r?\n\r?\nlocal\s+function\s+FindAutoStartWorldButton')
if (-not $startFlow.Success) { throw 'Unable to isolate Endless start flow' }
$requestIndex = $startFlow.Groups['body'].Value.IndexOf('AutoEndlessExtraWeapon.RequestEquip(')
$confirmIndex = $startFlow.Groups['body'].Value.IndexOf('GetAttribute("ExtraWeaponUUID")')
$startIndex = $startFlow.Groups['body'].Value.LastIndexOf('ClickGuiButton(StartButton)')
if ($requestIndex -lt 0 -or $confirmIndex -lt 0 -or $startIndex -lt 0 -or $requestIndex -ge $confirmIndex -or $confirmIndex -ge $startIndex) {
    throw 'Endless flow must request, confirm, then click Start'
}

'v6-auto-endless-extra-weapon-ok'
