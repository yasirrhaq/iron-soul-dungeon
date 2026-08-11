$ErrorActionPreference = 'Stop'

$scriptPath = Join-Path $PSScriptRoot '..\..\holygrail\script-v6-full-run-dg.lua'
$content = Get-Content -Raw -LiteralPath $scriptPath

function Assert-Contains($pattern, $message) {
    if ($content -notmatch $pattern) { throw $message }
}

Assert-Contains 'AutoSkillNetworkMultiplier\s*=\s*3' 'Missing default 3x network multiplier'
Assert-Contains 'Config\.AutoSkillNetworkMultiplier\s*=\s*math\.floor\(ClampNumber\(Config\.AutoSkillNetworkMultiplier,\s*3,\s*8,\s*3\)\)' 'Network multiplier must load within 3x-8x'
Assert-Contains 'Config\.AutoSkillNetworkMultiplier\s*=\s*AutoSkillNetworkFlow\.Multiplier' 'Network multiplier must persist'
Assert-Contains 'AutoSkillNetworkFlow\.Multiplier\s*=\s*Config\.AutoSkillNetworkMultiplier' 'Network multiplier must initialize from config'
Assert-Contains 'AutoSkillNetworkFlow\.CaptureUntil\s*=\s*os\.clock\(\)\s*\+\s*8' 'Auto Skill callback must open network capture window'

$hook = [regex]::Match($content, '(?s)oldCallback\s*=\s*setBypass\(game,\s*"__namecall".*?\r?\n\s*end\)\r?\nelse')
if (-not $hook.Success) { throw 'Unable to isolate shared namecall hook' }
$hookBody = $hook.Value
if ($hookBody -notmatch 'method\s*==\s*"FireServer"') { throw 'Network burst must intercept FireServer only' }
if ($hookBody -notmatch 'self\s*==\s*AutoSkillNetworkFlow\.Remote') { throw 'Network burst must target PlayerActionRE only' }
if ($hookBody -notmatch 'args\[1\]\s*==\s*"BulletShoot"') { throw 'Network burst must replay BulletShoot only' }
if ($hookBody -notmatch 'not\s+AutoSkillNetworkFlow\.Replaying') { throw 'Network burst needs recursive replay guard' }
if ($hookBody -notmatch 'local\s+argumentCount\s*=\s*select\("#",\s*\.\.\.\)') { throw 'Network burst must preserve nil arguments' }
if ($hookBody -notmatch 'CapturedArgs\.n\s*=\s*argumentCount') { throw 'Captured payload must retain original argument count' }
if ($hookBody -notmatch 'for\s+ReplayIndex\s*=\s*2,\s*AutoSkillNetworkFlow\.Multiplier\s+do') { throw 'Network burst must replay multiplier minus original packet'
}
if ($hookBody -notmatch 'task\.wait\(AutoSkillNetworkFlow\.ReplayDelay\)') { throw 'Network burst needs bounded replay spacing' }
if ($hookBody -match 'args\[1\]\s*==\s*"SkillAction"') { throw 'Network burst must not duplicate SkillAction' }
if ($hookBody -notmatch 'return\s+oldCallback\(self,\s*unpack\(args,\s*1,\s*argumentCount\)\)') { throw 'Original remote call must preserve nil arguments' }

Assert-Contains 'SkillNetworkBurstCard' 'Missing Skill Network Burst slider card'
Assert-Contains 'SKILL NETWORK BURST' 'Missing Skill Network Burst slider title'
Assert-Contains '3\s*\+\s*Percent\s*\*\s*5' 'Slider must map to integer 3x-8x range'
Assert-Contains 'AutoSkillNetworkFlow\.Multiplier\)\s*\.\.\s*"x"' 'Slider must display selected multiplier'

'v6-auto-skill-network-multihit-ok'
