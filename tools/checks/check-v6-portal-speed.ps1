$ErrorActionPreference = 'Stop'

$scriptPath = Join-Path $PSScriptRoot '..\..\holygrail\script-v6-full-run-dg.lua'
$content = Get-Content -Raw -LiteralPath $scriptPath

function Assert-Contains($pattern, $message) {
    if ($content -notmatch $pattern) { throw $message }
}

Assert-Contains 'local\s+PORTAL_COOLDOWN_DURATION\s*=\s*4' 'Portal cooldown must be 4s'
Assert-Contains 'local\s+MAP_LOAD_DELAY\s*=\s*3' 'Map load delay must be 3s'
Assert-Contains '\(CurrentTime\s*-\s*LastEnemySeen\)\s*>=\s*2\.0' 'No-enemy portal wait must be 2s'
Assert-Contains '\(CurrentTime\s*-\s*LastPortalCheck\)\s*>=\s*0\.75' 'Portal scan interval must be 0.75s'

'v6-portal-speed-ok'