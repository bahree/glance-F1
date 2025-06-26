from fastapi import APIRouter, Response
from fastapi.responses import PlainTextResponse, StreamingResponse
import httpx
import io
from datetime import datetime, timedelta
import pytz
import os

from fastapi_cache import FastAPICache
from fastapi_cache.backends.inmemory import InMemoryBackend
from .map_generator import generate_track_map_svg

router = APIRouter()

# Use our internal API endpoint instead of external API
NEXT_RACE_API_URL = "http://localhost:4463/f1/next_race/"

TZ = os.environ.get("TIMEZONE").strip()
if TZ not in pytz.all_timezones:
    raise ValueError('Invalid time zone selection')
MT = pytz.timezone(TZ)

@router.on_event("startup")
# Initialize caching
async def startup():
    FastAPICache.init(InMemoryBackend())

async def get_next_race_end():
    async with httpx.AsyncClient() as client:
        try:
            # Use our internal next race API to fetch race time for smart caching
            r = await client.get(NEXT_RACE_API_URL)
            r.raise_for_status()
            data = r.json()
            
            # Extract race time from our internal API response format
            race_data = data.get("race", [])
            if race_data:
                race_dt_str = race_data[0].get("schedule", {}).get("race", {}).get("datetime_rfc3339")
                if race_dt_str:
                    race_dt = datetime.fromisoformat(race_dt_str)
                    race_dt = race_dt.astimezone(MT)
                    return race_dt
        except Exception as e:
            print("Error fetching race time:", e)
            print("Used URL:", NEXT_RACE_API_URL)
    return None

@router.get("/", summary="Fetch next track map")
async def get_dynamic_track_map():
    cache_key = "track_map_svg"
    cache = FastAPICache.get_backend()

    # Try cached version
    svg_content = await cache.get(cache_key)
    if svg_content:
        return Response(content=svg_content, media_type="image/svg+xml")

    async with httpx.AsyncClient() as client:
        try:
            resp = await client.get(NEXT_RACE_API_URL)
            resp.raise_for_status()
        except Exception as e:
            print("Fetch error:", e)
            print("URL:", NEXT_RACE_API_URL)
            return PlainTextResponse(f"Failed to fetch race info: {str(e)}", status_code=502)
        

    try:
        data = resp.json()
        race_data = data.get("race", [])
        if not race_data:
            raise ValueError("No race data found in API response")
        
        # Get the next race data from our internal API
        next_race = race_data[0]  # Our API returns the next race as first item
        
        year = int(data.get("season", 2024))
        circuit = next_race.get("circuit", {})
        country = circuit.get("country", "")
        city = circuit.get("city", "")
        gp = f"{city} {country}".strip()
        race_dt_str = next_race.get("schedule", {}).get("race", {}).get("datetime_rfc3339")

        if not gp or not race_dt_str:
            raise ValueError("Missing circuit info or race time in API response")

        # Cache logic.
        # Doesn't use same logic as current/drivers/constructors due to not needing to
        # reload the track map between weekend events 
        try:
            if race_dt_str:
                race_dt = datetime.fromisoformat(race_dt_str).astimezone(MT)

                # Expire 4 hours after race time
                expire = int((race_dt + timedelta(hours=4) - datetime.now(MT)).total_seconds())
            else:
                expire = 3600 # Fall back in case cache expired, shouldn't raise but yeah.
        except Exception as e:
            print("Cache expiry fallback due to error:", e)
            expire = 3600  # fallback: 1 hour if can't fetch next race data

        print(f"Cache expired: Fetching track map for {gp} {year}")
        try:
            svg_content = generate_track_map_svg(year, gp, circuit.get("circuitName", "Unknown Circuit"), "Q")
        except Exception as e:
            print(f"Map generation error for {year}: {str(e)}")
            # Fallback to previous year if current year data doesn't exist (common for future seasons)
            if year > 2024:
                print(f"Trying fallback year {year-1} for {gp}")
                try:
                    svg_content = generate_track_map_svg(year-1, gp, circuit.get("circuitName", "Unknown Circuit"), "Q")
                except Exception as fallback_e:
                    print(f"Fallback map generation error: {str(fallback_e)}")
                    return PlainTextResponse(f"Could not generate track map for {year} or {year-1}: {str(e)} / {str(fallback_e)}", status_code=500)
            else:
                return PlainTextResponse(f"Could not generate track map: {str(e)}", status_code=500)
        svg_bytes = svg_content.encode("utf-8")
        await cache.set(cache_key, svg_content, expire=expire)

        return StreamingResponse(io.BytesIO(svg_bytes), media_type="image/svg+xml")

    except Exception as e:
        return PlainTextResponse(f"Failed to generate SVG: {str(e)}", status_code=500)
