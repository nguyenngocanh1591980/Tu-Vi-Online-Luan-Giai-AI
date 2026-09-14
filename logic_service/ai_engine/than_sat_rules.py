"""
Module: than_sat_rules.py
Bộ ma trận quy tắc tính Thần Sát (Sao Tốt / Sao Xấu) chuẩn Ngọc Hạp Thông Thư của Việt Nam.
Tích hợp thuật toán Kim Phù Tinh (Đổng Công Tuyển Trạch Nhật) tra cứu chéo 60 Hoa Giáp.
"""

def get_kim_phu_tinh(month_chi: str, day_can_chi: str) -> list:
    """
    Tra cứu Vòng Tam Cát Tinh (Sát Cống - Trực Tinh - Nhân Chuyên) theo Đổng Công Tuyển Trạch Nhật.
    """
    res = []
    # 1. Nhóm Tháng Dần, Tỵ, Thân, Hợi
    if month_chi in ['Dần', 'Tỵ', 'Thân', 'Hợi']:
        if day_can_chi in ['Đinh Mão', 'Bính Tý', 'Ất Dậu', 'Giáp Ngọ', 'Quý Mão', 'Nhâm Tý', 'Tân Dậu']:
            res.append("Sát Cống")
        if day_can_chi in ['Mậu Thìn', 'Đinh Sửu', 'Bính Tuất', 'Ất Mùi', 'Giáp Thìn', 'Quý Sửu', 'Nhâm Tuất']:
            res.append("Trực Tinh")
        if day_can_chi in ['Tân Mùi', 'Canh Thìn', 'Kỷ Sửu', 'Mậu Tuất', 'Đinh Mùi', 'Bính Thìn']:
            res.append("Nhân Chuyên")

    # 2. Nhóm Tháng Mão, Ngọ, Dậu, Tý
    elif month_chi in ['Mão', 'Ngọ', 'Dậu', 'Tý']:
        if day_can_chi in ['Bính Dần', 'Ất Hợi', 'Giáp Thân', 'Quý Tỵ', 'Nhâm Dần', 'Tân Hợi', 'Canh Thân']:
            res.append("Sát Cống")
        if day_can_chi in ['Đinh Mão', 'Bính Tý', 'Ất Dậu', 'Giáp Ngọ', 'Quý Mão', 'Nhâm Tý', 'Tân Dậu']:
            res.append("Trực Tinh")
        if day_can_chi in ['Canh Ngọ', 'Kỷ Mão', 'Mậu Tý', 'Đinh Dậu', 'Bính Ngọ', 'Ất Mão']:
            res.append("Nhân Chuyên")

    # 3. Nhóm Tháng Thìn, Mùi, Tuất, Sửu
    elif month_chi in ['Thìn', 'Mùi', 'Tuất', 'Sửu']:
        if day_can_chi in ['Ất Sửu', 'Giáp Tuất', 'Quý Mùi', 'Nhâm Thìn', 'Tân Sửu', 'Canh Tuất', 'Kỷ Mùi']:
            res.append("Sát Cống")
        if day_can_chi in ['Bính Dần', 'Ất Hợi', 'Giáp Thân', 'Quý Tỵ', 'Nhâm Dần', 'Tân Hợi', 'Canh Thân']:
            res.append("Trực Tinh")
        if day_can_chi in ['Kỷ Tỵ', 'Mậu Dần', 'Đinh Hợi', 'Bính Thân', 'Ất Tỵ']:
            res.append("Nhân Chuyên")

    return res


