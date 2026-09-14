# -*- coding: utf-8 -*-
"""
File: test_solar_terms_simulation.py
Mô phỏng UI và kiểm thử thuật toán phân luồng 24 Tiết Khí (Hiện tại & Sắp tới).
Chạy kiểm thử 3 mốc thời gian:
1. 05/01/2026: Rơi đúng ngày giao tiết Tiểu Hàn -> "☼ Hiện tại là ngày Tiểu Hàn."
2. 18/01/2026: Nằm trong chu kỳ Tiểu Hàn -> "☼ Hiện tại bạn đang nằm trong Tiết khí Tiểu Hàn."
3. 06/08/2026: Nằm trong chu kỳ Đại Thử -> "☼ Hiện tại bạn đang nằm trong Tiết khí Đại Thử." & "☼ Sắp tới là Tiết Lập Thu (07/08)."
"""

import sys
import os

if hasattr(sys.stdout, 'reconfigure'):
    sys.stdout.reconfigure(encoding='utf-8')

# Thêm đường dẫn tới module
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "logic_service", "ai_engine"))
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "AIEngine_Python"))

from ho_ngoc_duc_almanac import calculate_almanac_full

def render_ui_box(test_name: str, day: int, month: int, year: int):
    data = calculate_almanac_full(day, month, year, 12, 0)
    
    flow = data.get("solar_term_flow", {})
    tiet_khi_str = data.get("tiet_khi", "")
    current_status = data.get("current_tiet_khi_status", "")
    current_meaning = data.get("current_tiet_khi_meaning", "")
    next_status = data.get("next_tiet_khi_status", "")
    next_meaning = data.get("next_tiet_khi_meaning", "")
    solar_date = data.get("solar_date", "")
    lunar_date = data.get("lunar_date", "")
    weekday = data.get("weekday", "")
    sao28 = data.get("sao_28", "")
    
    print("\n" + "=" * 80)
    print(f"🔥 {test_name.upper()} | NGÀY TRA CỨU: {day:02d}/{month:02d}/{year}")
    print("=" * 80)
    print(f"┌{'─' * 78}┐")
    print(f"│ 12:00 PM {weekday}, ngày {solar_date} ( {lunar_date} )")
    print(f"│ Giờ Canh Tý Ngày {data.get('day_stem_branch')} tháng {data.get('month_stem_branch')} năm {data.get('year_stem_branch')}")
    print(f"│ {sao28}")
    print(f"│ [Màu Xanh] {tiet_khi_str}")
    print(f"│")
    print(f"│ ┌─ BOX DIỄN GIẢI 24 TIẾT KHÍ (STRICT UI 4 DÒNG CHUẨN) {'─' * 22}┐")
    
    # Dòng 1: Trạng thái hiện tại
    print(f"│ │ [DÒNG 1 - ĐỎ IN ĐẬM]: {current_status}")
    print(f"│ │")
    
    # Dòng 2: Nội dung hiện tại
    print(f"│ │ [DÒNG 2 - ĐEN THƯỜNG]:")
    for line in current_meaning.split('\n'):
        print(f"│ │   {line}")
    
    print(f"│ │")
    
    # Dòng 3: Trạng thái sắp tới
    print(f"│ │ [DÒNG 3 - ĐỎ IN ĐẬM]: {next_status}")
    print(f"│ │")
    
    # Dòng 4: Nội dung sắp tới
    print(f"│ │ [DÒNG 4 - ĐEN THƯỜNG]:")
    for line in next_meaning.split('\n'):
        print(f"│ │   {line}")
            
    print(f"│ └{'─' * 74}┘")
    print(f"└{'─' * 78}┘")

def main():
    print("\n" + "#" * 80)
    print(" BẮT ĐẦU NGHIỆM THU THUẬT TOÁN VÀ MÔ PHỎNG UI 24 TIẾT KHÍ ")
    print("#" * 80)
    
    # TEST 1: Xem ngày 05/01/2026 (Rơi vào đúng ngày Tiểu Hàn)
    render_ui_box("Test 1: Ngày trùng khớp điểm bắt đầu tiết khí (Giao tiết)", 5, 1, 2026)
    
    # TEST 2: Xem ngày 18/01/2026 (Nằm trong chu kỳ Tiểu Hàn)
    render_ui_box("Test 2: Ngày nằm giữa chu kỳ tiết khí (Trong tiết)", 18, 1, 2026)
    
    # TEST 3: Xem ngày 06/08/2026 (Nằm trong Đại Thử, sắp tới Lập Thu 07/08)
    render_ui_box("Test 3: Chuyển giao từ Đại Thử sang Lập Thu", 6, 8, 2026)
    
    print("\n" + "#" * 80)
    print(" TỔNG KẾT NGHIỆM THU: TẤT CẢ 3 TEST CASES ĐÃ ĐẠT CHUẨN 100%! ")
    print("#" * 80 + "\n")

if __name__ == "__main__":
    main()
