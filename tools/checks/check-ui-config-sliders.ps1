$ErrorActionPreference = 'Stop'

$scriptPath = Join-Path $PSScriptRoot '..\..\scripts\base\base-script-v2.lua'
$content = Get-Content -Raw -LiteralPath $scriptPath

function Assert-Contains($pattern, $message) {
    if ($content -notmatch $pattern) { throw $message }
}

function HeightFromPercent($percent) {
    return [math]::Max(5, [math]::Floor($percent * 100))
}

function BaseSpeedFromPercent($percent) {
    return [math]::Floor(16 + ($percent * 84))
}

if ((HeightFromPercent 0.00) -ne 5) { throw 'Height slider minimum must be 5' }
if ((HeightFromPercent 1.00) -ne 100) { throw 'Height slider maximum must be 100' }
if ((BaseSpeedFromPercent 0.00) -ne 16) { throw 'BaseSpeed slider minimum must be 16' }
if ((BaseSpeedFromPercent 1.00) -ne 100) { throw 'BaseSpeed slider maximum must be 100' }

Assert-Contains 'local\s+UserInputService\s*=\s*game:GetService\("UserInputService"\)' 'Missing UserInputService'
Assert-Contains 'local\s+HttpService\s*=\s*game:GetService\("HttpService"\)' 'Missing HttpService'
Assert-Contains 'local\s+Config\s*=\s*\{' 'Missing Config table'
Assert-Contains 'BaseSpeed\s*=\s*16' 'Missing default BaseSpeed = 16'
Assert-Contains 'IronSoulConfig' 'Missing config folder name'
Assert-Contains 'YasirConfig\.json' 'Missing config file name'
Assert-Contains 'JSONEncode\(Config\)' 'Missing JSON config save'
Assert-Contains 'JSONDecode\(IsiFile\)' 'Missing JSON config load'
Assert-Contains '_G\.BaseSpeed\s*=\s*Config\.BaseSpeed' 'Missing _G.BaseSpeed load'
Assert-Contains 'local\s+function\s+IsInLobby\(\)' 'Missing safe lobby detector'
Assert-Contains 'Hum\.WalkSpeed\s*=\s*16' 'Missing lobby WalkSpeed reset'
Assert-Contains 'Hum\.WalkSpeed\s*=\s*_G\.BaseSpeed' 'Missing BaseSpeed WalkSpeed apply'
Assert-Contains 'LabelHeight' 'Missing height label'
Assert-Contains 'SliderHeightFrame' 'Missing height slider frame'
Assert-Contains 'SliderHeightButton' 'Missing height slider knob'
Assert-Contains 'LabelBaseSpeed' 'Missing BaseSpeed label'
Assert-Contains 'SliderBaseSpeedFrame' 'Missing BaseSpeed slider frame'
Assert-Contains 'SliderBaseSpeedButton' 'Missing BaseSpeed slider knob'
Assert-Contains 'ActiveSlider\s*=\s*"HEIGHT"' 'Missing height slider drag state'
Assert-Contains 'ActiveSlider\s*=\s*"BASE_SPEED"' 'Missing BaseSpeed slider drag state'
Assert-Contains 'SaveConfig\(\)' 'Missing config save calls'
Assert-Contains 'not\s+IsInLobby\(\)' 'Missing lobby guards'

'ui-config-sliders-ok'
