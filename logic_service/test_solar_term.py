from datetime import datetime, timedelta
from skyfield.api import load
from skyfield.framelib import ecliptic_frame

_ts = load.timescale()
_eph = load('de421.bsp')
_sun = _eph['sun']
_earth = _eph['earth']

def jd_from_datetime(dt: datetime) -> float:
    a = (14 - dt.month) // 12
    y = dt.year + 4800 - a
    m = dt.month + 12 * a - 3
    day_frac = (dt.hour + dt.minute / 60.0 + dt.second / 3600.0) / 24.0
    return dt.day + (153 * m + 2) // 5 + 365 * y + y // 4 - y // 100 + y // 400 - 32045 - 0.5 + day_frac

def sun_longitude_deg(jdn: float) -> float:
    t = _ts.ut1_jd(jdn)
    astrometric = _earth.at(t).observe(_sun)
    lat, lon, distance = astrometric.apparent().frame_latlon(ecliptic_frame)
    return lon.degrees

def find_exact_solar_term_time(target_deg: float, year: int, approx_month: int, approx_day: int) -> datetime:
    approx_dt_utc = datetime(year, approx_month, approx_day, 12, 0)
    low = approx_dt_utc - timedelta(days=4)
    high = approx_dt_utc + timedelta(days=4)
    for _ in range(40):
        mid = low + (high - low) / 2
        jd = jd_from_datetime(mid)
        l = sun_longitude_deg(jd)
        diff = (l - target_deg + 180) % 360 - 180
        if diff < 0: low = mid
        else: high = mid
    return mid + timedelta(hours=7)

# Mang Chủng is 75 degrees.
# According to user: Mang Chủng 2026 is 22:37 on June 5. (Wait, let's see approx_month=6, approx_day=6)
res = find_exact_solar_term_time(75.0, 2026, 6, 6)
print(f"Mang Chủng: {res.strftime('%H:%M %d/%m/%Y')}")
