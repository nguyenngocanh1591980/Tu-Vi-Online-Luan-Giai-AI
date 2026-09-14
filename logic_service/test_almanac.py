from skyfield import almanac
from skyfield.api import load
from datetime import timedelta
import pytz

ts = load.timescale()
eph = load('de421.bsp')
t0 = ts.utc(2026, 1, 1)
t1 = ts.utc(2026, 12, 31)
t, y = almanac.find_discrete(t0, t1, almanac.seasons(eph))
for ti, yi in zip(t, y):
    print(almanac.SEASON_EVENTS[yi], ti.utc_datetime() + timedelta(hours=7))

# For 24 solar terms, we can write a custom discrete function:
def solar_terms(ephemeris):
    earth, sun = ephemeris['earth'], ephemeris['sun']
    def function(t):
        e = earth.at(t)
        lat, lon, dist = e.observe(sun).apparent().ecliptic_latlon()
        return (lon.degrees // 15) % 24
    function.step_days = 15.0
    return function

t, y = almanac.find_discrete(t0, t1, solar_terms(eph))
for ti, yi in zip(t, y):
    if yi * 15 == 75:
        print("Skyfield almanac Mang Chung:", ti.utc_datetime() + timedelta(hours=7))
