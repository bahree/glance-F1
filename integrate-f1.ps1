# Glance F1 Integration Script
# This script helps you add the F1 API service to your existing Glance docker-compose.yml

param(
    [Parameter(Mandatory=$true)]
    [string]$GlanceComposePath,
    
    [string]$NetworkName = "glance-network",
    [string]$Timezone = "America/Los_Angeles"
)

function Write-ColoredText {
    param([string]$Text, [string]$Color = "White")
    Write-Host $Text -ForegroundColor $Color
}

Write-ColoredText "🏎️  Glance F1 Integration Script" "Cyan"
Write-ColoredText "=================================" "Cyan"

# Check if the compose file exists
if (-not (Test-Path $GlanceComposePath)) {
    Write-ColoredText "❌ Error: Glance docker-compose.yml not found at: $GlanceComposePath" "Red"
    exit 1
}

Write-ColoredText "📂 Found Glance compose file: $GlanceComposePath" "Green"

# Read the existing compose file
$composeContent = Get-Content $GlanceComposePath -Raw

# Check if F1 API is already present
if ($composeContent -like "*f1-api*") {
    Write-ColoredText "⚠️  F1 API service already exists in the compose file" "Yellow"
    $response = Read-Host "Do you want to update it? (y/N)"
    if ($response -ne "y" -and $response -ne "Y") {
        Write-ColoredText "❌ Aborted by user" "Red"
        exit 0
    }
}

# F1 API service definition
$f1ApiService = @"

  f1-api:
    image: amitbahree/glance-f1:latest
    container_name: f1-api
    ports:
      - "4463:4463"  # Optional: for direct external access
    environment:
      - TIMEZONE=$Timezone  # Match your timezone
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:4463/f1/next_race/"]
      interval: 30s
      timeout: 10s
      retries: 3
    networks:
      - $NetworkName
"@

# Network definition
$networkDefinition = @"

networks:
  $NetworkName:
    driver: bridge
"@

Write-ColoredText "🔧 Processing compose file..." "Yellow"

# Create backup
$backupPath = $GlanceComposePath + ".backup." + (Get-Date -Format "yyyyMMdd-HHmmss")
Copy-Item $GlanceComposePath $backupPath
Write-ColoredText "💾 Backup created: $backupPath" "Green"

try {
    # Read the compose file as lines for easier manipulation
    $lines = Get-Content $GlanceComposePath
    $newLines = @()
    $inServices = $false
    $servicesIndented = $false
    $addedF1Api = $false
    $hasNetworks = $false
    
    foreach ($line in $lines) {
        # Track if we're in the services section
        if ($line -match "^services:" -or $line -match "^version:") {
            $inServices = $true
        } elseif ($line -match "^networks:") {
            $hasNetworks = $true
            $inServices = $false
        } elseif ($line -match "^[a-zA-Z]" -and $line -notmatch "^\s") {
            $inServices = $false
        }
        
        # Check indentation of services
        if ($inServices -and $line -match "^\s+\w+" -and -not $servicesIndented) {
            $servicesIndented = $true
        }
        
        # Skip existing f1-api service if updating
        if ($line -match "^\s*f1-api:" -or ($line -match "^\s+" -and $addedF1Api -and $line -notmatch "^\s*[a-zA-Z-]+:")) {
            continue
        }
        
        $newLines += $line
        
        # Add F1 API service after the last service
        if ($inServices -and $line -match "^\s*[a-zA-Z-]+:" -and -not $addedF1Api) {
            # This is a service definition, we'll add F1 API after all services
        }
    }
    
    # Add F1 API service at the end of services section
    if (-not $addedF1Api) {
        # Find the last service and add F1 API after it
        $serviceEndIndex = -1
        for ($i = $newLines.Count - 1; $i -ge 0; $i--) {
            if ($newLines[$i] -match "^\s+\w+" -and $newLines[$i] -notmatch "^\s*networks:" -and $newLines[$i] -notmatch "^\s*volumes:") {
                $serviceEndIndex = $i
                break
            }
        }
        
        if ($serviceEndIndex -gt -1) {
            # Find the end of the last service
            $insertIndex = $serviceEndIndex + 1
            while ($insertIndex -lt $newLines.Count -and $newLines[$insertIndex] -match "^\s+" -and $newLines[$insertIndex] -notmatch "^[a-zA-Z]") {
                $insertIndex++
            }
            
            # Insert F1 API service
            $f1ApiLines = $f1ApiService -split "`n"
            for ($i = $f1ApiLines.Count - 1; $i -ge 0; $i--) {
                $newLines = $newLines[0..($insertIndex-1)] + $f1ApiLines[$i] + $newLines[$insertIndex..($newLines.Count-1)]
            }
        } else {
            # If we can't find services, add at the end
            $newLines += $f1ApiService -split "`n"
        }
    }
    
    # Add networks section if it doesn't exist
    if (-not $hasNetworks) {
        $newLines += $networkDefinition -split "`n"
    }
    
    # Write the updated compose file
    $newLines | Out-File $GlanceComposePath -Encoding UTF8
    
    Write-ColoredText "✅ Successfully updated $GlanceComposePath" "Green"
    Write-ColoredText "📋 Added F1 API service with:" "White"
    Write-ColoredText "   - Image: amitbahree/glance-f1:latest" "Gray"
    Write-ColoredText "   - Port: 4463" "Gray"
    Write-ColoredText "   - Network: $NetworkName" "Gray"
    Write-ColoredText "   - Timezone: $Timezone" "Gray"
    
    Write-ColoredText "`n🚀 Next steps:" "Cyan"
    Write-ColoredText "1. Update your Glance config to use: http://f1-api:4463/f1/..." "White"
    Write-ColoredText "2. Run: docker-compose up -d" "White"
    Write-ColoredText "3. Test: http://localhost:4463/f1/next_race/" "White"
    
} catch {
    Write-ColoredText "❌ Error updating compose file: $($_.Exception.Message)" "Red"
    Write-ColoredText "💾 Restoring backup..." "Yellow"
    Copy-Item $backupPath $GlanceComposePath
    Write-ColoredText "✅ Backup restored" "Green"
    exit 1
}

Write-ColoredText "`n✨ Integration complete!" "Green"
