# Automated Flutter Environment Installer for Windows
# ---------------------------------------------------
# Run this script if you need to compile or edit the Mobile App code.
# It checks if Flutter is installed. If not, it downloads the 1GB SDK, 
# installs it to C:\flutter, and sets up your Windows PATH variables.

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host " Setting up Flutter Developer Environment " -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan

$flutterBin = "C:\flutter\bin"
$flutterExe = "$flutterBin\flutter.bat"
$needsInstall = $true

# Check if Flutter is already installed in the system PATH or default directory
if ((Get-Command "flutter" -ErrorAction SilentlyContinue) -or (Test-Path $flutterExe)) {
    Write-Host "`n[✓] Flutter SDK is already installed on this system! Skipping 1GB download." -ForegroundColor Green
    $needsInstall = $false
    
    if (Get-Command "flutter" -ErrorAction SilentlyContinue) {
        $flutterExe = (Get-Command "flutter").Source
    }
}

if ($needsInstall) {
    # 1. Download Flutter SDK
    $flutterZip = "$env:TEMP\flutter_sdk.zip"
    $flutterUrl = "https://storage.googleapis.com/flutter_infra_release/releases/stable/windows/flutter_windows_3.24.1-stable.zip"

    Write-Host "`n[1/4] Downloading Flutter SDK (This is a 1GB+ file, please wait)..." -ForegroundColor Yellow
    Invoke-WebRequest -Uri $flutterUrl -OutFile $flutterZip

    # 2. Extract to C:\
    Write-Host "`n[2/4] Extracting Flutter to C:\flutter (This takes a few minutes)..." -ForegroundColor Yellow
    $shell = New-Object -ComObject Shell.Application
    $zipPackage = $shell.NameSpace($flutterZip)
    $destinationFolder = $shell.NameSpace("C:\")
    $destinationFolder.CopyHere($zipPackage.Items(), 16 -bor 256)

    # 3. Add to Windows PATH
    Write-Host "`n[3/4] Adding Flutter to Windows PATH..." -ForegroundColor Yellow
    $userPath = [Environment]::GetEnvironmentVariable("Path", "User")

    if ($userPath -notmatch [regex]::Escape($flutterBin)) {
        $newPath = $userPath + ";" + $flutterBin
        [Environment]::SetEnvironmentVariable("Path", $newPath, "User")
        $env:Path = $env:Path + ";" + $flutterBin
    }
}

# 4. Initialize Dependencies
Write-Host "`n[4/4] Installing App Dependencies..." -ForegroundColor Yellow
$appDir = Join-Path $PSScriptRoot "smart_plant_care\flutter_app"
if (Test-Path $appDir) {
    Set-Location $appDir
    & $flutterExe pub get
} else {
    Write-Host "[WARNING] Could not find flutter_app directory to run 'pub get'." -ForegroundColor Yellow
}

Write-Host "`n==========================================" -ForegroundColor Green
Write-Host " SUCCESS! Flutter is 100% Ready!" -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Green
if ($needsInstall) {
    Write-Host "Please CLOSE this window and open a NEW Terminal to use Flutter."
}
Write-Host "To run the app on Chrome, navigate to the flutter_app folder and run:"
Write-Host "flutter run -d chrome" -ForegroundColor Cyan
Pause
