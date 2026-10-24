param(
    [string]$Godot = "",
    [switch]$Graphical
)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
if (-not $Godot) {
    $Godot = Join-Path $projectRoot '.tools\godot-4.7.2\Godot_v4.7.2-stable_win64_console.exe'
}
$version = (& $Godot --version | Out-String).Trim()
if ($LASTEXITCODE -ne 0 -or $version -notmatch '^4\.7\.2\.stable\.') {
    throw "Expected Godot 4.7.2 stable; received: $version"
}
$buildPath = Join-Path $projectRoot 'builds\windows\Aetheria.exe'
$artifactRoot = Join-Path $projectRoot 'artifacts'
New-Item -ItemType Directory -Path (Split-Path -Parent $buildPath), $artifactRoot -Force | Out-Null
$exportLog = Join-Path $artifactRoot 'windows-export.log'
& $Godot --headless --path $projectRoot --export-debug 'Windows Desktop' $buildPath --log-file $exportLog
if ($LASTEXITCODE -ne 0) { throw 'Windows export failed. Install matching 4.7.2 stable templates.' }
if ((Get-Content -LiteralPath $exportLog -Raw) -match '(?m)^(SCRIPT ERROR:|ERROR:)') {
    throw "Windows export emitted errors; read $exportLog"
}

$smokeLog = Join-Path $artifactRoot 'windows-export-smoke.log'
$oldSmokePath = $env:AETHERIA_SMOKE_SAVE_PATH
try {
    $env:AETHERIA_SMOKE_SAVE_PATH = Join-Path $artifactRoot "export-smoke-save-$([guid]::NewGuid().ToString('N')).json"
    # Waiting explicitly is necessary for the GUI-subsystem Windows executable.
    $smoke = Start-Process -FilePath $buildPath -WorkingDirectory (Split-Path -Parent $buildPath) -ArgumentList @(
        '--headless', '--quit-after', '1800', '--log-file', ('"' + $smokeLog + '"'),
        '--', '--foundation-smoke'
    ) -WindowStyle Hidden -PassThru -Wait
    $smokeText = Get-Content -LiteralPath $smokeLog -Raw
    if ($smoke.ExitCode -ne 0 -or $smokeText -notmatch 'EXPORT SMOKE PASS:' -or $smokeText -notmatch 'PACKAGED ACTION PASS:' -or $smokeText -notmatch 'PACKAGED RESEARCH PASS: packaged research save reload' -or $smokeText -match '(?m)^(SCRIPT ERROR:|ERROR:|FAIL:)') {
        throw "Exported application smoke test failed; read $smokeLog"
    }
} finally {
    $env:AETHERIA_SMOKE_SAVE_PATH = $oldSmokePath
}
if ($Graphical) {
    $graphicsLog = Join-Path $artifactRoot 'windows-export-graphical-smoke.log'
    try {
        $env:AETHERIA_SMOKE_SAVE_PATH = Join-Path $artifactRoot "export-graphics-save-$([guid]::NewGuid().ToString('N')).json"
        $graphics = Start-Process -FilePath $buildPath -WorkingDirectory (Split-Path -Parent $buildPath) -ArgumentList @(
            '--quit-after', '1800', '--log-file', ('"' + $graphicsLog + '"'), '--', '--foundation-smoke', '--capture'
        ) -WindowStyle Hidden -PassThru -Wait
        $graphicsText = Get-Content -LiteralPath $graphicsLog -Raw
        if ($graphics.ExitCode -ne 0 -or $graphicsText -notmatch 'PACKAGED ACTION PASS:' -or $graphicsText -notmatch 'PACKAGED RESEARCH PASS: packaged research save reload' -or $graphicsText -match '(?m)^(SCRIPT ERROR:|ERROR:|FAIL:)') {
            throw "Exported graphical action checks failed; read $graphicsLog"
        }
    } finally {
        $env:AETHERIA_SMOKE_SAVE_PATH = $oldSmokePath
    }
}
Write-Output "Windows debug export and packaged-content smoke test passed: $buildPath"
