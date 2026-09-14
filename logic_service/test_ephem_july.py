import ephem
import math
from datetime import timedelta

def get_lon(date):
    sun = ephem.Sun(date)
    # Ecliptic longitude in radians
    eq = ephem.Equatorial(sun.ra, sun.dec, epoch=date)
    ecl = ephem.Ecliptic(eq)
    return math.degrees(ecl.lon)

def find_root(target, d0, d1):
    low = d0
    high = d1
    for _ in range(50):
        mid = low + (high - low) / 2.0
        l = get_lon(mid)
        diff = (l - target + 180) % 360 - 180
        if diff < 0: low = mid
        else: high = mid
    return mid

# Tiểu Thử (105 degrees)
d0 = ephem.Date('2026/7/6')
d1 = ephem.Date('2026/7/8')
res = find_root(105.0, d0, d1)
dt = ephem.Date(res).datetime() + timedelta(hours=7)
print("PyEphem Tiểu Thử:", dt.strftime('%H:%M %d/%m'))

# Đại Thử (120 degrees)
d0 = ephem.Date('2026/7/22')
d1 = ephem.Date('2026/7/24')
res2 = find_root(120.0, d0, d1)
dt2 = ephem.Date(res2).datetime() + timedelta(hours=7)
print("PyEphem Đại Thử:", dt2.strftime('%H:%M %d/%m'))
