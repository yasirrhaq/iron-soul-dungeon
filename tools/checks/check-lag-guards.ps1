$ErrorActionPreference = 'Stop'

$scriptPath = Join-Path $PSScriptRoot '..\..\scripts\base\base-script-v2.lua'
$content = Get-Content -Raw -LiteralPath $scriptPath

function Assert-Contains($pattern, $message) {
    if ($content -notmatch $pattern) { throw $message }
}

Assert-Contains '_G\.IronSoulCleanup\(\)' 'Script must cleanup prior run before reconnecting loops'
Assert-Contains '_G\.IronSoulRunActive\s*=\s*true' 'Script must create a run-active flag'
Assert-Contains 'local\s+function\s+RegisterConnection\(connection\)' 'Missing connection registry'
Assert-Contains 'RegisterConnection\(RunService\.Heartbeat:Connect' 'Heartbeat connections must be registered for cleanup'
Assert-Contains 'RegisterConnection\(RunService\.Stepped:Connect' 'Stepped connection must be registered for cleanup'
Assert-Contains 'while\s+_G\.IronSoulRunActive\s+do' 'Background loops must stop after re-execute cleanup'
Assert-Contains 'local\s+NextTargetScanAt\s*=\s*0' 'Missing target scan throttle state'
Assert-Contains 'local\s+function\s+CanScanTargets\(currentTime\)' 'Missing target scan guard'
Assert-Contains 'if\s+not\s+CanScanTargets\(CurrentTime\)\s+then\s+task\.wait\(0\.5\)' 'Target loop must skip expensive scans when guard blocks'
Assert-Contains 'NextTargetScanAt\s*=\s*currentTime\s*\+\s*2\.0' 'Lobby/no-dungeon scans must be throttled to 2 seconds'
Assert-Contains 'NextTargetScanAt\s*=\s*currentTime\s*\+\s*0\.5' 'Dungeon scans must stay responsive'

'lag-guards-ok'
