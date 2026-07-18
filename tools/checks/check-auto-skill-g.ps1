$ErrorActionPreference = 'Stop'

$scriptPath = Join-Path $PSScriptRoot '..\..\holygrail\script-v6-full-run-dg.lua'
$content = Get-Content -Raw -LiteralPath $scriptPath

function Assert-Contains($pattern, $message) {
    if ($content -notmatch $pattern) { throw $message }
}

function Assert-NotContains($pattern, $message) {
    if ($content -match $pattern) { throw $message }
}

function Assert-TextNotContains($text, $pattern, $message) {
    if ($text -match $pattern) { throw $message }
}

Assert-Contains 'local\s+LastUsed\s*=\s*\{[^}]*G\s*=\s*0' 'Missing G in LastUsed'
Assert-Contains 'local\s+Cooldowns\s*=\s*\{[^}]*G\s*=\s*7' 'Missing G cooldown 7'
Assert-Contains 'G\s*=\s*"SkillAW"' 'Missing G SkillAW button mapping'
Assert-Contains 'local\s+SkillPriority\s*=\s*\{"G",\s*"R",\s*"E",\s*"Q"\}' 'G must stay first in auto-skill priority'
Assert-Contains 'local\s+function\s+IsSkillButtonEquipped\(button\)' 'Missing equipped skill button guard'
Assert-Contains 'return\s+button:IsA\("GuiObject"\)\s+and\s+button\.Visible\s*==\s*true' 'G equipped guard must use current SkillAW visibility'
Assert-Contains 'if\s+key\s*==\s*"G"\s+and\s+not\s+IsSkillButtonEquipped\(Button\)\s+then\s+return\s+false\s+end' 'Unequipped G must not block lower priority skills'
$guard = [regex]::Match($content, 'local\s+function\s+IsSkillButtonEquipped\(button\)(?<body>[\s\S]*?)\r?\nend')
if (-not $guard.Success) { throw 'Missing equipped skill button guard body' }
Assert-TextNotContains $guard.Groups['body'].Value 'GetDescendants\(\)' 'G equipped guard must not scan decorative background images'
Assert-Contains 'PressKey\(Key\)\s+LastUsed\[Key\]\s*=\s*os\.clock\(\)' 'Auto-skill loop must press priority key and update cooldown'

'auto-skill-g-ok'
