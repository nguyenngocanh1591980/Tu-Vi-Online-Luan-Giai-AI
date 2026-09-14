import sys
import os

# Add paths
sys.path.append(r'E:\Tu vi online\AIEngine_Python')
sys.path.append(r'E:\Tu vi online\logic_service\ai_engine')

from ho_ngoc_duc_almanac import calculate_almanac_full
from ngu_hanh_engine import compare_nap_am_month_day

def run_test():
    print("================================================================================")
    print("           BẮT ĐẦU KIỂM THỬ: MODULE NGŨ HÀNH (BLOCK IX) SO SÁNH NẠP ÂM          ")
    print("================================================================================")
    
    # 1. Ca kiểm thử 1: TỶ HÒA
    print("\n--- [CA KIỂM THỬ 1: TỶ HÒA (CÙNG HÀNH)] ---")
    month_case1 = "Giáp Tý" # Hải Trung Kim
    day_case1 = "Ất Sửu"    # Hải Trung Kim
    res_case1 = compare_nap_am_month_day(month_case1, day_case1)
    exp_case1 = "Tháng Giáp Tý(Hải Trung Kim), Ngày Ất Sửu(Hải Trung Kim). Tức là Tháng & Ngày Hòa là (Tỷ Hòa)"
    print(f"Tháng: {month_case1} | Ngày: {day_case1}")
    print(f"Output:   {res_case1}")
    print(f"Kỳ vọng:  {exp_case1}")
    pass_case1 = (res_case1 == exp_case1)
    print(f"Kết luận: {'[PASS] KHỚP 100%' if pass_case1 else '[FAIL] KHÔNG KHỚP'}")

    # 2. Ca kiểm thử 2: PHẠT NHẬT (THÁNG KHẮC NGÀY)
    print("\n--- [CA KIỂM THỬ 2: PHẠT NHẬT (THÁNG KHẮC NGÀY)] ---")
    month_case2 = "Ất Mùi"   # Sa Trung Kim
    day_case2 = "Mậu Tuất"  # Bình Địa Mộc
    res_case2 = compare_nap_am_month_day(month_case2, day_case2)
    exp_case2 = "Tháng Ất Mùi(Sa Trung Kim), Ngày Mậu Tuất(Bình Địa Mộc). Tức là Tháng khắc Ngày là (Phạt Nhật)"
    print(f"Tháng: {month_case2} | Ngày: {day_case2}")
    print(f"Output:   {res_case2}")
    print(f"Kỳ vọng:  {exp_case2}")
    pass_case2 = (res_case2 == exp_case2)
    print(f"Kết luận: {'[PASS] KHỚP 100%' if pass_case2 else '[FAIL] KHÔNG KHỚP'}")

    # 3. Ca kiểm thử 3: NGHĨA NHẬT / BẢO NHẬT (THÁNG SINH NGÀY - Ví dụ mẫu Prompt)
    print("\n--- [CA KIỂM THỬ 3: THÁNG SINH NGÀY (VÍ DỤ MẪU)] ---")
    month_case3 = "Ất Mùi"   # Sa Trung Kim
    day_case3 = "Bính Ngọ"  # Thiên Hà Thủy
    res_case3 = compare_nap_am_month_day(month_case3, day_case3)
    exp_case3 = "Tháng Ất Mùi(Sa Trung Kim), Ngày Bính Ngọ(Thiên Hà Thủy). Tức là Tháng Sinh Ngày là (Nghĩa Nhật / Bảo Nhật - Đắc khí)"
    print(f"Tháng: {month_case3} | Ngày: {day_case3}")
    print(f"Output:   {res_case3}")
    print(f"Kỳ vọng:  {exp_case3}")
    pass_case3 = (res_case3 == exp_case3)
    print(f"Kết luận: {'[PASS] KHỚP 100%' if pass_case3 else '[FAIL] KHÔNG KHỚP'}")

    # 4. Ca kiểm thử 4: TIẾT KHÍ NHẬT (NGÀY SINH THÁNG)
    print("\n--- [CA KIỂM THỬ 4: TIẾT KHÍ NHẬT (NGÀY SINH THÁNG)] ---")
    month_case4 = "Ất Mùi"   # Sa Trung Kim
    day_case4 = "Đinh Mùi"  # Thiên Hà Thủy -> Ngày Thủy sinh Tháng Kim là Tiết Khí Nhật
    res_case4 = compare_nap_am_month_day(day_case4, month_case4) # Thủy & Kim
    exp_case4 = "Tháng Đinh Mùi(Thiên Hà Thủy), Ngày Ất Mùi(Sa Trung Kim). Tức là Ngày sinh Tháng là (Tiết Khí Nhật - Hao tổn)"
    print(f"Tháng: {day_case4} | Ngày: {month_case4}")
    print(f"Output:   {res_case4}")
    print(f"Kỳ vọng:  {exp_case4}")
    pass_case4 = (res_case4 == exp_case4)
    print(f"Kết luận: {'[PASS] KHỚP 100%' if pass_case4 else '[FAIL] KHÔNG KHỚP'}")

    # 5. Ca kiểm thử 5: CHẾ NHẬT (NGÀY KHẮC THÁNG)
    print("\n--- [CA KIỂM THỬ 5: CHẾ NHẬT (NGÀY KHẮC THÁNG)] ---")
    month_case5 = "Mậu Tuất" # Bình Địa Mộc
    day_case5 = "Ất Mùi"    # Sa Trung Kim -> Ngày Kim khắc Tháng Mộc là Chế Nhật
    res_case5 = compare_nap_am_month_day(month_case5, day_case5)
    exp_case5 = "Tháng Mậu Tuất(Bình Địa Mộc), Ngày Ất Mùi(Sa Trung Kim). Tức là Ngày khắc Tháng là (Chế Nhật)"
    print(f"Tháng: {month_case5} | Ngày: {day_case5}")
    print(f"Output:   {res_case5}")
    print(f"Kỳ vọng:  {exp_case5}")
    pass_case5 = (res_case5 == exp_case5)
    print(f"Kết luận: {'[PASS] KHỚP 100%' if pass_case5 else '[FAIL] KHÔNG KHỚP'}")

    # 6. Ca kiểm thử E2E: Ngày 23/07/2026 (10/06 Âm Lịch)
    print("\n--- [CA KIỂM THỬ E2E: BLOCK IX ĐẦY ĐỦ 6 DÒNG (NGÀY 23/07/2026)] ---")
    res = calculate_almanac_full(23, 7, 2026, 0, 0)
    
    expected_lines = [
        "Ngũ Hành Năm 2026: Bính Ngọ - Thiên Hà Thủy (Nước Trên Trời)",
        "Tháng Ất Mùi(Sa Trung Kim), Ngày Mậu Tuất(Bình Địa Mộc). Tức là Tháng khắc Ngày là (Phạt Nhật)",
        "Ngày Mậu Tuất, Tức Can(Thổ) Và Chi(Thổ) là đồng Thổ, Tức là Ngày Cát",
        "Nạp Âm (Ngày Mậu Tuất) là Bình Địa Mộc hợp với các tuổi Mùi, Dần, Tuất. Xung tuổi Giáp Tý, Canh Tý,",
        "Ngày Thuộc Hành Mộc Khắc thuận Hành Thổ và khắc nghịch hành Kim",
        "Ngày Tuất lục hợp Mão, Tam hợp Dần và Ngọ Thành Hỏa Cục. Xung Thìn, hình Sửu, hại Dậu, phá Mùi, tuyệt Hợi."
    ]
    
    actual_lines = res.get("dong_5_ngu_hanh_lines", res.get("dong_5_ngu_hanh", "").split("\n"))
    
    print("\n[KẾT QUẢ THỰC TẾ XUẤT RA TỪ HỆ THỐNG]:")
    print("--------------------------------------------------------------------------------")
    for i, line in enumerate(actual_lines, 1):
        print(f"Dòng {i}: {line}")
    print("--------------------------------------------------------------------------------")
    
    print("\n[ĐỐI CHIẾU VỚI TEST CASE MẪU]:")
    e2e_passed = True
    for i in range(len(expected_lines)):
        exp = expected_lines[i]
        act = actual_lines[i] if i < len(actual_lines) else ""
        is_match = (exp == act)
        status = "KHỚP 100% [PASS]" if is_match else "SAI BIỆT [FAIL]"
        if not is_match:
            e2e_passed = False
        print(f"Dòng {i+1}: {status}")
        if not is_match:
            print(f"  + Kỳ vọng: '{exp}'")
            print(f"  + Thực tế: '{act}'")
            
    print("================================================================================")
    all_passed = pass_case1 and pass_case2 and pass_case3 and pass_case4 and pass_case5 and e2e_passed
    if all_passed:
        print(">>> TẤT CẢ CÁC CA KIỂM THỬ VÀ 6 DÒNG BLOCK IX ĐÃ PASS 100%! CHUẨN XÁC TUYỆT ĐỐI! <<<")
    else:
        print(">>> CÓ CA KIỂM THỬ CHƯA PASS! VUI LÒNG KIỂM TRA LẠI! <<<")
    print("================================================================================")
    return all_passed

if __name__ == "__main__":
    success = run_test()
    if not success:
        sys.exit(1)

