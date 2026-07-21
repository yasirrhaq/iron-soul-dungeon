$ErrorActionPreference = 'Stop'

$root = Resolve-Path (Join-Path $PSScriptRoot '..\..')
$v6Path = Join-Path $root 'holygrail\script-v6-full-run-dg.lua'
$content = Get-Content -Raw -LiteralPath $v6Path

function Assert-Contains($pattern, $message) {
    if ($content -notmatch $pattern) { throw $message }
}

function Assert-NotContains($pattern, $message) {
    if ($content -match $pattern) { throw $message }
}

& git -C $root diff HEAD --quiet -- 'holygrail/script-v5-full-run-dg.lua'
if ($LASTEXITCODE -ne 0) { throw 'script-v5 must remain unchanged' }

Assert-Contains 'local\s+TeleportService\s*=\s*game:GetService\("TeleportService"\)' 'Missing TeleportService'
Assert-Contains 'AutoRejoin\s*=\s*true' 'Auto Rejoin must default on'
Assert-Contains 'Config\.AutoRejoin\s*=\s*_G\.AutoRejoin' 'Auto Rejoin must persist'
Assert-Contains 'LoadingTimeout\s*=\s*60' 'Loading timeout must be 60 seconds'
Assert-Contains 'os\.clock\(\)\s*-\s*StartedAt\s*<\s*150' 'Character loading watchdog must wait 150 seconds'
Assert-Contains 'HumanoidRootPart' 'Character loading watchdog must require a root part'
Assert-Contains 'TeleportService:Teleport\(PlaceId, LocalPlayer\)' 'Character loading watchdog must rejoin without PlayerGui'
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
Assert-Contains 'FallbackScanInterval\s*=\s*30' 'Fallback GUI scan must be 30 seconds'
Assert-Contains 'function\s+RejoinWatchdog\.BindPlayerGui\(' 'PlayerGui binding must be non-blocking'
Assert-Contains 'BindPlayerGui\(LocalPlayer:FindFirstChild\("PlayerGui"\)\)' 'Reconnect watcher must not wait for PlayerGui before CoreGui'
Assert-Contains 'LocalPlayer\.ChildAdded:Connect' 'PlayerGui late binding must be handled'
Assert-Contains 'PlayerGui\.DescendantAdded:Connect' 'Teleport UI detection must use PlayerGui events'
Assert-Contains 'CoreGui\.ChildAdded:Connect' 'Reconnect root detection must use CoreGui child events'
Assert-Contains 'RobloxPromptGui\.DescendantAdded:Connect' 'Reconnect detection must stay inside RobloxPromptGui'
Assert-Contains 'Scan\(PromptOverlay\)\s+or\s+Scan\(RobloxPromptGui\)' 'Reconnect scan must fall back to full RobloxPromptGui'
Assert-Contains 'DISCONNECT_TEXT' 'Reconnect watcher must recover from disconnected prompt text'
Assert-Contains 'SendKeyEvent\(true,\s*Enum\.KeyCode\.Return' 'Reconnect click must include keyboard fallback'
Assert-NotContains 'CoreGui\.DescendantAdded:Connect' 'Reconnect detection must not watch every CoreGui descendant'
Assert-Contains 'function\s+RejoinWatchdog\.RefreshCachedTargets\(' 'Missing cached-target refresh'
Assert-Contains '(?s)function\s+RejoinWatchdog\.Tick\(\).*?if\s+not\s+_G\.AutoRejoin\s+then.*?return' 'Auto Rejoin off must skip detection work'
Assert-NotContains 'local\s+TeleportText\s*=\s*RejoinWatchdog\.FindVisibleText' 'Tick must not scan PlayerGui every second'
Assert-NotContains 'local\s+ReconnectButton\s*=\s*RejoinWatchdog\.FindReconnectButton' 'Tick must not scan reconnect GUI every second'

'v6-auto-rejoin-ok'
