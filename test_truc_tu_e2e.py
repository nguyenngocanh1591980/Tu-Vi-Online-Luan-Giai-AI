"""
Kịch bản kiểm thử Tự Động (Auto-Test E2E): Thập Nhị Trực & Nhị Thập Bát Tú
Xác minh 2 ca kiểm thử bắt buộc:
1. Chuỗi UI nguyên văn cho Trực Định
2. Chuỗi UI nguyên văn cho Sao Tinh (Sao thứ 25)
"""

import os
import sys
import json
import datetime

# Setup import path
logic_service_path = os.path.join(os.path.dirname(__file__), "logic_service")
if logic_service_path not in sys.path:
    sys.path.insert(0, logic_service_path)

from ai_engine.truc_tu_engine import calculate_thap_nhi_truc, calculate_nhi_thap_bat_tu

def run_e2e_tests():
    print("=" * 80)
    print("CHƯƠNG TRÌNH KIỂM THỬ TỰ ĐỘNG: THẬP NHỊ TRỰC & NHỊ THẬP BÁT TÚ")
    print("Nguồn dữ liệu: Cách Tính Ý Nghĩa Thập Nhị Trực và Nhị Thập Bát Tú(Đã Chỉnh Lý).docx")
    print("=" * 80)

    # -------------------------------------------------------------
    # TEST 1: THẬP NHỊ TRỰC - TRỰC ĐỊNH
    # -------------------------------------------------------------
    print("\n" + "#" * 30 + " TEST 1: THẬP NHỊ TRỰC " + "#" * 30)
    # Ví dụ: Tháng 7 Âm Lịch, Ngày Tý (Địa chi Tý: (0 - 8)%12 = 4 -> Trực Định)
    lunar_month = 7
    day_chi = "Giáp Tý"
    truc_res = calculate_thap_nhi_truc(lunar_month, day_chi)

    expected_truc_dinh = "Trực Định: Ngày tốt, mọi thứ ổn định, phù hợp để ký kết hợp đồng, giao dịch và cầu tài lộc. Ngày có trực Định lên làm các việc buôn bán giao thương, làm chuồng gia súc. Bên cạnh đó cần tránh những việc như thưa kiện, xuất hành đi xa."

    print(f"[*] Input: Tháng {lunar_month} Âm lịch, Ngày {day_chi}")
    print(f"[*] Thuật toán tính được: {truc_res['name']} (Hành: {truc_res['hanh']}, Âm Dương: {truc_res['polarity']})")
    print("\n--- [KẾT QUẢ RENDER UI BLOCK VI) THẬP NHỊ TRỰC] ---")
    print(truc_res['ui_gop_text'])
    print("---------------------------------------------------")

    assert truc_res['short_name'] == "Định", f"Lỗi: Kỳ vọng Trực Định nhưng nhận được {truc_res['short_name']}"
    assert truc_res['ui_gop_text'] == expected_truc_dinh, "Lỗi: Nội dung Trực Định không khớp 100% với Test Case!"
    print("[✓] TEST 1 PASSED: Chuỗi UI Trực Định khớp 100% từng ký tự với Test Case bắt buộc!\n")

    # -------------------------------------------------------------
    # TEST 2: NHỊ THẬP BÁT TÚ - SAO TINH (STT 25)
    # -------------------------------------------------------------
    print("#" * 30 + " TEST 2: NHỊ THẬP BÁT TÚ " + "#" * 30)
    # Ngày 16/08/2026 (Chủ Nhật)
    # Khoảng cách từ 01/01/1995 đến 16/08/2026: (2026-08-16 - 1995-01-01).days % 28 + 11 = 25 -> Sao Tinh
    solar_day = 16
    solar_month = 8
    solar_year = 2026
    star_res = calculate_nhi_thap_bat_tu(solar_day, solar_month, solar_year)

    expected_sao_tinh = """25 - Tinh Nhật Mã (Sao Tinh): Hành Nhật - Lý Trung: Xấu. Thuộc Phương Nam – Chu Tước (Chim sẻ đỏ) (Bình Tú) Tướng tinh con ngựa. Thuộc chòm sao Rắn Biển (Hydra). Chủ trị ngày chủ nhật
- Nên làm: Xây dựng phòng mới.
- Kiêng cử: Chôn cất, cưới gã, mở thông đường nước.
- Ngoại lệ: Sao Tinh là 1 trong Thất Sát Tinh, nếu sanh con nhằm ngày này nên lấy tên Sao đặt tên cho trẻ để dễ nuôi, có thể lấy tên sao của năm, hay sao của tháng cũng được. Tại Dần Ngọ Tuất đều tốt, tại Ngọ là Nhập Miếu, tạo tác được tôn trọng. Tại Thân là Đăng Giá( lên xe ): xây cất tốt mà chôn cất nguy. Hạp với 7 ngày: Giáp Dần, Nhâm Dần, Giáp Ngọ, Bính Ngọ, Mậu Ngọ, Bính Tuất, CanhTuất.
Tinh tú nhật hảo tạo tân phòng,
Tiến chức gia quan cận Đế vương,
Bất khả mai táng tính phóng thủy,
Hung tinh lâm vị nữ nhân vong.
Sinh ly, tử biệt vô tâm luyến,
Tự yếu quy hưu biệt giá lang.
Khổng tử cửu khúc châu nan độ,
Phóng thủy, khai câu, thiên mệnh thương"""

    print(f"[*] Input: Ngày Dương lịch {solar_day:02d}/{solar_month:02d}/{solar_year}")
    print(f"[*] Thuật toán tính được: STT {star_res['stt']} - {star_res['full_name']} ({star_res['short_name']})")
    print(f"[*] Hành: {star_res['hanh']} | Lý Trung: {star_res['ly_trung']}")
    print("\n--- [KẾT QUẢ RENDER UI BLOCK VII) NHỊ THẬP BÁT TÚ] ---")
    print(star_res['ui_render_text'])
    print("------------------------------------------------------")

    assert star_res['stt'] == 25, f"Lỗi: Kỳ vọng Sao số 25 nhưng nhận được {star_res['stt']}"
    assert star_res['ui_render_text'] == expected_sao_tinh, "Lỗi: Nội dung Sao Tinh không khớp 100% với Test Case!"
    print("[✓] TEST 2 PASSED: Chuỗi UI Sao Tinh khớp 100% từng dấu chấm, dấu phẩy và vị trí xuống dòng với Test Case bắt buộc!\n")

    print("=" * 80)
    print("TỔNG KẾT: TẤT CẢ TEST CASES ĐÃ VƯỢT QUA 100% - HỆ THỐNG ĐẠT CHUẨN NGHIỆM THU!")
    print("=" * 80)

if __name__ == "__main__":
    run_e2e_tests()
