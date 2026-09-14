from datetime import datetime, timedelta
import math
from skyfield.api import load
from skyfield.framelib import ecliptic_frame

_ts = load.timescale()
_eph = load('de421.bsp')
_sun = _eph['sun']
_earth = _eph['earth']

def get_sun_lon(t):
    astrometric = _earth.at(t).observe(_sun)
    lat, lon, distance = astrometric.apparent().frame_latlon(ecliptic_frame)
    return lon.degrees

# binary search Mang Chung (75 deg)
t0 = _ts.utc(2026, 6, 1)
t1 = _ts.utc(2026, 6, 10)

def f(t):
    return (get_sun_lon(t) - 75.0 + 180) % 360 - 180

# binary search
low = t0
high = t1
for _ in range(50):
    mid_jd = (low.tt + high.tt) / 2
    mid = _ts.tt_jd(mid_jd)
    if f(mid) < 0:
        low = mid
    else:
        high = mid

mid_utc = mid.utc_datetime()
local_time = mid_utc + timedelta(hours=7)
print("Skyfield Apparent Mang Chung:", local_time.strftime('%H:%M %d/%m/%Y'))

def get_sun_lon_true(t):
    astrometric = _earth.at(t).observe(_sun)
    # Using true (astrometric) rather than apparent (which includes aberration)
    lat, lon, distance = astrometric.frame_latlon(ecliptic_frame)
    return lon.degrees

low = t0
high = t1
for _ in range(50):
    mid_jd = (low.tt + high.tt) / 2
    mid = _ts.tt_jd(mid_jd)
    if (get_sun_lon_true(mid) - 75.0 + 180) % 360 - 180 < 0:
        low = mid
    else:
        high = mid

mid_utc = mid.utc_datetime()
local_time = mid_utc + timedelta(hours=7)
print("Skyfield True Mang Chung:", local_time.strftime('%H:%M %d/%m/%Y'))
