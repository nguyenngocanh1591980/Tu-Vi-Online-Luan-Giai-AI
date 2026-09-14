import json
import re

# Chuẩn hóa 8 nhóm Cát Tinh và 8 nhóm Hung Tinh từ tài liệu gốc
CAT_TINH_GROUPS = [
    ("Nhóm 1: Tốt mọi việc", [
        "Âm Đức", "Bảo Quang", "Đại Hồng Sa", "Hoạt Diệu", "Ích Hậu", "Kim Đường Hoàng Đạo", 
        "Lục Hợp", "Minh Đường Hoàng Đạo", "Minh Tinh", "Ngọc Đường Hoàng Đạo", "Ngọc Vũ", 
        "Ngũ Hợp", "Ngũ Phú(Ngũ Phúc)", "Nguyệt Ân", "Nguyệt Đức", "Phổ Hộ", "Phúc Hậu", 
        "Phúc Sinh", "Tam Hợp", "Thanh Long Hoàng Đạo", "Thánh Tâm", "Thiên Ân", 
        "Thiên Đức Hoàng Đạo", "Thiên Hỷ", "Thiên Phú", "Thiên Quan (Tư Mệnh Hoàng Đạo)", 
        "Thiên Quý", "Thời Âm", "Thời Dương", "Tục Thế", "Tuế Đức Hợp", "Tuế Lộc", 
        "Vương Nhật", "Yếu An", "Mãn Đức Tinh", "U vi tinh", "Nguyệt Giải", "Cát Khánh", 
        "Thiên Thành", "Tuế Hợp", "Yến Yên", "Hoàng Ân", "Nhân Chuyên"
    ]),
    ("Nhóm 2: Tốt đối với xuất hành, di chuyển chỗ ở", [
        "Âm Quý", "Binh Bảo – Binh Cát – Binh Phúc", "Dịch Mã", "Dương Quý", "Hỉ Thần", 
        "Nguyệt Đức Hợp", "Nguyệt Tài", "Phúc Đức", "Phúc Tinh", "Thiên Mã(Lộc Mã)", 
        "Thiên Tài(Kim Qũy Hoàng Đạo)"
    ]),
    ("Nhóm 3: Tốt với các nghi lễ hôn thú", [
        "Âm Quý", "Bất Tương", "Binh Bảo – Binh Cát – Binh Phúc", "Cát Kì", "Dương Đức", 
        "Dương Quý", "Hỉ Thần", "Kim Quĩ Hoàng Đạo", "Nguyệt Đức Hợp", "Phúc Đức", 
        "Phúc Tinh", "Thiên Nguyện", "Thời Đức", "Tứ Tướng", "Tuế Đức", "Tướng Nhật", 
        "Thiên Phúc", "Tứ Vượng", "Sát Cống"
    ]),
    ("Nhóm 4: Tốt đối với khởi công xây dựng, động thổ, sửa chữa nhà cửa, đền miếu", [
        "Bất Tương", "Dân Nhật", "Ngọc Thủ", "Ngọc Vũ", "Ngũ Hợp", "Nguyệt Đức Hợp", 
        "Nguyệt Không", "Nguyệt Tài", "Phúc Đức", "Phúc Tinh", "Sinh Khí", "Thiên Đức Hợp", 
        "Thiên Nguyện", "Thời Đức", "Tứ Tướng", "Tuế Đức", "Tứ Vượng", "Sát Cống"
    ]),
    ("Nhóm 5: Tốt đối với khai trương, mở cửa hàng, giao dịch ký kết, cầu tài lộc, dọn nhà mới", [
        "Âm Quý", "Bất Tương", "Địa Tài(Bảo Quang Hoàng Đạo)", "Dương Đức", "Dương Quý", 
        "Hỉ Thần", "Kim Quĩ Hoàng Đạo", "Lộc Khố", "Mẫu Thương", "Ngũ Hợp", "Nguyệt Tài", 
        "Phúc Đức", "Phúc Tinh", "Sinh Khí", "Thiên Mã(Lộc Mã)", "Thiên Tài(Kim Qũy Hoàng Đạo)", 
        "Thiên Thương", "Thời Đức", "Thiên Phúc", "Tứ Vượng", "Sát Cống"
    ]),
    ("Nhóm 6: Tốt với mai táng, di chuyển, sửa chữa, xây lại lăng mộ", [
        "Địa Tài(Bảo Quang Hoàng Đạo)", "Thiên Nguyện", "Kính Tâm"
    ]),
    ("Nhóm 7: Tốt với tế tự, cầu phúc, tranh chấp, kiện tụng, giải oan", [
        "Âm Quý", "Binh Bảo – Binh Cát – Binh Phúc", "Dương Quý", "Giải Thần", "Hỉ Thần", 
        "Kim Quĩ Hoàng Đạo", "Kính An", "Lục Nghi", "Nguyệt Đức Hợp", "Phúc Đức", 
        "Phúc Tinh", "Thiên Đức Hợp", "Thiên Hậu", "Thiên Vu(Thiên Vũ)", "Thiên Xá", 
        "Thời Đức", "Trừ Thần", "Tứ Tướng", "Thiên Phúc"
    ]),
    ("Nhóm 8: Tốt nhưng khác với nội dung bên trên", [
        "Binh Bảo – Binh Cát – Binh Phúc", "Cát Kì", "Dịch Mã", "Giải Thần", "Lâm Nhật", 
        "Mẫu Thương", "Nguyệt Đức Hợp", "Nguyệt Không", "Nguyệt Tài", "Quan Nhật", 
        "Sinh Khí", "Thiên Hậu", "Thiên Nguyện", "Thiên Thương", "Thiên Y", "Thời Đức", 
        "Thủ Nhật", "Trừ Thần", "Tư Mệnh Hoàng Đạo", "Tứ Tướng", "Tuế Đức", "Tướng Nhật", 
        "Diệu Xương"
    ])
]

