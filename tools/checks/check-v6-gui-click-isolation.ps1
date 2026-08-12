$ErrorActionPreference = 'Stop'

$root = Resolve-Path (Join-Path $PSScriptRoot '..\..')
$v6Path = Join-Path $root 'holygrail\script-v6-full-run-dg.lua'
$content = Get-Content -Raw -LiteralPath $v6Path

function Assert-Contains($pattern, $message) {
    if ($content -notmatch $pattern) { throw $message }
}

& git -C $root diff HEAD --quiet -- 'holygrail/script-v5-full-run-dg.lua'
if ($LASTEXITCODE -ne 0) { throw 'script-v5 must remain unchanged' }

Assert-Contains 'function\s+RejoinWatchdog\.TryFireGuiButtonSignals\(Button\)' 'Missing shared signal-first click helper'
Assert-Contains '(?s)RejoinWatchdog\.TryFireGuiButtonSignals\(Button\).*?MouseButton1Down.*?MouseButton1Click.*?Activated' 'Signal helper must fire down, click, and activated signals'
Assert-Contains '(?s)function\s+RejoinWatchdog\.ClickButton\(Button\).*?RejoinWatchdog\.TryFireGuiButtonSignals\(Button\).*?SendMouseButtonEvent' 'Reconnect click must try signals before coordinate input'
Assert-Contains '(?s)local\s+function\s+ClickGuiButton\(Button\).*?RejoinWatchdog\.TryFireGuiButtonSignals\(Button\).*?SendMouseButtonEvent' 'Game GUI click must try signals before coordinate input'

'v6-gui-click-isolation-ok'
