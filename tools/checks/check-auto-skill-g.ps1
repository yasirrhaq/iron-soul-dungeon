$ErrorActionPreference = 'Stop'

$scriptPath = Join-Path $PSScriptRoot '..\..\scripts\base\base-script-v2.lua'
$content = Get-Content -Raw -LiteralPath $scriptPath

function Assert-Contains($pattern, $message) {
    if ($content -notmatch $pattern) { throw $message }
}

Assert-Contains 'local\s+LastUsed\s*=\s*\{[^}]*G\s*=\s*0' 'Missing G in LastUsed'
Assert-Contains 'local\s+Cooldowns\s*=\s*\{[^}]*G\s*=\s*7' 'Missing G cooldown 7'
Assert-Contains 'PressKey\("G"\)\s+LastUsed\.G\s*=\s*CurrentTime' 'Missing auto skill G press/update'

'auto-skill-g-ok'
