from skyfield.api import load, Topos
from datetime import timedelta
import math

# Download latest EOP data
ts = load.timescale(builtin=False)
eph = load('de421.bsp')
earth, sun = eph['earth'], eph['sun']
from skyfield.framelib import ecliptic_frame

def get_lon(jd):
    t = ts.ut1_jd(jd)
    _, lon, _ = earth.at(t).observe(sun).apparent().frame_latlon(ecliptic_frame)
    return lon.degrees

def find_exact_solar_term_time(target_deg: float, t0_jd, t1_jd):
    low = t0_jd
    high = t1_jd
    for _ in range(50):
        mid = low + (high - low) / 2
        l = get_lon(mid)
        diff = (l - target_deg + 180) % 360 - 180
        if diff < 0: low = mid
        else: high = mid
    return ts.ut1_jd(mid).utc_datetime() + timedelta(hours=7)

# Tiểu Thử (105 degrees)
t0 = ts.utc(2027, 7, 5).ut1
t1 = ts.utc(2027, 7, 10).ut1
dt_tieu_thu = find_exact_solar_term_time(105.0, t0, t1)
print(f"Tiểu Thử: {dt_tieu_thu.strftime('%H:%M %d/%m')}")

# Đại Thử (120 degrees)
t0 = ts.utc(2027, 7, 21).ut1
t1 = ts.utc(2027, 7, 25).ut1
dt_dai_thu = find_exact_solar_term_time(120.0, t0, t1)
print(f"Đại Thử: {dt_dai_thu.strftime('%H:%M %d/%m')}")
