$ErrorActionPreference = 'Stop'

$scriptPath = Join-Path $PSScriptRoot '..\..\holygrail\script-v6-full-run-dg.lua'
$content = Get-Content -Raw -LiteralPath $scriptPath

function Assert-Contains($pattern, $message) {
    if ($content -notmatch $pattern) { throw $message }
}

Assert-Contains 'DeathRestartPending\s*=\s*false' 'Missing persisted death restart default'
Assert-Contains 'Config\.DeathRestartPending\s*=\s*Config\.DeathRestartPending\s*==\s*true' 'Missing death restart normalization'
Assert-Contains '(?m)^AutoGiveupFlow\s*=\s*\{' 'Missing Auto Giveup runtime state'
Assert-Contains 'AwaitingSettlement\s*=\s*false' 'Missing settlement transition latch'
Assert-Contains 'Remotes.*GamePlayerRE' 'Missing GamePlayerRE resolution'
Assert-Contains 'FireServer\("ExitSettlement"\)' 'Auto Giveup must use direct ExitSettlement remote'
Assert-Contains 'AutoGiveupFlow\.AwaitingSettlement\s*=\s*true' 'ExitSettlement must latch settlement waiting state'
Assert-Contains 'GetAttribute\("RemainLife"\)' 'Auto Giveup must read the authoritative remaining-life attribute'
Assert-Contains 'RemainLife\s*<=\s*0' 'Auto Giveup must detect death from RemainLife'
Assert-Contains '(?s)BattleHUD.*PlayerRevive.*ReviveFrame.*Revive.*ExitBtn' 'Missing exact PlayerRevive ExitBtn path'
Assert-Contains 'if\s+not\s+_G\.AutoGiveup' 'Auto Giveup flow must respect its toggle'
Assert-Contains 'Config\.DeathRestartPending\s*=\s*_G\.AutoFarm\s+and\s+_G\.AutoReplay' 'Lobby restart intent must follow Auto Farm and Auto Replay'
Assert-Contains '(?s)ResultGui.*ScreenSettlement.*BtnGroup.*ReturnToLobbyBtn' 'Missing exact Return to Lobby path'
Assert-Contains 'AutoGiveupFlow\.AwaitingSettlement\s+and\s+ReturnButton' 'Settlement button must remain actionable after death text disappears'
Assert-Contains 'function\s+AutoGiveupFlow\.ProcessLobbyRestart\(' 'Missing post-teleport lobby restart processor'
Assert-Contains '(?s)DeathRestartPending.*QueueAutoStartSoloDungeon\(' 'Death restart must queue saved solo dungeon'
Assert-Contains 'GetOreBackpackUsage\(' 'Death restart must check backpack before queueing'
Assert-Contains 'Config\.DeathRestartPending\s*=\s*false\s*SaveConfig\(\)' 'Death restart pending must clear after room creation'
$deathScanIndex = $content.IndexOf('pcall(ScanAndHandleDeath)')
$targetScanIndex = $content.IndexOf('pcall(GetClosestTargetZeroSpike)')
if ($deathScanIndex -lt 0 -or $targetScanIndex -lt 0 -or $deathScanIndex -ge $targetScanIndex) {
    throw 'Death handling must run before target acquisition'
}

$deathFunction = [regex]::Match($content, 'local\s+function\s+ScanAndHandleDeath\(\)(?<body>[\s\S]*?)\r?\nend\r?\n\r?\nlocal\s+function\s+ScanAndExecuteReplay')
if (-not $deathFunction.Success) { throw 'Unable to isolate ScanAndHandleDeath' }
$deathBody = $deathFunction.Groups['body'].Value
if ($deathBody -match 'TaskRE|UpdateTaskProgress') { throw 'Auto Giveup must not fire TaskRE telemetry manually' }
$exitButtonIndex = $deathBody.IndexOf('EksekusiKlikReplay(ExitButton)')
$exitRemoteIndex = $deathBody.IndexOf('Remote:FireServer("ExitSettlement")')
if ($exitButtonIndex -lt 0 -or $exitRemoteIndex -lt 0 -or $exitButtonIndex -ge $exitRemoteIndex) {
    throw 'Auto Giveup must activate the real ExitBtn before direct remote fallback'
}

'v6-auto-giveup-ok'
