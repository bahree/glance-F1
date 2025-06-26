# Glance F1 Integration Guide

This guide explains how to integrate the F1 API service with your existing Glance dashboard.

## Option 1: Add F1 API to Existing Glance Setup

If you already have a `docker-compose.yml` file for Glance, add the F1 API service to it:

### Step 1: Add the F1 API Service

Add this to your existing `docker-compose.yml`:

```yaml
services:
  # Your existing Glance service
  glance:
    # ... your existing glance configuration ...
    depends_on:
      - f1-api  # Add this line
    networks:
      - glance-network  # Add this line (or use your existing network name)

  # Add this new service
  f1-api:
    image: amitbahree/glance-f1:latest
    container_name: f1-api
    ports:
      - "4463:4463"  # Optional: for direct external access
    environment:
      - TIMEZONE=America/Los_Angeles  # Match your timezone
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:4463/f1/next_race/"]
      interval: 30s
      timeout: 10s
      retries: 3
    networks:
      - glance-network  # Use your network name

networks:
  glance-network:  # Add if you don't have a custom network
    driver: bridge
```

### Step 2: Update Your Glance Config

In your Glance configuration file, use these widget URLs:

```yaml
# For widgets in the same docker-compose file
- type: rss
  title: F1 Season Calendar
  url: http://f1-api:4463/f1/races/
  
- type: rss  
  title: F1 Next Race
  url: http://f1-api:4463/f1/next_race/
```

## Option 2: Use Our Complete Setup

Use our provided `docker-compose-combined.yml` file:

### Step 1: Deploy the Complete Stack

```powershell
# Navigate to your project directory
cd c:\src\glance-F1

# Start both services
docker-compose -f docker-compose-combined.yml up -d
```

### Step 2: Copy Widget Files

Copy the F1 widget YAML files to your Glance config directory:

```powershell
# Copy all F1 widgets to your Glance config
Copy-Item "Glance Widgets\*.yml" "path\to\your\glance\config\widgets\"
```

## Docker Networking Explained

### Internal Communication
- **Service Names as Hostnames**: Containers can reach each other using service names
- **F1 API Internal URL**: `http://f1-api:4463/...`
- **No External Dependencies**: Everything works within the Docker network

### External Access
- **Glance Dashboard**: `http://localhost:8080`
- **F1 API Direct**: `http://localhost:4463` (if port is exposed)
- **Health Check**: `http://localhost:4463/f1/next_race/`

### Port Configuration
```yaml
ports:
  - "4463:4463"  # host:container - External access
# Internal access always uses container port (4463)
```

## Environment Variables

### Timezone Synchronization
Make sure both services use the same timezone:

```yaml
glance:
  environment:
    - TZ=America/Los_Angeles

f1-api:
  environment:
    - TIMEZONE=America/Los_Angeles  # Must match Glance TZ
```

### Available Timezones
- `America/Los_Angeles` (PST/PDT)
- `America/New_York` (EST/EDT)
- `Europe/London` (GMT/BST)
- `UTC` (Universal)
- [Full list](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones)

## Troubleshooting

### Service Communication Issues

1. **Check Network Configuration**:
   ```powershell
   docker network ls
   docker network inspect glance-f1_glance-network
   ```

2. **Test Internal Connectivity**:
   ```powershell
   # From within the Glance container
   docker exec glance curl http://f1-api:4463/f1/next_race/
   ```

3. **Check Service Logs**:
   ```powershell
   docker logs f1-api
   docker logs glance
   ```

### Common Issues

| Issue | Solution |
|-------|----------|
| "Connection refused" | Check if F1 API is running: `docker ps` |
| "Name resolution failed" | Ensure both services are on same network |
| "Timeout" | Check healthcheck and restart F1 API |
| Wrong race times | Verify timezone environment variables match |

### Widget URLs

| Widget Type | Internal URL | External URL |
|-------------|-------------|--------------|
| Next Race | `http://f1-api:4463/f1/next_race/` | `http://localhost:4463/f1/next_race/` |
| Season Calendar | `http://f1-api:4463/f1/races/` | `http://localhost:4463/f1/races/` |

## Health Monitoring

The F1 API includes a health check that tests the next race endpoint every 30 seconds:

```yaml
healthcheck:
  test: ["CMD", "curl", "-f", "http://localhost:4463/f1/next_race/"]
  interval: 30s
  timeout: 10s
  retries: 3
```

Monitor health status:
```powershell
docker ps  # Shows health status in STATUS column
```

## Updating the F1 API

To update to a newer version:

```powershell
# Pull latest image
docker pull amitbahree/glance-f1:latest

# Restart the service
docker-compose -f docker-compose-combined.yml up -d f1-api
```

The update will maintain all existing data and configuration.
