# Background
I host [glance](https://github.com/glanceapp/glance) on one of my home servers, Timothy. All my devices use a custom glance config as their default browser and new tab pages.

As a big F1 fan, I was excited to see that the community had added a [F1 integration](https://github.com/glanceapp/community-widgets/blob/main/widgets/formula1-widgets-by-abaza738/README.md).

# Problem
However, I had several issues with this integration.
1. Times were shown in UTC, not specific to a users timezone.
2. API calls were slowing down my Glance integration.
3. Lack of control over data fields like team name. It shows lengthy official team names like "Mercedes AMG Petronas F1 Team" instead of just "Mercedes"
4. Lacking detail. For instance, I wanted a track map, lap record holder, previous winners when it displayed the next race.
5. Lack of dynamic control over event time. While you can select what event to have a countdown to (IE race vs. qualifying), you have to manually specify this instead of using time analysis to show the next event that hasn't passed.

# Solution
## APIs
As a solution, I created 4 API endpoints that allow me full control over what I fetch, as well as caching behaviour. Across each endpoint, I utilize smart caching that only refreshes the underlying API data a few hours after the race is over, preventing unnecessary loading when results have not changed.

The 4 end points are:
1. Next race. This features details such as circuit name, lap record holder, and countdown to the race.
2. Driver championship. This cleans up the naming of each driver and adds a nice nationality flag for each driver.
3. Constructors championship. Cleans up team names to a simplified form and adds home country flag for each team.
4. Track map. This generates an SVG of the current track. It relies on positioning data from a prior years event at the same track.

## Widgets
I really enjoyed the theme and style of the community widgets, so I largely use their theming and design, I just change the underlying API to achieve more custom results.

# Demo
My current F1 Glance set up is shown below. 
<br>
![F1 API](https://github.com/user-attachments/assets/f904c6f8-4e0c-4e29-8513-8bd535c5117b)

