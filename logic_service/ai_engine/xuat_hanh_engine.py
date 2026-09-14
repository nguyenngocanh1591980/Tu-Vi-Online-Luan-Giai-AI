# -*- coding: utf-8 -*-
"""
CSDL & Logic Hệ Thống Xuất Hành (Lý Thuần Phong & Khổng Minh)
Nguồn dữ liệu duy nhất: Thư Viện cho AI Học / Tầng 1- Dữ Liệu Chuẩn Hóa
Cách tính Ngày Giờ Hướng xuất hành tốt theo Lý Thuần Phong và Khổng Minh Lục Diệu (Đã Chỉnh Lý)
"""

# ==============================================================================
# MODULE 1: GIỜ XUẤT HÀNH (LÝ THUẦN PHONG)
# ==============================================================================
LY_THUAN_PHONG_MEANINGS = {
    1: {
        "name": "Đại An",
        "quality": "Cát",
        "desc": "Mọi việc đều tốt, cầu tài đi hướng Tây - Nam. Nhà cửa yên lành, người xuất hành đều bình yên."
    },
    2: {
        "name": "Tốc Hỷ",
        "quality": "Cát",
        "desc": "Vui sắp tới. Cầu tài đi hướng Nam, đi việc gặp gỡ các quan nhiều may mắn. Người xuất hành đều bình yên. Chăn nuôi đều thuận lợi, người đi có tin vui về…"
    },
    3: {
        "name": "Lưu Niên",
        "quality": "Hung",
        "desc": "Nghiệp khó thành, cầu tài mờ mịt, kiện cáo nên hoãn lại. Người đi chưa có tin về. Mất của đi hướng Nam tìm nhanh mới thấy, nên phòng ngừa cãi cọ, miệng tiếng rất tầm thường. Việc làm chậm, lâu la nhưng làm việc gì cũng chắc chắn."
    },
    4: {
        "name": "Xích Khẩu",
        "quality": "Hung",
        "desc": "Hay cãi cọ, gây chuyện đói kém, phải nên đề phòng, người đi nên hoãn lại, phòng người nguyền rủa, tránh lây bệnh. (Nói chung khi có việc hội họp, việc quan, tranh luận…Tránh đi vào giờ này, nếu bắt buộc phải đi thì nên giữ miệng dễ gây ẩu đả cãi nhau)."
    },
    5: {
        "name": "Tiểu Các",
        "quality": "Cát",
        "desc": "Rất tốt lành, đi thường gặp may mắn. Buôn bán có lời, phụ nữ báo tin vui mừng, người đi sắp về nhà, mọi việc đều hòa hợp, có bệnh cầu tài sẽ khỏi, người nhà đều mạnh khỏe."
    },
    6: {
        "name": "Tuyệt Lộ",
        "quality": "Hung",
        "desc": "Cầu tài không có lợi hay bị trái ý, ra đi hay gặp hạn, việc quan trọng phải đòn, gặp ma quỷ cúng lễ mới an."
    },
    0: {
        "name": "Tuyệt Lộ",
        "quality": "Hung",
        "desc": "Cầu tài không có lợi hay bị trái ý, ra đi hay gặp hạn, việc quan trọng phải đòn, gặp ma quỷ cúng lễ mới an."
    }
}

KHAC_GIO_MAP = [
    {"khac": 1, "pair_label": "Giờ Tý (23h-1h) và Giờ Ngọ (11h-13h)"},
    {"khac": 2, "pair_label": "Giờ Sửu (1h-3h) và Giờ Mùi (13h-15h)"},
    {"khac": 3, "pair_label": "Giờ Dần (3h-5h) và Giờ Thân (15h-17h)"},
    {"khac": 4, "pair_label": "Giờ Mão (5h-7h) và Giờ Dậu (17h-19h)"},
    {"khac": 5, "pair_label": "Giờ Thìn (7h-9h) và Giờ Tuất (19h-21h)"},
    {"khac": 6, "pair_label": "Giờ Tỵ (9h-11h) và Giờ Hợi (21h-23h)"},
]

