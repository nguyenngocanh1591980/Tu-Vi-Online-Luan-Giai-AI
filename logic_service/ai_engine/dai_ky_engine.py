"""
Module dai_ky_engine.py
Tính toán 8 trường hợp Đại Kỵ trong năm & 2 luồng kiểm tra chéo Ngày/Giờ Thọ Tử,
móc nối trực tiếp với Module Tiết Khí cho Tứ Ly và Tứ Tuyệt.
Nguồn trích xuất 100% nguyên văn:
E:\\Tu vi online\\AI học tử vi\\Thư Viện cho AI Học\\Tầng 1- Dữ Liệu Chuẩn Hóa\\Các Ngày Đại Kỵ Trong Năm Và Cách Hóa Giải(Đã chỉnh lý).docx
"""

import json
import os
from datetime import date, timedelta
from typing import Dict, Any, List, Tuple

_DB_PATH = os.path.join(os.path.dirname(__file__), "dai_ky_db.json")
if not os.path.exists(_DB_PATH):
    _DB_PATH = os.path.join(os.path.dirname(os.path.dirname(os.path.dirname(__file__))), "dai_ky_db.json")
if not os.path.exists(_DB_PATH):
    _DB_PATH = "dai_ky_db.json"

_DB_CACHE = None

def _get_db() -> dict:
    global _DB_CACHE
    if _DB_CACHE is None:
        with open(_DB_PATH, "r", encoding="utf-8") as f:
            _DB_CACHE = json.load(f)
    return _DB_CACHE

CHI_GIO_MAP = [
    ("Tý", 23, 1),
    ("Sửu", 1, 3),
    ("Dần", 3, 5),
    ("Mão", 5, 7),
    ("Thìn", 7, 9),
    ("Tỵ", 9, 11),
    ("Ngọ", 11, 13),
    ("Mùi", 13, 15),
    ("Thân", 15, 17),
    ("Dậu", 17, 19),
    ("Tuất", 19, 21),
    ("Hợi", 21, 23),
]

def get_chi_from_hour(hour: int) -> str:
    if hour == 23 or hour == 0:
        return "Tý"
    for chi, start, end in CHI_GIO_MAP[1:]:
        if start <= hour < end:
            return chi
    return "Tý"

def get_tu_ly_tu_tuyet_dates(year: int) -> Tuple[Dict[str, date], Dict[str, date]]:
    """
    Lấy ngày chính xác của Tứ Ly và Tứ Tuyệt trong năm thông qua module Tiết Khí
    """
    try:
        from ho_ngoc_duc_almanac import get_yearly_timeline
        timeline = get_yearly_timeline(year)
    except Exception:
        # Fallback if imported from elsewhere
        try:
            from ai_engine.ho_ngoc_duc_almanac import get_yearly_timeline
            timeline = get_yearly_timeline(year)
        except Exception:
            timeline = []

    tu_ly_dates = {}
    tu_tuyet_dates = {}

    for name, term_d, dt in timeline:
        if name in ["Xuân Phân", "Hạ Chí", "Thu Phân", "Đông Chí"]:
            tu_ly_dates[name] = term_d - timedelta(days=1)
        elif name in ["Lập Xuân", "Lập Hạ", "Lập Thu", "Lập Đông"]:
            tu_tuyet_dates[name] = term_d - timedelta(days=1)

    return tu_ly_dates, tu_tuyet_dates

