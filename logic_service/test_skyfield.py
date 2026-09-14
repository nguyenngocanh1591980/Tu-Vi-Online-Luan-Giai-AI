from skyfield.api import load
from skyfield import almanac
from datetime import timedelta

ts = load.timescale()
eph = load('de421.bsp')
t0 = ts.utc(2026, 6, 1)
t1 = ts.utc(2026, 7, 1)
t, y = almanac.find_discrete(t0, t1, almanac.seasons(eph))

for time, season in zip(t, y):
    dt = time.utc_datetime() + timedelta(hours=7)
    print("Skyfield season:", season, dt.strftime('%H:%M:%S %d/%m/%Y'))