def calculate_gio_xuat_hanh_ly_thuan_phong(lunar_month: int, lunar_day: int):
    """
    Module 1: Tính Giờ Xuất Hành Lý Thuần Phong (gộp UI 6 dòng)
    Công thức: (Ngày âm + Tháng âm + Khắc định đi) - 2
    Sau đó lấy kết quả chia cho 6 lấy số dư.
    """
    gop_list = []
    for item in KHAC_GIO_MAP:
        khac = item["khac"]
        pair_label = item["pair_label"]
        raw_val = (lunar_day + lunar_month + khac) - 2
        rem = raw_val % 6
        if rem == 0:
            rem = 6
        state_info = LY_THUAN_PHONG_MEANINGS[rem]
        
        # Render line: Giờ ... và Giờ ... : [Tên Trạng Thái] [Cát/Hung] - [Ý nghĩa]
        line_text = f"{pair_label} : {state_info['name']} [{state_info['quality']}] - {state_info['desc']}"
        gop_list.append({
            "khac": khac,
            "pair_label": pair_label,
            "name": state_info["name"],
            "quality": state_info["quality"],
            "desc": state_info["desc"],
            "rendered_text": line_text
        })
    return gop_list


# ==============================================================================
# MODULE 2: HƯỚNG XUẤT HÀNH (HỶ THẦN, TÀI THẦN, HẠC THẦN)
# ==============================================================================
THIEN_CAN_HUONG_MAP = {
    "Giáp": {
        "hy_than": "Đông Bắc",
        "tai_than": "Chính Đông",
        "goi_y": "Đi Đông Bắc (cầu duyên) hoặc Chính Đông (cầu tài)"
    },
    "Ất": {
        "hy_than": "Tây Bắc",
        "tai_than": "Chính Đông",
        "goi_y": "Đi Tây Bắc (cầu duyên) hoặc Chính Đông (cầu tài)"
    },
    "Bính": {
        "hy_than": "Tây Nam",
        "tai_than": "Chính Nam",
        "goi_y": "Đi Chính Nam tốt cho cả tài lộc và niềm vui"
    },
    "Đinh": {
        "hy_than": "Chính Nam",
        "tai_than": "Chính Nam",
        "goi_y": "Đi hướng Chính Nam đón đại cát (Trùng hướng)"
    },
    "Mậu": {
        "hy_than": "Đông Nam",
        "tai_than": "Chính Bắc",
        "goi_y": "Chọn Đông Nam hoặc Bắc (tránh hướng Hạc thần)"
    },
    "Kỷ": {
        "hy_than": "Đông Bắc",
        "tai_than": "Chính Nam",
        "goi_y": "Đi Đông Bắc hoặc Chính Nam"
    },
    "Canh": {
        "hy_than": "Tây Bắc",
        "tai_than": "Chính Tây",
        "goi_y": "Đi Tây Bắc hoặc Chính Tây"
    },
    "Tân": {
        "hy_than": "Tây Nam",
        "tai_than": "Chính Tây",
        "goi_y": "Đi Tây Nam hoặc Chính Tây"
    },
    "Nhâm": {
        "hy_than": "Chính Nam",
        "tai_than": "Chính Bắc",
        "goi_y": "Đi Chính Nam hoặc Chính Bắc"
    },
    "Quý": {
        "hy_than": "Đông Nam",
        "tai_than": "Chính Nam",
        "goi_y": "Đi Đông Nam hoặc Chính Nam"
    }
}

