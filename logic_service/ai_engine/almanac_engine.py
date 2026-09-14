"""
Module almanac_engine.py
Tính toán đầy đủ thông tin Lịch Vạn Sự sử dụng thuật toán Hồ Ngọc Đức và Tiết Khí Ngũ Hổ Độn.
"""

from ai_engine.ho_ngoc_duc_almanac import calculate_almanac_full

def calculate_almanac_details(day: int, month: int, year: int, hour: int = 0, minute: int = 0) -> dict:
    """
    Tính toán chi tiết cho Lịch Vạn Sự theo ngày Dương lịch.
    """
    return calculate_almanac_full(day, month, year, hour, minute)
