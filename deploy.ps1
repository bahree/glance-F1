# F1 API Deployment Script for Docker Hub
# Replace 'amitbahree' with your actual Docker Hub username if different

param(
    [string]$DockerHubUsername = "amitbahree",
    [string]$Tag = "latest"
)

$imageName = "$DockerHubUsername/glance-f1"
$fullTag = "$imageName`:$Tag"

Write-Host "Building F1 API Docker image..." -ForegroundColor Green

# Build the image
docker build -t $fullTag .
if ($LASTEXITCODE -ne 0) {
    Write-Host "Docker build failed!" -ForegroundColor Red
    exit 1
}

Write-Host "Docker image built successfully: $fullTag" -ForegroundColor Green

# Login to Docker Hub
Write-Host "Logging into Docker Hub..." -ForegroundColor Green
docker login -u $DockerHubUsername

if ($LASTEXITCODE -ne 0) {
    Write-Host "Login failed!" -ForegroundColor Red
    exit 1
}

# Push the image
Write-Host "Pushing image to Docker Hub..." -ForegroundColor Green
docker push $fullTag

if ($LASTEXITCODE -ne 0) {
    Write-Host "Push failed!" -ForegroundColor Red
    exit 1
}

Write-Host "Successfully pushed $fullTag" -ForegroundColor Green

# Also tag and push as 'latest' if not already latest
if ($Tag -ne "latest") {
    $latestTag = "$imageName`:latest"
    docker tag $fullTag $latestTag
    docker push $latestTag
    Write-Host "Also pushed as: $latestTag" -ForegroundColor Green
}

Write-Host "`nDeployment complete! Your image is available at:" -ForegroundColor Yellow
Write-Host "https://hub.docker.com/r/$imageName" -ForegroundColor Cyan

Write-Host "`nTo deploy on your Glance machine:" -ForegroundColor Yellow
Write-Host "docker pull $fullTag" -ForegroundColor Cyan
Write-Host "docker run -d -p 4463:4463 -e TIMEZONE=America/New_York --name f1-api $fullTag" -ForegroundColor Cyan

Write-Host "`nOr update your docker-compose.yml with:" -ForegroundColor Yellow
Write-Host "image: $fullTag" -ForegroundColor Cyan