def calculate_dai_ky(
    solar_day: int,
    solar_month: int,
    solar_year: int,
    hour: int,
    minute: int,
    lunar_day: int,
    lunar_month: int,
    lunar_year: int,
    day_can: str,
    day_chi: str,
    year_can: str,
) -> Dict[str, Any]:
    """
    Hàm kiểm tra 8 trường hợp Đại Kỵ và kiểm tra chéo Ngày/Giờ Thọ Tử
    """
    db = _get_db()
    cur_date = date(solar_year, solar_month, solar_day)
    hour_chi = get_chi_from_hour(hour)

    vi_pham_list = []

    # 1. Tam Nương
    tam_nuong_db = db["tam_nuong"]
    if lunar_day in tam_nuong_db["lunar_days"]:
        vi_pham_list.append({
            "id": tam_nuong_db["id"],
            "name": tam_nuong_db["name"],
            "header": tam_nuong_db["header"],
            "y_nghia": tam_nuong_db["y_nghia"],
        })

    # 2. Nguyệt Kỵ
    nguyet_ky_db = db["nguyet_ky"]
    if lunar_day in nguyet_ky_db["lunar_days"]:
        vi_pham_list.append({
            "id": nguyet_ky_db["id"],
            "name": nguyet_ky_db["name"],
            "header": nguyet_ky_db["header"],
            "y_nghia": nguyet_ky_db["y_nghia"],
        })

    # 3. Sát Chủ Âm
    sat_chu_am_db = db["sat_chu_am"]
    month_str = str(lunar_month)
    sat_chu_am_chi = sat_chu_am_db["matrix_month_chi"].get(month_str) or sat_chu_am_db["matrix_month_chi"].get(lunar_month)
    if sat_chu_am_chi == day_chi:
        vi_pham_list.append({
            "id": sat_chu_am_db["id"],
            "name": sat_chu_am_db["name"],
            "header": sat_chu_am_db["header"],
            "y_nghia": sat_chu_am_db["y_nghia"],
        })

    # 4. Sát Chủ Dương
    sat_chu_duong_db = db["sat_chu_duong"]
    sat_chu_duong_chi = sat_chu_duong_db["matrix_month_chi"].get(month_str) or sat_chu_duong_db["matrix_month_chi"].get(lunar_month)
    if sat_chu_duong_chi == day_chi:
        vi_pham_list.append({
            "id": sat_chu_duong_db["id"],
            "name": sat_chu_duong_db["name"],
            "header": sat_chu_duong_db["header"],
            "y_nghia": sat_chu_duong_db["y_nghia"],
        })

    # 5. Dương Công Kỵ
    duong_cong_ky_db = db["duong_cong_ky"]
    dck_days = duong_cong_ky_db["lunar_month_days"].get(month_str) or duong_cong_ky_db["lunar_month_days"].get(lunar_month, [])
    if lunar_day in dck_days:
        vi_pham_list.append({
            "id": duong_cong_ky_db["id"],
            "name": duong_cong_ky_db["name"],
            "header": duong_cong_ky_db["header"],
            "y_nghia": duong_cong_ky_db["y_nghia"],
        })

    # 6. Kim Thần Thất Sát
    kim_than_db = db["kim_than_that_sat"]
    ktts_chis = kim_than_db["matrix_year_can_day_chi"].get(year_can, [])
    if day_chi in ktts_chis:
        vi_pham_list.append({
            "id": kim_than_db["id"],
            "name": kim_than_db["name"],
            "header": kim_than_db["header"],
            "y_nghia": kim_than_db["y_nghia"],
        })

    # 7. Tứ Ly & 8. Tứ Tuyệt (móc nối Tiết Khí)
    tu_ly_dates, tu_tuyet_dates = get_tu_ly_tu_tuyet_dates(solar_year)

    tu_ly_matched = None
    for term_name, t_date in tu_ly_dates.items():
        if cur_date == t_date:
            tu_ly_matched = term_name
            break

    if tu_ly_matched:
        tu_ly_db = db["tu_ly"]
        vi_pham_list.append({
            "id": tu_ly_db["id"],
            "name": f"Tứ Ly (trước tiết {tu_ly_matched})",
            "header": tu_ly_db["header"],
            "y_nghia": tu_ly_db["y_nghia"],
        })

    tu_tuyet_matched = None
    for term_name, t_date in tu_tuyet_dates.items():
        if cur_date == t_date:
            tu_tuyet_matched = term_name
            break

    if tu_tuyet_matched:
        tu_tuyet_db = db["tu_tuyet"]
        vi_pham_list.append({
            "id": tu_tuyet_db["id"],
            "name": f"Tứ Tuyệt (trước tiết {tu_tuyet_matched})",
            "header": tu_tuyet_db["header"],
            "y_nghia": tu_tuyet_db["y_nghia"],
        })

    # Kiểm tra Thọ Tử (Ngày & Giờ độc lập)
    tho_tu_db = db["tho_tu"]
    tho_tu_day_chi = tho_tu_db["matrix_day_by_month"].get(month_str) or tho_tu_db["matrix_day_by_month"].get(lunar_month)
    is_tho_tu_day = (day_chi == tho_tu_day_chi)

    tho_tu_hour_chi = tho_tu_db["matrix_hour_by_day_chi"].get(day_chi)
    is_tho_tu_hour = (hour_chi == tho_tu_hour_chi)

    hour_frame_str = tho_tu_db["hour_frames"].get(tho_tu_hour_chi, "")

    # Tổng hợp UI Text
    date_str = f"{solar_day:02d}-{solar_month:02d}-{solar_year}"

    has_tho_tu = is_tho_tu_day or is_tho_tu_hour
    has_common_violation = len(vi_pham_list) > 0

    if not has_common_violation and not has_tho_tu:
        # Trường hợp 1: Ngày Cát
        ui_type = "CAT"
        line_1 = f"Ngày {date_str} là Ngày Cát (Không Phạm các trường hợp Đại Kỵ trong Năm là Tam Nương, Nguyệt Kỵ...)"
        full_text = line_1
        details = []

    elif not has_common_violation and has_tho_tu:
        # Trường hợp 3: Chuyên biệt Thọ Tử
        if is_tho_tu_day and is_tho_tu_hour:
            ui_type = "THO_TU_CA_HAI"
            line_1 = f"Ngày {date_str} là Ngày Đại Kỵ vì phạm vào Ngày Thọ Tử và Cả giờ Thọ Tử nên kiêng mọi chuyện"
            header = tho_tu_db["header_ca_hai"]
            meaning = tho_tu_db["y_nghia_ca_hai"]
        elif is_tho_tu_day:
            ui_type = "THO_TU_NGAY"
            line_1 = f"Ngày {date_str} là Ngày Đại Kỵ vì phạm vào Ngày Thọ Tử"
            header = tho_tu_db["header_ngay"]
            meaning = tho_tu_db["y_nghia_ngay"]
        else:
            ui_type = "THO_TU_GIO"
            line_1 = f"Ngày {date_str} là Ngày {day_chi} vi phạm vào Giờ Thọ Tử (giờ {tho_tu_hour_chi}:{hour_frame_str})"
            header = tho_tu_db["header_gio"]
            meaning = tho_tu_db["y_nghia_gio"]

        details = [{
            "header": header,
            "y_nghia": meaning
        }]
        full_text = f"{line_1}\n\n{header}\nÝ Nghĩa: {meaning}"

    else:
        # Trường hợp 2: Phạm Đại Kỵ thông thường (kèm hoặc không kèm Thọ Tử)
        ui_type = "DAI_KY_THONG_THUONG"
        names = [v["name"] for v in vi_pham_list]
        if is_tho_tu_day and is_tho_tu_hour:
            names.append("Thọ Tử (Ngày & Giờ)")
        elif is_tho_tu_day:
            names.append("Thọ Tử")
        elif is_tho_tu_hour:
            names.append("Giờ Thọ Tử")

        names_str = ", ".join(names)
        line_1 = f"Ngày {date_str} là Ngày Đại Kỵ vì phạm vào Ngày {names_str}"

        details = []
        for v in vi_pham_list:
            details.append({
                "header": v["header"],
                "y_nghia": v["y_nghia"]
            })

        if is_tho_tu_day and is_tho_tu_hour:
            details.append({
                "header": tho_tu_db["header_ca_hai"],
                "y_nghia": tho_tu_db["y_nghia_ca_hai"]
            })
        elif is_tho_tu_day:
            details.append({
                "header": tho_tu_db["header_ngay"],
                "y_nghia": tho_tu_db["y_nghia_ngay"]
            })
        elif is_tho_tu_hour:
            details.append({
                "header": tho_tu_db["header_gio"],
                "y_nghia": tho_tu_db["y_nghia_gio"]
            })

        details_texts = [f"{d['header']}\nÝ Nghĩa: {d['y_nghia']}" for d in details]
        full_text = f"{line_1}\n\n" + "\n\n".join(details_texts)

    return {
        "is_cat": (not has_common_violation and not has_tho_tu),
        "ui_type": ui_type,
        "line_1": line_1,
        "details": details,
        "full_text": full_text,
        "is_tho_tu_day": is_tho_tu_day,
        "is_tho_tu_hour": is_tho_tu_hour,
        "tho_tu_hour_chi": tho_tu_hour_chi,
        "tho_tu_hour_frame": hour_frame_str,
        "vi_pham_list": vi_pham_list,
    }
