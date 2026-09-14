import sys
import os

# Add paths
sys.path.append(r'E:\Tu vi online\AIEngine_Python')
sys.path.append(r'E:\Tu vi online\logic_service\ai_engine')

from trach_nhat_engine import calculate_trach_nhat
from ho_ngoc_duc_almanac import calculate_almanac_full

def run_tests():
    print("================================================================================")
    print("      BẮT ĐẦU KIỂM THỬ E2E: MODULE TRẠCH NHẬT ĐÁNH GIÁ NGÀY XẤU/ĐẸP (BLOCK XII) ")
    print("================================================================================")

    # --------------------------------------------------------------------------
    # CA 1: NGÀY RẤT ĐẸP (Không dính Đại Kỵ, nhiều Cát Tinh, test trần +30 điểm)
    # --------------------------------------------------------------------------
    print("\n--- [CA 1: NGÀY RẤT ĐẸP & KIỂM TRA GIỚI HẠN TRẦN +30 ĐIỂM] ---")
    mock_dai_ky_dep = {"is_cat": True, "vi_pham_list": [], "details": []}
    mock_hd_dep = {"is_good": True, "type": "Hoàng Đạo", "display_text": "Ngày Hoàng Đạo"}
    mock_truc_dep = {"short_name": "Thành"} # +15
    mock_star_dep = {"short_name": "Giác"}   # +15 (Cát Tú)
    # Danh sách rất nhiều sao cát để điểm vượt trần (+120 điểm)
    sao_tot_nhieu = [
        "Thiên Đức", "Nguyệt Đức", "Thiên Hỷ", "Tuế Đức", "Thiên Đức Hoàng Đạo",
        "Bảo Quang Hoàng Đạo", "Mẫu Thương", "Tam Hợp", "Lục Hợp"
    ]
    sao_xau_it = []

    res_dep = calculate_trach_nhat(
        dai_ky_res=mock_dai_ky_dep,
        month_cc="Ất Mùi",  # Kim
        day_cc="Bính Ngọ",  # Thủy (Tháng sinh Ngày +15, Can Chi đồng hành +5 -> Mục 2 = +20)
        ngay_hoang_hac_dao=mock_hd_dep, # +15
        truc_data=mock_truc_dep,        # +15
        star_data=mock_star_dep,        # +15
        sao_tot=sao_tot_nhieu,
        sao_xau=sao_xau_it,
        date_str="01-01-2026"
    )

    print(f"Điểm Mục 1 (Đại Kỵ): {res_dep['score_1']}")
    print(f"Điểm Mục 2 (Ngũ Hành): {res_dep['score_2']} (2A={res_dep['score_2a']}, 2B={res_dep['score_2b']})")
    print(f"Điểm Mục 3 (Hoàng Đạo): {res_dep['score_3']}")
    print(f"Điểm Mục 4 (Trực): {res_dep['score_4']}")
    print(f"Điểm Mục 5 (Sao 28): {res_dep['score_5']}")
    print(f"Điểm Mục 6 Raw: {res_dep['raw_score_6']} | Điểm Mục 6 Capped: {res_dep['score_6']}")
    print(f"Tổng Điểm: {res_dep['tong_diem']}/105")
    print(f"Phân Loại: {res_dep['phan_loai']}")
    print("\n[TEMPLATE RENDER CA 1]:")
    print("--------------------------------------------------------------------------------")
    print(res_dep['rendered_summary'])
    print("--------------------------------------------------------------------------------")

    pass_ca1 = (
        res_dep['score_1'] == 0
        and res_dep['score_6'] == 30 # Capped at +30
        and res_dep['phan_loai'] == "Ngày Rất Đẹp"
        and "Hôm nay là Ngày Rất Đẹp" in res_dep['rendered_summary']
        and "Mục 1 (Đại Kỵ) = 0 điểm." in res_dep['rendered_summary']
        and "Tối ưu cho mọi việc đại sự: Động thổ, Cưới hỏi, Khai trương, Nhập trạch." in res_dep['rendered_summary']
    )
    print(f"Kết luận Ca 1: {'[PASS] KHỚP 100%' if pass_ca1 else '[FAIL] KHÔNG KHỚP'}")

    # --------------------------------------------------------------------------
    # CA 2: NGÀY RẤT XẤU (Phạm Thọ Tử, Sát Chủ, test sàn -30 điểm và in tên sao kỵ)
    # --------------------------------------------------------------------------
    print("\n--- [CA 2: NGÀY RẤT XẤU & KIỂM TRA GIỚI HẠN SÀN -30 ĐIỂM & IN TÊN ĐẠI KỴ] ---")
    mock_dai_ky_xau = {
        "is_cat": False,
        "is_tho_tu_day": True,
        "vi_pham_list": [
            {"name": "Tam Nương", "header": "1: Ngày Tam Nương", "y_nghia": "Ý nghĩa Tam Nương"},
            {"name": "Sát Chủ Âm", "header": "192.Sát Chủ Âm", "y_nghia": "Ý nghĩa Sát Chủ Âm"}
        ],
        "details": [
            {"header": "1: Ngày Tam Nương", "y_nghia": "Ý nghĩa Tam Nương"},
            {"header": "192.Sát Chủ Âm", "y_nghia": "Ý nghĩa Sát Chủ Âm"}
        ]
    }
    mock_hd_xau = {"is_good": False, "type": "Hắc Đạo", "display_text": "Ngày Hắc Đạo"} # -15
    mock_truc_xau = {"short_name": "Phá"} # -20
    mock_star_xau = {"short_name": "Nguy"} # -15 (Hung Tú)
    sao_tot_it = []
    # Rất nhiều sao xấu để test âm sâu (-500 điểm)
    sao_xau_nhieu = [
        "Trùng Tang", "Trùng Phục", "Thiên Cương", "Hoang Ốc", "Đại Hao",
        "Ngũ Quỷ", "Kiếp Sát", "Tuế Phá", "Hà Khôi", "Thiên Lại", "Quả Tú", "Cô Thần"
    ]

    res_xau = calculate_trach_nhat(
        dai_ky_res=mock_dai_ky_xau,
        month_cc="Mậu Tuất", # Mộc
        day_cc="Giáp Thân", # Kim (Can khắc Chi -15, Ngày khắc Tháng -15 -> Mục 2 = -30)
        ngay_hoang_hac_dao=mock_hd_xau, # -15
        truc_data=mock_truc_xau,        # -20
        star_data=mock_star_xau,        # -15
        sao_tot=sao_tot_it,
        sao_xau=sao_xau_nhieu,
        date_str="29-05-2026"
    )

    print(f"Điểm Mục 1 (Đại Kỵ): {res_xau['score_1']}")
    print(f"Điểm Mục 2 (Ngũ Hành): {res_xau['score_2']} (2A={res_xau['score_2a']}, 2B={res_xau['score_2b']})")
    print(f"Điểm Mục 3 (Hoàng Đạo): {res_xau['score_3']}")
    print(f"Điểm Mục 4 (Trực): {res_xau['score_4']}")
    print(f"Điểm Mục 5 (Sao 28): {res_xau['score_5']}")
    print(f"Điểm Mục 6 Raw: {res_xau['raw_score_6']} | Điểm Mục 6 Capped: {res_xau['score_6']}")
    print(f"Tổng Điểm: {res_xau['tong_diem']}/105")
    print(f"Phân Loại: {res_xau['phan_loai']}")
    print("\n[TEMPLATE RENDER CA 2]:")
    print("--------------------------------------------------------------------------------")
    print(res_xau['rendered_summary'])
    print("--------------------------------------------------------------------------------")

    pass_ca2 = (
        res_xau['score_1'] == -60
        and res_xau['score_6'] == -30 # Capped at -30
        and res_xau['phan_loai'] == "Ngày Rất Xấu"
        and "Hôm nay là Ngày Rất Xấu" in res_xau['rendered_summary']
        and "Mục 1 (Đại Kỵ) = -60 điểm (Phạm Tam Nương, Sát Chủ Âm, Thọ Tử)." in res_xau['rendered_summary']
        and "Tuyệt đối đình chỉ các việc lớn, chỉ hợp dọn dẹp, dỡ bỏ." in res_xau['rendered_summary']
    )
    print(f"Kết luận Ca 2: {'[PASS] KHỚP 100%' if pass_ca2 else '[FAIL] KHÔNG KHỚP'}")

    # --------------------------------------------------------------------------
    # CA 3: E2E KIỂM THỬ TRỰC TIẾP QUA HO_NGOC_DUC_ALMANAC (Ngày 29/05/2026)
    # --------------------------------------------------------------------------
    print("\n--- [CA 3: E2E TÍCH HỢP HO_NGOC_DUC_ALMANAC (NGÀY 29/05/2026)] ---")
    almanac_res = calculate_almanac_full(29, 5, 2026, 0, 0)
    ket_luan_text = almanac_res.get("dong_12_ket_luan", "")
    print("[NỘI DUNG BLOCK XII XUẤT RA]:")
    print("--------------------------------------------------------------------------------")
    print(ket_luan_text[:400] + "...\n(Đã bao gồm danh sách giải nghĩa chi tiết các sao)")
    print("--------------------------------------------------------------------------------")

    pass_e2e = (
        "Hôm nay là Ngày Rất Xấu" in ket_luan_text
        and "Mục 1 (Đại Kỵ) = -60 điểm (Phạm Tam Nương, Sát Chủ Âm, Kim Thần Thất Sát)." in ket_luan_text
        and "Ứng Dụng Thực Tế: Tuyệt đối đình chỉ các việc lớn, chỉ hợp dọn dẹp, dỡ bỏ." in ket_luan_text
    )
    print(f"Kết luận Ca 3 (E2E): {'[PASS] KHỚP 100%' if pass_e2e else '[FAIL] KHÔNG KHỚP'}")

    print("\n================================================================================")
    all_passed = pass_ca1 and pass_ca2 and pass_e2e
    if all_passed:
        print(">>> TẤT CẢ CÁC CA KIỂM THỬ TRẠCH NHẬT BLOCK XII ĐÃ PASS 100%! <<<")
    else:
        print(">>> CÓ CA KIỂM THỬ CHƯA PASS! VUI LÒNG KIỂM TRA LẠI! <<<")
    print("================================================================================")
    return all_passed

if __name__ == "__main__":
    success = run_tests()
    if not success:
        sys.exit(1)
