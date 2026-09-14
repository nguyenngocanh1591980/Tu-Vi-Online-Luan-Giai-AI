import math
from datetime import datetime, timedelta

def sun_longitude(jdn):
    return (jdn - 2451545.0) * 0.98564736 + 280.46

def sun_longitude_hnd(jdn):
    # Ho Ngoc Duc's original formula:
    dr = math.pi / 180.0
    T = (jdn - 2415020.0) / 36525.0
    T2 = T * T
    T3 = T2 * T
    
    L = 279.69668 + 36000.76892 * T + 0.0003025 * T2
    M = 358.47583 + 35999.04975 * T - 0.000150 * T2 - 0.0000033 * T3
    e = 0.01675104 - 0.0000418 * T - 0.000000126 * T2
    
    C = (1.919460 - 0.004789 * T - 0.000014 * T2) * math.sin(M * dr)
    C += (0.020094 - 0.000100 * T) * math.sin(2 * M * dr)
    C += 0.000293 * math.sin(3 * M * dr)
    
    sun_long = (L + C) % 360.0
    if sun_long < 0:
        sun_long += 360.0
    return sun_long

def get_solar_term(target, year, month, approx_day):
    # Binary search using sun_longitude_hnd
    low = jd_from_datetime(datetime(year, month, approx_day, 12) - timedelta(days=4))
    high = jd_from_datetime(datetime(year, month, approx_day, 12) + timedelta(days=4))
    
    for _ in range(50):
        mid = (low + high) / 2
        l = sun_longitude_hnd(mid)
        diff = (l - target + 180) % 360 - 180
        if diff < 0:
            low = mid
        else:
            high = mid
    return mid

def jd_from_datetime(dt: datetime) -> float:
    a = (14 - dt.month) // 12
    y = dt.year + 4800 - a
    m = dt.month + 12 * a - 3
    day_frac = (dt.hour + dt.minute / 60.0 + dt.second / 3600.0) / 24.0
    return dt.day + (153 * m + 2) // 5 + 365 * y + y // 4 - y // 100 + y // 400 - 32045 - 0.5 + day_frac

def jd_to_datetime(jd):
    jd += 0.5
    Z = int(jd)
    F = jd - Z
    if Z < 2299161:
        A = Z
    else:
        alpha = int((Z - 1867216.25) / 36524.25)
        A = Z + 1 + alpha - int(alpha / 4)
    B = A + 1524
    C = int((B - 122.1) / 365.25)
    D = int(365.25 * C)
    E = int((B - D) / 30.6001)
    day = B - D - int(30.6001 * E) + F
    month = E - 1 if E < 14 else E - 13
    year = C - 4716 if month > 2 else C - 4715
    
    day_frac = day - int(day)
    hour = day_frac * 24
    minute = (hour - int(hour)) * 60
    second = (minute - int(minute)) * 60
    
    return datetime(year, month, int(day), int(hour), int(minute), int(second))

jd_mangchung = get_solar_term(75.0, 2026, 6, 6)
dt_mangchung = jd_to_datetime(jd_mangchung)
print("HND Mang Chung:", (dt_mangchung + timedelta(hours=7)).strftime('%H:%M %d/%m/%Y'))
