# Automated Arduino Dependencies Installer for Smart Plant Care System
# -------------------------------------------------------------------
# Run this script on the client's PC AFTER installing the standard Arduino IDE.
# It bypasses the IDE's GUI to forcefully and reliably download the heavy 
# ESP32 packages and required libraries via the Command Line.

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host " Setting up Arduino Environment for ESP32 " -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan

# Find the bundled arduino-cli inside the Arduino IDE installation
$cliPath = "$env:LOCALAPPDATA\Programs\Arduino IDE\resources\app\lib\backend\resources\arduino-cli.exe"

if (!(Test-Path $cliPath)) {
    Write-Host "[ERROR] Arduino IDE 2.x is not installed or not found at the default location." -ForegroundColor Red
    Write-Host "Please download and install the Arduino IDE from arduino.cc first!" -ForegroundColor Yellow
    Pause
    exit
}

Write-Host "`n[1/3] Configuring ESP32 Board Manager URLs..." -ForegroundColor Yellow
$esp32Url = "https://raw.githubusercontent.com/espressif/arduino-esp32/gh-pages/package_esp32_index.json"

# Update index with the URL
& $cliPath core update-index --additional-urls $esp32Url

Write-Host "`n[2/3] Downloading & Installing ESP32 Core (v2.0.17)..." -ForegroundColor Yellow
Write-Host "This will take a few minutes. Please wait..." -ForegroundColor Gray
# Force install the core (this is the massive download that usually fails in the GUI)
& $cliPath core install esp32:esp32@2.0.17 --additional-urls $esp32Url

if ($LASTEXITCODE -ne 0) {
    Write-Host "`n[ERROR] Failed to install ESP32 Core. Please check your internet connection and run again." -ForegroundColor Red
    Pause
    exit
}

Write-Host "`n[3/3] Installing Required Sensor & WiFi Libraries..." -ForegroundColor Yellow
# Install DHT, Adafruit Unified Sensor (dependency), Firebase, and ArduinoJson
$libraries = @("DHT sensor library", "Adafruit Unified Sensor", "Firebase ESP Client", "ArduinoJson")

foreach ($lib in $libraries) {
    Write-Host "Installing: $lib" -ForegroundColor Gray
    & $cliPath lib install $lib
}

Write-Host "`n==========================================" -ForegroundColor Green
Write-Host " SUCCESS! Environment is 100% Ready!" -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Green
Write-Host "You can now open the Arduino IDE and select 'DOIT ESP32 DEVKIT V1'."
Pause
