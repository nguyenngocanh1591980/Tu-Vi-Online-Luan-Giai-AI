from datetime import datetime

CAN = ['Canh', 'Tân', 'Nhâm', 'Quý', 'Giáp', 'Ất', 'Bính', 'Đinh', 'Mậu', 'Kỷ']
CHI = ['Thân', 'Dậu', 'Tuất', 'Hợi', 'Tý', 'Sửu', 'Dần', 'Mão', 'Thìn', 'Tỵ', 'Ngọ', 'Mùi']

THANG_CHI = ['Dần', 'Mão', 'Thìn', 'Tỵ', 'Ngọ', 'Mùi', 'Thân', 'Dậu', 'Tuất', 'Hợi', 'Tý', 'Sửu']

def get_year_can_chi(year: int) -> str:
    """Tính Can Chi của năm Âm Lịch"""
    can = CAN[year % 10]
    chi = CHI[year % 12]
    return f"{can} {chi}"

def get_month_can(year_can: str, lunar_month: int) -> str:
    """
    Tính Can của Tháng Âm Lịch dựa trên Can của Năm.
    Năm Giáp, Kỷ: Tháng Giêng (Dần) là Bính Dần.
    Năm Ất, Canh: Tháng Giêng là Mậu Dần.
    Năm Bính, Tân: Tháng Giêng là Canh Dần.
    Năm Đinh, Nhâm: Tháng Giêng là Nhâm Dần.
    Năm Mậu, Quý: Tháng Giêng là Giáp Dần.
    """
    base_can_index = 0
    if year_can in ['Giáp', 'Kỷ']: base_can_index = 6  # Bính
    elif year_can in ['Ất', 'Canh']: base_can_index = 8  # Mậu
    elif year_can in ['Bính', 'Tân']: base_can_index = 0  # Canh
    elif year_can in ['Đinh', 'Nhâm']: base_can_index = 2  # Nhâm
    elif year_can in ['Mậu', 'Quý']: base_can_index = 4  # Giáp
    
    # Tháng 1 là Dần (index 0 trong THANG_CHI). Can chạy thuận.
    month_can_index = (base_can_index + (lunar_month - 1)) % 10
    
    return f"{CAN[month_can_index]} {THANG_CHI[(lunar_month - 1) % 12]}"

def get_hour_can_chi(day_can: str, hour: int) -> str:
    """
    Tính Can Chi của Giờ dựa trên Can của Ngày.
    Ngày Giáp, Kỷ: Giờ Tý là Giáp Tý.
    Ngày Ất, Canh: Giờ Tý là Bính Tý.
    Ngày Bính, Tân: Giờ Tý là Mậu Tý.
    Ngày Đinh, Nhâm: Giờ Tý là Canh Tý.
    Ngày Mậu, Quý: Giờ Tý là Nhâm Tý.
    """
    # Chi của giờ
    if hour == 23 or hour == 0: chi_idx = 4 # Tý
    else: chi_idx = (4 + ((hour + 1) // 2)) % 12
    chi = CHI[chi_idx]
    
    # Base can cho giờ Tý
    base_can_idx = 0
    if day_can in ['Giáp', 'Kỷ']: base_can_idx = 4 # Giáp
    elif day_can in ['Ất', 'Canh']: base_can_idx = 6 # Bính
    elif day_can in ['Bính', 'Tân']: base_can_idx = 8 # Mậu
    elif day_can in ['Đinh', 'Nhâm']: base_can_idx = 0 # Canh
    elif day_can in ['Mậu', 'Quý']: base_can_idx = 2 # Nhâm
    
    # Can của giờ tương ứng
    hour_idx = ((hour + 1) // 2) % 12
    can_idx = (base_can_idx + hour_idx) % 10
    can = CAN[can_idx]
    
    return f"{can} {chi}"

def convert_solar_to_lunar(day: int, month: int, year: int) -> dict:
    """
    Hàm convert Dương Lịch sang Âm Lịch sử dụng package vnlunar.
    """
    try:
        import vnlunar
        # Dùng time_zone = 7.0 cho Âm lịch Việt Nam (quan trọng)
        lunar = vnlunar.convert_solar_to_lunar(day, month, year, 7.0)
        lunar_y = lunar['year']
        lunar_m = lunar['month']
        lunar_d = lunar['day']
    except ImportError:
        # Nếu chưa có thư viện, dùng giả lập cơ bản
        # Giả lập: Ngày âm trễ hơn ngày dương khoảng 20-30 ngày tùy tháng
        lunar_y = year
        lunar_m = month - 1 if month > 1 else 12
        if month == 1: lunar_y -= 1
        lunar_d = day
        
    return {
        "lunar_day": lunar_d,
        "lunar_month": lunar_m,
        "lunar_year": lunar_y
    }

def get_day_can_chi(day: int, month: int, year: int) -> str:
    """
    Tính Can Chi của ngày theo Dương lịch (Julian Day).
    Thuật toán chuẩn cho ngày Can Chi.
    """
    from datetime import date
    try:
        d = date(year, month, day)
        # Offset chuẩn: Ngày 1/1/1900 là Giáp Tuất
        # Tính số ngày từ 1/1/1900
        ref_date = date(1900, 1, 1)
        delta = (d - ref_date).days
        
        # 1/1/1900: Giáp (4), Tuất (2)
        can_idx = (4 + delta) % 10
        chi_idx = (2 + delta) % 12
        return f"{CAN[can_idx]} {CHI[chi_idx]}"
    except Exception:
        return "Canh Ngọ"

def get_full_astrology_data(day: int, month: int, year: int, hour: int, minute: int, is_solar: bool = True) -> dict:
    """
    Đầu vào là ngày Dương lịch (is_solar=True) hoặc Âm Lịch (is_solar=False)
    Trả về bộ dữ liệu Can Chi hoàn chỉnh
    """
    if is_solar:
        lunar = convert_solar_to_lunar(day, month, year)
        lunar_d = lunar['lunar_day']
        lunar_m = lunar['lunar_month']
        lunar_y = lunar['lunar_year']
        solar_d, solar_m, solar_y = day, month, year
    else:
        # Tạm thời chưa xử lý convert ngược Âm -> Dương chính xác nếu thiếu thư viện xịn
        lunar_d, lunar_m, lunar_y = day, month, year
        solar_d, solar_m, solar_y = day, month, year 

    year_cc = get_year_can_chi(lunar_y)
    month_cc = get_month_can(year_cc.split()[0], lunar_m)
    day_cc = get_day_can_chi(solar_d, solar_m, solar_y)
    hour_cc = get_hour_can_chi(day_cc.split()[0], hour)
    
    return {
        "solar_date": f"{solar_d:02d}/{solar_m:02d}/{solar_y}",
        "lunar_date": f"{lunar_d:02d}/{lunar_m:02d}/{lunar_y}",
        "time": f"{hour:02d}:{minute:02d}",
        "year_stem_branch": year_cc,
        "month_stem_branch": month_cc,
        "day_stem_branch": day_cc,
        "time_stem_branch": hour_cc,
        "lunar_day": lunar_d,
        "lunar_month": lunar_m,
        "lunar_year": lunar_y
    }
