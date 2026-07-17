$ErrorActionPreference = 'Stop'

$root = Resolve-Path (Join-Path $PSScriptRoot '..\..')
$v6Path = Join-Path $root 'holygrail\script-v6-full-run-dg.lua'
$content = Get-Content -Raw -LiteralPath $v6Path

function Assert-Contains($pattern, $message) {
    if ($content -notmatch $pattern) { throw $message }
}

& git -C $root diff HEAD --quiet -- 'holygrail/script-v5-full-run-dg.lua'
if ($LASTEXITCODE -ne 0) { throw 'script-v5 must remain unchanged' }

Assert-Contains 'AutoForgeTargetMode\s*=\s*false' 'Target mode must default off'
Assert-Contains 'AutoForgeAutoDeleteNonMatch\s*=\s*false' 'Auto-delete must default off'
Assert-Contains 'AutoForgeProfiles\s*=\s*\{\}' 'Profiles must default empty'
Assert-Contains 'Config\.AutoForgeTargetMode\s*=\s*AutoForge\.TargetMode' 'Target mode must persist'
Assert-Contains 'Config\.AutoForgeAutoDeleteNonMatch\s*=\s*AutoForge\.AutoDeleteNonMatch' 'Auto-delete must persist'
Assert-Contains 'Config\.AutoForgeProfiles\s*=\s*AutoForge\.Profiles' 'Profiles must persist'
Assert-Contains 'function\s+AutoForge\.NormalizeStatId\(' 'Missing stat normalizer'
Assert-Contains 'function\s+AutoForge\.NormalizeProfiles\(' 'Missing profile normalizer'
Assert-Contains 'function\s+AutoForge\.ValidateProfile\(' 'Missing profile validation'
Assert-Contains 'function\s+AutoForge\.BuildResultSummary\(' 'Missing result summary helper'
Assert-Contains 'function\s+AutoForge\.MatchProfile\(' 'Missing profile matcher'
Assert-Contains 'function\s+AutoForge\.FindMatchingProfile\(' 'Missing first-match helper'
Assert-Contains 'function\s+AutoForge\.CheckEquipmentStorage\(' 'Missing equipment bag guard'
Assert-Contains 'AtkBonus\s*=\s*true' 'Offensive group must include AtkBonus'
Assert-Contains 'CHDmgBonus\s*=\s*true' 'Offensive group must include CHDmgBonus'
Assert-Contains 'CHIRate\s*=\s*true' 'Offensive group must include CHIRate'
Assert-Contains 'SkillDmgBonus\s*=\s*true' 'Offensive group must include SkillDmgBonus'
Assert-Contains 'InvokeServer\("ForgeResult",\s*true\)' 'Forge result accept path missing'
Assert-Contains 'InvokeServer\("ForgeResult",\s*false\)' 'Forge result delete path missing'
Assert-Contains 'TARGET FOUND - ' 'Target match status missing'
Assert-Contains 'NON-MATCH - ACCEPTED' 'Non-match keep status missing'
Assert-Contains 'NON-MATCH - DELETED' 'Non-match delete status missing'
Assert-Contains 'STOPPED - EQUIPMENT BAG FULL' 'Equipment bag stop missing'
Assert-Contains 'TargetFoundData' 'Target-found modal state missing'
Assert-Contains 'pool only allows duplicate crit damage' 'Self-check must cover pool-only duplicate slots'
Assert-Contains 'pool at least allows non-pool remainder' 'Self-check must cover pool minimum with free remainder'
Assert-Contains 'require stat stacks with pool only' 'Self-check must cover require-stat plus pool-only stack'
Assert-Contains 'pool only rejects non-pool slot' 'Self-check must reject non-pool slot under pool-only rule'
Assert-Contains 'duplicate normalized stats' 'Self-check must cover normalized duplicate keys'
Assert-Contains 'first profile wins' 'Self-check must cover OR ordering'
Assert-Contains 'ForgeTargetsPage' 'Missing target profile page'
Assert-Contains 'TargetProfileEditor' 'Missing target profile editor'
Assert-Contains 'TargetFoundModal' 'Missing target-found modal'

'v6-target-stat-forge-ok'
