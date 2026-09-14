import math
from datetime import datetime, timedelta
import pytz
from timezonefinder import TimezoneFinder

tf = TimezoneFinder()

class SolarTimeCalculator:
    @staticmethod
    def get_true_solar_time(local_dt: datetime, lat: float, lon: float) -> datetime:
        """
        Chuyển đổi giờ địa phương (local_dt) tại toạ độ (lat, lon) thành Giờ Mặt Trời (True Solar Time).
        
        Các bước:
        1. Tìm Timezone từ (lat, lon) bằng timezonefinder.
        2. Localize local_dt theo Timezone đó và chuyển về UTC.
        3. Tính Local Mean Time (LMT) = UTC + lon/15.
        4. Tính Equation of Time (EoT) xấp xỉ bằng công thức thiên văn.
        5. Trả về True Solar Time (TST) = LMT + EoT dưới dạng naive datetime để dùng thay thế cho giờ nhập.
        """
        # 1. Tìm Timezone từ tọa độ
        tz_name = tf.timezone_at(lng=lon, lat=lat)
        if not tz_name:
            # Fallback nếu không tìm thấy múi giờ (giữ nguyên giờ cũ)
            return local_dt
            
        tz = pytz.timezone(tz_name)
        
        # 2. Localize local_dt và chuyển sang UTC
        try:
            localized_dt = tz.localize(local_dt, is_dst=None)
        except pytz.exceptions.AmbiguousTimeError:
            localized_dt = tz.localize(local_dt, is_dst=False)
        except pytz.exceptions.NonExistentTimeError:
            # Giờ nhảy cóc do DST, cộng thêm 1 tiếng
            localized_dt = tz.localize(local_dt + timedelta(hours=1), is_dst=False)
            
        utc_dt = localized_dt.astimezone(pytz.utc).replace(tzinfo=None)
        
        # 3. Tính Local Mean Time (LMT)
        # 15 độ kinh độ = 1 giờ
        lmt_dt = utc_dt + timedelta(hours=(lon / 15.0))
        
        # 4. Tính Equation of Time (EoT)
        # N: Số ngày từ đầu năm
        N = utc_dt.timetuple().tm_yday
        
        # B = 360/365 * (N - 81) độ. Tính theo radian:
        B = 2 * math.pi * (N - 81) / 364.0
        
        # Công thức EoT xấp xỉ (theo phút)
        eot_minutes = 9.87 * math.sin(2 * B) - 7.53 * math.cos(B) - 1.5 * math.sin(B)
        
        # 5. True Solar Time = LMT + EoT
        tst_dt = lmt_dt + timedelta(minutes=eot_minutes)
        
        return tst_dt
