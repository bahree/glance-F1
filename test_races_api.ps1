# F1 Races API Test Script
Write-Host "Testing F1 Races API..." -ForegroundColor Green

try {
    $response = Invoke-RestMethod -Uri "http://localhost:4463/f1/races/" -Method Get
    
    Write-Host "`n=== API Summary ===" -ForegroundColor Yellow
    Write-Host "Season: $($response.season)"
    Write-Host "Total Races: $($response.total_races)"
    Write-Host "Timezone: $($response.timezone)"
    Write-Host "Cache Expires: $($response.cache_expires)"
    
    Write-Host "`n=== Race Status Summary ===" -ForegroundColor Yellow
    $completed = ($response.races | Where-Object {$_.status -eq "completed"}).Count
    $upcoming = ($response.races | Where-Object {$_.status -eq "upcoming"}).Count
    $today = ($response.races | Where-Object {$_.status -eq "today"}).Count
    
    Write-Host "Completed: $completed"
    Write-Host "Upcoming: $upcoming"
    Write-Host "Today: $today"
    
    Write-Host "`n=== Recent/Upcoming Races ===" -ForegroundColor Yellow
    $response.races | ForEach-Object {
        $statusEmoji = switch ($_.status) {
            "completed" { "✅" }
            "today" { "🏁" }
            "upcoming" { "📅" }
            default { "❓" }
        }
        
        $winner = if ($_.winner.surname) { " - Winner: $($_.winner.name) $($_.winner.surname)" } else { "" }
        Write-Host "$statusEmoji Round $($_.round): $($_.raceName) ($($_.schedule.race.date))$winner"
    }
    
    Write-Host "`n=== Circuit Details Sample ===" -ForegroundColor Yellow
    $sampleRace = $response.races | Select-Object -First 1
    Write-Host "Sample Race: $($sampleRace.raceName)"
    Write-Host "Circuit: $($sampleRace.circuit.circuitName)"
    Write-Host "Length: $($sampleRace.circuit.circuitLengthKm) km"
    Write-Host "Laps: $($sampleRace.laps)"
    Write-Host "Total Distance: $($sampleRace.totalDistanceKm) km"
    Write-Host "Lap Record: $($sampleRace.circuit.lapRecord) by $($sampleRace.circuit.fastestLapDriverName)"
    
} catch {
    Write-Host "Error testing API: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`nTest completed!" -ForegroundColor Green
