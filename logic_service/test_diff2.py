from datetime import datetime, timedelta
import math
from skyfield.api import load
from skyfield.framelib import ecliptic_frame

_ts = load.timescale()
_eph = load('de421.bsp')
_sun = _eph['sun']
_earth = _eph['earth']

# Mang Chung 2026 should be 2026-06-05 22:37 UTC+7
dt = datetime(2026, 6, 5, 22, 37) - timedelta(hours=7)
t = _ts.utc(dt.year, dt.month, dt.day, dt.hour, dt.minute, dt.second)

# True
print("True:", _earth.at(t).observe(_sun).frame_latlon(ecliptic_frame)[1].degrees)
# Apparent
print("Apparent:", _earth.at(t).observe(_sun).apparent().frame_latlon(ecliptic_frame)[1].degrees)

# What if we use Ho Ngoc Duc approximation?
def jd_from_datetime(d):
    a = (14 - d.month) // 12
    y = d.year + 4800 - a
    m = d.month + 12 * a - 3
    day_frac = (d.hour + d.minute / 60.0 + d.second / 3600.0) / 24.0
    return d.day + (153 * m + 2) // 5 + 365 * y + y // 4 - y // 100 + y // 400 - 32045 - 0.5 + day_frac

jd = jd_from_datetime(dt)
# in ho_ngoc_duc_almanac, it uses _ts.ut1_jd(jdn)
t_ut1 = _ts.ut1_jd(jd)
print("UT1 Apparent:", _earth.at(t_ut1).observe(_sun).apparent().frame_latlon(ecliptic_frame)[1].degrees)
