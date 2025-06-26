<div align="center">
  
# The F1 Season... At A Glance

![README](https://img.shields.io/badge/Actively%20Mainted-Yes)
![README](https://img.shields.io/github/v/release/skyallinott/glance-f1)
![README](https://img.shields.io/docker/pulls/skyallinott/f1_api)
![README](https://img.shields.io/github/issues/skyallinott/glance-f1)


![README](https://img.shields.io/github/commit-activity/w/skyallinott/glance-f1)
![README](https://img.shields.io/github/commits-since/skyallinott/glance-f1/latest)
![README](https://img.shields.io/github/commits-difference/skyallinott/glance-f1?base=master&head=development&label=Development%20Commits%20Not%20Merged%20Into%20Main)

___

<h3>

[Background](#background) • [Why Use This Repo?](#why-use-this-repo) • [Solution](#solution)
<br>
[Installation](#installation) • [Demo](#demo)

</h3>

</div>

# Background
I host [glance](https://github.com/glanceapp/glance) on one of my home servers. As a big F1 fan, I was excited to see that the community had added a [F1 integration](https://github.com/glanceapp/community-widgets/blob/main/widgets/formula1-widgets-by-abaza738/README.md), but was disappointed with the rigidity of the API it uses. 

# Why Use this Repo?
I ran into the following issues with the API that this repository solves:

1. Times were shown in UTC, not specific to a users timezone.
2. API calls were slow and there was no smart caching, slowing down my Glance.
3. Lack of control over data fields like team name. It shows lengthy official team names like "Mercedes AMG Petronas F1 Team" instead of just "Mercedes"
4. Lacking detail. For instance, I wanted a track map, lap record holder, previous winners when it displayed the next race.
5. Lack of dynamic control over event time. While you can select what event to have a countdown to (IE race vs. qualifying), you have to manually specify this instead of using time analysis to show the next event that hasn't passed.

# Solution
## APIs
As a solution, I created 4 API endpoints that allow me full control over what I fetch, as well as caching behavior. Across each endpoint, I utilize smart caching that only refreshes the underlying API data a few hours after the race is over, preventing unnecessary loading when results have not changed.

The 4 endpoints are:
1. **Next race** (`/f1/next_race/`). This features details such as circuit name, lap record holder, and countdown to the race.
2. **Driver championship** (`/f1/drivers/`). This cleans up the naming of each driver and adds a nice nationality flag for each driver.
3. **Constructors championship** (`/f1/constructors/`). Cleans up team names to a simplified form and adds home country flag for each team.
4. **Track map** (`/f1/next_map/`). This generates an SVG of the current track using FastF1 telemetry data. It includes intelligent fallback to previous year's data when current season data isn't available.
5. **All races** (`/f1/races/`). Returns the complete race calendar with detailed scheduling information.

### New Features in v1.2
- **Fixed Track Map Generation**: The `/f1/next_map/` endpoint now works reliably with proper error handling
- **Intelligent Year Fallback**: When current season data isn't available (e.g., 2025), automatically falls back to previous year's track data
- **PST Timezone Default**: All times now default to Pacific Standard Time (America/Los_Angeles)
- **Enhanced Error Handling**: Better error messages and graceful degradation when FastF1 data is unavailable

## Widgets
I really enjoyed the theme and style of the community widgets by @abaza738, so I largely use their theming and design, I just change the underlying API to achieve more custom results.

# Installation

## Quick Start (Recommended)
This repo uses Docker to run. Below is an example compose file using the published image:

```yaml
version: "3.9"

services:
  f1_api:
    container_name: f1_api
    image: amitbahree/glance-f1:latest
    environment:
      - TIMEZONE=America/Los_Angeles # Specify your timezone (defaults to PST)
      - TRACK_COLOUR=#e5d486 # Specify desired track map color
      - EVENT_DETAIL=main # Optional. main tracks qualis and races (inc. sprints), race tracks races only
    ports:
      - 4463:4463
    restart: unless-stopped
```

## Environment Variables
- **TIMEZONE**: Your local timezone (defaults to `America/Los_Angeles`)
- **TRACK_COLOUR**: Hex color for track maps (defaults to `#e10600`)
- **EVENT_DETAIL**: Event tracking mode - `main` for all events, `race` for races only (defaults to `main`)

## Widget Integration
To integrate with your glance setup (to install glance, see their documentation), add the provided widget YAML files to your glance config:
- `f1_next_race.yml`
- `f1_drivers_championship.yml` 
- `f1_constructors_championship.yml`
- `f1_upcoming_races.yml`

Make sure to replace `{LOCAL_IP}` with your device's IP address and update ports if needed.

# Local Development & Publishing

## Building Locally
If you want to build and customize the image yourself:

### Prerequisites
- Docker installed on your machine
- Git for cloning the repository

### Build Steps
1. **Clone the repository**:
   ```bash
   git clone https://github.com/your-repo/glance-f1.git
   cd glance-f1
   ```

2. **Build the Docker image**:
   ```bash
   docker build -t glance-f1:latest ./API
   ```

3. **Run locally for testing**:
   ```bash
   docker run -d -p 4463:4463 \
     -e TIMEZONE="Your/Timezone" \
     -e TRACK_COLOUR="#your_color" \
     --name f1-api \
     glance-f1:latest
   ```

4. **Test the endpoints**:
   ```bash
   curl http://localhost:4463/f1/next_race/
   curl http://localhost:4463/f1/next_map/
   curl http://localhost:4463/f1/drivers/
   curl http://localhost:4463/f1/constructors/
   curl http://localhost:4463/f1/races/
   ```

## Publishing to Registry
To publish your customized image to Docker Hub or another registry:

### Docker Hub Publishing
1. **Tag your image**:
   ```bash
   docker tag glance-f1:latest your-dockerhub-username/glance-f1:latest
   docker tag glance-f1:latest your-dockerhub-username/glance-f1:v1.2
   ```

2. **Login to Docker Hub**:
   ```bash
   docker login
   ```

3. **Push to registry**:
   ```bash
   docker push your-dockerhub-username/glance-f1:latest
   docker push your-dockerhub-username/glance-f1:v1.2
   ```

### Using on Another Machine
Once published, you can pull and run on any machine:
```bash
docker pull your-dockerhub-username/glance-f1:latest
docker run -d -p 4463:4463 --name f1-api your-dockerhub-username/glance-f1:latest
```

## Project Structure
```
glance-F1/
├── API/
│   ├── main.py                    # FastAPI application entry point
│   ├── requirements.txt           # Python dependencies
│   ├── Dockerfile                 # Container build instructions
│   └── API_Endpoints/
│       ├── constructors_cleaner.py
│       ├── current_race_cleaner.py
│       ├── drivers_cleaner.py
│       └── map/
│           ├── map_generator.py   # Track SVG generation
│           └── router.py          # Map endpoint logic
├── Glance Widgets/               # YAML files for Glance integration
└── docker-compose.yaml          # Local development compose file
``` 


# Demo
On the left below is a possible configuration using this custom API. On the right is a configuration using the default API used in the community widget.

The key improvements include:
- **Localized time zones** - All times shown in your preferred timezone
- **Interactive track maps** - SVG track layouts with proper fallback handling
- **Enhanced track details** - Lap records, circuit information, and previous race data
- **Clean championship displays** - Simplified team/driver names with country flags
- **Smart caching** - Efficient data loading that respects F1 weekend schedules

## API Endpoints Overview
- `GET /f1/next_race/` - Next race information with countdown and circuit details
- `GET /f1/next_map/` - SVG track map for the next race circuit  
- `GET /f1/drivers/` - Current driver championship standings
- `GET /f1/constructors/` - Current constructor championship standings
- `GET /f1/races/` - Complete race calendar with scheduling information

<div align="center" >
  <img src="./Demo Images/glance-f1.png" width="225px" height = "600px" hspace="20px" />
  <img src="./Demo Images/community-f1.png" width="225px" height = "600px" hspace="20px" />
</div>

# Troubleshooting

## Common Issues

### Track Map Returns 500 Error
- **Issue**: The `/f1/next_map/` endpoint returns a 500 Internal Server Error
- **Cause**: FastF1 data might not be available for the current season
- **Solution**: The API automatically falls back to previous year's data. If still failing, check container logs:
  ```bash
  docker logs f1_api
  ```

### Times Showing in Wrong Timezone
- **Issue**: Race times appear in UTC instead of your local timezone
- **Solution**: Set the `TIMEZONE` environment variable:
  ```yaml
  environment:
    - TIMEZONE=America/Los_Angeles  # Replace with your timezone
  ```
- **Valid timezones**: Use standard timezone names from the [IANA Time Zone Database](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones)

### Container Won't Start
- **Issue**: Docker container fails to start
- **Solution**: Check if port 4463 is already in use:
  ```bash
  # Windows
  netstat -an | findstr :4463
  
  # Linux/Mac
  lsof -i :4463
  ```

### Empty Championship Data
- **Issue**: Driver/Constructor endpoints return empty data
- **Expected**: This is normal for future seasons where championship data isn't available yet

## Getting Help
- Check container logs: `docker logs f1_api`
- Verify all endpoints: 
  ```bash
  curl http://localhost:4463/f1/next_race/
  curl http://localhost:4463/f1/next_map/
  ```
- Create an issue in the GitHub repository with logs and error details

# Contributing
Contributions are welcome! Please feel free to submit issues, feature requests, or pull requests.

## Development Setup
1. Clone the repository
2. Make your changes to the code
3. Test locally using the build instructions above
4. Submit a pull request with a clear description of changes

## License
This project is open source. Please respect the terms of use for the underlying F1 data APIs.
