import fastf1
import requests
import pandas as pd


request = requests.get("http://192.168.0.159:4463/f1/next_race/")

data = request.json()

country = data['race'][0]['circuit']['country']
year = 2024

# Get session info
session_info_query = 'https://api.openf1.org/v1/sessions?country_name=' + country + '&session_type=Race&year=' + str(year)
session_info = requests.get(session_info_query).json()
session_key = session_info[1]['session_key']


pit_query = 'https://api.openf1.org/v1/pit?session_key=' + str(session_key)

pit_stops = requests.get(pit_query).json()

pit_stops

pit_stops_df = pd.DataFrame.from_dict(pit_stops)

average = pit_stops_df.groupby('driver_number')['pit_duration'].mean()
average = average.sort_values()
average