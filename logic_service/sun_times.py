"""
Module: sun_times.py
Đường dẫn: e:\\Tu vi online\\logic_service\\sun_times.py
Mục đích: Tính toán giờ Mặt Trời mọc và lặn trong ngày tại Hà Nội và TP. Hồ Chí Minh
sử dụng thư viện thiên văn (ephem / skyfield) theo thời gian thực (múi giờ GMT+7).

Tọa độ chuẩn hóa:
- Hà Nội: Vĩ độ 21.0285° N, Kinh độ 105.8542° E
- TP. Hồ Chí Minh: Vĩ độ 10.8231° N, Kinh độ 106.6297° E

Định dạng JSON trả về bám sát định dạng bảng hiển thị UI yêu cầu:
Cột: "Mặt trời", "Giờ mọc", "Giờ lặn"
Ví dụ tham chiếu:
- Hà Nội: Mọc 05:44, Lặn 18:00 (Khoảng 5h44, Khoảng 18h00)
- TP. Hồ Chí Minh: Mọc 05:43, Lặn 17:54 (Khoảng 5h43, Khoảng 17h54)
"""

import os
import json
import math
import datetime
from typing import Dict, Any, List, Optional, Union

# Múi giờ Việt Nam GMT+7
VN_TZ = datetime.timezone(datetime.timedelta(hours=7))

# Cấu hình tọa độ chuẩn
LOCATIONS = [
    {
        "key": "hanoi",
        "name": "Hà Nội",
        "lat": 21.0285,
        "lon": 105.8542,
        "elevation": 0.0
    },
    {
        "key": "hcm",
        "name": "TP. Hồ Chí Minh",
        "lat": 10.8231,
        "lon": 106.6297,
        "elevation": 0.0
    }
]

# Tìm file de421.bsp nếu có để nạp Skyfield
_DE421_CANDIDATES = [
    os.path.join(os.path.dirname(__file__), "de421.bsp"),
    os.path.join(os.path.dirname(__file__), "ai_engine", "de421.bsp"),
    os.path.join(os.path.dirname(os.path.dirname(__file__)), "logic_service", "de421.bsp"),
    os.path.join(os.path.dirname(os.path.dirname(__file__)), "logic_service", "ai_engine", "de421.bsp"),
    "de421.bsp"
]
_DE421_PATH = next((p for p in _DE421_CANDIDATES if os.path.exists(p)), None)


def _parse_input_date(date_input: Optional[Union[str, datetime.date, datetime.datetime]] = None) -> datetime.date:
    """Chuẩn hóa ngày đầu vào thành datetime.date (mặc định hôm nay theo GMT+7)."""
    if date_input is None:
        return datetime.datetime.now(VN_TZ).date()
    if isinstance(date_input, datetime.datetime):
        return date_input.date()
    if isinstance(date_input, datetime.date):
        return date_input
    if isinstance(date_input, str):
        date_str = date_input.strip()
        # Hỗ trợ format YYYY-MM-DD hoặc DD/MM/YYYY
        if "-" in date_str:
            parts = [int(p) for p in date_str.split("-")]
            if len(parts) == 3:
                if parts[0] > 1000:  # YYYY-MM-DD
                    return datetime.date(parts[0], parts[1], parts[2])
                else:  # DD-MM-YYYY
                    return datetime.date(parts[2], parts[1], parts[0])
        elif "/" in date_str:
            parts = [int(p) for p in date_str.split("/")]
            if len(parts) == 3:
                if parts[0] > 1000:  # YYYY/MM/DD
                    return datetime.date(parts[0], parts[1], parts[2])
                else:  # DD/MM/YYYY
                    return datetime.date(parts[2], parts[1], parts[0])
    raise ValueError(f"Không thể phân giải định dạng ngày: {date_input}")


def _round_time(dt: Optional[datetime.datetime]) -> tuple[str, str]:
    """
    Làm tròn thời gian tới phút gần nhất.
    Trả về: (định dạng ngắn '05:44', định dạng chữ hiển thị UI 'Khoảng 5h44')
    """
    if not dt:
        return "--:--", "--"
    
    # Làm tròn giây vào phút
    mins = dt.minute + (1 if dt.second >= 30 else 0)
    hrs = dt.hour
    if mins >= 60:
        hrs += 1
        mins -= 60
    if hrs >= 24:
        hrs -= 24
        
    short_str = f"{hrs:02d}:{mins:02d}"
    ui_text = f"Khoảng {hrs}h{mins:02d}"
    return short_str, ui_text


