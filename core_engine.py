import json
import sys

# Đảm bảo console in được tiếng Việt
if hasattr(sys.stdout, 'reconfigure'):
    sys.stdout.reconfigure(encoding='utf-8')

# Bảng mapping Can Chi
THIEN_CAN = ["Giáp", "Ất", "Bính", "Đinh", "Mậu", "Kỷ", "Canh", "Tân", "Nhâm", "Quý"]
DIA_CHI = ["Tý", "Sửu", "Dần", "Mão", "Thìn", "Tỵ", "Ngọ", "Mùi", "Thân", "Dậu", "Tuất", "Hợi"]

def get_can_gio(can_ngay, chi_gio):
    """Tính Thiên Can của giờ dựa vào Ngũ Thử Độn"""
    if not can_ngay or not chi_gio:
        return None
    
    can_ngay_cap = can_ngay.capitalize()
    chi_gio_cap = chi_gio.capitalize()
    
    if can_ngay_cap not in THIEN_CAN or chi_gio_cap not in DIA_CHI:
        return None
        
    can_idx = THIEN_CAN.index(can_ngay_cap)
    chi_idx = DIA_CHI.index(chi_gio_cap)
    
    ty_can_idx = ((can_idx % 5) * 2) % 10
    can_gio_idx = (ty_can_idx + chi_idx) % 10
    return THIEN_CAN[can_gio_idx]

def get_thang_kien(thang_am_lich_so):
    """
    Ánh xạ (Mapping) từ số tháng Âm lịch sang Địa Chi tương ứng (Tháng Kiến).
    """
    thang_am_lich_so = str(thang_am_lich_so).strip()
    mapping = {
        "1": "dần", "2": "mão", "3": "thìn", "4": "tỵ", "5": "ngọ", "6": "mùi",
        "7": "thân", "8": "dậu", "9": "tuất", "10": "hợi", "11": "tý", "12": "sửu"
    }
    return mapping.get(thang_am_lich_so, "")

