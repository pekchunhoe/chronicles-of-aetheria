param([string]$Godot = '')
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
if (-not $Godot) { $Godot = Join-Path $projectRoot '.tools\godot-4.7.2\Godot_v4.7.2-stable_win64_console.exe' }
if (-not (Test-Path -LiteralPath $Godot)) { throw 'Install Godot 4.7.2 stable or pass -Godot with its console executable path.' }
$version = (& $Godot --version | Out-String).Trim()
if ($LASTEXITCODE -ne 0 -or $version -notmatch '^4\.7\.2\.stable\.') { throw "Expected Godot 4.7.2 stable; got $version" }
$null = Get-Command node -ErrorAction Stop
$webRoot = Join-Path $projectRoot 'web'
$stagingRoot = Join-Path $projectRoot ('.tools\web-export-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $stagingRoot, $webRoot, (Join-Path $projectRoot 'artifacts') -Force | Out-Null
$logPath = Join-Path $projectRoot 'artifacts\web-export.log'
& $Godot --headless --path $projectRoot --export-release 'Web' (Join-Path $stagingRoot 'index.html') --log-file $logPath
if ($LASTEXITCODE -ne 0) { throw 'Web export failed. Install matching official 4.7.2 Web templates (python tools/install_web_templates.py for the local portable editor).' }
if ((Get-Content -LiteralPath $logPath -Raw) -match '(?m)^(SCRIPT ERROR:|ERROR:)') { throw "Web export emitted errors. Read $logPath" }
# Godot substitutes an empty head-include line and appends a newline. Normalize
# generated HTML whitespace before hashing so Git's whitespace check stays clean.
$htmlPath = Join-Path $stagingRoot 'index.html'
$html = [System.IO.File]::ReadAllText($htmlPath)
$html = [regex]::Replace($html, '(?m)[\t ]+$', '').TrimEnd() + "`n"
[System.IO.File]::WriteAllText($htmlPath, $html, [System.Text.UTF8Encoding]::new($false))
& node (Join-Path $PSScriptRoot 'verify_web_export.mjs') --directory $stagingRoot --write-manifest
if ($LASTEXITCODE -ne 0) { throw 'Incomplete export; existing web build was preserved.' }
# Replace only names owned by the previous generated manifest; preserve other files.
$previousManifest = Join-Path $webRoot 'build-manifest.json'
if (Test-Path -LiteralPath $previousManifest) {
    $previous = Get-Content -LiteralPath $previousManifest -Raw | ConvertFrom-Json
    foreach ($name in $previous.files.PSObject.Properties.Name) {
        if ($name -notmatch '^[a-zA-Z0-9_.-]+$') { throw 'Unsafe name in previous export manifest' }
        if (-not (Test-Path -LiteralPath (Join-Path $stagingRoot $name))) {
            Remove-Item -LiteralPath (Join-Path $webRoot $name) -ErrorAction SilentlyContinue
        }
    }
}
Get-ChildItem -LiteralPath $stagingRoot -File | ForEach-Object { Copy-Item -LiteralPath $_.FullName -Destination (Join-Path $webRoot $_.Name) -Force }
& node (Join-Path $PSScriptRoot 'verify_web_export.mjs')
if ($LASTEXITCODE -ne 0) { throw 'Web output verification failed.' }
$resolvedStaging = (Resolve-Path -LiteralPath $stagingRoot).Path
$resolvedTools = (Resolve-Path -LiteralPath (Join-Path $projectRoot '.tools')).Path
if ((Split-Path -Parent $resolvedStaging) -ne $resolvedTools -or (Split-Path -Leaf $resolvedStaging) -notmatch '^web-export-[a-f0-9]{32}$') {
    throw 'Refused cleanup outside the verified temporary export directory.'
}
Remove-Item -LiteralPath $resolvedStaging -Recurse -Force
Write-Output "Web release build ready at $webRoot. Commit the complete generated export together with its source changes."
