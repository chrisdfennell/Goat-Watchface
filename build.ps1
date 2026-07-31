param(
    # Default to the 454x454 AMOLED product. Use -Device fenix843mm to
    # build/preview the 416x416 variant, fr255 for a 260x260 MIP check, etc.
    [string]$Device = "fenix847mm",
    [switch]$Run,
    [switch]$Export
)

# Load local build configuration or create default if missing
$configFile = Join-Path $PSScriptRoot "build_config.json"
if (Test-Path $configFile) {
    $config = Get-Content $configFile | ConvertFrom-Json
    $JavaHome = $config.JavaHome
    $SdkDir = $config.SdkDir
} else {
    $JavaHome = "C:\Program Files\Android\openjdk\jdk-21.0.8"
    $SdkDir = "C:\Users\christopher.fennell\AppData\Roaming\Garmin\ConnectIQ\Sdks\connectiq-sdk-win-9.1.0-2026-03-09-6a872a80b"
    $configObj = [ordered]@{
        JavaHome = $JavaHome
        SdkDir = $SdkDir
    }
    $configObj | ConvertTo-Json | Out-File -Encoding utf8 $configFile
}

# 1. Setup Java Environment
$env:JAVA_HOME = $JavaHome
$env:PATH = (Join-Path $JavaHome "bin") + ";" + $env:PATH

# 2. Define Garmin SDK Paths
$sdkBin = Join-Path $SdkDir "bin"

# 3. Create output directory if it doesn't exist
if (!(Test-Path -Path "bin")) {
    New-Item -ItemType Directory -Path "bin" | Out-Null
}

# 4. Build the project
$monkeyc = Join-Path $sdkBin "monkeyc.bat"
$junglePath = Join-Path $PSScriptRoot "monkey.jungle"
$keyPath = Join-Path $PSScriptRoot "developer_key.der"

if ($Export) {
    Write-Host "Packaging application for Connect IQ Store (.iq)..." -ForegroundColor Cyan
    $outputPath = Join-Path $PSScriptRoot "bin\GoatFace.iq"
    & $monkeyc -e -f $junglePath -o $outputPath -y $keyPath
} else {
    Write-Host "Building for device: $Device..." -ForegroundColor Cyan
    $outputPath = Join-Path $PSScriptRoot "bin\GoatFace.prg"
    & $monkeyc -f $junglePath -o $outputPath -y $keyPath -d $Device
}

if ($LASTEXITCODE -ne 0) {
    Write-Error "Compilation failed with exit code $LASTEXITCODE."
    exit $LASTEXITCODE
}

if ($Export) {
    Write-Host "Package Succeeded! Output: bin\GoatFace.iq" -ForegroundColor Green
} else {
    Write-Host "Build Succeeded! Output: bin\GoatFace.prg" -ForegroundColor Green
}

# 5. Launch in Simulator if requested
if ($Run) {
    Write-Host "Checking if Simulator is running..." -ForegroundColor Cyan
    $simProcess = Get-Process -Name "simulator" -ErrorAction SilentlyContinue
    if (!$simProcess) {
        Write-Host "Starting Connect IQ Simulator..." -ForegroundColor Cyan
        $simulator = Join-Path $sdkBin "simulator.exe"
        Start-Process -FilePath $simulator
        Start-Sleep -Seconds 4 # Give it a moment to boot
    } else {
        Write-Host "Simulator is already running." -ForegroundColor Cyan
    }

    Write-Host "Deploying to $Device in simulator..." -ForegroundColor Cyan
    $monkeydo = Join-Path $sdkBin "monkeydo.bat"
    & $monkeydo $outputPath $Device
}
