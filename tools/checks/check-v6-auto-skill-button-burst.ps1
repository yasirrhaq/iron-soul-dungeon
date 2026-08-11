$ErrorActionPreference = 'Stop'

$scriptPath = Join-Path $PSScriptRoot '..\..\holygrail\script-v6-full-run-dg.lua'
$content = Get-Content -Raw -LiteralPath $scriptPath

function Assert-Contains($pattern, $message) {
    if ($content -notmatch $pattern) { throw $message }
}

Assert-Contains 'local\s+SkillBurstDelay\s*=\s*0\.04' 'Missing bounded skill burst delay'
Assert-Contains 'local\s+function\s+TriggerSkillButton\(key\)' 'Missing skill button callback trigger'
Assert-Contains 'firesignal.*Button\.MouseButton1Down' 'Skill callback must invoke original button-down handler'
Assert-Contains 'firesignal.*Button\.MouseButton1Up' 'Skill callback must invoke original button-up handler'
Assert-Contains '(?s)local\s+function\s+TriggerSkillButton\(key\).*?PressKey\(key\).*?return\s+"keyboard"' 'Keyboard fallback must remain available'
Assert-Contains 'TriggerSkillButton\(Key\)\s+LastUsed\[Key\]\s*=\s*os\.clock\(\)' 'Auto Skill must use button callback trigger'

$triggerDefinition = $content.IndexOf('local function TriggerSkillButton(key)')
$autoSkillLoopMatch = [regex]::Match($content, 'task\.spawn\(function\(\)\s*while\s+true\s+do\s*task\.wait\(0\.1\)')
if ($triggerDefinition -lt 0 -or -not $autoSkillLoopMatch.Success -or $triggerDefinition -gt $autoSkillLoopMatch.Index) {
    throw 'Skill button callback must be in lexical scope before Auto Skill loop'
}

$loop = [regex]::Match($content, 'task\.spawn\(function\(\)\s*while\s+true\s+do\s*task\.wait\(0\.1\)(?<body>[\s\S]*?)\r?\n\s*end\r?\nend\)')
if (-not $loop.Success) { throw 'Unable to isolate Auto Skill loop' }
$body = $loop.Groups['body'].Value
if ($body -match 'TriggerSkillButton\(Key\)[\s\S]*?break') { throw 'Button burst must not stop after first ready skill' }
if ($body -notmatch 'task\.wait\(SkillBurstDelay\)') { throw 'Button burst must apply bounded spacing between skills' }
if ($body -notmatch 'if\s+not\s+TriggeredSkill\s+and\s+ShouldSwitchWeapon') { throw 'Weapon switch must wait until no skill was triggered' }

'v6-auto-skill-button-burst-ok'