def _calc_with_skyfield(target_date: datetime.date, lat: float, lon: float) -> tuple[str, str, str, str]:
    """Tính toán thời điểm mọc / lặn bằng thư viện Skyfield."""
    from skyfield import api, almanac
    ts = api.load.timescale()
    eph = api.load(_DE421_PATH)
    loc = api.wgs84.latlon(lat, lon)
    
    t0 = ts.from_datetime(datetime.datetime(target_date.year, target_date.month, target_date.day, 0, 0, 0, tzinfo=VN_TZ))
    t1 = ts.from_datetime(datetime.datetime(target_date.year, target_date.month, target_date.day, 23, 59, 59, tzinfo=VN_TZ))
    
    f = almanac.sunrise_sunset(eph, loc)
    times, events = almanac.find_discrete(t0, t1, f)
    
    rise_dt, set_dt = None, None
    for t, e in zip(times, events):
        dt_local = t.astimezone(VN_TZ)
        if e == 1:
            rise_dt = dt_local
        elif e == 0:
            set_dt = dt_local
            
    r_short, r_ui = _round_time(rise_dt)
    s_short, s_ui = _round_time(set_dt)
    return r_short, r_ui, s_short, s_ui


def _calc_with_ephem(target_date: datetime.date, lat: float, lon: float) -> tuple[str, str, str, str]:
    """Tính toán thời điểm mọc / lặn bằng thư viện Ephem."""
    import ephem
    obs = ephem.Observer()
    obs.lat = str(lat)
    obs.lon = str(lon)
    obs.elevation = 0.0
    obs.pressure = 1010.0
    obs.horizon = '-0:34'  # Chuẩn khúc xạ khí quyển 34 arcminutes
    
    # Ngày bắt đầu tính theo giờ GMT+7 (00:00:00 GMT+7 = 17:00:00 UTC ngày hôm trước)
    dt_local_start = datetime.datetime(target_date.year, target_date.month, target_date.day, 0, 0, 0, tzinfo=VN_TZ)
    dt_utc_start = dt_local_start.astimezone(datetime.timezone.utc)
    obs.date = ephem.Date(dt_utc_start)
    
    sun = ephem.Sun()
    rise_utc = obs.next_rising(sun).datetime().replace(tzinfo=datetime.timezone.utc)
    set_utc = obs.next_setting(sun).datetime().replace(tzinfo=datetime.timezone.utc)
    
    rise_local = rise_utc.astimezone(VN_TZ)
    set_local = set_utc.astimezone(VN_TZ)
    
    r_short, r_ui = _round_time(rise_local)
    s_short, s_ui = _round_time(set_local)
    return r_short, r_ui, s_short, s_ui


def _calc_with_noaa_formula(target_date: datetime.date, lat: float, lon: float) -> tuple[str, str, str, str]:
    """Thuật toán giải tích thiên văn NOAA dự phòng nếu không tải được C-extension."""
    day_of_year = target_date.timetuple().tm_yday
    b = (360.0 / 365.24) * (day_of_year - 81) * math.pi / 180.0
    eot = 9.87 * math.sin(2 * b) - 7.53 * math.cos(b) - 1.5 * math.sin(b)  # phút
    decl = 23.44 * math.sin(b) * math.pi / 180.0
    lat_rad = lat * math.pi / 180.0
    
    # Góc thiên đỉnh chuẩn gồm bán kính đĩa mặt trời và khúc xạ khí quyển (90.833 độ)
    zenith = 90.833 * math.pi / 180.0
    cos_w0 = (math.cos(zenith) - math.sin(lat_rad) * math.sin(decl)) / (math.cos(lat_rad) * math.cos(decl))
    cos_w0 = max(-1.0, min(1.0, cos_w0))
    w0 = math.acos(cos_w0) * 180.0 / math.pi
    
    # Mặt trời qua kinh tuyến địa phương (Giờ chính Ngọ)
    t_noon = 12.0 - (lon - 105.0) / 15.0 - (eot / 60.0)
    t_rise = t_noon - (w0 / 15.0)
    t_set = t_noon + (w0 / 15.0)
    
    def to_datetime(t_float: float) -> datetime.datetime:
        hrs = int(t_float)
        frac = (t_float - hrs) * 60.0
        mins = int(frac)
        secs = int((frac - mins) * 60.0)
        return datetime.datetime(target_date.year, target_date.month, target_date.day, hrs, mins, secs, tzinfo=VN_TZ)
        
    r_short, r_ui = _round_time(to_datetime(t_rise))
    s_short, s_ui = _round_time(to_datetime(t_set))
    return r_short, r_ui, s_short, s_ui


