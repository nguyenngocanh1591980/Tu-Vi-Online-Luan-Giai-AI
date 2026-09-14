import math
from datetime import datetime, timedelta
from skyfield.api import load
from skyfield.framelib import ecliptic_frame

_ts = load.timescale(builtin=False)
_eph = load('de421.bsp')
_sun = _eph['sun']
_earth = _eph['earth']

def get_lon_apparent(jd):
    t = _ts.ut1_jd(jd)
    lat, lon, distance = _earth.at(t).observe(_sun).apparent().ecliptic_latlon()
    return lon.degrees

def get_lon_j2000(jd):
    t = _ts.ut1_jd(jd)
    _, lon, _ = _earth.at(t).observe(_sun).apparent().frame_latlon(ecliptic_frame)
    return lon.degrees

def find_exact(target_deg, y, m, d):
    low = _ts.utc(y, m, d - 4).ut1
    high = _ts.utc(y, m, d + 4).ut1
    for _ in range(50):
        mid = low + (high - low) / 2
        l = get_lon_apparent(mid)
        diff = (l - target_deg + 180) % 360 - 180
        if diff < 0: low = mid
        else: high = mid
    return _ts.ut1_jd(mid).utc_datetime() + timedelta(hours=7)

def find_exact_j2000(target_deg, y, m, d):
    low = _ts.utc(y, m, d - 4).ut1
    high = _ts.utc(y, m, d + 4).ut1
    for _ in range(50):
        mid = low + (high - low) / 2
        l = get_lon_j2000(mid)
        diff = (l - target_deg + 180) % 360 - 180
        if diff < 0: low = mid
        else: high = mid
    return _ts.ut1_jd(mid).utc_datetime() + timedelta(hours=7)

def round_time(dt):
    if dt.second >= 30:
        return dt + timedelta(minutes=1)
    return dt

dt1_app = find_exact(195.0, 2026, 10, 8)
dt2_app = find_exact(210.0, 2026, 10, 23)
print(f"Hàn Lộ (Apparent): {dt1_app.strftime('%H:%M:%S %d/%m')} -> Làm tròn: {round_time(dt1_app).strftime('%H:%M %d/%m')}")
print(f"Sương Giáng (Apparent): {dt2_app.strftime('%H:%M:%S %d/%m')} -> Làm tròn: {round_time(dt2_app).strftime('%H:%M %d/%m')}")

dt1_j2000 = find_exact_j2000(195.0, 2026, 10, 8)
dt2_j2000 = find_exact_j2000(210.0, 2026, 10, 23)
print(f"Hàn Lộ (J2000 cũ): {dt1_j2000.strftime('%H:%M:%S %d/%m')} -> truncated: {dt1_j2000.strftime('%H:%M %d/%m')}")
print(f"Sương Giáng (J2000 cũ): {dt2_j2000.strftime('%H:%M:%S %d/%m')} -> truncated: {dt2_j2000.strftime('%H:%M %d/%m')}")
