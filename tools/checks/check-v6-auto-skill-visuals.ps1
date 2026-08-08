$ErrorActionPreference = 'Stop'

$scriptPath = Join-Path $PSScriptRoot '..\..\holygrail\script-v6-full-run-dg.lua'
$content = Get-Content -Raw -LiteralPath $scriptPath

function Assert-Contains($pattern, $message) {
    if ($content -notmatch $pattern) { throw $message }
}

Assert-Contains 'DisableAutoSkillAnimation\s*=\s*false' 'Missing Disable Auto Skill Animation default'
Assert-Contains 'Config\.DisableAutoSkillAnimation\s*=\s*Config\.DisableAutoSkillAnimation\s*==\s*true' 'Missing Disable Auto Skill Animation normalization'
Assert-Contains 'Config\.DisableAutoSkillAnimation\s*=\s*_G\.DisableAutoSkillAnimation' 'Disable Auto Skill Animation must persist'
Assert-Contains '_G\.DisableAutoSkillAnimation\s*=\s*Config\.DisableAutoSkillAnimation' 'Missing Disable Auto Skill Animation runtime assignment'
Assert-Contains 'CreateToggleRow\(FarmTab,\s*"Disable Auto Skill Animation"' 'Missing Farm visual suppression toggle'
Assert-Contains '(?m)^AutoSkillVisualSuppression\s*=\s*\{' 'Missing auto-skill visual suppression state'
Assert-Contains 'function\s+AutoSkillVisualSuppression\.Begin\(Key\)' 'Missing scoped auto-skill suppression start'
Assert-Contains 'function\s+AutoSkillVisualSuppression\.Finish\(SessionId' 'Missing suppression restoration'
Assert-Contains 'function\s+AutoSkillVisualSuppression\.SetEnabled\(Value\)' 'Missing immediate toggle handler'
Assert-Contains 'Track:AdjustWeight\(0,\s*0\)' 'Skill animation must stay running at zero visual weight'
Assert-Contains 'ParticleEmitter' 'Missing ParticleEmitter suppression'
Assert-Contains 'Trail' 'Missing Trail suppression'
Assert-Contains 'Beam' 'Missing Beam suppression'
Assert-Contains 'Smoke' 'Missing Smoke suppression'
Assert-Contains 'Fire' 'Missing Fire suppression'
Assert-Contains 'Sparkles' 'Missing Sparkles suppression'
Assert-Contains 'Highlight' 'Missing Highlight suppression'
Assert-Contains 'AutoSkillVisualSuppression\.Begin\(Key\)\s*PressKey\(Key\)' 'Suppression must begin only beside auto-skill key press'

$suppression = [regex]::Match($content, '(?m)^AutoSkillVisualSuppression\s*=\s*\{(?<body>[\s\S]*?)\r?\ntask\.spawn\(function\(\)\s*while\s+true\s+do\s*task\.wait\(0\.1\)')
if (-not $suppression.Success) { throw 'Unable to isolate auto-skill suppression implementation' }
if ($suppression.Groups['body'].Value -match '\w+:Stop\(') { throw 'Visual suppression must not stop animation tracks or gameplay instances' }

'auto-skill-visuals-ok'
