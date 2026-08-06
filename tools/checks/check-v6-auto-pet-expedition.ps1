$ErrorActionPreference = 'Stop'

$root = Resolve-Path (Join-Path $PSScriptRoot '..\..')
$v6Path = Join-Path $root 'holygrail\script-v6-full-run-dg.lua'
$content = Get-Content -Raw -LiteralPath $v6Path

function Assert-Contains($pattern, $message) {
    if ($content -notmatch $pattern) { throw $message }
}

& git -C $root diff HEAD --quiet -- 'holygrail/script-v5-full-run-dg.lua'
if ($LASTEXITCODE -ne 0) { throw 'script-v5 must remain unchanged' }

Assert-Contains 'AutoPetExpedition\s*=\s*false' 'Auto Expedition must default off'
Assert-Contains 'AutoClaimPetExpedition\s*=\s*false' 'Auto Claim Expedition must default off'
Assert-Contains 'PetExpeditionSlotOrder\s*=\s*\{\s*2\s*,\s*3\s*,\s*4\s*\}' 'Default slot order must be 2,3,4'
Assert-Contains 'function\s+AutoPetExpedition\.NormalizeSlotOrder\(' 'Missing slot-order normalization'
Assert-Contains 'Config\.AutoPetExpedition\s*=\s*_G\.AutoPetExpedition' 'Auto Expedition toggle must persist'
Assert-Contains 'Config\.AutoClaimPetExpedition\s*=\s*_G\.AutoClaimPetExpedition' 'Auto Claim toggle must persist'
Assert-Contains 'Config\.PetExpeditionSlotOrder\s*=\s*AutoPetExpedition\.SlotOrder' 'Slot order must persist'
Assert-Contains 'PetsExpeditionUtil:_GetEffectiveDailyCount\(LocalPlayer\)' 'Remaining chances must use effective daily count'
Assert-Contains 'PetsExpeditionUtil\.Config\.DailyLimit' 'Remaining chances must use game daily limit'
Assert-Contains '(?s)PetsExpeditionUtil\.CanDispatch.*?LocalPlayer,\s*SlotIndex,\s*Pet\.UID' 'Pet eligibility must use CanDispatch'
Assert-Contains 'PetsAffinityUtil:GetAffinityLevel\(' 'Pet priority must use affinity level'
Assert-Contains 'PetsUtil:GetPetInfo\(' 'Pet priority tie-break must use rarity and sort definition'
Assert-Contains 'for\s+SlotIndex\s*=\s*1\s*,\s*AutoPetExpedition\.SlotCount\s+do' 'Claim must scan every game slot'
Assert-Contains 'RemoteEvent:FireServer\("Claim",\s*SlotIndex\)' 'Claim payload must be action then slot'
Assert-Contains 'RemoteEvent:FireServer\("Dispatch",\s*SlotIndex,\s*PetUID\)' 'Dispatch payload must be action, slot, pet UID'
Assert-Contains 'ConfirmTimeout\s*=\s*5' 'Confirmation timeout must be bounded'
Assert-Contains 'function\s+AutoPetExpedition\.WaitForSlot\(' 'Missing replicated slot confirmation wait'
Assert-Contains 'RejoinWatchdog\.BlocksAutomation\(\)' 'Expedition runner must pause during rejoin recovery'
Assert-Contains 'AutoPetExpeditionToggle' 'Missing Auto Expedition UI toggle'
Assert-Contains 'AutoClaimPetExpeditionToggle' 'Missing Auto Claim UI toggle'
Assert-Contains 'PetExpeditionSlotOrderInput' 'Missing Slot Order UI input'
Assert-Contains 'PetExpeditionChanceLabel' 'Missing remaining-chances UI label'
Assert-Contains 'PetExpeditionStatusLabel' 'Missing expedition status UI label'
Assert-Contains 'PetExpeditionSlotOrderInput\.FocusLost:Connect' 'Slot Order input must persist on focus loss'
Assert-Contains '(?s)if\s+Name\s*==\s*"Pets"\s+then\s*RefreshPetExpeditionUI\(\)' 'Opening PETS page must refresh live chances and status'

'v6-auto-pet-expedition-ok'
