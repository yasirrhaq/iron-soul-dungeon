$ErrorActionPreference = 'Stop'

$scriptPath = Join-Path $PSScriptRoot '..\..\holygrail\script-v6-full-run-dg.lua'
$content = Get-Content -Raw -LiteralPath $scriptPath

function Assert-Contains($pattern, $message) {
    if ($content -notmatch $pattern) { throw $message }
}

Assert-Contains 'AutoSkillVisualFlow\s*=\s*AutoSkillVisualFlow\s+or\s+\{' 'Missing Auto Skill visual suppression state'
Assert-Contains '(?s)ProcFX.*ProcSFX.*ProcCameraShake.*ProcCameraShote.*ProcCameraFOV.*ProcFilmEffect.*ProcLighting' 'Missing visual-only hook list'
Assert-Contains 'hookfunction\(SkillEffect\[MethodName\]' 'Missing SkillEffect visual method hook'
Assert-Contains 'Self\s+and\s+Self\.IsSelf.*SuppressUntil' 'Visual suppression must target local player during Auto Skill window'
Assert-Contains '(?s)local\s+function\s+TriggerSkillButton\(key\).*?SuppressUntil\s*=\s*os\.clock\(\)\s*\+\s*8.*?firesignal' 'Auto Skill trigger must open suppression window before callbacks'

$methodList = [regex]::Match($content, 'AutoSkillVisualFlow\.Methods\s*=\s*\{(?<body>[\s\S]*?)\}')
if (-not $methodList.Success) { throw 'Unable to isolate visual method hook list' }
if ($methodList.Groups['body'].Value -match 'ProcBulletFire|ProcVelocity|DoSkillActionFX|SyncBulletFire') {
    throw 'Visual suppression must not hook gameplay or damage paths'
}

'v6-auto-skill-vfx-suppression-ok'
