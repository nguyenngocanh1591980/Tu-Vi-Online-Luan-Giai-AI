from datetime import datetime
from solar_time_calculator import SolarTimeCalculator

# Test case: Sinh tại California (Los Angeles)
# Toạ độ Los Angeles: Lat 34.0522, Lon -118.2437
# Ngày: 1 tháng 3 năm 2008, lúc 12:00 trưa (Múi giờ địa phương)

local_dt = datetime(2008, 3, 1, 12, 0)
lat = 34.0522
lon = -118.2437

print(f"Giờ nhập (Local Time): {local_dt}")
tst = SolarTimeCalculator.get_true_solar_time(local_dt, lat, lon)
print(f"Giờ Mặt Trời Thực Tế (True Solar Time): {tst}")

# Test case dính ranh giới qua ngày mới:
# Sinh lúc 23:50 tại Los Angeles (múi giờ có thể là PST UTC-8)
# UTC sẽ là 07:50 ngày hôm sau
# LMT = UTC - 118.24/15 = 07:50 - 7.88 hours = ~ 23:57 ngày cũ
# EoT = vài phút -> Có thể nhảy sang ngày hôm sau

local_dt_2 = datetime(2008, 3, 1, 23, 50)
print(f"\nGiờ nhập (Local Time): {local_dt_2}")
tst_2 = SolarTimeCalculator.get_true_solar_time(local_dt_2, lat, lon)
print(f"Giờ Mặt Trời Thực Tế (True Solar Time): {tst_2}")
