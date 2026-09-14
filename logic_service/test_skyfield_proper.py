from skyfield.api import load, Topos
import math
from datetime import timedelta

ts = load.timescale()
eph = load('de421.bsp')
earth, sun = eph['earth'], eph['sun']

def get_lon(jd):
    t = ts.ut1_jd(jd)
    # Apparent ecliptic longitude of date
    _, lon, _ = earth.at(t).observe(sun).apparent().ecliptic_latlon()
    return lon.degrees

def find_root(target, jd0, jd1):
    for _ in range(50):
        mid = jd0 + (jd1 - jd0) / 2
        l = get_lon(mid)
        diff = (l - target + 180) % 360 - 180
        if diff < 0: jd0 = mid
        else: jd1 = mid
    return mid

t0 = ts.utc(2026, 6, 1).ut1
t1 = ts.utc(2026, 6, 10).ut1

res_jd = find_root(75.0, t0, t1)
dt = ts.ut1_jd(res_jd).utc_datetime() + timedelta(hours=7)
print("Mang Chung True Equinox of Date:", dt.strftime('%H:%M:%S %d/%m/%Y'))

def get_lon_j2000(jd):
    t = ts.ut1_jd(jd)
    from skyfield.framelib import ecliptic_frame
    _, lon, _ = earth.at(t).observe(sun).apparent().frame_latlon(ecliptic_frame)
    return lon.degrees

def find_root_j2000(target, jd0, jd1):
    for _ in range(50):
        mid = jd0 + (jd1 - jd0) / 2
        l = get_lon_j2000(mid)
        diff = (l - target + 180) % 360 - 180
        if diff < 0: jd0 = mid
        else: jd1 = mid
    return mid

res_jd2 = find_root_j2000(75.0, t0, t1)
dt2 = ts.ut1_jd(res_jd2).utc_datetime() + timedelta(hours=7)
print("Mang Chung J2000:", dt2.strftime('%H:%M:%S %d/%m/%Y'))
