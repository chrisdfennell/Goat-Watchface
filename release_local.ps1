# Build the release artifacts locally: the store .iq (every product in the
# manifest) plus a side-loadable .prg per panel size.
#
# This exists because the CI container image only ships Connect IQ SDK 9.1.0,
# which does not recognise the newest product IDs in manifest.xml (fr70, fr170,
# fr170m, d2mach2pro). Until CI can install a matching SDK, run this on a
# machine that has one and attach the output to the GitHub release:
#
#     .\release_local.ps1
#     gh release create v1.1.1 (Get-ChildItem release\*).FullName --notes-file ...
#
# Needs build_config.json pointing at your JDK and SDK, and developer_key.der
# in the project root.

param([string]$OutDir = "release")

$ErrorActionPreference = "Stop"

$config = Get-Content (Join-Path $PSScriptRoot "build_config.json") | ConvertFrom-Json
$env:JAVA_HOME = $config.JavaHome
$env:PATH = (Join-Path $config.JavaHome "bin") + ";" + $env:PATH
$monkeyc = Join-Path $config.SdkDir "bin\monkeyc.bat"
$jungle = Join-Path $PSScriptRoot "monkey.jungle"
$key = Join-Path $PSScriptRoot "developer_key.der"

if (!(Test-Path $key)) { throw "developer_key.der not found in the project root." }

$out = Join-Path $PSScriptRoot $OutDir
if (Test-Path $out) { Remove-Item -Recurse -Force $out }
New-Item -ItemType Directory -Path $out | Out-Null

# One .prg per distinct panel size the face targets.
$devices = @(
    "fenix847mm",      # AMOLED 454
    "fenix843mm",      # AMOLED 416
    "fr165",           # AMOLED 390
    "fr265s",          # AMOLED 360
    "fenix8solar51mm", # MIP 280
    "fenix8solar47mm", # MIP 260
    "fenix7s",         # MIP 240
    "fr255s",          # MIP 218
    "fr965"            # AMOLED 454
)

Write-Host "Packaging store .iq (every product in the manifest)..." -ForegroundColor Cyan
& $monkeyc -e -f $jungle -y $key -o (Join-Path $out "GoatFace.iq")
if ($LASTEXITCODE -ne 0) { throw "store package failed ($LASTEXITCODE)" }

foreach ($d in $devices) {
    Write-Host "Compiling .prg for $d..." -ForegroundColor Cyan
    & $monkeyc -f $jungle -y $key -o (Join-Path $out "GoatFace_$d.prg") -d $d
    if ($LASTEXITCODE -ne 0) { throw "$d failed ($LASTEXITCODE)" }
}

Write-Host ""
Get-ChildItem $out | Select-Object Name, @{n = "KB"; e = { [math]::Round($_.Length / 1KB) } }
Write-Host "`nArtifacts in $out" -ForegroundColor Green
