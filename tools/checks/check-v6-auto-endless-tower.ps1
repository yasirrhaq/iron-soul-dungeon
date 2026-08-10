$ErrorActionPreference = 'Stop'

$root = Resolve-Path (Join-Path $PSScriptRoot '..\..')
$scriptPath = Join-Path $root 'holygrail\script-v6-full-run-dg.lua'
$content = Get-Content -Raw -LiteralPath $scriptPath

function Assert-Contains($pattern, $message) {
    if ($content -notmatch $pattern) { throw $message }
}

& git -C $root diff HEAD --quiet -- 'holygrail/script-v5-full-run-dg.lua'
if ($LASTEXITCODE -ne 0) { throw 'script-v5 must remain unchanged' }

Assert-Contains 'AutoJoinEndlessTower\s*=\s*false' 'Auto Join Endless Tower must default off'
Assert-Contains 'EndlessTowerStartingRound\s*=\s*0' 'Starting round must default to Highest Unlocked'
Assert-Contains 'EndlessTowerMaxPlayers\s*=\s*1' 'Endless Tower must default to solo'
Assert-Contains 'Config\.AutoJoinEndlessTower\s*=\s*_G\.AutoJoinEndlessTower' 'Auto Join Endless toggle must persist'
Assert-Contains 'Config\.EndlessTowerStartingRound\s*=\s*AutoEndlessTower\.StartingRound' 'Starting round must persist'
Assert-Contains 'Config\.EndlessTowerMaxPlayers\s*=\s*AutoEndlessTower\.MaxPlayers' 'Player count must persist'
Assert-Contains 'function\s+AutoEndlessTower\.NormalizeStartingRound\(' 'Missing starting-round normalization'
Assert-Contains 'math\.clamp\([^\r\n]*1\s*,\s*196\)' 'Starting point must cap at round 196'
Assert-Contains 'GetWorldRecords\([^\r\n]*"Endless1"\s*,\s*1\s*,\s*"MaxRound"' 'Highest unlocked start must use seasonal MaxRound'
Assert-Contains 'function\s+AutoEndlessTower\.GetHighestStartingRound\(' 'Missing highest-unlocked starting-round resolver'
Assert-Contains 'FindAutoStartFreePortal\(\)' 'Endless join must wait for an empty MatchRoom slot'
Assert-Contains 'PlayersCount\s*==\s*0' 'Empty-room detection must reject occupied rooms'
Assert-Contains 'GraceDelay\s*=\s*8' 'Lobby room creation must wait through an eight-second loading grace'
Assert-Contains 'function\s+AutoLobbyStartGate\.IsReady\(' 'Missing shared lobby readiness gate'
Assert-Contains 'GetAttribute\("EnterRoomId"\)' 'Endless join must stop after the server assigns a room'
Assert-Contains 'FireServer\("CreatRoom",\s*"Endless1",\s*1,\s*AutoEndlessTower\.MaxPlayers,\s*StartingRound\)' 'Endless create-room payload changed'
Assert-Contains '(?s)local\s+function\s+TryAutoStartSoloDungeon\(\).*?_G\.AutoJoinEndlessTower.*?return\s+false' 'Endless join must take priority over normal dungeon auto-start'
Assert-Contains '(?s)function\s+AutoEndlessTower\.TryJoin\(\).*?AutoLobbyStartGate\.IsReady\(\)' 'Endless join must wait for lobby loading grace'
Assert-Contains '(?s)local\s+function\s+TryAutoStartSoloDungeon\(\).*?AutoLobbyStartGate\.IsReady\(\)' 'Normal dungeon restart must wait for lobby loading grace'
Assert-Contains 'function\s+AutoEndlessTower\.TryStartRun\(' 'Missing Endless start-modal handler'
Assert-Contains 'equip extra weapon' 'Start-modal detection must identify Equip Extra Weapon'
Assert-Contains '(?s)function\s+AutoEndlessTower\.TryStartRun\(\).*?ClickGuiButton\(StartButton\)' 'Endless start-modal handler must activate Start'
Assert-Contains '(?s)if\s+_G\.AutoJoinEndlessTower\s+then.*?AutoEndlessTower\.TryStartRun.*?AutoEndlessTower\.TryJoin' 'Start modal must be handled before another lobby join attempt'
Assert-Contains 'AutoJoinEndlessTowerToggle' 'Missing Auto Join Endless Tower UI toggle'
Assert-Contains 'EndlessStartingRoundDropdown' 'Missing starting-round selector'
Assert-Contains 'EndlessPlayerCountDropdown' 'Missing player-count selector'
Assert-Contains 'EndlessStatusLabel' 'Missing Endless Tower status label'
Assert-Contains 'TowerTabButton' 'Missing Endless Tower utility tab'

'v6-auto-endless-tower-ok'
