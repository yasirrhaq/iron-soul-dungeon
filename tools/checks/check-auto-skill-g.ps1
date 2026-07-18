$ErrorActionPreference = 'Stop'

$scriptPaths = @(
    (Join-Path $PSScriptRoot '..\..\holygrail\script-v6-full-run-dg.lua'),
    (Join-Path $PSScriptRoot '..\..\scripts\scratch\current-working-script.lua')
)

function Assert-Contains($pattern, $message) {
    if ($content -notmatch $pattern) { throw $message }
}

function Assert-TextNotContains($text, $pattern, $message) {
    if ($text -match $pattern) { throw $message }
}

foreach ($scriptPath in $scriptPaths) {
    $content = Get-Content -Raw -LiteralPath $scriptPath
    $label = Split-Path -Leaf $scriptPath

    Assert-Contains 'local\s+LastUsed\s*=\s*\{[^}]*G\s*=\s*0' "$label missing G in LastUsed"
    Assert-Contains 'local\s+Cooldowns\s*=\s*\{[^}]*G\s*=\s*7' "$label missing G cooldown 7"
    Assert-Contains 'G\s*=\s*"SkillAW"' "$label missing G SkillAW button mapping"
    Assert-Contains 'local\s+SkillPriority\s*=\s*\{"G",\s*"R",\s*"E",\s*"Q"\}' "$label G must stay first in auto-skill priority"
    Assert-Contains 'local\s+function\s+IsSkillButtonEquipped\(button\)' "$label missing equipped skill button guard"
    Assert-Contains 'return\s+button:IsA\("GuiObject"\)\s+and\s+button\.Visible\s*==\s*true' "$label G equipped guard must use current SkillAW visibility"
    Assert-Contains 'if\s+key\s*==\s*"G"\s+and\s+not\s+IsSkillButtonEquipped\(Button\)\s+then\s+return\s+false\s+end' "$label unequipped G must not block lower priority skills"

    $guard = [regex]::Match($content, 'local\s+function\s+IsSkillButtonEquipped\(button\)(?<body>[\s\S]*?)\r?\nend')
    if (-not $guard.Success) { throw "$label missing equipped skill button guard body" }
    Assert-TextNotContains $guard.Groups['body'].Value 'GetDescendants\(\)' "$label G equipped guard must not scan decorative background images"
    Assert-Contains 'PressKey\(Key\)\s+LastUsed\[Key\]\s*=\s*os\.clock\(\)' "$label auto-skill loop must press priority key and update cooldown"
}

'auto-skill-g-ok'