HUNG_TINH_GROUPS = [
    ("Nhóm 1: Mọi việc đều kiêng", [
        "Âm Sai / Âm Thác", "Bạch Hổ Hắc Đạo", "Bàng Phế", "Câu Giảo", "Đại Bại", 
        "Đại Hao", "Hà Khôi", "Hoang Vu", "Nguyệt Hình", "Ngõa Toái", "Thiên Cương", 
        "Thiên Lại", "Thọ Tử", "Thụ Tử", "Tiểu Hồng Sa", "Tuế Phá", "Băng Tiêu Ngõa Hãm", 
        "Kim Thần Thất Sát"
    ]),
    ("Nhóm 2: Xấu đối với xuất hành, di chuyển chỗ ở", [
        "Địa Tặc", "Ngũ Quỷ", "Không Vong", "Nguyệt Yếm đại họa", "Cửu Không", "Hoàng Sa", 
        "Âm Thác", "Dương Thác", "Chiêu Dao", "Chu Tước Hăc Đạo", "Cửu Khảm", "Cửu Không", 
        "Dương Thác", "Đại Hoạ", "Địa Tặc", "Du Họa", "Hàm Trì", "Hoàng Sa", "Huyền Vũ Hắc Đạo", 
        "Khô Tiêu", "Kiếp Sát", "Lôi Công", "Phục Nhật", "Thiên Lao Hắc Đạo", "Tàn Bại", 
        "Tiểu Thời", "Tứ Cùng", "Tứ Hao", "Thiên Phủng", "Ly Sào", 
        "Dương Công Kỵ", "Tam Nương", "Nguyệt Kỵ"
    ]),
    ("Nhóm 3: Xấu với các nghi lễ hôn thú", [
        "Nguyệt Hư", "Cô Thần", "Tam tang", "Trùng phục", "Quả Tú", "Ly Sàng", "Nhân Cách", 
        "Tứ Thời Cô Quả", "Không Phòng", "Âm Thác", "Dương Thác", "Bát Chuyên", "Bát Long", 
        "Bát Phong", "Bát Ma", "Câu Trần Hắc Đạo", "Chu Tước Hăc Đạo", "Cô Thần", "Cửu Hổ", 
        "Cửu Khảm", "Dương Thác", "Đại Hoạ", "Đại Thời", "Hàm Trì", "Kiếp Sát", "Lục Xà", 
        "Mộc Mã Sát", "Nguyệt Hại", "Phá Bại", "Phi Ma Sát(Tai Sát)", "Tai Sát (Thiên Hỏa)", 
        "Thiên Bổng", "Thiên Lao Hắc Đạo", "Trùng Nhật", "Tứ Cùng", "Tứ Kỵ", "Tứ Phế", 
        "Yếm Đối", "Ly Sào", "Dương Công Kỵ", "Tam Nương", "Lập Tảo", 
        "Nguyệt Kỵ", "Sát Chủ Dương"
    ]),
    ("Nhóm 4: Xấu đối với khởi công xây dựng, động thổ, sửa chữa nhà cửa", [
        "Thiên Ngục", "Thiên Hỏa", "Địa Phá", "Nguyệt Phá", "Thiên Ôn", "Thổ Phủ", 
        "Thiên Tặc", "Thổ Ôn", "Địa Tặc", "Hỏa Tai", "Thiên Cẩu", "Lục Bất Thành", 
        "Trùng Tang", "Cô Thần", "Phủ Đầu Sát", "Cửu Thổ Quỷ", "Nguyệt Hỏa", "Nguyệt Hoả", "Độc Hỏa", "Nguyệt Hoả(Độc Hỏa)", "Nhân Cách", 
        "Chu Tước Hắc Đạo", "Nguyệt Kiến", "Ngũ Hư", "Nguyệt Hư", "Hà Khôi", "Cẩu Giảo", 
        "Lôi Công", "Lỗ Ban Sát", "Thổ Cấm", "Bất Thành", "Bệnh Phù", "Câu Trần Hắc Đạo", 
        "Chích Thoái", "Cửu Khảm", "Đại Hoạ", "Đại Thời", "Đại Tướng Quân", "Đao Châm Sát", 
        "Địa Hỏa", "Địa Nang", "Địa Tặc", "Du Họa", "Hàm Trì", "Kiếp Sát", "Lôi Công", 
        "Mộc Mã Sát", "Nguyệt Hại", "Nguyệt Chuyển", "Phá Bại", "Phục Binh (Tọa Sát)", 
        "Phục Nhật", "Tai Sát (Thiên Hỏa)", "Thiên Địa Chuyển", "Thiên Địa Chuyển Sát", 
        "Thiên Lao Hắc Đạo", "Thổ Kỵ", "Thiên Địa Trục", "Tứ Cùng", "Tứ Phế", "Tử Phù", 
        "Tuế Hình", "Tuế Sát", "Dương Công Kỵ", "Tam Nương", "Lập Tảo", 
        "Nguyệt Kiến Chuyển Sát", "Nguyệt Kỵ", "Nhập Tòa Địa Phá", "Sát Chủ Dương"
    ]),
    ("Nhóm 5: Xấu đối với khai trương, mở cửa hàng, giao dịch ký kết, cầu tài lộc, dọn nhà mới", [
        "Tiểu Hao", "Lục Bất Thành", "Xích Khẩu", "Nguyệt Hư", "Nguyệt Sát", "Cửu Không", 
        "Không Vong", "Thiên Tặc", "Chu Tước Hăc Đạo", "Bát Ma", "Câu Trần Hắc Đạo", 
        "Cửu Khảm", "Dương Thác", "Đại Hoạ", "Đại Thời", "Hàm Trì", "Huyền Vũ Hắc Đạo", 
        "Ngũ Mộ", "Nguyệt Hại", "Phá Bại", "Phi Ma Sát(Tai Sát)", "Thiên Bổng", 
        "Thiên Lao Hắc Đạo", "Tàn Bại", "Thiên Sứ", "Tiểu Thời", "Tứ Cùng", "Tứ Hao", 
        "Tứ Phế", "Ương Bại", "Ly Sào", "Dương Công Kỵ", "Tam Nương", 
        "Lập Tảo", "Nguyệt Kỵ", "Sát Chủ Dương"
    ]),
    ("Nhóm 6: Xấu với mai táng, di chuyển, sửa chữa, xây lại lăng mộ", [
        "Thổ Phủ", "Địa Tặc", "Thổ Ôn", "Thiên Tặc", "Trùng Phục", "Nguyệt Kiến", 
        "Bạch Hổ", "Huyền Vũ", "Câu Trận", "Tam tang", "Ngũ Hư", "Nguyệt Sát", 
        "Thổ Cấm", "Quỷ Khốc", "Bát Toạ", "Câu Trần Hắc Đạo", "Chích Thoái", 
        "Dương Thác", "Địa Tặc", "Huyền Vũ Hắc Đạo", "Kiếp Sát", "Phục Nhật", 
        "Thiên Bổng", "Thổ Kỵ", "Trùng Nhật", "Tứ Đại Mộ (Tứ thời đại mộ)", "Tứ Cùng", 
        "Tứ Kỵ", "Sát Chủ Âm"
    ]),
    ("Nhóm 7: Xấu với tế tự, cầu phúc, tranh chấp, kiện tụng, giải oan", [
        "Thổ Ôn", "Thiên Cẩu", "Thần Cách", "Tội Chỉ", "Chu Tước", "Xích Khẩu", 
        "Thiên Hình Hắc Đạo", "Vãng Vong", "Tội Chí", "Đại Thời", "Du Họa", 
        "Khô Tiêu", "Tàn Bại", "Thiên Sứ", "Thiên Phủng", "Tử Phù"
    ]),
    ("Nhóm 8: Xấu nhưng khác với nội dung bên trên", [
        "Cô Thần", "Cửu Tiêu", "Đại Hoạ", "Đại Sát", "Đại Thời", "Đại Tướng Quân", 
        "Đao Châm Sát", "Địa Hỏa", "Du Họa", "Huyết Chi", "Huyết Kỵ", "Khô Tiêu", 
        "Lôi Công", "Mộc Mã Sát", "Ngũ Mộ", "Phủ Sát", "Phi Liêm", "Phục Binh (Tọa Sát)", 
        "Tai Sát (Thiên Hỏa)", "Thiên Bổng", "Thổ Kỵ", "Tàn Bại", "Tử Khí", "Tứ Kích", 
        "Tứ Kỵ", "Ương Bại"
    ])
]

