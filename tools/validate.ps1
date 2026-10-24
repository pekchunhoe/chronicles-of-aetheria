param(
    [string]$Godot = "",
    [switch]$Capture
)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
if (-not $Godot) {
    $localEngine = Join-Path $projectRoot '.tools\godot-4.7.2\Godot_v4.7.2-stable_win64_console.exe'
    if (Test-Path -LiteralPath $localEngine) { $Godot = $localEngine }
    else { $Godot = (Get-Command godot -ErrorAction Stop).Source }
}
$version = (& $Godot --version | Out-String).Trim()
if ($LASTEXITCODE -ne 0 -or $version -notmatch '^4\.7\.2\.stable\.') {
    throw "Expected Godot 4.7.2 stable; received: $version"
}
New-Item -ItemType Directory -Path (Join-Path $projectRoot 'artifacts') -Force | Out-Null

function Invoke-GodotCheck {
    param([string]$Name, [string[]]$EngineArguments, [string]$ExpectedSummary = '')
    $logPath = Join-Path $projectRoot "artifacts\$Name.log"
    # Frame-count assertions need one 60 Hz physics step per rendered iteration.
    # Keep the live route on its real clock so its performance metrics remain valid.
    if ($Name -like '*tests' -or $Name -eq 'phase2-showcase') {
        $EngineArguments = @('--fixed-fps', '60') + $EngineArguments
    }
    & $Godot --path $projectRoot --log-file $logPath @EngineArguments
    if ($LASTEXITCODE -ne 0) { throw "$Name failed with exit code $LASTEXITCODE" }
    $log = Get-Content -LiteralPath $logPath -Raw
    if ($log -match '(?m)^(SCRIPT ERROR:|ERROR:|FAIL:)' -or $log -match 'ObjectDB instances were leaked|resources still in use') {
        throw "$Name emitted an engine/test error. Read $logPath"
    }
    if ($ExpectedSummary -and $log -notmatch $ExpectedSummary) {
        throw "$Name did not complete its expected assertions. Read $logPath"
    }
}

Invoke-GodotCheck 'editor-import' @('--headless', '--editor', '--import', '--quit')
Invoke-GodotCheck 'unit-tests' @('--headless', '--script', 'res://tests/run_unit_tests.gd', '--quit-after', '1200') 'RESULT: \d+ passed, 0 failed'
Invoke-GodotCheck 'scene-tests' @('--headless', '--script', 'res://tests/integration/run_scene_tests.gd', '--quit-after', '1200') 'RESULT: \d+ passed, 0 failed'
Invoke-GodotCheck 'action-tests' @('--headless', '--script', 'res://tests/integration/run_action_tests.gd', '--quit-after', '6000') 'RESULT: \d+ passed, 0 failed'
Invoke-GodotCheck 'dungeon-route' @('--headless', '--script', 'res://tests/integration/run_dungeon_route.gd', '--quit-after', '6000') 'RESULT: \d+ passed, 0 failed'
Invoke-GodotCheck 'visual-tests' @('--headless', '--script', 'res://tests/integration/run_visual_tests.gd', '--quit-after', '1200') 'RESULT: \d+ passed, 0 failed'
Invoke-GodotCheck 'headless-boot' @('--headless', '--quit-after', '10')
if ($Capture) {
    Invoke-GodotCheck 'graphical-scene-tests' @('--script', 'res://tests/integration/run_scene_tests.gd', '--quit-after', '1200', '--', '--capture') 'RESULT: \d+ passed, 0 failed'
    Invoke-GodotCheck 'graphical-action-tests' @('--script', 'res://tests/integration/run_action_tests.gd', '--quit-after', '6000', '--', '--capture') 'RESULT: \d+ passed, 0 failed'
    Invoke-GodotCheck 'graphical-dungeon-route' @('--script', 'res://tests/integration/run_dungeon_route.gd', '--quit-after', '6000') 'RESULT: \d+ passed, 0 failed'
    Invoke-GodotCheck 'graphical-visual-tests' @('--script', 'res://tests/integration/run_visual_tests.gd', '--quit-after', '1200') 'RESULT: \d+ passed, 0 failed'
    Invoke-GodotCheck 'phase2-showcase' @('--script', 'res://tools/capture_visual_showcase.gd', '--quit-after', '2400') 'SHOWCASE PASS'
}
Write-Output "Phase 2 validation passed with $version. Device and export gates are separate."
