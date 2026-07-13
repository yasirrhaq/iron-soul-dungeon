$ErrorActionPreference = 'Stop'

$scriptPath = Join-Path $PSScriptRoot '..\..\scripts\base\base-script-v2.lua'
$content = Get-Content -Raw -LiteralPath $scriptPath

function Assert-Contains($pattern, $message) {
    if ($content -notmatch $pattern) { throw $message }
}

Assert-Contains 'if\s+Hum\.WalkSpeed\s*~=\s*_G\.BaseSpeed\s+then\s+Hum\.WalkSpeed\s*=\s*_G\.BaseSpeed\s+end' 'BaseSpeed must only write when WalkSpeed changes'
Assert-Contains 'if\s+Hum\.WalkSpeed\s*~=\s*16\s+then\s+Hum\.WalkSpeed\s*=\s*16\s+end' 'Default speed reset must only write when WalkSpeed changes'

'walkspeed-guard-ok'