def calculate_sun_times_single(target_date: datetime.date, lat: float, lon: float) -> dict:
    """Tính toán thời điểm mặt trời mọc/lặn với thứ tự ưu tiên: Skyfield -> Ephem -> NOAA Formula."""
    if _DE421_PATH and os.path.exists(_DE421_PATH):
        try:
            r_short, r_ui, s_short, s_ui = _calc_with_skyfield(target_date, lat, lon)
            return {"short_rise": r_short, "ui_rise": r_ui, "short_set": s_short, "ui_set": s_ui, "engine": "skyfield"}
        except Exception:
            pass
            
    try:
        r_short, r_ui, s_short, s_ui = _calc_with_ephem(target_date, lat, lon)
        return {"short_rise": r_short, "ui_rise": r_ui, "short_set": s_short, "ui_set": s_ui, "engine": "ephem"}
    except Exception:
        r_short, r_ui, s_short, s_ui = _calc_with_noaa_formula(target_date, lat, lon)
        return {"short_rise": r_short, "ui_rise": r_ui, "short_set": s_short, "ui_set": s_ui, "engine": "noaa_formula"}


def get_sun_times_table(date_input: Optional[Union[str, datetime.date, datetime.datetime]] = None) -> List[Dict[str, Any]]:
    """
    Hàm chính: Tính toán bảng giờ Mặt Trời mọc và lặn tại Hà Nội và TP. Hồ Chí Minh.
    Cấu trúc dữ liệu trả về bám sát định dạng bảng hiển thị UI yêu cầu gồm các cột:
    - "Mặt trời": Tên thành phố ("Hà Nội", "TP. Hồ Chí Minh")
    - "Giờ mọc": Chuỗi hiển thị ("Khoảng 5h44")
    - "Giờ lặn": Chuỗi hiển thị ("Khoảng 18h00")
    Kèm các trường số liệu chi tiết: "moc" ("05:44"), "lan" ("18:00").
    """
    target_date = _parse_input_date(date_input)
    table = []
    
    for loc in LOCATIONS:
        calc_res = calculate_sun_times_single(target_date, loc["lat"], loc["lon"])
        row = {
            "Mặt trời": loc["name"],
            "Giờ mọc": calc_res["ui_rise"],
            "Giờ lặn": calc_res["ui_set"],
            "moc": calc_res["short_rise"],
            "lan": calc_res["short_set"],
            "vi_do": loc["lat"],
            "kinh_do": loc["lon"]
        }
        table.append(row)
        
    return table


def get_sun_times_json(date_input: Optional[Union[str, datetime.date, datetime.datetime]] = None, indent: int = 2) -> str:
    """
    Trả về chuỗi JSON chính xác theo yêu cầu hiển thị UI.
    """
    table = get_sun_times_table(date_input)
    # Lấy định dạng thuần túy bám sát 3 cột yêu cầu: Mặt trời, Giờ mọc, Giờ lặn
    ui_table = [
        {
            "Mặt trời": row["Mặt trời"],
            "Giờ mọc": row["Giờ mọc"],
            "Giờ lặn": row["Giờ lặn"]
        }
        for row in table
    ]
    return json.dumps(ui_table, ensure_ascii=False, indent=indent)


def get_sun_times_full_response(date_input: Optional[Union[str, datetime.date, datetime.datetime]] = None) -> Dict[str, Any]:
    """
    Trả về cấu trúc phản hồi API đầy đủ gồm ngày tra cứu, các cột và bảng dữ liệu.
    """
    target_date = _parse_input_date(date_input)
    table = get_sun_times_table(target_date)
    return {
        "status": "success",
        "date": target_date.strftime("%Y-%m-%d"),
        "timezone": "GMT+7",
        "columns": ["Mặt trời", "Giờ mọc", "Giờ lặn"],
        "data": table
    }


if __name__ == "__main__":
    import sys
    sys.stdout.reconfigure(encoding='utf-8')
    
    print("=== KIỂM TRA ĐẦU RA VỚI NGÀY THAM CHIẾU: 2026-09-15 ===")
    json_result_test = get_sun_times_json("2026-09-15")
    print(json_result_test)
    
    print("\n=== KIỂM TRA ĐẦU RA HÔM NAY (THỜI GIAN THỰC) ===")
    today_json = get_sun_times_json()
    print(today_json)