HAC_THAN_NHOM_LIST = [
    {
        "can_chi_list": ["Ất Mão", "Bính Thìn", "Đinh Tỵ", "Mậu Ngọ", "Kỷ Mùi"],
        "huong": "Chính Đông",
        "ghi_chu": "Cấm kỵ xuất hành, khởi công hoặc đi chuyển sâu về hướng Chính Đông."
    },
    {
        "can_chi_list": ["Canh Thân", "Tân Dậu", "Nhâm Tuất", "Quý Hợi", "Giáp Tý", "Ất Sửu"],
        "huong": "Đông Nam",
        "ghi_chu": "Cấm kỵ xuất hành, khởi công hoặc đi chuyển sâu về hướng Đông Nam."
    },
    {
        "can_chi_list": ["Bính Dần", "Đinh Mão", "Mậu Thìn", "Kỷ Tỵ", "Canh Ngọ"],
        "huong": "Chính Nam",
        "ghi_chu": "Cấm kỵ xuất hành, khởi công hoặc đi chuyển sâu về hướng Chính Nam."
    },
    {
        "can_chi_list": ["Tân Mùi", "Nhâm Thân", "Quý Dậu", "Giáp Tuất", "Ất Hợi", "Bính Tý"],
        "huong": "Tây Nam",
        "ghi_chu": "Cấm kỵ xuất hành, khởi công hoặc đi chuyển sâu về hướng Tây Nam."
    },
    {
        "can_chi_list": ["Đinh Sửu", "Mậu Dần", "Kỷ Mão", "Canh Thìn", "Tân Tỵ"],
        "huong": "Chính Tây",
        "ghi_chu": "Cấm kỵ xuất hành, khởi công hoặc đi chuyển sâu về hướng Chính Tây."
    },
    {
        "can_chi_list": ["Nhâm Ngọ", "Quý Mùi", "Giáp Thân", "Ất Dậu", "Bính Tuất", "Đinh Hợi"],
        "huong": "Tây Bắc",
        "ghi_chu": "Cấm kỵ xuất hành, khởi công hoặc đi chuyển sâu về hướng Tây Bắc."
    }
]

HAC_THAN_LEN_TROI = {
    "huong": "Lên Trời (Không ở nhân gian, đỡ lo ngại)",
    "ghi_chu": "Hạc Thần lánh vị, ngày này xuất hành ít bị ảnh hưởng bởi hung thần này.",
    "is_len_troi": True,
    "display_text": "Không có hướng Hạc Thần. Đi được mọi hướng đều an toàn"
}

def calculate_huong_xuat_hanh(day_can: str, day_can_chi: str):
    """
    Module 2: Hướng Xuất Hành (Hỷ Thần, Tài Thần, Hạc Thần)
    Render 2 dòng theo Hình 6:
    Dòng 1: Hướng Xuất Hành | Đi hướng [Hướng Hỷ Thần] đón Hỷ Thần | Đi hướng [Hướng Tài Thần] đón Tài Thần | Tránh hướng [Hướng Hạc Thần] gặp Hạc Thần (xấu)
    (Nếu Hạc Thần Lên Trời: đổi thành 'Không có hướng Hạc Thần. Đi được mọi hướng đều an toàn')
    Dòng 2: Ngày [Can Chi Ngày] | [Gợi ý lựa chọn xuất hành từ Hình 4]. [Ghi chú hành sự từ Hình 5].
    """
    can_info = THIEN_CAN_HUONG_MAP.get(day_can, {
        "hy_than": "Đông Bắc",
        "tai_than": "Chính Đông",
        "goi_y": "Đi Đông Bắc (cầu duyên) hoặc Chính Đông (cầu tài)"
    })

    hac_info = HAC_THAN_LEN_TROI
    for nhom in HAC_THAN_NHOM_LIST:
        if day_can_chi in nhom["can_chi_list"]:
            hac_info = nhom
            break

    hy_than = can_info["hy_than"]
    tai_than = can_info["tai_than"]
    goi_y = can_info["goi_y"]
    hac_than = hac_info["huong"]
    ghi_chu = hac_info["ghi_chu"]
    is_len_troi = hac_info.get("is_len_troi", False)

    if is_len_troi:
        hac_than_str = "Không có hướng Hạc Thần. Đi được mọi hướng đều an toàn"
        dong_1 = f"Hướng Xuất Hành    Đi hướng {hy_than} đón Hỷ Thần    Đi hướng {tai_than} đón Tài Thần    {hac_than_str}"
    else:
        hac_than_str = f"Tránh hướng {hac_than} gặp Hạc Thần (xấu)"
        dong_1 = f"Hướng Xuất Hành    Đi hướng {hy_than} đón Hỷ Thần    Đi hướng {tai_than} đón Tài Thần    {hac_than_str}"

    dong_2 = f"Ngày {day_can_chi}    {goi_y}. {ghi_chu}"

    return {
        "hy_than": hy_than,
        "tai_than": tai_than,
        "hac_than": hac_than,
        "is_len_troi": is_len_troi,
        "hac_than_str": hac_than_str,
        "goi_y": goi_y,
        "ghi_chu": ghi_chu,
        "dong_1": dong_1,
        "dong_2": dong_2,
        "rendered_text": f"{dong_1}\n{dong_2}"
    }


