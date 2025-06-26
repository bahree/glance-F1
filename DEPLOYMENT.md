# F1 API Deployment Instructions

## Your Docker Hub Image
Your F1 API is now available at: https://hub.docker.com/r/amitbahree/glance-f1

## Quick Deployment on Your Glance Machine

### Option 1: Using Docker Run
```bash
# Pull the latest image
docker pull amitbahree/glance-f1:latest

# Stop existing container if running
docker stop f1-api 2>/dev/null || true
docker rm f1-api 2>/dev/null || true

# Run the new container
docker run -d \
  --name f1-api \
  -p 4463:4463 \
  -e TIMEZONE=America/New_York \
  --restart unless-stopped \
  amitbahree/glance-f1:latest
```

### Option 2: Using Docker Compose
1. Copy the `docker-compose.example.yml` to your Glance machine as `docker-compose.yml`
2. Run: `docker-compose pull f1-api && docker-compose up -d f1-api`

## Testing the Deployment

```bash
# Test the APIs
curl http://localhost:4463/f1/next_race/
curl http://localhost:4463/f1/races/

# Check container status
docker ps | grep f1-api
docker logs f1-api
```

## API Endpoints Available

- `/f1/next_race/` - Next upcoming race information
- `/f1/races/` - All races in current season (NEW!)
- `/f1/constructors_standings/` - Constructor championship standings
- `/f1/drivers_standings/` - Driver championship standings
- `/f1/next_map/` - Race circuit map

## Glance Widget Configuration

Add this to your `glance.yml` to use the new races API:

```yaml
- type: custom-api
  title: F1 2025 Season Calendar
  cache: 1h
  url: http://f1-api:4463/f1/races/
  template: |
    <div class="flex flex-column gap-4">
      {{ range .JSON.Array "races" }}
        <div class="flex justify-between align-center padding-4 rounded 
          {{ if eq (.String "status") "completed" }}bg-green-subtle{{ else if eq (.String "status") "today" }}bg-yellow-subtle{{ else }}bg-primary-subtle{{ end }}">
          
          <div>
            <p class="size-h6 color-highlight">
              R{{ .String "round" }}: {{ .String "raceName" }}
            </p>
            <p class="size-h7 color-primary">
              {{ .String "schedule.race.date" }} - {{ .String "circuit.country" }}
            </p>
          </div>
          
          <div class="text-right">
            {{ if .String "winner.surname" }}
              <p class="size-h7 color-green">🏆 {{ .String "winner.surname" }}</p>
            {{ else }}
              {{ $datetime := .String "schedule.race.datetime_rfc3339" }}
              <p class="size-h7" {{ parseRelativeTime "rfc3339" $datetime }}></p>
            {{ end }}
          </div>
          
        </div>
      {{ end }}
    </div>
```

## Environment Variables

- `TIMEZONE`: Set your preferred timezone (default: America/New_York)

## Health Check

The container includes a health check that pings the next_race endpoint every 30 seconds.

## Updates

To update to a new version:
```bash
docker pull amitbahree/glance-f1:latest
docker-compose up -d f1-api  # or restart with docker run
```
