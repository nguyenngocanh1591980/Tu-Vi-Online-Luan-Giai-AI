from skyfield.api import load
from datetime import timedelta
import math

ts = load.timescale()
eph = load('de421.bsp')
earth = eph['earth']
sun = eph['sun']

def get_lon_of_date(t_tt):
    t = ts.tt_jd(t_tt)
    # Using ecliptic_latlon which is True Equator and Equinox of Date!
    lat, lon, distance = earth.at(t).observe(sun).apparent().ecliptic_latlon()
    return lon.degrees

t0 = ts.utc(2026, 6, 4).tt
t1 = ts.utc(2026, 6, 7).tt

for _ in range(50):
    mid = (t0 + t1) / 2
    lon = get_lon_of_date(mid)
    diff = (lon - 75.0 + 180) % 360 - 180
    if diff < 0:
        t0 = mid
    else:
        t1 = mid

dt = ts.tt_jd(mid).utc_datetime() + timedelta(hours=7)
print("Mang Chung (Longitude of Date):", dt.strftime('%H:%M %d/%m/%Y'))

# Hạ chí (90 deg)
t0 = ts.utc(2026, 6, 20).tt
t1 = ts.utc(2026, 6, 23).tt
for _ in range(50):
    mid = (t0 + t1) / 2
    lon = get_lon_of_date(mid)
    diff = (lon - 90.0 + 180) % 360 - 180
    if diff < 0:
        t0 = mid
    else:
        t1 = mid

dt = ts.tt_jd(mid).utc_datetime() + timedelta(hours=7)
print("Hạ Chí (Longitude of Date):", dt.strftime('%H:%M %d/%m/%Y'))