# ==============================================================================
# MODULE 3: TÍNH CHẤT NGÀY CÁT HUNG (KHỔNG MINH LỤC DIỆU)
# ==============================================================================
KHONG_MINH_LUC_DIEU_STATES = [
    {
        "name": "Đại An",
        "tinh_chat": "Ổn định, bền vững",
        "goi_y": "Phù hợp với việc dài hạn, xây sửa nhà, cưới hỏi, khai trương, xuất hành"
    },
    {
        "name": "Lưu Niên",
        "tinh_chat": "Trì trệ, hao thời gian",
        "goi_y": "Nên rà soát, bảo trì, hoàn thiện hồ sơ hoặc học tập, tránh khởi sự lớn"
    },
    {
        "name": "Tốc Hỷ",
        "tinh_chat": "Niềm vui nhanh, hanh thông sớm",
        "goi_y": "Phù hợp cưới hỏi, mừng việc, khởi động công việc hoặc xin việc"
    },
    {
        "name": "Xích Khẩu",
        "tinh_chat": "Thị phi, tranh cãi",
        "goi_y": "Nên làm việc hậu trường, chuẩn bị yên lặng, tránh đàm phán hoặc kiện tụng"
    },
    {
        "name": "Tiểu Cát",
        "tinh_chat": "May mắn nhỏ, thuận lợi",
        "goi_y": "Phù hợp với các hoạt động nhỏ như khai trương nhỏ, ký kết hợp đồng nhẹ"
    },
    {
        "name": "Không Vong",
        "tinh_chat": "Hư không, dễ đổ vỡ",
        "goi_y": "Nên tĩnh tâm, hoạch định hoặc tu tâm, tránh mọi quyết định quan trọng lớn"
    }
]

def calculate_khong_minh_luc_dieu(lunar_month: int, lunar_day: int):
    """
    Module 3: Phương pháp 2 - Tra cứu nhanh theo tháng và ngày âm
    Khởi mùng 1:
      Tháng 1&7: Đại An (idx 0)
      Tháng 2&8: Lưu Niên (idx 1)
      Tháng 3&9: Tốc Hỷ (idx 2)
      Tháng 4&10: Xích Khẩu (idx 3)
      Tháng 5&11: Tiểu Cát (idx 4)
      Tháng 6&12: Không Vong (idx 5)
    Render UI (Hình 10 - Block trên):
      Khổng Minh Lục Diệu    Ngày [Tên Trạng Thái] là Ngày [Tính chất]. [Gợi ý ứng dụng].
    """
    start_idx = (lunar_month - 1) % 6
    state_idx = (start_idx + (lunar_day - 1)) % 6
    state = KHONG_MINH_LUC_DIEU_STATES[state_idx]

    rendered_text = f"Khổng Minh Lục Diệu    Ngày {state['name']} là Ngày {state['tinh_chat']}. {state['goi_y']}."

    return {
        "name": state["name"],
        "tinh_chat": state["tinh_chat"],
        "goi_y": state["goi_y"],
        "rendered_text": rendered_text
    }


