$url = "https://smart-plant-care-342d6-default-rtdb.asia-southeast1.firebasedatabase.app/plants/plant1/sensorData.json"

Write-Host "Starting Virtual ESP32 Hardware Simulator..."
Write-Host "Pushing data to Firebase every 5 seconds. Press Ctrl+C to stop."
Write-Host "--------------------------------------------------------"

while ($true) {
    # Generate realistic dummy sensor data
    $soil = Get-Random -Minimum 30 -Maximum 85
    $light = Get-Random -Minimum 40 -Maximum 95
    $temp = 22.0 + (Get-Random -Minimum 0 -Maximum 100) / 10.0
    $hum = 45.0 + (Get-Random -Minimum 0 -Maximum 300) / 10.0

    $body = @{
        soilMoisture = $soil
        light = $light
        temperature = $temp
        humidity = $hum
        timestamp = [int][double]::Parse((Get-Date (Get-Date).ToUniversalTime() -UFormat %s))
    } | ConvertTo-Json

    try {
        $response = Invoke-RestMethod -Uri $url -Method Put -Body $body -ContentType "application/json"
        Write-Host "✅ Sent -> Temp: $temp °C | Humidity: $hum % | Soil: $soil % | Light: $light %"
    } catch {
        Write-Host "❌ Failed to send data. Is Firebase accessible?"
    }

    Start-Sleep -Seconds 5
}
