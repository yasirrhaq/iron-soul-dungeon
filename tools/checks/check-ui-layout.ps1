$ErrorActionPreference = 'Stop'

$scriptPath = Join-Path $PSScriptRoot '..\..\scripts\base\base-script-v2.lua'
$content = Get-Content -Raw -LiteralPath $scriptPath
$menuScaleMatch = [regex]::Match($content, 'return\s+UDim2\.new\(\s*0\.05\s*,\s*0\s*,\s*([-0-9.]+)\s*,\s*yOffset\s*\)')
if (-not $menuScaleMatch.Success) { throw 'Missing MenuPosition scale' }
$menuYScale = [double]$menuScaleMatch.Groups[1].Value

function Get-Layout($name) {
    $escapedName = [regex]::Escape($name)
    $position = [regex]::Match($content, "$escapedName\.Position\s*=\s*UDim2\.new\(\s*[-0-9.]+\s*,\s*[-0-9.]+\s*,\s*([-0-9.]+)\s*,\s*([-0-9.]+)\s*\)")
    $menuPosition = [regex]::Match($content, "$escapedName\.Position\s*=\s*MenuPosition\(\s*([-0-9.]+)\s*\)")
    $size = [regex]::Match($content, "$escapedName\.Size\s*=\s*UDim2\.new\(\s*[-0-9.]+\s*,\s*[-0-9.]+\s*,\s*[-0-9.]+\s*,\s*([-0-9.]+)\s*\)")

    if (-not $position.Success -and -not $menuPosition.Success) { throw "Missing Position for $name" }
    if (-not $size.Success) { throw "Missing Size for $name" }

    $yScale = $menuYScale
    $yOffset = [double]$menuPosition.Groups[1].Value
    if ($position.Success) {
        $yScale = [double]$position.Groups[1].Value
        $yOffset = [double]$position.Groups[2].Value
    }

    [pscustomobject]@{
        Name = $name
        YScale = $yScale
        YOffset = $yOffset
        Height = [double]$size.Groups[1].Value
    }
}

$controls = @(
    (Get-Layout 'MasterButton'),
    (Get-Layout 'ModeButton'),
    (Get-Layout 'ReplayButtonToggle'),
    (Get-Layout 'LabelHeight'),
    (Get-Layout 'SliderHeightFrame'),
    (Get-Layout 'LabelBaseSpeed'),
    (Get-Layout 'SliderBaseSpeedFrame'),
    (Get-Layout 'ForgeButtonToggle'),
    (Get-Layout 'StatsLabel')
)

foreach ($viewportHeight in 360, 480, 720, 1080) {
    for ($i = 0; $i -lt ($controls.Count - 1); $i++) {
        $current = $controls[$i]
        $next = $controls[$i + 1]
        $currentBottom = ($current.YScale * $viewportHeight) + $current.YOffset + $current.Height
        $nextTop = ($next.YScale * $viewportHeight) + $next.YOffset

        if ($nextTop -lt $currentBottom) {
            throw "$($next.Name) overlaps $($current.Name) at viewport height $viewportHeight px"
        }
    }
}

'layout-ok'