def normalize_star_name(s):
    if not s:
        return ""
    s_clean = re.sub(r'\(.*?\)', '', s).strip()
    s_clean = s_clean.split('–')[0].split('-')[0].strip()
    return s_clean.lower()

def matches_group(star_name, group_list):
    sn = normalize_star_name(star_name)
    for g in group_list:
        gn = normalize_star_name(g)
        if sn == gn or sn in gn or gn in sn:
            return True
    return False

def build_grouped_sao_meanings(sao_tot_list, sao_xau_list, local_meanings):
    """
    Hàm phân nhóm sao Cát và sao Hung theo đúng 8 Nhóm chuẩn hóa
    kết hợp Strict Priority Waterfall Logic (Nhóm 1 -> 8).
    """
    result = []
    printed_meanings = set()

    # ================== PHẦN 1: SAO CÁT TINH ==================
    if sao_tot_list:
        result.append({"star": "Phần 1: Sao Cát Tinh", "meaning": "", "is_header": True, "type": "good"})
        
        for g_title, g_stars in CAT_TINH_GROUPS:
            matched_stars = []
            for s in sao_tot_list:
                if matches_group(s, g_stars):
                    matched_stars.append(s)
            
            if matched_stars:
                result.append({"star": g_title, "meaning": "", "is_header": True, "is_sub_header": True, "type": "good"})
                for s in matched_stars:
                    sn = normalize_star_name(s)
                    if sn not in printed_meanings:
                        meaning = local_meanings.get(s, "Tốt mọi việc")
                        result.append({"star": s, "meaning": meaning, "is_header": False, "type": "good"})
                        printed_meanings.add(sn)
                    else:
                        # Đã in ý nghĩa ở nhóm ưu tiên cao hơn -> Chỉ in tên sao
                        result.append({"star": s, "meaning": "", "is_header": False, "type": "good"})

    # ================== PHẦN 2: SAO HUNG TINH ==================
    if sao_xau_list:
        result.append({"star": "Phần 2: Sao Hung Tinh", "meaning": "", "is_header": True, "type": "bad"})
        
        for g_title, g_stars in HUNG_TINH_GROUPS:
            matched_stars = []
            for s in sao_xau_list:
                if matches_group(s, g_stars):
                    matched_stars.append(s)
            
            if matched_stars:
                result.append({"star": g_title, "meaning": "", "is_header": True, "is_sub_header": True, "type": "bad"})
                for s in matched_stars:
                    sn = normalize_star_name(s)
                    if sn not in printed_meanings:
                        meaning = local_meanings.get(s, "Xấu mọi việc")
                        result.append({"star": s, "meaning": meaning, "is_header": False, "type": "bad"})
                        printed_meanings.add(sn)
                    else:
                        # Đã in ý nghĩa ở nhóm ưu tiên cao hơn -> Chỉ in tên sao
                        result.append({"star": s, "meaning": "", "is_header": False, "type": "bad"})

    return result
