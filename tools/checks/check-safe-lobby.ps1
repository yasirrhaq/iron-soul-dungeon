$ErrorActionPreference = 'Stop'

$scriptPath = Join-Path $PSScriptRoot '..\..\scripts\base\base-script-v2.lua'
$content = Get-Content -Raw -LiteralPath $scriptPath

function Assert-Contains($pattern, $message) {
    if ($content -notmatch $pattern) { throw $message }
}

function Assert-NotContains($pattern, $message) {
    if ($content -match $pattern) { throw $message }
}

Assert-Contains 'local\s+HasSeenDungeonTarget\s*=\s*false' 'Portal must know if a real dungeon target was ever seen'
Assert-Contains 'HasSeenDungeonTarget\s*=\s*true' 'Real target acquisition must unlock dungeon portal progression'
Assert-Contains 'HasSeenDungeonTarget\s+and\s+\(currentTime\s*-\s*LastEnemySeen\)' 'Portal gate must require a prior dungeon target'
Assert-Contains 'local\s+LobbyTargetContainers\s*=\s*\{' 'Missing cheap lobby container blacklist'
Assert-Contains 'EnemyNpc\s*=\s*true' 'Lobby EnemyNpc folder must be blacklisted'
if ($content -match 'MatchRoom\s*=\s*true') { throw 'MatchRoom must not be blacklisted; dungeon targets can live there' }
Assert-Contains 'local\s+function\s+IsLobbyTargetModel\(model\)' 'Missing cheap lobby target detector'
Assert-Contains 'if\s+obj:IsA\("Model"\)\s+and\s+obj\s+~=\s+Character\s+and\s+not\s+Players:GetPlayerFromCharacter\(obj\)\s+and\s+not\s+IsLobbyTargetModel\(obj\)\s+then' 'Target scanner must skip players and lobby NPC folders cheaply'
Assert-NotContains 'not\s+Players:GetPlayerFromCharacter\(obj\)\s+and\s+CandidateAllowedByMode\(obj\)' 'Target scanner must not use expensive candidate filter'
Assert-Contains 'Hum\.WalkSpeed\s*=\s*_G\.BaseSpeed' 'Missing BaseSpeed application'
Assert-Contains 'if\s+_G\.AutoFarm\s+then\s+if\s+Hum\.WalkSpeed\s*~=\s*_G\.BaseSpeed\s+then\s+Hum\.WalkSpeed\s*=\s*_G\.BaseSpeed\s+end' 'BaseSpeed must stay active in lobby while script is on'
Assert-Contains '_G\.AutoFarm\s+and\s+_G\.UndergroundMode\s+and\s+Target\s+and\s+not\s+IsInLobby\(\)' 'Anti-fall platform must require a valid target outside lobby'
Assert-NotContains 'if\s+string\.find\(Name,\s*"dungeon"\).*return\s+false' 'Lobby detector must not treat folder names alone as active dungeon'

'safe-lobby-ok'
