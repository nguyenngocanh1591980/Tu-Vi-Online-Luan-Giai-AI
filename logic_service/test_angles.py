from skyfield.api import load
from skyfield.framelib import ecliptic_frame
ts = load.timescale(builtin=False)
eph = load('de421.bsp')
earth, sun = eph['earth'], eph['sun']
t = ts.utc(2026, 10, 8, 6, 29) # ~13:29 UTC+7 -> 06:29 UTC
astrometric = earth.at(t).observe(sun)
apparent = astrometric.apparent()

# 1. frame_latlon
_, lon1, _ = apparent.frame_latlon(ecliptic_frame)
print("frame_latlon(ecliptic_frame):", lon1.degrees)

# 2. ecliptic_latlon()
_, lon2, _ = apparent.ecliptic_latlon()
print("ecliptic_latlon():", lon2.degrees)

# 3. ecliptic_latlon('date')
_, lon3, _ = apparent.ecliptic_latlon(epoch=t)
print("ecliptic_latlon('date'):", lon3.degrees)

# 4. true_equator_and_equinox_of_date
from skyfield.framelib import true_equator_and_equinox_of_date
_, lon4, _ = apparent.frame_latlon(true_equator_and_equinox_of_date)
print("true_equator_and_equinox_of_date:", lon4.degrees)

