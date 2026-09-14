from scipy.optimize import brentq
from skyfield.api import load
from skyfield.framelib import ecliptic_frame
from datetime import timedelta

ts = load.timescale()
eph = load('de421.bsp')
earth, sun = eph['earth'], eph['sun']

def get_apparent_lon(t_tt):
    t = ts.tt_jd(t_tt)
    lat, lon, dist = earth.at(t).observe(sun).apparent().frame_latlon(ecliptic_frame)
    return lon.degrees

def get_true_lon(t_tt):
    t = ts.tt_jd(t_tt)
    lat, lon, dist = earth.at(t).observe(sun).frame_latlon(ecliptic_frame)
    return lon.degrees

t0 = ts.utc(2026, 6, 5).tt
t1 = ts.utc(2026, 6, 6).tt

tt_root_app = brentq(lambda tt: get_apparent_lon(tt) - 75.0, t0, t1)
tt_root_true = brentq(lambda tt: get_true_lon(tt) - 75.0, t0, t1)

print("Apparent:", ts.tt_jd(tt_root_app).utc_datetime() + timedelta(hours=7))
print("True:", ts.tt_jd(tt_root_true).utc_datetime() + timedelta(hours=7))
