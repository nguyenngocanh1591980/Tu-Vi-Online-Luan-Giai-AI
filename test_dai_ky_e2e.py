import sys
import os

sys.path.append(r'E:\Tu vi online\AIEngine_Python')
sys.path.append(r'E:\Tu vi online\logic_service\ai_engine')

from ho_ngoc_duc_almanac import calculate_almanac_full

def run_e2e_tests():
    print("================================================================================")
    print("           BẮT ĐẦU KIỂM THỬ AUTO-TEST E2E: MODULE NGÀY ĐẠI KỴ & THỌ TỬ          ")
    print("================================================================================")

    # -------------------------------------------------------------------------
    # Ca 1: Ngày 22/07/2022 (Nhánh 1: Ngày Cát)
    # -------------------------------------------------------------------------
    print("\n--------------------------------------------------------------------------------")
    print("[CA KIỂM THỬ 1]: Ngày 22/07/2022 (Không phạm bất kỳ Đại Kỵ nào -> Ngày Cát)")
    print("--------------------------------------------------------------------------------")
    res1 = calculate_almanac_full(22, 7, 2022, 8, 0)
    dai_ky_1 = res1["module_dai_ky"]
    text1 = res1["dong_4_ngay_ky"]
    print("Kết quả xuất ra:")
    print(text1)
    exp1 = "Ngày 22-07-2022 là Ngày Cát (Không Phạm các trường hợp Đại Kỵ trong Năm là Tam Nương, Nguyệt Kỵ...)"
    assert dai_ky_1["is_cat"] == True, "Ca 1 phải là Ngày Cát!"
    assert text1 == exp1, f"Ca 1 text không khớp!\nThực tế: {text1}\nKỳ vọng: {exp1}"
    print("=> CA 1: KHỚP 100% [PASS]")

    # -------------------------------------------------------------------------
    # Ca 2: Ngày phạm Sát Chủ Âm (Kiểm tra chuỗi Ý nghĩa ghép chuẩn xác)
    # -------------------------------------------------------------------------
    print("\n--------------------------------------------------------------------------------")
    print("[CA KIỂM THỬ 2]: Ngày 23/07/2026 (Tháng 6 Âm Lịch, Ngày Mậu Tuất -> Phạm Sát Chủ Âm)")
    print("--------------------------------------------------------------------------------")
    res2 = calculate_almanac_full(23, 7, 2026, 8, 0)
    dai_ky_2 = res2["module_dai_ky"]
    text2 = res2["dong_4_ngay_ky"]
    print("Kết quả xuất ra:")
    print(text2)
    assert dai_ky_2["is_cat"] == False, "Ca 2 không được là Ngày Cát!"
    sat_chu_am_detail = next((d for d in dai_ky_2["details"] if "Sát Chủ Âm" in d["header"]), None)
    assert sat_chu_am_detail is not None, "Ca 2 phải có chi tiết Sát Chủ Âm!"
    exp_sat_chu_am_yn = "Được xem là ngày dễ gây hao tài, tổn thất và vận xui. Nếu làm việc lớn vào ngày này có thể ảnh hưởng đến gia đạo và tài lộc. Sát chủ Âm đây là những ngày xấu, đại kỵ cho các công việc liên quan đến phần âm, mồ mả, mai táng, cải táng, bốc mộ hoặc ma chay."
    assert sat_chu_am_detail["y_nghia"] == exp_sat_chu_am_yn, "Ý nghĩa Sát Chủ Âm không khớp!"
    print("=> CA 2: KHỚP 100% [PASS]")

    # -------------------------------------------------------------------------
    # Ca 3: Ngày phạm CẢ Ngày & Giờ Thọ Tử (Kịch bản 3.3)
    # -------------------------------------------------------------------------
    print("\n--------------------------------------------------------------------------------")
    print("[CA KIỂM THỬ 3]: Ngày 19/07/2026 (06/06 Âm Lịch, Ngày Giáp Ngọ, lúc 14:00 Giờ Mùi -> Phạm Cả Ngày & Giờ Thọ Tử)")
    print("--------------------------------------------------------------------------------")
    res3 = calculate_almanac_full(19, 7, 2026, 14, 0)
    dai_ky_3 = res3["module_dai_ky"]
    text3 = res3["dong_4_ngay_ky"]
    print("Kết quả xuất ra:")
    print(text3)
    assert dai_ky_3["is_cat"] == False, "Ca 3 không được là Ngày Cát!"
    assert dai_ky_3["is_tho_tu_day"] == True, "Ca 3 phải phạm Ngày Thọ Tử!"
    assert dai_ky_3["is_tho_tu_hour"] == True, "Ca 3 phải phạm Giờ Thọ Tử!"
    exp_line_1_3 = "Ngày 19-07-2026 là Ngày Đại Kỵ vì phạm vào Ngày Thọ Tử và Cả giờ Thọ Tử nên kiêng mọi chuyện"
    assert dai_ky_3["line_1"] == exp_line_1_3, f"Line 1 Ca 3 không khớp!\nThực tế: {dai_ky_3['line_1']}\nKỳ vọng: {exp_line_1_3}"
    print("=> CA 3: KHỚP 100% [PASS]")

    # -------------------------------------------------------------------------
    # Ca 4: Ngày Tứ Tuyệt (Trước ngày Lập Xuân 1 ngày - kiểm chứng module móc nối Tiết Khí)
    # -------------------------------------------------------------------------
    print("\n--------------------------------------------------------------------------------")
    print("[CA KIỂM THỬ 4]: Ngày 03/02/2026 (Trước Lập Xuân 04/02/2026 đúng 1 ngày -> Ngày Tứ Tuyệt)")
    print("--------------------------------------------------------------------------------")
    res4 = calculate_almanac_full(3, 2, 2026, 8, 0)
    dai_ky_4 = res4["module_dai_ky"]
    text4 = res4["dong_4_ngay_ky"]
    print("Kết quả xuất ra:")
    print(text4)
    assert dai_ky_4["is_cat"] == False, "Ca 4 không được là Ngày Cát!"
    tu_tuyet_detail = next((d for d in dai_ky_4["details"] if "Tứ Tuyệt" in d["header"]), None)
    assert tu_tuyet_detail is not None, "Ca 4 phải nhận diện đúng Ngày Tứ Tuyệt từ Tiết Khí!"
    print("=> CA 4: KHỚP 100% [PASS]")

    print("\n================================================================================")
    print(">>> TẤT CẢ 4 CA KIỂM THỬ ĐÃ PASS HOÀN TOÀN VỚI ĐỘ CHUẨN XÁC TUYỆT ĐỐI! <<<")
    print("================================================================================")

if __name__ == "__main__":
    run_e2e_tests()