# ==============================================================================
# MODULE 4: NGÀY XUẤT HÀNH (CỤ KHỔNG MINH)
# ==============================================================================
KM_GROUP_1 = {
    "months": [1, 4, 7, 10],
    "stars": {
        "Đường Phong": {
            "days": [1, 7, 13, 19, 25],
            "quality": "Tốt",
            "meaning": "Rất tốt, xuất hành thuận lợi, cầu tài được như ý muốn, gặp quý nhân phù trợ."
        },
        "Kim Thổ": {
            "days": [2, 8, 14, 20, 26],
            "quality": "Hung",
            "meaning": "Ra đi nhỡ tàu, nhỡ xe, cầu tài không được, trên đường đi mất của, bất lợi."
        },
        "Kim Dương": {
            "days": [3, 9, 15, 21, 27],
            "quality": "Tốt",
            "meaning": "Xuất hành tốt, có quý nhân phù trợ, tài lộc thông suốt, thưa kiện có nhiều lý phải."
        },
        "Thuần Dương": {
            "days": [4, 10, 16, 22, 28],
            "quality": "Tốt",
            "meaning": "Xuất hành tốt, lúc về cũng tốt, nhiều thuận lợi, được người tốt giúp đỡ, cầu tài được như ý muốn, tranh luận thường thắng lợi."
        },
        "Đạo Tặc": {
            "days": [5, 11, 17, 23, 29],
            "quality": "Hung",
            "meaning": "Rất xấu. Xuất hành bị hại, mất của."
        },
        "Hảo Thương": {
            "days": [6, 12, 18, 24, 30],
            "quality": "Tốt",
            "meaning": "Xuất hành thuận lợi, gặp người lớn vừa lòng, làm việc việc như ý muốn, áo phẩm vinh quy."
        }
    }
}

KM_GROUP_2 = {
    "months": [2, 5, 8, 11],
    "stars": {
        "Thiên Đạo": {
            "days": [1, 9, 17, 25],
            "quality": "Hung",
            "meaning": "Xuất hành cầu tài nên tránh, dù được cũng rất tốn kém, thất lý mà thua."
        },
        "Thiên Môn": {
            "days": [2, 10, 18, 26],
            "quality": "Tốt",
            "meaning": "Xuất hành làm mọi việc đều vừa ý, cầu được ước thấy mọi việc đều thành đạt."
        },
        "Thiên Đường": {
            "days": [3, 11, 19, 27],
            "quality": "Tốt",
            "meaning": "Xuất hành tốt, quý nhân phù trợ, buôn bán may mắn, mọi việc đều như ý."
        },
        "Thiên Tài": {
            "days": [4, 12, 20, 28],
            "quality": "Tốt",
            "meaning": "Nên xuất hành, cầu tài thắng lợi. Được người tốt giúp đỡ. Mọi việc đều thuận."
        },
        "Thiên Tặc": {
            "days": [5, 13, 21, 29],
            "quality": "Hung",
            "meaning": "Xuất hành xấu, cầu tài không được. Đi đường dễ mất cắp. Mọi việc đều rất xấu."
        },
        "Thiên Dương": {
            "days": [6, 14, 22],
            "quality": "Tốt",
            "meaning": "Xuất hành tốt, cầu tài được tài. Hỏi vợ được vợ. Mọi việc đều như ý muốn."
        },
        "Thiên Hầu": {
            "days": [7, 15, 23],
            "quality": "Hung",
            "meaning": "Xuất hành dầu ít hay nhiều cũng cãi cọ, phải tránh xẩy ra tai nạn chảy máu, máu sẽ khó cầm."
        },
        "Thiên Thương": {
            "days": [8, 16, 24, 30],
            "quality": "Tốt",
            "meaning": "Xuất hành để gặp cấp trên thì tuyệt vời, cầu tài thì được tài. Mọi việc đều thuận lợi."
        }
    }
}

