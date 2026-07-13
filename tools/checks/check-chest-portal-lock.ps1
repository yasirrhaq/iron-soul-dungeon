$ErrorActionPreference = 'Stop'

$scriptPath = Join-Path $PSScriptRoot '..\..\scripts\base\base-script-v2.lua'
$content = Get-Content -Raw -LiteralPath $scriptPath

function Assert-Contains($pattern, $message) {
    if ($content -notmatch $pattern) { throw $message }
}

function CanEnterPortal($currentTime, $lastTargetSeen, $lastBreakableSeen) {
    return (($currentTime - $lastTargetSeen) -ge 4.0) -and (($currentTime - $lastBreakableSeen) -ge 12.0)
}

if (CanEnterPortal 10.0 0.0 9.0) {
    throw 'Recent breakable hit must block portal even when normal target delay elapsed'
}

if (-not (CanEnterPortal 20.0 0.0 0.0)) {
    throw 'Stale breakable hit must allow portal after delay'
}

Assert-Contains 'local\s+BreakablePortalDelay\s*=\s*12\.0' 'Missing BreakablePortalDelay = 12.0'
Assert-Contains 'local\s+function\s+CanEnterPortal\(currentTime\)' 'Missing CanEnterPortal helper'
Assert-Contains 'LastBreakableSeen\s*=\s*os\.clock\(\)' 'Breakable targets must refresh LastBreakableSeen'
Assert-Contains 'CanEnterPortal\(CurrentTime\)' 'Portal branch must use CanEnterPortal(CurrentTime)'

'chest-portal-lock-ok'
