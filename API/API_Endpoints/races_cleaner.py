from fastapi import APIRouter
from fastapi_cache import FastAPICache
from fastapi_cache.backends.inmemory import InMemoryBackend
import httpx
from datetime import datetime, timedelta
import pytz
import os

router = APIRouter()

# Timezone information
TZ = os.environ.get("TIMEZONE").strip()
if TZ not in pytz.all_timezones:
    raise ValueError('Invalid time zone selection')
MT = pytz.timezone(TZ)
UTC = pytz.utc

@router.on_event("startup")
async def startup():
    FastAPICache.init(InMemoryBackend())

# Convert to timezone function
def convert_to_mt(date_str, time_str):
    if not date_str or not time_str:
        return None
    dt_utc = datetime.strptime(f"{date_str}T{time_str}", "%Y-%m-%dT%H:%M:%SZ")
    dt_utc = UTC.localize(dt_utc)
    return dt_utc.astimezone(MT)

def format_race_schedule(schedule):
    """Format race schedule times to local timezone"""
    formatted_schedule = {}
    for session, val in schedule.items():
        if val and val.get("date") and val.get("time"):
            dt_mt = convert_to_mt(val["date"], val["time"])
            formatted_schedule[session] = {
                "date": dt_mt.strftime("%Y-%m-%d"),
                "time": dt_mt.strftime("%I%p").replace('0', ''),
                "datetime_rfc3339": dt_mt.isoformat()
            }
        else:
            formatted_schedule[session] = val
    return formatted_schedule

def process_circuit_data(circuit):
    """Process and clean circuit data"""
    if not circuit:
        return circuit
    
    # Process circuit length
    if "circuitLength" in circuit:
        try:
            raw_length = int(circuit["circuitLength"].replace("km", "").strip())
            circuit["circuitLengthKm"] = raw_length / 1000.0
        except Exception:
            circuit["circuitLengthKm"] = None

    # Format fastest driver name
    fastest_driver_id = circuit.get("fastestLapDriverId")
    if fastest_driver_id:
        name_parts = fastest_driver_id.replace("_", " ").split(" ")
        circuit["fastestLapDriverName"] = name_parts[-1].capitalize()

    # Format lap record time
    fastest_lap_time = circuit.get("lapRecord")
    if fastest_lap_time:
        circuit["lapRecord"] = ".".join(fastest_lap_time.rsplit(":", 1))

    return circuit

def process_race_data(race):
    """Process individual race data"""
    processed_race = race.copy()
    
    # Format schedule
    if "schedule" in processed_race:
        processed_race["schedule"] = format_race_schedule(processed_race["schedule"])
    
    # Process circuit data
    if "circuit" in processed_race:
        processed_race["circuit"] = process_circuit_data(processed_race["circuit"])
    
    # Calculate total distance
    laps = processed_race.get("laps")
    circuit_length = processed_race.get("circuit", {}).get("circuitLengthKm")
    if laps and circuit_length is not None:
        processed_race["totalDistanceKm"] = round(laps * circuit_length, 2)
    else:
        processed_race["totalDistanceKm"] = None
    
    # Determine race status
    now = datetime.utcnow()
    race_date_str = processed_race.get("schedule", {}).get("race", {}).get("date")
    race_time_str = processed_race.get("schedule", {}).get("race", {}).get("time")
    
    if race_date_str and race_time_str:
        try:
            # Parse the formatted time back to check status
            race_dt_local = datetime.fromisoformat(processed_race["schedule"]["race"]["datetime_rfc3339"])
            race_dt_utc = race_dt_local.astimezone(UTC).replace(tzinfo=None)
            
            if race_dt_utc < now:
                processed_race["status"] = "completed"
            elif race_dt_utc.date() == now.date():
                processed_race["status"] = "today"
            else:
                processed_race["status"] = "upcoming"
        except Exception:
            processed_race["status"] = "unknown"
    else:
        processed_race["status"] = "unknown"
    
    return processed_race

@router.get("/", summary="Fetch all races in current season")
async def get_all_races():
    cache = FastAPICache.get_backend()
    cache_key = "f1:all_races"

    cached = await cache.get(cache_key)
    if cached:
        return cached

    async with httpx.AsyncClient() as client:
        try:
            # Get data from current season API
            response = await client.get("https://f1api.dev/api/current")
            if response.status_code != 200:
                return {"error": f"Failed to fetch races data. Status: {response.status_code}"}
            races_data = response.json()
        except Exception as e:
            return {"error": f"Exception while fetching: {e}"}

    # Process all races
    processed_races = []
    races = races_data.get("races", [])
    
    for race in races:
        processed_race = process_race_data(race)
        processed_races.append(processed_race)

    # Sort races by round number
    processed_races = sorted(processed_races, key=lambda r: r.get("round", 0))

    # Cache for 1 hour - races don't change frequently
    expire = 3600
    expiry_dt = datetime.now(MT) + timedelta(hours=1)

    # Output data
    response_data = {
        "season": races_data.get("season"),
        "championship": races_data.get("championship"),
        "timezone": TZ,
        "cache_expires": expiry_dt.isoformat(),
        "total_races": len(processed_races),
        "races": processed_races
    }

    await cache.set(cache_key, response_data, expire=expire)
    return response_data
