$ErrorActionPreference = 'Stop'

$scriptPath = Join-Path $PSScriptRoot '..\..\holygrail\script-v6-full-run-dg.lua'
$content = Get-Content -Raw -LiteralPath $scriptPath

function Assert-Contains($pattern, $message) {
    if ($content -notmatch $pattern) { throw $message }
}

Assert-Contains 'AutoPickEndlessOffensiveCard\s*=\s*false' 'Auto card picker must default off'
Assert-Contains 'AutoUnlockEndlessPaidCard\s*=\s*false' 'Paid card unlock must default off'
Assert-Contains 'EndlessCardMinGoldReserve\s*=\s*0' 'Minimum gold reserve must default to zero'
Assert-Contains 'Config\.AutoPickEndlessOffensiveCard\s*=\s*AutoEndlessCard\.Enabled' 'Auto card picker must persist'
Assert-Contains 'Config\.AutoUnlockEndlessPaidCard\s*=\s*AutoEndlessCard\.UnlockPaid' 'Paid unlock toggle must persist'
Assert-Contains 'Config\.EndlessCardMinGoldReserve\s*=\s*AutoEndlessCard\.MinGoldReserve' 'Gold reserve must persist'

Assert-Contains 'WorldBonusCardUtil' 'Missing WorldBonusCardUtil integration'
Assert-Contains 'WorldBonusCardUtil\.RemoteEvent' 'Missing card remote event'
Assert-Contains 'RemoteEvent\.OnClientEvent:Connect' 'Card picker must be event-driven'
Assert-Contains 'Action\s*==\s*"ShowCards"' 'Card picker must process ShowCards'
Assert-Contains 'Action\s*==\s*"SelectResult"' 'Card picker must reset from SelectResult'
Assert-Contains 'GetCardInfo\(Card\.ID\)' 'Card picker must inspect actual card metadata'
Assert-Contains 'TranslateByKey' 'Card picker must score translated card text'
Assert-Contains 'GetCardRarity' 'Card picker must use rarity as offensive tie-breaker'
Assert-Contains 'critical damage|crit damage|critical rate|crit rate|skill damage|weapon damage|attack speed|penetration|armor break' 'Missing offensive keyword coverage'
$scoreFunction = [regex]::Match($content, '(?s)function\s+AutoEndlessCard\.ScoreText\(Text\)(?<body>.*?)\r?\nend\r?\n\r?\nfunction\s+AutoEndlessCard\.BuildSignature')
if (-not $scoreFunction.Success) { throw 'Unable to isolate offensive card scoring' }
if ($scoreFunction.Groups['body'].Value -notmatch '(?s)for\s+_,\s*Pattern\s+in\s+ipairs\(AutoEndlessCard\.DefensivePatterns\).*?string\.find\(Text,\s*Pattern,\s*1,\s*true\).*?return\s+0') {
    throw 'Defensive card text must not score as offensive'
}
Assert-Contains 'CurrencyUtil:Has\(LocalPlayer,\s*CurrencyId,\s*Candidate\.Price\s*\+\s*AutoEndlessCard\.MinGoldReserve\)' 'Paid unlock must preserve configured gold reserve'
Assert-Contains 'RemoteEvent:FireServer\("Unlock",\s*Candidate\.Index\)' 'Paid offensive card must unlock by index'
Assert-Contains 'RemoteEvent:FireServer\("Select",\s*Candidate\.Index\)' 'Best available card must select by index'
Assert-Contains 'task\.delay\(3,' 'Unlock confirmation must use bounded timeout'
Assert-Contains 'AutoEndlessCard\.LastSignature' 'Card picker must deduplicate repeated ShowCards payloads'

$flow = [regex]::Match($content, '(?s)function\s+AutoEndlessCard\.SetStatus\(.*?function\s+AutoEndlessCard\.Connect\(\).*?\r?\nend')
if (-not $flow.Success) { throw 'Unable to isolate AutoEndlessCard event flow' }
if ($flow.Value -match 'Heartbeat|RenderStepped|while\s+true') { throw 'Auto card picker must not poll continuously' }

Assert-Contains 'AutoPickEndlessCardToggle' 'Missing Auto Pick Offensive Card UI toggle'
Assert-Contains 'AutoUnlockEndlessPaidCardToggle' 'Missing paid unlock UI toggle'
Assert-Contains 'EndlessCardMinGoldReserveInput' 'Missing minimum gold reserve input'
Assert-Contains 'local\s+TowerPage\s*=\s*Instance\.new\("ScrollingFrame"\)' 'Tower page must scroll for card controls'

'v6-auto-endless-card-ok'
