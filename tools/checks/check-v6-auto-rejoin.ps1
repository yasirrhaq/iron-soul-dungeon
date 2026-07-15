$ErrorActionPreference = 'Stop'

$root = Resolve-Path (Join-Path $PSScriptRoot '..\..')
$v6Path = Join-Path $root 'holygrail\script-v6-full-run-dg.lua'
$content = Get-Content -Raw -LiteralPath $v6Path

function Assert-Contains($pattern, $message) {
    if ($content -notmatch $pattern) { throw $message }
}

& git -C $root diff HEAD --quiet -- 'holygrail/script-v5-full-run-dg.lua'
if ($LASTEXITCODE -ne 0) { throw 'script-v5 must remain unchanged' }

Assert-Contains 'local\s+TeleportService\s*=\s*game:GetService\("TeleportService"\)' 'Missing TeleportService'
Assert-Contains 'AutoRejoin\s*=\s*true' 'Auto Rejoin must default on'
Assert-Contains 'Config\.AutoRejoin\s*=\s*_G\.AutoRejoin' 'Auto Rejoin must persist'
Assert-Contains 'LoadingTimeout\s*=\s*60' 'Loading timeout must be 60 seconds'
Assert-Contains 'RetryDelays\s*=\s*\{15,\s*30,\s*60\}' 'Retry delays changed'
Assert-Contains 'AttemptWindow\s*=\s*600' 'Attempt window must be ten minutes'
Assert-Contains 'MaxAttempts\s*=\s*3' 'Attempt limit must be three'
Assert-Contains 'Config\.LobbyPlaceId\s*=\s*game\.PlaceId' 'Lobby PlaceId must be captured'
Assert-Contains 'TeleportService:Teleport\(Config\.LobbyPlaceId, LocalPlayer\)' 'Missing lobby teleport'
Assert-Contains 'Bugon-teleport-log\.txt' 'Missing diagnostic journal'
Assert-Contains 'CreateToggleRow\(FarmTab,\s*"Auto Rejoin"' 'Missing menu toggle'
Assert-Contains 'RecoveryPending' 'Missing recovery persistence'
Assert-Contains 'REJOIN:' 'Missing watchdog status'
Assert-Contains 'Config\.RecoveryPending.*IsInLobby\(\)' 'Missing post-rejoin lobby flow'
Assert-Contains '\(_G\.AutoSell\s+or\s+Config\.RecoveryPending\).*IsInLobby' 'Recovery must permit required lobby auto-sell'
Assert-Contains 'not\s+RejoinWatchdog\.BlocksAutomation\(\)' 'Recovery must gate automation'

'v6-auto-rejoin-ok'