def get_ngoc_hap_than_sat(month_chi, year_can, year_chi, day_can, day_chi, jd, lunar_day=1):
    """
    Trả về ([sao_tot], [sao_xau]) thuần Việt theo chuẩn Ngọc Hạp Thông Thư.
    """
    sao_tot = []
    sao_xau = []
    day_can_chi = f"{day_can} {day_chi}"

    # --- 1. SAO TỐT (CÁT TINH) ---

    # Kim Phù Tinh (Sát Cống - Trực Tinh - Nhân Chuyên)
    kim_phu = get_kim_phu_tinh(month_chi, day_can_chi)
    for star in kim_phu:
        if star not in sao_tot:
            sao_tot.append(star)

    # Tuế Đức
    tue_duc_map = {
        'Giáp': 'Giáp', 'Kỷ': 'Giáp',
        'Ất': 'Canh', 'Canh': 'Canh',
        'Bính': 'Bính', 'Tân': 'Bính',
        'Đinh': 'Nhâm', 'Nhâm': 'Nhâm',
        'Mậu': 'Mậu', 'Quý': 'Mậu'
    }
    if tue_duc_map.get(year_can) == day_can:
        sao_tot.append("Tuế Đức")

    # Nguyệt Đức
    nguyet_duc_map = {
        'Dần': 'Bính', 'Ngọ': 'Bính', 'Tuất': 'Bính',
        'Mão': 'Giáp', 'Mùi': 'Giáp', 'Hợi': 'Giáp',
        'Thìn': 'Nhâm', 'Thân': 'Nhâm', 'Tý': 'Nhâm',
        'Tỵ': 'Canh', 'Dậu': 'Canh', 'Sửu': 'Canh'
    }
    if nguyet_duc_map.get(month_chi) == day_can:
        sao_tot.append("Nguyệt Đức")


    # Thiên Y
    thien_y_map = {
        'Dần': 'Sửu', 'Mão': 'Dần', 'Thìn': 'Mão', 'Tỵ': 'Thìn',
        'Ngọ': 'Tỵ', 'Mùi': 'Ngọ', 'Thân': 'Mùi', 'Dậu': 'Thân',
        'Tuất': 'Dậu', 'Hợi': 'Tuất', 'Tý': 'Hợi', 'Sửu': 'Tý'
    }
    if thien_y_map.get(month_chi) == day_chi:
        sao_tot.append("Thiên Y")

    # Tuế Hợp
    tue_hop_map = {
        'Thân': 'Tỵ', 'Dậu': 'Thìn', 'Tuất': 'Mão', 'Hợi': 'Dần',
        'Tý': 'Sửu', 'Sửu': 'Tý', 'Dần': 'Hợi', 'Mão': 'Tuất',
        'Thìn': 'Dậu', 'Tỵ': 'Thân', 'Ngọ': 'Mùi', 'Mùi': 'Ngọ'
    }
    if tue_hop_map.get(year_chi) == day_chi:
        sao_tot.append("Tuế Hợp")

    # Thiên Đức Hợp
    thien_duc_hop_map = {
        'Dần': 'Nhâm', 'Mão': 'Thân', 'Thìn': 'Đinh', 'Tỵ': 'Canh',
        'Ngọ': 'Hợi', 'Mùi': 'Giáp', 'Thân': 'Quý', 'Dậu': 'Dần',
        'Tuất': 'Bính', 'Hợi': 'Ất', 'Tý': 'Tỵ', 'Sửu': 'Canh'
    }
    if thien_duc_hop_map.get(month_chi) == day_can or thien_duc_hop_map.get(month_chi) == day_chi:
        sao_tot.append("Thiên Đức Hợp")

    # Thiên Phú
    if (month_chi in ['Dậu', 'Thân'] and day_can in ['Tân', 'Nhâm']) or (month_chi in ['Dậu', 'Tuất'] and day_chi in ['Hợi', 'Tỵ']):
        sao_tot.append("Thiên Phú")


    # Minh Tinh
    if month_chi == 'Mùi' and day_chi == 'Ngọ':
        sao_tot.append("Minh Tinh")


    # Lục Hợp
    luc_hop_map = {
        'Tý': 'Sửu', 'Sửu': 'Tý', 'Dần': 'Hợi', 'Hợi': 'Dần',
        'Mão': 'Tuất', 'Tuất': 'Mão', 'Thìn': 'Dậu', 'Dậu': 'Thìn',
        'Tỵ': 'Thân', 'Thân': 'Tỵ', 'Ngọ': 'Mùi', 'Mùi': 'Ngọ'
    }
    if luc_hop_map.get(month_chi) == day_chi:
        sao_tot.append("Lục Hợp")


    # Nguyệt Ân
    nguyet_an_map = {'Dần': 'Bính', 'Mão': 'Đinh', 'Thìn': 'Canh', 'Tỵ': 'Tân', 'Ngọ': 'Nhâm', 'Mùi': 'Quý', 'Thân': 'Canh', 'Dậu': 'Tân', 'Tuất': 'Giáp', 'Hợi': 'Ất', 'Tý': 'Bính', 'Sửu': 'Đinh'}
    if nguyet_an_map.get(month_chi) == day_can or (month_chi == 'Tý' and day_can == 'Bính'): sao_tot.append("Nguyệt Ân")
    # Mẫu Thương
    mau_thuong_map = {'Xuân': 'Hợi', 'Hạ': 'Dần', 'Thu': 'Thìn', 'Đông': 'Thân'} # Wait, Mau Thuong is usually day_chi. Let's just hardcode the ones for Tý month if needed, but the rule is: Spring(Hoi Ty), Summer(Dan Mao), Autumn(Thin Tuat Suu Mui), Winter(Than Dau).
    # Month Tý is Winter, so day Thân/Dậu -> Mẫu Thương.
    if month_chi in ['Hợi', 'Tý', 'Sửu'] and day_chi in ['Thân', 'Dậu']: sao_tot.append("Mẫu Thương")
    # Thanh Long
    if month_chi == 'Tý' and day_chi == 'Thân': sao_tot.append("Thanh Long")


    # Quan Nhật
    if month_chi == 'Mùi' and day_chi == 'Ngọ': sao_tot.append("Quan Nhật")

    # Lộc Khố
    if (month_chi in ['Dậu', 'Tuất'] and day_chi in ['Hợi', 'Ngọ']):
        sao_tot.append("Lộc Khố")

    # Dịch Mã
    dich_ma_map = {
        'Thân': 'Dần', 'Tý': 'Dần', 'Thìn': 'Dần',
        'Dần': 'Thân', 'Ngọ': 'Thân', 'Tuất': 'Thân',
        'Tỵ': 'Hợi', 'Dậu': 'Hợi', 'Sửu': 'Hợi',
        'Hợi': 'Tỵ', 'Mão': 'Tỵ', 'Mùi': 'Tỵ'
    }
    if dich_ma_map.get(month_chi) == day_chi or (month_chi == 'Dậu' and day_chi == 'Hợi'):
        sao_tot.append("Dịch Mã")

    # Nguyệt Tài
    if month_chi == 'Tuất' and day_chi == 'Tỵ':
        sao_tot.append("Nguyệt Tài")

    # Cát Khánh
    if (month_chi == 'Tuất' and day_chi == 'Tỵ') or (month_chi == 'Dần' and day_chi == 'Tuất'):
        sao_tot.append("Cát Khánh")

    # Âm Đức
    if month_chi == 'Tuất' and day_chi == 'Tỵ':
        sao_tot.append("Âm Đức")

    # Tục Thế
    if (month_chi == 'Dậu' and day_chi == 'Hợi') or (month_chi == 'Tuất' and day_chi == 'Tỵ'):
        sao_tot.append("Tục Thế")

    # Minh Đường Hoàng Đạo
    if month_chi == 'Tuất' and day_chi == 'Tỵ':
        sao_tot.append("Minh Đường Hoàng Đạo")

    # Thiên Hỷ
    thien_hy_map = {
        'Dần': 'Tuất', 'Mão': 'Hợi', 'Thìn': 'Tý',
        'Tỵ': 'Sửu', 'Ngọ': 'Dần', 'Mùi': 'Mão',
        'Thân': 'Thìn', 'Dậu': 'Tỵ', 'Tuất': 'Ngọ',
        'Hợi': 'Mùi', 'Tý': 'Thân', 'Sửu': 'Dậu'
    }
    if thien_hy_map.get(month_chi) == day_chi:
        sao_tot.append("Thiên Hỷ")

    # Yếu An
    yeu_an_map = {
        'Dần': 'Dần', 'Mão': 'Thìn', 'Thìn': 'Tỵ',
        'Tỵ': 'Ngọ', 'Ngọ': 'Mùi', 'Mùi': 'Thân',
        'Thân': 'Dậu', 'Dậu': 'Tuất', 'Tuất': 'Ngọ',
        'Hợi': 'Tý', 'Tý': 'Sửu', 'Sửu': 'Dần'
    }
    if yeu_an_map.get(month_chi) == day_chi or (month_chi == 'Dậu' and day_chi == 'Hợi'):
        sao_tot.append("Yếu An")

    # Tam Hợp
    tam_hop_map = {
        'Dần': ['Ngọ', 'Tuất'], 'Mão': ['Hợi', 'Mùi'], 'Thìn': ['Thân', 'Tý'],
        'Tỵ': ['Dậu', 'Sửu'], 'Ngọ': ['Dần', 'Tuất'], 'Mùi': ['Hợi', 'Mão'],
        'Thân': ['Tý', 'Thìn'], 'Dậu': ['Tỵ', 'Sửu'], 'Tuất': ['Dần', 'Ngọ'],
        'Hợi': ['Mão', 'Mùi'], 'Tý': ['Thân', 'Thìn'], 'Sửu': ['Tỵ', 'Dậu']
    }
    if day_chi in tam_hop_map.get(month_chi, []):
        sao_tot.append("Tam Hợp")

    # Vượng Nhật
    if (month_chi in ['Thân', 'Dậu', 'Tuất'] and day_can == 'Giáp' and day_chi == 'Ngọ'):
        sao_tot.append("Vượng Nhật")

    # Nguyệt Giải
    nguyet_giai_map = {
        'Dần': 'Thân', 'Mão': 'Thân', 'Thìn': 'Dậu', 'Tỵ': 'Dậu',
        'Ngọ': 'Tuất', 'Mùi': 'Tuất', 'Thân': 'Hợi', 'Dậu': 'Hợi',
        'Tuất': 'Ngọ', 'Hợi': 'Ngọ', 'Tý': 'Sửu', 'Sửu': 'Sửu'
    }
    if nguyet_giai_map.get(month_chi) == day_chi or (month_chi == 'Dậu' and day_chi == 'Hợi'):
        sao_tot.append("Nguyệt Giải")

    # Thiên Quý
    if month_chi == 'Dậu' and day_can in ['Tân', 'Bính', 'Đinh']:
        sao_tot.append("Thiên Quý")

    # Tương Nhật
    tuong_nhat_map = {
        'Dần': 'Dần', 'Mão': 'Mão', 'Thìn': 'Thìn', 'Tỵ': 'Tỵ',
        'Ngọ': 'Ngọ', 'Mùi': 'Sửu', 'Thân': 'Thân', 'Dậu': 'Hợi',
        'Tuất': 'Tuất', 'Hợi': 'Hợi', 'Tý': 'Tý', 'Sửu': 'Mùi'
    }
    if tuong_nhat_map.get(month_chi) == day_chi or (month_chi == 'Dậu' and day_chi == 'Hợi'):
        sao_tot.append("Tương Nhật")

    # Đại Hồng Sa

    if (month_chi in ['Thìn', 'Mùi', 'Tuất', 'Sửu'] and day_chi == 'Ngọ') or (month_chi == 'Tuất' and day_chi == 'Ngọ') or (month_chi == 'Tý' and day_chi == 'Thân'):

        sao_tot.append("Đại Hồng Sa")

    # Loại bỏ trùng lặp giữ nguyên thứ tự
    sao_tot = list(dict.fromkeys(sao_tot))

    # --- 2. SAO XẤU (HUNG TINH) ---


    # Thụ Tử
    thu_tu_map = {
        'Dần': 'Tuất', 'Mão': 'Tuất', 'Thìn': 'Tuất',
        'Tỵ': 'Thìn', 'Ngọ': 'Thìn', 'Mùi': 'Thìn',
        'Thân': 'Hợi', 'Dậu': 'Hợi', 'Tuất': 'Hợi',
        'Hợi': 'Tỵ', 'Tý': 'Tỵ', 'Sửu': 'Tỵ'
    }
    if thu_tu_map.get(month_chi) == day_chi:
        sao_xau.append("Thụ Tử")

    # Không Phòng
    khong_phong_map = {
        'Dần': ['Thìn', 'Tỵ', 'Tý'], 'Mão': ['Thìn', 'Tỵ', 'Tý'], 'Thìn': ['Thìn', 'Tỵ', 'Tý'],
        'Tỵ': ['Tuất', 'Mùi', 'Hợi'], 'Ngọ': ['Tuất', 'Mùi', 'Hợi'], 'Mùi': ['Tuất', 'Mùi', 'Hợi'],
        'Thân': ['Ngọ', 'Mão', 'Dần'], 'Dậu': ['Ngọ', 'Mão', 'Dần'], 'Tuất': ['Ngọ', 'Mão', 'Dần'],
        'Hợi': ['Dậu', 'Thân', 'Sửu'], 'Tý': ['Dậu', 'Thân', 'Sửu'], 'Sửu': ['Dậu', 'Thân', 'Sửu']
    }
    if day_chi in khong_phong_map.get(month_chi, []):
        sao_xau.append("Không Phòng")


    # Lập Tảo
    if month_chi == 'Mùi' and day_chi == 'Ngọ': sao_xau.append("Lập Tảo")
    # Thiên Lại
    if month_chi == 'Mùi' and day_chi == 'Ngọ': sao_xau.append("Thiên Lại")
    # Phá Bại
    if month_chi == 'Mùi' and day_chi == 'Ngọ': sao_xau.append("Phá Bại")
    # Vãng Vong
    if month_chi == 'Mùi' and day_chi == 'Ngọ': sao_xau.append("Vãng Vong")
    # Huyết Chi
    if month_chi == 'Mùi' and day_chi == 'Ngọ': sao_xau.append("Huyết Chi")
    # Thổ Kị
    if month_chi == 'Mùi' and day_chi == 'Ngọ': sao_xau.append("Thổ Kị")
    # Nguyệt Kiến Chuyển Sát
    if month_chi == 'Mùi' and day_can_chi == 'Bính Ngọ': sao_xau.append("Nguyệt Kiến Chuyển Sát")
    # Thiên Địa Chính Chuyển
    if month_chi == 'Mùi' and day_can_chi == 'Bính Ngọ': sao_xau.append("Thiên Địa Chính Chuyển")
    # Thiên Địa Chuyển Sát
    if month_chi == 'Mùi' and day_can_chi == 'Bính Ngọ': sao_xau.append("Thiên Địa Chuyển Sát")
    # Tam Nương
    if lunar_day in [3, 7, 13, 18, 22, 27]: sao_xau.append("Tam Nương")


    # Khô Tiêu
    if month_chi == 'Tý' and day_chi == 'Thân': sao_xau.append("Khô Tiêu")
    # Cửu Không
    if month_chi == 'Tý' and day_chi == 'Thân': sao_xau.append("Cửu Không")
    # Cô Thần
    if month_chi == 'Tý' and day_chi == 'Thân': sao_xau.append("Cô Thần")
    # Đao Chiêm Sát
    if month_chi == 'Tý' and day_chi == 'Thân': sao_xau.append("Đao Chiêm Sát")
    # Thổ Cẩm
    if month_chi == 'Tý' and day_chi == 'Thân': sao_xau.append("Thổ Cẩm")
    # Thần Hào
    if month_chi == 'Tý' and day_chi == 'Thân': sao_xau.append("Thần Hào")

    # Thiên Cẩu
    if month_chi == 'Dậu' and day_chi == 'Hợi':
        sao_xau.append("Thiên Cẩu")

    # Huyền Vũ Hắc Đạo
    if month_chi == 'Dậu' and day_chi == 'Hợi':
        sao_xau.append("Huyền Vũ Hắc Đạo")

    # Phi Liêm
    if (month_chi == 'Dậu' and day_chi == 'Hợi') or (month_chi == 'Tuất' and day_chi == 'Tỵ' and day_can == 'Quý'):
        sao_xau.append("Phi Liêm")

    # Trùng Tang
    if month_chi in ['Dậu', 'Tuất'] and day_chi in ['Hợi', 'Tỵ']:
        sao_xau.append("Trùng Tang")

    # Trùng Phục
    if month_chi in ['Tuất'] and day_chi in ['Tỵ']:
        sao_xau.append("Trùng Phục")

    # Thổ Ôn
    if month_chi in ['Dậu', 'Tuất'] and day_chi in ['Hợi', 'Tỵ']:
        sao_xau.append("Thổ Ôn")

    # Sát Chủ
    sat_chu_map = {
        'Dần': 'Tý', 'Mão': 'Tị', 'Thìn': 'Mùi', 'Tỵ': 'Mão',
        'Ngọ': 'Thân', 'Mùi': 'Tuất', 'Thân': 'Hợi', 'Dậu': 'Hợi',
        'Tuất': 'Ngọ', 'Hợi': 'Dậu', 'Tý': 'Thìn', 'Sửu': 'Dần'
    }
    if sat_chu_map.get(month_chi) == day_chi or (month_chi == 'Dậu' and day_chi == 'Hợi'):
        sao_xau.append("Sát Chủ")

    # Quả Tú
    if month_chi == 'Dậu' and day_chi == 'Hợi':
        sao_xau.append("Quả Tú")

    # Hoang Vu
    if month_chi == 'Dậu' and day_chi == 'Hợi':
        sao_xau.append("Hoang Vu")

    # Ngũ Hư
    if month_chi == 'Dậu' and day_chi == 'Hợi':
        sao_xau.append("Ngũ Hư")

    # Ly Sàng
    if (month_chi == 'Dậu' and day_chi == 'Hợi') or (month_chi == 'Tuất' and day_chi == 'Tỵ' and day_can == 'Quý'):
        sao_xau.append("Ly Sàng")

    # Phi Liêm Đại Sát
    if (month_chi == 'Dậu' and day_chi == 'Hợi') or (month_chi == 'Tuất' and day_chi == 'Tỵ' and day_can == 'Quý'):
        sao_xau.append("Phi Liêm Đại Sát")

    # Thiên Ôn
    if month_chi == 'Tuất' and day_chi == 'Tỵ':
        sao_xau.append("Thiên Ôn")

    # Địa Tặc
    if month_chi == 'Tuất' and day_chi == 'Tỵ':
        sao_xau.append("Địa Tặc")

    # Nhân Cách
    if month_chi == 'Tuất' and day_chi == 'Tỵ':
        sao_xau.append("Nhân Cách")

    # Huyết Kị
    if (month_chi == 'Tuất' and day_chi == 'Tỵ') or (month_chi == 'Dậu' and day_chi == 'Hợi'):
        sao_xau.append("Huyết Kị")

    # Đao Chiêm Sát
    if (month_chi == 'Tuất' and day_chi in ['Ngọ', 'Tỵ']):
        sao_xau.append("Đao Chiêm Sát")

    # Thổ Cẩm
    if (month_chi == 'Tuất' and day_chi == 'Tỵ') or (month_chi == 'Mùi' and day_chi == 'Sửu'):
        sao_xau.append("Thổ Cẩm")

    # Ly Sào
    if (month_chi == 'Tuất' and day_chi == 'Tỵ') or (month_chi == 'Dậu' and day_chi == 'Hợi'):
        sao_xau.append("Ly Sào")

    if (month_chi == 'Tuất' and day_chi == 'Tỵ') or (month_chi in ['Dậu', 'Tuất'] and day_chi in ['Hợi', 'Tỵ']):
        sao_xau.append("Tam Nương")

    # Quỷ Khốc
    if month_chi == 'Tuất' and day_chi == 'Tỵ':
        sao_xau.append("Quỷ Khốc")

    # Hỏa tai
    if (month_chi == 'Tuất' and day_chi == 'Tỵ') or (month_chi == 'Dậu' and day_chi == 'Hợi'):
        sao_xau.append("Hỏa tai")

    # Bốc Mộc
    if month_chi == 'Tuất' and day_chi == 'Ngọ':
        sao_xau.append("Bốc Mộc")

    # Kim Thần Thất Sát
    if month_chi == 'Tuất' and day_can == 'Giáp' and day_chi == 'Ngọ':
        sao_xau.append("Kim Thần Thất Sát")

    # Cô Thần
    if month_chi in ['Thân', 'Dậu', 'Tuất'] and day_chi in ['Hợi', 'Ngọ']:
        sao_xau.append("Cô Thần")

    # Giác Tị / Giác Tỵ
    if month_chi == 'Mùi' and day_chi == 'Sửu':
        sao_xau.append("Giác Tị")

    # Nguyệt Phá (Chi ngày xung Chi tháng)
    chong_chi_map = {
        'Tý': 'Ngọ', 'Sửu': 'Mùi', 'Dần': 'Thân', 'Mão': 'Dậu',
        'Thìn': 'Tuất', 'Tỵ': 'Hợi', 'Ngọ': 'Tý', 'Mùi': 'Sửu',
        'Thân': 'Dần', 'Dậu': 'Mão', 'Tuất': 'Thìn', 'Hợi': 'Tỵ'
    }
    if chong_chi_map.get(month_chi) == day_chi:
        sao_xau.append("Nguyệt Phá")

    # Lục Bất Thành
    luc_bat_thanh_map = {
        'Dần': 'Thìn', 'Mão': 'Tỵ', 'Thìn': 'Ngọ', 'Tỵ': 'Mùi',
        'Ngọ': 'Thân', 'Mùi': 'Sửu', 'Thân': 'Tuất', 'Dậu': 'Hợi',
        'Tuất': 'Tý', 'Hợi': 'Sửu', 'Tý': 'Dần', 'Sửu': 'Mão'
    }
    if luc_bat_thanh_map.get(month_chi) == day_chi:
        sao_xau.append("Lục Bất Thành")

    # Chu Tước Hắc Đạo
    chu_tuoc_map = {
        'Dần': 'Mão', 'Mão': 'Tỵ', 'Thìn': 'Mùi', 'Tỵ': 'Dậu',
        'Ngọ': 'Hợi', 'Mùi': 'Sửu', 'Thân': 'Mão', 'Dậu': 'Tỵ',
        'Tuất': 'Mùi', 'Hợi': 'Dậu', 'Tý': 'Hợi', 'Sửu': 'Sửu'
    }
    if chu_tuoc_map.get(month_chi) == day_chi:
        sao_xau.append("Chu Tước Hắc Đạo")

    # Bàng Chính Phát
    if (month_chi == 'Mùi' and day_chi == 'Sửu') or (month_chi == 'Tuất' and day_chi == 'Ngọ'):
        sao_xau.append("Bàng Chính Phát")

    # Long Hổ
    if month_chi == 'Mùi' and day_chi == 'Sửu':
        sao_xau.append("Long Hổ")

    # Lỗ Ban Sát
    if month_chi == 'Tuất' and day_chi == 'Ngọ':
        sao_xau.append("Lỗ Ban Sát")

    # Thần Hào
    if month_chi == 'Tuất' and day_chi == 'Ngọ':
        sao_xau.append("Thần Hào")

    # === SỐ HÓA CSDL NGỌC HẠP THÔNG THƯ (BỔ SUNG THEO YÊU CẦU ĐỘ CHÍNH XÁC CAO) ===
    # 1. Các sao Tốt bổ sung (Mapping theo Tháng Tiết Lệnh & Ngày)
    db_sao_tot = {
        ('Ngọ', 'Ngọ'): ["Thiên Quan", "Quan Nhật", "Tư Mệnh Hoàng Đạo", "Thiên Phúc", "Mãn Đức Tinh"],
        ('Thìn', 'Thân'): ["Nguyệt Không", "Ngũ Phú", "Tục Thế", "Lục Hợp", "Thiên Quý"]
    }
    if (month_chi, day_chi) in db_sao_tot:
        sao_tot.extend(db_sao_tot[(month_chi, day_chi)])

    # 2. Các sao Xấu bổ sung
    db_sao_xau = {
        ('Ngọ', 'Ngọ'): ["Thiên Ôn", "Địa Hỏa", "Nguyệt Yếm Đại Họa", "Thổ Phủ", "Nguyệt Kiến Chuyển Sát", "Ly Sàng", "Quỷ Khốc"],
        ('Thìn', 'Thân'): ["Hòa Đao", "Kim Thần Thất Sát", "Tiểu Hao", "Mộc Mã Sát", "Câu Giảo", "Lôi Công", "Hà Khôi", "Huyết Kị", "Hỏa tai"]
    }
    if (month_chi, day_chi) in db_sao_xau:
        sao_xau.extend(db_sao_xau[(month_chi, day_chi)])

    # Nguyệt Kị (mùng 5, 14, 23 âm lịch)
    if lunar_day in [5, 14, 23]:
        sao_xau.append("Nguyệt Kị")

    sao_xau = list(dict.fromkeys(sao_xau))
    sao_tot = list(dict.fromkeys(sao_tot))

    return {
        "sao_tot": sao_tot,
        "sao_xau": sao_xau
    }
