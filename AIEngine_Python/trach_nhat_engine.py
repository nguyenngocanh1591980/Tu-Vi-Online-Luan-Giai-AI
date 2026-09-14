"""
Module trach_nhat_engine.py
Tính toán điểm số Trạch Nhật 6 Hạng Mục (-165 đến +105 điểm) và Phân Loại Ngày Đẹp/Xấu.
Nguồn dữ liệu tham chiếu 100% nguyên văn:
E:\\Tu vi online\\AI học tử vi\\Thư Viện cho AI Học\\Tầng 1- Dữ Liệu Chuẩn Hóa\\Mô hình Tính toán Tổng Kết xác định ngày xấu ngày đẹp(Đã chỉnh lý).docx
"""

from typing import Dict, Any, List, Tuple
import os
import json

# Danh sách phân loại Nhị Thập Bát Tú
CAT_TU_LIST = [
    "Giác", "Phòng", "Vĩ", "Cơ", "Đẩu", "Thất", "Bích",
    "Lâu", "Vị", "Tất", "Sâm", "Tỉnh", "Trương", "Chẩn"
]
BINH_TU_LIST = ["Khuê", "Tinh", "Dực"]
HUNG_TU_LIST = [
    "Cang", "Đê", "Tâm", "Ngưu", "Nữ", "Hư",
    "Nguy", "Mão", "Chủy", "Quỷ", "Liễu"
]

# Thập Nhị Trực
TRUC_DAI_CAT = ["Thành", "Mãn", "Khai"]
TRUC_TIEU_CAT = ["Kiến", "Định"]
TRUC_BINH_HOA = ["Bình", "Chấp", "Thu", "Thâu", "Trừ"]
TRUC_HUNG = ["Bế", "Nguy"]
TRUC_DAI_HUNG = ["Phá"]

# Thần Sát Phân Nhóm Điểm
DAI_CAT_TINH = {
    "Thiên Đức", "Nguyệt Đức", "Thiên Hỷ", "Tuế Đức", "Thiên Đức Hợp",
    "Nguyệt Đức Hợp", "Thiên Phú", "Thiên Quan", "Tư Mệnh Hoàng Đạo",
    "Thiên Đức Hoàng Đạo", "Ngọc Đường Hoàng Đạo", "Kim Đường Hoàng Đạo",
    "Thanh Long Hoàng Đạo", "Minh Đường Hoàng Đạo", "Bảo Quang Hoàng Đạo",
    "Địa Tài(Bảo Quang Hoàng Đạo)", "Thiên Tài(Kim Qũy Hoàng Đạo)", "Kim Quĩ Hoàng Đạo"
}

DAI_HUNG_TINH = {
    "Trùng Tang", "Trùng Phục", "Thiên Cương", "Hoang Ốc", "Đại Hao",
    "Ngũ Quỷ", "Kiếp Sát", "Tuế Phá", "Hà Khôi", "Thiên Lại", "Quả Tú",
    "Cô Thần", "Băng Tiêu Ngõa Hãm", "Đại Hoạ", "Nguyệt Hình", "Thổ Phủ",
    "Thiên Ôn", "Thổ Ôn", "Thiên Ngục", "Hoang Vu", "Tiểu Hồng Sa"
}

def clean_star_name(star_raw: str) -> str:
    """Làm sạch tên sao, loại bỏ hậu tố như '(Theo Giờ)', '- 青龍', v.v."""
    s = star_raw.split("(")[0].split("-")[0].strip()
    return s

