"""
Module truc_tu_engine.py
Tính toán độc lập Thập Nhị Trực (12 Trực) và Nhị Thập Bát Tú (28 Sao)
Nguồn dữ liệu trích xuất nguyên văn từ tài liệu chuẩn hóa:
E:\Tu vi online\AI học tử vi\Thư Viện cho AI Học\Tầng 1- Dữ Liệu Chuẩn Hóa\Cách Tính Ý Nghĩa Thập Nhị Trực và Nhị Thập Bát Tú(Đã Chỉnh Lý).docx
"""

import json
import os
import datetime
from typing import Dict, Any, Optional

# Load CSDL Chuẩn Hóa
DB_PATH = os.path.join(os.path.dirname(__file__), "thap_nhi_truc_nhi_thap_bat_tu_db.json")
if not os.path.exists(DB_PATH):
    # Fallback to root path
    DB_PATH = os.path.join(os.path.dirname(os.path.dirname(os.path.dirname(__file__))), "thap_nhi_truc_nhi_thap_bat_tu_db.json")

_DB_CACHE = None

def _get_db() -> dict:
    global _DB_CACHE
    if _DB_CACHE is None:
        with open(DB_PATH, "r", encoding="utf-8") as f:
            _DB_CACHE = json.load(f)
    return _DB_CACHE

TRUC_NAMES = ["Kiến", "Trừ", "Mãn", "Bình", "Định", "Chấp", "Phá", "Nguy", "Thành", "Thu", "Khai", "Bế"]
BRANCHES = ["Tý", "Sửu", "Dần", "Mão", "Thìn", "Tỵ", "Ngọ", "Mùi", "Thân", "Dậu", "Tuất", "Hợi"]

def calculate_thap_nhi_truc(lunar_month: int, day_chi: str) -> Dict[str, Any]:
    """
    Thuật toán xác định Thập Nhị Trực:
    Dựa vào Bảng 2:
    - Tháng 1 (Dần) khởi Kiến tại Dần
    - Tháng 2 (Mão) khởi Kiến tại Mão
    ...
    - Tháng 11 (Tý) khởi Kiến tại Tý
    - Tháng 12 (Sửu) khởi Kiến tại Sửu

    Công thức:
    BaseChi = (lunar_month + 1) % 12 (với Tý=0, Sửu=1, Dần=2...)
    TrucIndex = (day_chi_idx - BaseChi) % 12
    """
    db = _get_db()
    truc_items = db["thap_nhi_truc"]["items"]
    
    # Normalize day_chi (e.g. "Giáp Tý" -> "Tý" or "Tý" -> "Tý")
    clean_chi = day_chi.strip().split()[-1]
    if clean_chi not in BRANCHES:
        raise ValueError(f"[CẦN_HƯỚNG_DẪN] Không nhận diện được Địa chi ngày: '{day_chi}'")
        
    day_chi_idx = BRANCHES.index(clean_chi)
    base_chi_idx = (lunar_month + 1) % 12
    truc_idx = (day_chi_idx - base_chi_idx) % 12
    
    truc_name = TRUC_NAMES[truc_idx]
    
    item = next((t for t in truc_items if t["ten_ngan"] == truc_name), None)
    if not item:
        raise ValueError(f"[CẦN_HƯỚNG_DẪN] Không tìm thấy dữ liệu Trực '{truc_name}' trong DB")
        
    return {
        "stt": item["stt"],
        "name": item["ten_truc"],
        "short_name": item["ten_ngan"],
        "polarity": item["am_duong"],
        "hanh": item["hanh"],
        "meaning_raw": item["y_nghia_nguyen_van"],
        "ui_gop_text": item["ui_gop_text"]
    }

def calculate_nhi_thap_bat_tu(solar_day: int, solar_month: int, solar_year: int) -> Dict[str, Any]:
    """
    Thuật toán xác định Nhị Thập Bát Tú (28 Sao):
    Mốc tham chiếu cố định: Ngày 01/01/1995 là Chủ Nhật, tương ứng với Sao Hư (số thứ tự 11).

    Các bước tính:
    1. Đếm tổng số ngày khoảng cách từ 01/01/1995 đến ngày cần tính: delta_days = (TargetDate - 1995-01-01).days
    2. Lấy số dư: rem = delta_days % 28
    3. Cộng số dư với 11:
       - Nếu kết quả <= 28: đó là STT của Sao.
       - Nếu kết quả > 28: lấy (kết quả - 28) để ra STT của Sao.
    """
    db = _get_db()
    stars = db["nhi_thap_bat_tu"]["stars"]
    
    ref_date = datetime.date(1995, 1, 1) # Sunday, Sao Hư #11
    target_date = datetime.date(solar_year, solar_month, solar_day)
    
    diff_days = (target_date - ref_date).days
    rem = diff_days % 28
    
    star_num = rem + 11
    if star_num > 28:
        star_num -= 28
        
    star_item = next((s for s in stars if s["stt"] == star_num), None)
    if not star_item:
        raise ValueError(f"[CẦN_HƯỚNG_DẪN] Không tìm thấy dữ liệu Sao STT {star_num} trong DB")
        
    return {
        "stt": star_item["stt"],
        "full_name": star_item["ten_day_du"],
        "short_name": star_item["ten_ngan"],
        "hanh": star_item["hanh"],
        "ly_trung": star_item["ly_trung"],
        "header_line": star_item["header_line"],
        "direction_line": star_item["direction_line"],
        "details_line": star_item["details_line"],
        "nen_lam": star_item["nen_lam"],
        "kieng_cu": star_item["kieng_cu"],
        "ngoai_le": star_item["ngoai_le"],
        "poem": star_item["poem"],
        "ui_render_text": star_item["ui_render_text"]
    }
