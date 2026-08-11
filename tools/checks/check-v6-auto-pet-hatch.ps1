$ErrorActionPreference = 'Stop'

$root = Resolve-Path (Join-Path $PSScriptRoot '..\..')
$scriptPath = Join-Path $root 'holygrail\script-v6-full-run-dg.lua'
$content = Get-Content -Raw -LiteralPath $scriptPath

function Assert-Contains($pattern, $message) {
    if ($content -notmatch $pattern) { throw $message }
}

& git -C $root diff HEAD --quiet -- 'holygrail/script-v5-full-run-dg.lua'
if ($LASTEXITCODE -ne 0) { throw 'script-v5 must remain unchanged' }

Assert-Contains 'AutoPetHatch\s*=\s*false' 'Auto Hatch must default off'
Assert-Contains 'Config\.AutoPetHatch\s*=\s*_G\.AutoPetHatch' 'Auto Hatch toggle must persist'
Assert-Contains '_G\.AutoPetHatch\s*=\s*Config\.AutoPetHatch' 'Auto Hatch runtime must load from config'
Assert-Contains 'ConfirmTimeout\s*=\s*3' 'Hatch confirmation timeout must be bounded'
Assert-Contains 'function\s+AutoPetHatch\.GetEggs\(' 'Missing owned egg priority builder'
Assert-Contains 'GetOwnedEggs\(LocalPlayer\)' 'Auto Hatch must read owned eggs'
Assert-Contains 'GetEggCfg\(EggData\.EggId\)' 'Auto Hatch must resolve egg configuration'
Assert-Contains 'Left\.Rarity\s*>\s*Right\.Rarity' 'Egg priority must prefer higher rarity'
Assert-Contains 'Left\.Sort\s*<\s*Right\.Sort' 'Egg priority must prefer lower config sort'
Assert-Contains 'for\s+SlotIndex\s*=\s*1\s*,\s*3\s+do' 'Auto Hatch must scan all three hatch slots'
Assert-Contains 'PetsHatchUtil:IsCompleted\(SlotData\)' 'Completed hatch detection missing'
Assert-Contains 'PetsHatchUtil:Claim\(LocalPlayer,\s*SlotIndex\)' 'Completed slots must be claimed'
Assert-Contains 'PetsHatchUtil:StartHatch\(LocalPlayer,\s*EmptySlot,\s*Egg\.UUID\)' 'Empty slots must start highest-priority egg'
Assert-Contains 'task\.delay\(AutoPetHatch\.ConfirmTimeout' 'Missing bounded hatch confirmation retry'
Assert-Contains 'RejoinWatchdog\.BlocksAutomation\(\)' 'Auto Hatch must pause during rejoin recovery'
Assert-Contains 'DataUtil:ListenFor\(LocalPlayer,\s*\{\s*"PetHatch",\s*"Egg"\s*\}' 'Egg inventory refresh must be event-driven'
Assert-Contains 'DataUtil:ListenFor\(LocalPlayer,\s*\{\s*"PetHatch",\s*"Slots"\s*\}' 'Hatch slot refresh must be event-driven'
Assert-Contains 'AutoPetHatchToggle' 'Missing Auto Hatch UI toggle'
Assert-Contains 'PetHatchStatusLabel' 'Missing Auto Hatch status UI'

$flow = [regex]::Match($content, '(?s)function\s+AutoPetHatch\.SetStatus\(.*?function\s+AutoPetHatch\.Connect\(\).*?\r?\nend')
if (-not $flow.Success) { throw 'Unable to isolate AutoPetHatch flow' }
if ($flow.Value -match 'Heartbeat|RenderStepped|while\s+true') { throw 'Auto Hatch must not poll continuously' }
if ($flow.Value -notmatch '(?s)PetsHatchUtil:Claim\(LocalPlayer,\s*SlotIndex\).*?return') {
    throw 'Claim reconciliation must stop after one action'
}
if ($flow.Value -notmatch '(?s)PetsHatchUtil:StartHatch\(LocalPlayer,\s*EmptySlot,\s*Egg\.UUID\).*?return') {
    throw 'Start reconciliation must stop after one action'
}

'v6-auto-pet-hatch-ok'