KM_GROUP_3 = {
    "months": [3, 6, 9, 12],
    "stars": {
        "Chu Tước": {
            "days": [1, 9, 17],
            "quality": "Hung",
            "meaning": "Xuất hành, cầu tài đều xấu. Hay mất của, kiện cáo thua vì đuối lý."
        },
        "Bạch Hổ Đầu": {
            "days": [2, 10, 18, 26],
            "quality": "Tốt",
            "meaning": "Xuất hành, cầu tài đều được. Đi đâu đều thông đạt cả."
        },
        "Bạch Hổ Kiếp": {
            "days": [3, 11, 19, 27],
            "quality": "Tốt",
            "meaning": "Xuất hành, cầu tài được như ý muốn, đi hướng Nam và Bắc rất thuận lợi."
        },
        "Bạch Hổ Túc": {
            "days": [4, 12, 20, 28],
            "quality": "Hung",
            "meaning": "Cấm đi xa, làm việc gì cũng không thành công. Rất xấu trong mọi việc."
        },
        "Huyền Vũ": {
            "days": [5, 13, 21, 29],
            "quality": "Hung",
            "meaning": "Xuất hành thường gặp cãi cọ, gặp việc xấu, không nên đi."
        },
        "Thanh Long Đầu": {
            "days": [6, 14, 22],
            "quality": "Tốt",
            "meaning": "Xuất hành nên đi vào sáng sớm. Cầu tài thắng lợi. Mọi việc như ý."
        },
        "Thanh Long Kiếp": {
            "days": [7, 15, 23, 25],
            "quality": "Tốt",
            "meaning": "Xuất hành 4 phương, 8 hướng đều tốt, trăm sự được như ý."
        },
        "Thanh Long Túc": {
            "days": [8, 16, 24, 30],
            "quality": "Hung",
            "meaning": "Đi xa không nên, xuất hành xấu, tài lộc không có. Kiện cáo cũng đuối lý."
        }
    }
}

def calculate_khong_minh_xuat_hanh_star(lunar_month: int, lunar_day: int):
    """
    Module 4: Ngày Xuất Hành của Cụ Khổng Minh
    Render UI (Hình 10 - Block dưới):
      NGÀY [TÊN SAO]: [Ý nghĩa nguyên văn từ tài liệu]
    """
    if lunar_month in KM_GROUP_1["months"]:
        group = KM_GROUP_1
    elif lunar_month in KM_GROUP_2["months"]:
        group = KM_GROUP_2
    else:
        group = KM_GROUP_3

    star_name = ""
    star_info = None

    for s_name, s_data in group["stars"].items():
        if lunar_day in s_data["days"]:
            star_name = s_name
            star_info = s_data
            break

    if not star_info:
        star_name = "Bình Thường"
        meaning = "Xuất hành bình thường."
        quality = "Bình"
    else:
        meaning = star_info["meaning"]
        quality = star_info["quality"]

    rendered_text = f"NGÀY {star_name.upper()}: {meaning}"

    return {
        "star_name": star_name,
        "quality": quality,
        "meaning": meaning,
        "rendered_text": rendered_text
    }


# ==============================================================================
# HÀM TỔNG HỢP TOÀN BỘ DỮ LIỆU XUẤT HÀNH
# ==============================================================================
def get_full_xuat_hanh_data(lunar_month: int, lunar_day: int, day_can: str, day_can_chi: str):
    m1 = calculate_gio_xuat_hanh_ly_thuan_phong(lunar_month, lunar_day)
    m2 = calculate_huong_xuat_hanh(day_can, day_can_chi)
    m3 = calculate_khong_minh_luc_dieu(lunar_month, lunar_day)
    m4 = calculate_khong_minh_xuat_hanh_star(lunar_month, lunar_day)

    return {
        "module_1_ly_thuan_phong": m1,
        "module_2_huong_xuat_hanh": m2,
        "module_3_khong_minh_luc_dieu": m3,
        "module_4_khong_minh_ngay": m4,
        "dong_1_gio_xuat_hanh_gop": [item["rendered_text"] for item in m1],
        "dong_10_huong_xuat_hanh": m2["rendered_text"],
        "dong_11_khong_minh": f"{m3['rendered_text']}\n\n{m4['rendered_text']}"
    }
