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

Assert-Contains 'AutoPotion\s*=\s*false' 'Auto Potion must default off'
Assert-Contains 'AutoPotionSelected\s*=\s*\{\}' 'Auto Potion selection must default empty'
Assert-Contains 'Config\.AutoPotion\s*=\s*_G\.AutoPotion' 'Auto Potion toggle must persist'
Assert-Contains 'Config\.AutoPotionSelected\s*=\s*AutoPotion\.Selected' 'Auto Potion selection must persist'
Assert-Contains 'local\s+AutoPotion\s*=\s*\{' 'Auto Potion must use one namespace'
Assert-Contains 'Configs.*ResPotion' 'Auto Potion catalog must use ResPotion'
Assert-Contains 'Definition\.PotionType\s*==\s*"Buff"' 'Catalog must include only Buff potions'
Assert-NotContains 'Definition\.PotionType\s*==\s*"BondIntimacy"' 'Bond/Friendship potions must not be automated'
Assert-Contains 'PotionUtil:GetOwnedAmount\(LocalPlayer,\s*PotionId\)' 'Owned amount must use PotionUtil getter'
Assert-Contains '"BuffId"\s*\.\.\s*Index' 'Catalog must enumerate BuffId fields'
Assert-Contains '"Duration"\s*\.\.\s*Index' 'Catalog must enumerate Duration fields'
Assert-Contains 'function\s+AutoPotion\.GetBuffAttributeIds\(' 'Buff IDs must resolve to player attribute IDs'
Assert-Contains 'string\.match\(BuffId,\s*"\^Buff_\(\.\+\)_%d\+\$"\)' 'Buff resolver must strip native Buff_ prefix and tier suffix'
Assert-Contains 'GetAttributeChangedSignal\(AttributeId\)' 'Resolved buff attributes must drive primary refresh'
Assert-Contains 'Buff_DropRateBoost_1.*DropRateBoost' 'Self-check must cover internal Drop buff ID mapping'
Assert-Contains 'ScanInterval\s*=\s*15' 'Fallback scan must run every 15 seconds'
Assert-Contains 'QueueSpacing\s*=\s*0\.65' 'Potion queue spacing must be server-safe'
Assert-Contains 'ConfirmTimeout\s*=\s*5' 'Potion request confirmation timeout must be bounded'
Assert-Contains 'DungeonGraceSeconds\s*=\s*10' 'Dungeon-ready grace must last 10 seconds'
Assert-Contains 'GraceGeneration\s*=\s*0' 'Dungeon grace must invalidate stale timers'
Assert-Contains 'function\s+AutoPotion\.ResetDungeonGrace\(' 'Missing dungeon grace reset helper'
Assert-Contains 'function\s+AutoPotion\.CheckDungeonGrace\(' 'Missing dungeon grace eligibility helper'
Assert-Contains 'task\.delay\(AutoPotion\.DungeonGraceSeconds' 'Dungeon grace must trigger a delayed immediate scan'
Assert-Contains 'BLOCKED - POTION GRACE' 'Dungeon grace must expose blocked status'
Assert-Contains 'AutoPotion\.ResetDungeonGrace\(\)' 'Blocked states must reset dungeon grace'
Assert-Contains '(?s)if\s+Name\s*==\s*"MatchRoom".*?Name\s*==\s*"DragonEgg".*?then\s*if\s+Name\s*==\s*"MatchRoom"\s+or\s+Name\s*==\s*"PlayerAttrEntry"\s+then\s*AutoPotion\.ResetDungeonGrace\(\)' 'Stage object churn must scan without restarting dungeon grace'
Assert-Contains 'PotionUtil:UsePotion\(LocalPlayer,\s*PotionId,\s*1,\s*nil\)' 'Potion use must consume exactly one'
Assert-Contains 'AutoPotion\.Queued\[PotionId\]\s+or\s+AutoPotion\.Pending\[PotionId\]' 'Queue must reject queued or pending IDs'
Assert-Contains 'ActivationPending\s*=\s*\{\}' 'Missing accepted-request activation latch'
Assert-Contains 'AutoPotion\.ActivationPending\[PotionId\]' 'Inactive accepted potion must stay latched'
Assert-Contains 'RequestAccepted\s*=\s*RequestAccepted\s+or\s+Entry\.Owned\s*<\s*BeforeOwned' 'Owned decrease must record acceptance without ending confirmation'
Assert-NotContains 'AutoPotion\.IsEntryActive\(Entry\)\s+or\s+Entry\.Owned\s*<\s*BeforeOwned' 'Owned decrease must not release pending before buff activation'
Assert-Contains 'owned decrease waits for buff activation' 'Self-check must cover delayed buff replication'
Assert-Contains 'function\s+AutoPotion\.IsDungeonEligible\(' 'Missing dungeon eligibility guard'
Assert-Contains 'function\s+AutoPotion\.IsEndlessTower\(' 'Missing Endless Tower detector'
Assert-Contains 'workspace:FindFirstChild\("World"\)' 'Endless Tower detector must inspect current World'
Assert-Contains 'CurrentWorld:FindFirstChild\("Start"\)' 'Endless Tower detector must reuse native Start marker'
Assert-Contains 'BLOCKED - ENDLESS TOWER' 'Auto Potion must expose Endless Tower block status'
Assert-Contains 'IsInLobby\(\)' 'Auto Potion must block lobby use'
Assert-Contains 'workspace:GetAttribute\("LoadingEnd"\)' 'Auto Potion must block loading'
Assert-Contains 'IsSettlementVisible\(\)' 'Auto Potion must block settlement'
Assert-Contains 'RejoinWatchdog\.BlocksAutomation\(\)' 'Auto Potion must block rejoin recovery'
Assert-Contains 'PlayerAttrEntry' 'Auto Potion must read player buff attributes'
Assert-Contains 'function\s+AutoPotion\.DisconnectSignals\(' 'Missing signal teardown'
Assert-Contains 'function\s+AutoPotion\.SetEnabled\(' 'Missing runtime toggle lifecycle'
Assert-Contains 'task\.wait\(AutoPotion\.ScanInterval\)' 'Fallback worker must use 15-second interval'
Assert-Contains 'AUTO POTION' 'Missing Auto Potion Dungeon controls'
Assert-Contains 'AutoPotionSearch' 'Missing Auto Potion search input'
Assert-Contains 'AutoPotionList' 'Missing Auto Potion list'
Assert-Contains 'Out of Stock' 'Missing out-of-stock state'
Assert-Contains 'Unavailable' 'Missing unavailable state'
Assert-Contains 'function\s+AutoPotion\.RunSelfCheck\(' 'Missing table-driven Auto Potion self-check'
Assert-Contains 'one selected potion' 'Self-check must cover one selected potion'
Assert-Contains 'multiple independent potions' 'Self-check must cover independent potions'
Assert-Contains 'multi-buff potion' 'Self-check must cover multi-buff potion'
Assert-Contains 'out-of-stock potion' 'Self-check must cover out-of-stock behavior'
Assert-Contains 'missed-signal recovery' 'Self-check must cover fallback recovery'
Assert-Contains 'Bond exclusion' 'Self-check must cover Bond exclusion'
Assert-NotContains 'AutoPotion\.ScanInterval\s*=\s*1' 'Auto Potion must not poll every second'

'v6-auto-potion-ok'