def get_than_sat(thang_am_lich, can_nam, can_ngay, chi_ngay, selected_hour_chi=None, mua=None, truc_ngay=None, ngay_am_lich=None, chi_nam=None):
    """
    Quét qua file than_sat_db.json để xác định các sao Tốt / Xấu trong ngày,
    sử dụng cơ chế Condition Router đa điều kiện.
    - thang_am_lich: "1", "2", ..., "12"
    - can_nam: "giáp", "ất"... (Dùng để suy ra Can Tháng theo Ngũ Hổ Độn)
    - can_ngay: "giáp", "ất", ...
    - chi_ngay: "tý", "sửu", ...
    - selected_hour_chi: "tý", "sửu", ... (Chi giờ hiện tại để xét điều kiện sao theo giờ)
    - mua: "mùa xuân", "mùa hạ", "mùa thu", "mùa đông" (nếu None sẽ tự đoán theo thang_am_lich)
    - truc_ngay: "kiến", "trừ", "mãn", "bình", "định", "chấp", "phá", "nguy", "thành", "thâu", "khai", "bế"
    - ngay_am_lich: "1", "2", ..., "30"
    - chi_nam: "tý", "sửu", ..., "hợi" (Để xác định các sao theo năm như Tuế Phá)
    """
    
    # Sử dụng đường dẫn tuyệt đối để tránh lỗi khi run từ thư mục khác
    import os
    BASE_DIR = os.path.abspath(os.path.dirname(__file__))
    db_path = os.path.join(BASE_DIR, "than_sat_db.json")
    
    with open(db_path, "r", encoding="utf-8") as f:
        db = json.load(f)
        
    sao_tot = []
    sao_xau = []
    
    # 1. Khởi tạo & Chuẩn hóa dữ liệu đầu vào
    thang_am_lich = str(thang_am_lich).strip()
    can_nam = can_nam.strip().lower()
    can_ngay = can_ngay.strip().lower()
    chi_ngay = chi_ngay.strip().lower()
    
    if not mua:
        # Tiên đoán Mùa theo Tháng Âm Lịch (Tháng 1-3: Xuân, 4-6: Hạ, 7-9: Thu, 10-12: Đông)
        if thang_am_lich in ["1", "2", "3"]: mua = "mùa xuân"
        elif thang_am_lich in ["4", "5", "6"]: mua = "mùa hạ"
        elif thang_am_lich in ["7", "8", "9"]: mua = "mùa thu"
        elif thang_am_lich in ["10", "11", "12"]: mua = "mùa đông"
    else:
        mua = mua.strip().lower()

    # Danh sách đối chiếu (Look-up maps)
    list_can = ["giáp", "ất", "bính", "đinh", "mậu", "kỷ", "canh", "tân", "nhâm", "quý"]
    list_chi = ["tý", "sửu", "dần", "mão", "thìn", "tỵ", "ngọ", "mùi", "thân", "dậu", "tuất", "hợi"]

    # Tính Can Chi của tháng dựa trên Ngũ Hổ Độn
    # Giáp, Kỷ -> Bính (idx=2)
    # Ất, Canh -> Mậu (idx=4)
    # Bính, Tân -> Canh (idx=6)
    # Đinh, Nhâm -> Nhâm (idx=8)
    # Mậu, Quý -> Giáp (idx=0)
    ngu_ho_don_map = {"giáp": 2, "kỷ": 2, "ất": 4, "canh": 4, "bính": 6, "tân": 6, "đinh": 8, "nhâm": 8, "mậu": 0, "quý": 0}
    
    if can_nam in ngu_ho_don_map and thang_am_lich.isdigit():
        idx_can_tháng_1 = ngu_ho_don_map[can_nam]
        can_thang_idx = (idx_can_tháng_1 + int(thang_am_lich) - 1) % 10
        can_thang = list_can[can_thang_idx]
        chi_thang = get_thang_kien(thang_am_lich)
        print(f"[HỆ THỐNG] Ngũ Hổ Độn: Năm {can_nam.capitalize()} -> Tháng {thang_am_lich} Âm Lịch là tháng {can_thang.capitalize()} {chi_thang.capitalize()}")
    else:
        can_thang = ""
        chi_thang = get_thang_kien(thang_am_lich)

    # Vòng lặp duyệt TẤT CẢ sao, không break giữa chừng
    for star in db:
        logic = star.get("logic_an_sao", {})
        phan_loai = star.get("phan_loai", "")
        ten_sao = star.get("ten_sao", "")
        
        has_day_rule = False
        has_hour_rule = False
        has_month_rule = False
        has_season_rule = False
        has_year_rule = False
        match_day = False
        match_hour = False
        match_year = False
        matched_truc = False
        matched_day_normal = False
        
        thang_chi = get_thang_kien(thang_am_lich)
        
        for k, v in logic.items():
            if k.startswith("thang_") or k in ["can_ngay", "chi_ngay", "can_chi_ngay", "truc_ngay", "ngay_am_lich"]:
                has_day_rule = True
                if k.startswith("thang_"):
                    has_month_rule = True
                    if k.startswith("thang_mùa"):
                        has_season_rule = True
                    k_val = k.replace("thang_", "").strip().lower()
                    match_time = False
                    
                    if k_val == thang_chi: match_time = True
                    elif k_val == thang_am_lich: match_time = True
                    elif mua and k_val == mua: match_time = True
                    elif k_val == "giêng" and thang_am_lich == "1": match_time = True
                    elif k_val == "chạp" and thang_am_lich == "12": match_time = True
                    elif k_val == "một" and thang_am_lich == "11": match_time = True
                    
                    if match_time:
                        can_chi_full = f"{can_ngay.capitalize()} {chi_ngay.capitalize()}"
                        if "can_chi_ngay" in v and can_chi_full in v["can_chi_ngay"]:
                            match_day = True
                            matched_day_normal = True
                        if "can_ngay" in v and can_ngay.capitalize() in v["can_ngay"]:
                            match_day = True
                            matched_day_normal = True
                        if "chi_ngay" in v and chi_ngay.capitalize() in v["chi_ngay"]:
                            match_day = True
                            matched_day_normal = True
                        if "ngay_am_lich" in v and ngay_am_lich and str(ngay_am_lich) in [str(x) for x in v["ngay_am_lich"]]:
                            match_day = True
                            matched_day_normal = True
                        if "truc_ngay" in v and truc_ngay and truc_ngay.capitalize() in v["truc_ngay"]:
                            match_day = True
                            matched_truc = True
                
                elif k == "can_ngay":
                    if can_ngay.capitalize() in v:
                        match_day = True
                        matched_day_normal = True
                elif k == "chi_ngay":
                    if chi_ngay.capitalize() in v:
                        match_day = True
                        matched_day_normal = True
                elif k == "can_chi_ngay":
                    can_chi_full = f"{can_ngay.capitalize()} {chi_ngay.capitalize()}"
                    if can_chi_full in v:
                        match_day = True
                        matched_day_normal = True
                elif k == "truc_ngay" and truc_ngay:
                    if truc_ngay.capitalize() in v:
                        match_day = True
                        matched_truc = True
                elif k == "ngay_am_lich" and ngay_am_lich:
                    if str(ngay_am_lich) in [str(x) for x in v]:
                        match_day = True
                        matched_day_normal = True
            
            elif k == "theo_can_nam":
                has_year_rule = True
                if can_nam and can_nam.lower() in v:
                    conds = v[can_nam.lower()]
                    can_chi_full = f"{can_ngay.capitalize()} {chi_ngay.capitalize()}"
                    if "chi_ngay" in conds and chi_ngay.capitalize() in conds["chi_ngay"]:
                        match_day = True
                        match_year = True
                    if "can_ngay" in conds and can_ngay.capitalize() in conds["can_ngay"]:
                        match_day = True
                        match_year = True
                    if "can_chi_ngay" in conds and can_chi_full in conds["can_chi_ngay"]:
                        match_day = True
                        match_year = True

            elif k == "theo_nam":
                has_year_rule = True
                if chi_nam:
                    nam_key = f"nam_{chi_nam.lower()}"
                    if nam_key in v:
                        conds = v[nam_key]
                        can_chi_full = f"{can_ngay.capitalize()} {chi_ngay.capitalize()}"
                        if "chi_ngay" in conds and chi_ngay.capitalize() in conds["chi_ngay"]:
                            match_day = True
                            match_year = True
                        if "can_ngay" in conds and can_ngay.capitalize() in conds["can_ngay"]:
                            match_day = True
                            match_year = True
                        if "can_chi_ngay" in conds and can_chi_full in conds["can_chi_ngay"]:
                            match_day = True
                            match_year = True

            elif k == "theo_can_thang":
                has_month_rule = True
                has_day_rule = True
                if can_thang and can_thang.lower() in v:
                    conds = v[can_thang.lower()]
                    can_chi_full = f"{can_ngay.capitalize()} {chi_ngay.capitalize()}"
                    if "chi_ngay" in conds and chi_ngay.capitalize() in conds["chi_ngay"]:
                        match_day = True
                        matched_day_normal = True
                    if "can_ngay" in conds and can_ngay.capitalize() in conds["can_ngay"]:
                        match_day = True
                        matched_day_normal = True
                    if "can_chi_ngay" in conds and can_chi_full in conds["can_chi_ngay"]:
                        match_day = True
                        matched_day_normal = True
            
            elif k == "theo_gio":
                has_hour_rule = True
                if selected_hour_chi:
                    hour_chi_cap = selected_hour_chi.capitalize()
                    
                    # Dò theo Can Ngày
                    can_key = f"can_ngay_{can_ngay.lower()}"
                    if can_key in v:
                        hour_conds = v[can_key]
                        allowed_hours = []
                        if "chi_gio" in hour_conds:
                            allowed_hours.extend(hour_conds["chi_gio"])
                        if "can_chi_gio" in hour_conds:
                            allowed_hours.extend([h.split()[1] if ' ' in h else h for h in hour_conds["can_chi_gio"]])
                        
                        if hour_chi_cap in allowed_hours:
                            match_hour = True
                    
                    # Dò theo Chi Ngày
                    chi_key = f"chi_ngay_{chi_ngay.lower()}"
                    if chi_key in v:
                        hour_conds = v[chi_key]
                        allowed_hours = []
                        if "chi_gio" in hour_conds:
                            allowed_hours.extend(hour_conds["chi_gio"])
                        if "can_chi_gio" in hour_conds:
                            allowed_hours.extend([h.split()[1] if ' ' in h else h for h in hour_conds["can_chi_gio"]])
                        
                        if hour_chi_cap in allowed_hours:
                            match_hour = True
                            
            elif k == "theo_can_ngay_can_gio":
                has_hour_rule = True
                if selected_hour_chi:
                    can_gio = get_can_gio(can_ngay, selected_hour_chi)
                    if can_gio:
                        can_ngay_cap = can_ngay.capitalize()
                        if can_ngay_cap in v:
                            allowed_cans = [c.capitalize() for c in v[can_ngay_cap]]
                            if can_gio in allowed_cans:
                                match_hour = True
                                
            elif k == "theo_can_ngay_canchi_gio":
                has_hour_rule = True
                if selected_hour_chi:
                    can_gio = get_can_gio(can_ngay, selected_hour_chi)
                    if can_gio:
                        can_chi_gio = f"{can_gio} {selected_hour_chi.capitalize()}"
                        can_ngay_cap = can_ngay.capitalize()
                        if can_ngay_cap in v:
                            allowed_canchis = [c.capitalize() for c in v[can_ngay_cap]]
                            if can_chi_gio in allowed_canchis:
                                match_hour = True

        # 3. Khớp & Ghi nhận (Match & Append)
        show_star = False
        ten_sao_final = ten_sao
        
        if has_year_rule and match_year:
            show_star = True
            ten_sao_final = f"{ten_sao} (Theo Năm)"
        elif has_day_rule and not has_hour_rule:
            if match_day:
                show_star = True
                if has_season_rule:
                    ten_sao_final = f"{ten_sao} (Theo Mùa)"
                elif matched_truc and matched_day_normal:
                    ten_sao_final = f"{ten_sao} (Theo Trực Tháng Ngày)"
                elif matched_truc:
                    ten_sao_final = f"{ten_sao} (Theo Trực)"
        elif not has_day_rule and has_hour_rule:
            if match_hour:
                show_star = True
                ten_sao_final = f"{ten_sao} (Theo Giờ)"
        elif has_day_rule and has_hour_rule:
            if match_day and not match_hour:
                show_star = True
                if has_season_rule:
                    ten_sao_final = f"{ten_sao} (Theo Mùa)"
                elif matched_truc and matched_day_normal:
                    ten_sao_final = f"{ten_sao} (Theo Trực Tháng Ngày)"
                elif matched_truc:
                    ten_sao_final = f"{ten_sao} (Theo Trực)"
            elif not match_day and match_hour:
                show_star = True
                ten_sao_final = f"{ten_sao} (Theo Giờ)"
            elif match_day and match_hour:
                show_star = True
                if has_season_rule:
                    ten_sao_final = f"{ten_sao} (Theo Mùa Giờ)"
                elif matched_truc and matched_day_normal:
                    ten_sao_final = f"{ten_sao} (Theo Trực Tháng Ngày Giờ)"
                elif matched_truc:
                    ten_sao_final = f"{ten_sao} (Theo Trực Giờ)"
                elif has_month_rule:
                    ten_sao_final = f"{ten_sao} (Theo Tháng Ngày Giờ)"
                else:
                    ten_sao_final = f"{ten_sao} (Theo Ngày Giờ)"
                
        if show_star:
            if phan_loai == "Cát Tinh":
                sao_tot.append(ten_sao_final)
            elif phan_loai == "Hung Tinh":
                sao_xau.append(ten_sao_final)

    return sao_tot, sao_xau

if __name__ == "__main__":
    # 4. Nghiệm thu bắt buộc: Ngày 07/08/2027 (Năm Đinh Mùi, Tháng 7 Âm lịch, Ngày Mậu Ngọ)
    tot, xau = get_than_sat(thang_am_lich="7", can_nam="đinh", can_ngay="mậu", chi_ngay="ngọ")
    
    # Lọc lấy tên sao ngắn gọn để đối chiếu
    tot_clean = [s.split('.')[1].split('-')[0].strip() if '.' in s else s for s in tot]
    xau_clean = [s.split('.')[1].split('-')[0].strip() if '.' in s else s for s in xau]
    
    print("==================================================")
    print("   NGHIỆM THU NGÀY 07/08/2027 (THÁNG 7 ÂM, MẬU NGỌ)")
    print("==================================================")
    print(f"Sao tốt: {', '.join(tot_clean)}")
    print(f"Sao xấu: {', '.join(xau_clean)}")
    print("==================================================")