def calculate_trach_nhat(
    dai_ky_res: Dict[str, Any],
    month_cc: str,
    day_cc: str,
    ngay_hoang_hac_dao: Dict[str, Any],
    truc_data: Dict[str, Any],
    star_data: Dict[str, Any],
    sao_tot: List[str],
    sao_xau: List[str],
    date_str: str = ""
) -> Dict[str, Any]:
    """
    Tính điểm 6 hạng mục Trạch Nhật và phân loại ngày:
    Thang điểm: -165 đến +105 điểm.
    """
    # -------------------------------------------------------------
    # 1. HẠNG MỤC 1: Ngày Đại Kỵ Cố Định (Trọng số loại trừ)
    # -------------------------------------------------------------
    vi_pham_raw = [v.get("name", "") for v in dai_ky_res.get("vi_pham_list", [])]
    if dai_ky_res.get("is_tho_tu_day") and "Thọ Tử" not in vi_pham_raw:
        vi_pham_raw.append("Thọ Tử")

    # Lọc danh sách vi phạm duy nhất
    vi_pham_names = []
    for vp in vi_pham_raw:
        if vp and vp not in vi_pham_names:
            vi_pham_names.append(vp)

    severe_set = {"Tứ Ly", "Tứ Tuyệt", "Thọ Tử", "Sát Chủ Âm", "Sát Chủ Dương", "Sát Chủ", "Dương Công Kỵ Nhật", "Kim Thần Thất Sát"}
    
    if not vi_pham_names and dai_ky_res.get("is_cat", True):
        score_1 = 0
        muc_1_str = "Mục 1 (Đại Kỵ) = 0 điểm."
    else:
        has_severe = any(vp in severe_set for vp in vi_pham_names)
        score_1 = -60 if has_severe else -40
        names_joined = ", ".join(vi_pham_names)
        muc_1_str = f"Mục 1 (Đại Kỵ) = {score_1} điểm (Phạm {names_joined})."

    # -------------------------------------------------------------
    # 2. HẠNG MỤC 2: Quan Hệ Ngũ Hành Tiết Khí & Can Chi Ngày
    # -------------------------------------------------------------
    try:
        from ngu_hanh_engine import compare_nap_am_month_day, _get_db, CAN_HANH, CHI_HANH, SINH_MAP
        db = _get_db()
        can_chi_map = db.get("map", db)
    except Exception:
        can_chi_map = {}
        CAN_HANH = {}
        CHI_HANH = {}
        SINH_MAP = {}

    # A. Tiết khí Tháng - Ngày
    score_2a = 0
    m_info = can_chi_map.get(month_cc, {})
    d_info = can_chi_map.get(day_cc, {})
    m_hanh = m_info.get("hanh_nap_am", "")
    d_hanh = d_info.get("hanh_nap_am", "")

    sinh_map = {"Kim": "Thủy", "Thủy": "Mộc", "Mộc": "Hỏa", "Hỏa": "Thổ", "Thổ": "Kim"}
    khac_map = {"Kim": "Mộc", "Mộc": "Thổ", "Thổ": "Thủy", "Thủy": "Hỏa", "Hỏa": "Kim"}

    if m_hanh and d_hanh:
        if m_hanh == d_hanh:
            score_2a = 5   # Tỷ Hòa (+5)
        elif sinh_map.get(m_hanh) == d_hanh:
            score_2a = 15  # Tháng sinh Ngày (+15)
        elif khac_map.get(m_hanh) == d_hanh:
            score_2a = -10 # Tháng khắc Ngày (-10)
        elif sinh_map.get(d_hanh) == m_hanh:
            score_2a = -15 # Ngày sinh Tháng (-15)
        elif khac_map.get(d_hanh) == m_hanh:
            score_2a = -15 # Ngày khắc Tháng (-15)

    # B. Nội bộ Can Chi Ngày
    score_2b = 0
    day_parts = day_cc.split()
    can_ngay = day_parts[0] if len(day_parts) > 0 else "Bính"
    chi_ngay = day_parts[1] if len(day_parts) > 1 else "Ngọ"
    h_can = CAN_HANH.get(can_ngay, "")
    h_chi = CHI_HANH.get(chi_ngay, "")

    if h_can and h_chi:
        if h_can == h_chi:
            score_2b = 5   # Đồng Hành / Tỷ Hòa (+5)
        elif sinh_map.get(h_can) == h_chi:
            score_2b = 15  # Can sinh Chi (Đại Cát Thuận) (+15)
        elif sinh_map.get(h_chi) == h_can:
            score_2b = 10  # Chi sinh Can (Tiểu Cát Nghịch) (+10)
        else:
            score_2b = -15 # Can Chi tương khắc (-15)

    score_2 = score_2a + score_2b

    # -------------------------------------------------------------
    # 3. HẠNG MỤC 3: Ngày Hoàng Đạo / Hắc Đạo
    # -------------------------------------------------------------
    is_hoang_dao = ngay_hoang_hac_dao.get("is_good", False) or (ngay_hoang_hac_dao.get("type") == "Hoàng Đạo")
    score_3 = 15 if is_hoang_dao else -15

    # -------------------------------------------------------------
    # 4. HẠNG MỤC 4: Thập Nhị Trực
    # -------------------------------------------------------------
    truc_name = truc_data.get("short_name", "").replace("Trực ", "").strip()
    if truc_name in TRUC_DAI_CAT:
        score_4 = 15
    elif truc_name in TRUC_TIEU_CAT:
        score_4 = 10
    elif truc_name in TRUC_BINH_HOA:
        score_4 = 0
    elif truc_name in TRUC_HUNG:
        score_4 = -10
    elif truc_name in TRUC_DAI_HUNG:
        score_4 = -20
    else:
        score_4 = 0

    # -------------------------------------------------------------
    # 5. HẠNG MỤC 5: Nhị Thập Bát Tú (28 Sao)
    # -------------------------------------------------------------
    star_name = star_data.get("short_name", "").replace("Sao ", "").strip()
    if star_name in CAT_TU_LIST:
        score_5 = 15
    elif star_name in BINH_TU_LIST:
        score_5 = 0
    elif star_name in HUNG_TU_LIST:
        score_5 = -15
    else:
        score_5 = 0

    # -------------------------------------------------------------
    # 6. HẠNG MỤC 6: Thần Sát Trạch Nhật (Sao Phụ)
    # -------------------------------------------------------------
    raw_score_6 = 0
    for s in sao_tot:
        s_clean = clean_star_name(s)
        if any(dk in s_clean for dk in DAI_CAT_TINH):
            raw_score_6 += 20
        else:
            raw_score_6 += 10

    for s in sao_xau:
        s_clean = clean_star_name(s)
        if any(dh in s_clean for dh in DAI_HUNG_TINH):
            raw_score_6 -= 25
        else:
            raw_score_6 -= 10

    # Ràng buộc trần +30 và sàn -30
    score_6 = max(-30, min(30, raw_score_6))

    # -------------------------------------------------------------
    # TỔNG ĐIỂM & PHÂN LOẠI
    # -------------------------------------------------------------
    tong_diem = score_1 + score_2 + score_3 + score_4 + score_5 + score_6
    tong_diem = max(-165, min(105, tong_diem))

    # Phân loại theo Bảng Khung Điểm (Hình 4)
    if score_1 <= -60 or tong_diem <= -60:
        phan_loai = "Ngày Rất Xấu"
        dien_giai = "Phạm các mã Đại Kỵ cố định"
        ung_dung = "Tuyệt đối đình chỉ các việc lớn, chỉ hợp dọn dẹp, dỡ bỏ."
    elif score_1 == -40 or tong_diem <= -20:
        phan_loai = "Ngày Xấu"
        dien_giai = "Nhiều Hung tinh/Hung tú hoặc dính Tam Nương, Nguyệt Kỵ"
        ung_dung = "Hạn chế việc đại sự, tránh khai trương hay ký kết lớn."
    elif tong_diem >= 65 and score_1 == 0:
        phan_loai = "Ngày Rất Đẹp"
        truc_part = f"Trực Cát Là Trực {truc_name}" if (truc_name in TRUC_DAI_CAT or truc_name in TRUC_TIEU_CAT) else f"Trực {truc_name}"
        hd_part = "là Ngày Hoàng Đạo" if is_hoang_dao else "là Ngày Hắc Đạo"
        
        # Lấy tên các sao cát nổi bật
        notable_stars = [s for s in sao_tot if ("Đức" in s or "Hoàng Đạo" in s or "Thiên" in s or "Quang" in s) and "Theo Giờ" not in s]
        if notable_stars:
            stars_str = f" Có Sao {' và Sao '.join(notable_stars[:2])} trong ngày"
        else:
            stars_str = ""
        dien_giai = f"Cát khí vượng, có {truc_part} và {hd_part}{stars_str}"
        ung_dung = "Tối ưu cho mọi việc đại sự: Động thổ, Cưới hỏi, Khai trương, Nhập trạch."
    elif tong_diem >= 20 and score_1 == 0:
        phan_loai = "Ngày Đẹp"
        dien_giai = "Mục 1 (Đại Kỵ) = 0 điểm. Tổng các yếu tố Cát lấn áp Hung"
        ung_dung = "Tiến hành tốt các công việc quan trọng, xuất hành, giao dịch lớn."
    else:
        phan_loai = "Ngày Bình Thường"
        dien_giai = "Không dính Đại Kỵ nặng (-60 điểm). Cát tinh và Hung tinh cân bằng"
        ung_dung = "Phù hợp sinh hoạt hàng ngày, việc nhỏ, ký kết ngắn hạn."

    # Render Template Header
    rendered_summary = (
        f"Hôm nay là {phan_loai} Với Khung điểm là {tong_diem} điểm/105 điểm với\n\n"
        f"{muc_1_str}\n"
        f"{dien_giai}. Ứng Dụng Thực Tế: {ung_dung}"
    )

    # Ghép với chi tiết giải nghĩa cũ
    details = dai_ky_res.get("details", [])
    details_texts = [f"{d['header']}\nÝ Nghĩa: {d['y_nghia']}" for d in details]
    
    if details_texts:
        full_rendered_text = f"{rendered_summary}\n\n" + "\n\n".join(details_texts)
    else:
        full_rendered_text = rendered_summary

    return {
        "phan_loai": phan_loai,
        "tong_diem": tong_diem,
        "score_1": score_1,
        "score_2": score_2,
        "score_2a": score_2a,
        "score_2b": score_2b,
        "score_3": score_3,
        "score_4": score_4,
        "score_5": score_5,
        "score_6": score_6,
        "raw_score_6": raw_score_6,
        "muc_1_str": muc_1_str,
        "dien_giai": dien_giai,
        "ung_dung": ung_dung,
        "rendered_summary": rendered_summary,
        "full_rendered_text": full_rendered_text,
    }
