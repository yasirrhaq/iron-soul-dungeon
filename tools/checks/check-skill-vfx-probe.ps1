$ErrorActionPreference = 'Stop'

$probePath = Join-Path $PSScriptRoot '..\..\research\dump\skill-vfx-probe.lua'
if (-not (Test-Path -LiteralPath $probePath)) { throw 'Missing skill-vfx-probe.lua' }
$content = Get-Content -Raw -LiteralPath $probePath

function Assert-Contains($pattern, $message) {
    if ($content -notmatch $pattern) { throw $message }
}

Assert-Contains 'Connect\(Animator\.AnimationPlayed' 'Probe must capture played animation tracks'
Assert-Contains 'Track\.Animation\.AnimationId' 'Probe must log animation asset IDs'
Assert-Contains 'Connect\(workspace\.DescendantAdded' 'Probe must capture new runtime VFX instances'
Assert-Contains 'GetPropertyChangedSignal' 'Probe must capture pooled VFX property changes'
Assert-Contains 'Motor6D' 'Probe must detect custom joint movement'
Assert-Contains 'hookmetamethod' 'Probe must capture remote namecalls when executor supports hooks'
Assert-Contains 'FireServer' 'Probe must log RemoteEvent calls'
Assert-Contains 'InvokeServer' 'Probe must log RemoteFunction calls'
Assert-Contains 'setclipboard|toclipboard' 'Probe must export bounded results to clipboard'
Assert-Contains 'SkillVfxProbeStop' 'Probe must expose manual stop/export function'
Assert-Contains 'MaxLines\s*=\s*600' 'Probe output must stay bounded'

'skill-vfx-probe-ok'
