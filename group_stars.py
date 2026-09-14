def group_stars_for_ui(calculated_stars):
    """
    Phân nhóm danh sách các sao đã tính toán vào các nhóm giao diện (Accordion).
    - calculated_stars: List các dictionary chứa thông tin sao đã tính toán (VD: [{"ten_sao": "Địa Tặc", "y_nghia": "..."}]).
    - Return: Dictionary chứa các nhóm công việc, mỗi nhóm là một danh sách các sao cảnh báo.
    """
    
    # Định nghĩa các tập hợp sao xấu theo từng chủ đề dựa trên tài liệu
    groups_config = {
        "Xuất hành, di chuyển": [
            "Địa Tặc", "Ngũ Quỷ", "Không Vong", "Nguyệt Yếm đại họa", "Cửu Không", "Hoàng Sa", "Âm Thác", "Dương Thác"
        ],
        "Hôn thú": [
            "Nguyệt Hư", "Cô Thần", "Tam tang", "Trùng phục", "Quả Tú", "Ly Sàng", "Nhân Cách", "Tứ Thời Cô Quả", "Không Phòng", "Âm Thác", "Dương Thác"
        ],
        "Xây dựng, động thổ": [
            "Thiên Ngục", "Thiên Hỏa", "Địa Phá", "Nguyệt Phá", "Thiên Ôn", "Thổ Phủ", "Thiên Tặc", "Thổ Ôn", "Địa Tặc", "Hỏa Tai", "Thiên Cẩu", 
            "Lục Bất Thành", "Trùng Tang", "Cô Thần", "Phủ Đầu Sát", "Cửu Thổ Quỷ", "Nguyệt Hỏa", "Nhân Cách", "Chu Tước Hắc Đạo", "Nguyệt Kiến", 
            "Ngũ Hư", "Nguyệt Hư", "Hà Khôi", "Cẩu Giảo", "Lôi Công", "Lỗ Ban Sát", "Thổ Cấm"
        ],
        "Khai trương, giao dịch": [
            "Tiểu Hao", "Lục Bất Thành", "Xích Khẩu", "Nguyệt Hư", "Nguyệt Sát", "Cửu Không", "Không Vong", "Thiên Tặc", "Chu Tước Hắc Đạo"
        ],
        "Mai táng, lăng mộ": [
            "Thổ Phủ", "Địa Tặc", "Thổ Ôn", "Thiên Tặc", "Trùng Phục", "Nguyệt Kiến", "Bạch Hổ", "Huyền Vũ", "Câu Trận", "Tam tang", 
            "Ngũ Hư", "Nguyệt Sát", "Thổ Cấm", "Quỷ Khốc"
        ],
        "Tế tự, kiện tụng": [
            "Thổ Ôn", "Thiên Cẩu", "Thần Cách", "Tội Chỉ", "Chu Tước", "Xích Khẩu", "Thiên Hình Hắc Đạo", "Vãng Vong", "Tội Chí"
        ]
    }
    
    # Khởi tạo kết quả rỗng cho các nhóm
    grouped_result = {group_name: [] for group_name in groups_config.keys()}
    grouped_result["Cát Tinh Chung"] = []
    grouped_result["Các Sao Khác"] = []
    
    # Xử lý chuẩn hóa tên sao để so khớp (lowercase)
    normalized_config = {
        group_name: [star.lower() for star in star_list]
        for group_name, star_list in groups_config.items()
    }
    
    for star_obj in calculated_stars:
        ten_sao_goc = star_obj.get("ten_sao", "")
        phan_loai = star_obj.get("phan_loai", "")
        # Bỏ đi ID dạng "1.Âm Đức" -> "Âm Đức"
        ten_sao_clean = ten_sao_goc.split(".", 1)[-1].split(" - ")[0].strip()
        ten_sao_lower = ten_sao_clean.lower()
        
        is_grouped = False
        
        if phan_loai == "Cát Tinh":
            grouped_result["Cát Tinh Chung"].append(star_obj)
            is_grouped = True
        else:
            # Hung Tinh -> Kiểm tra xem nó thuộc nhóm xấu nào
            for group_name, star_list in normalized_config.items():
                if ten_sao_lower in star_list or any(ten_sao_lower.startswith(s) for s in star_list):
                    grouped_result[group_name].append(star_obj)
                    is_grouped = True
                    
        # Nếu là Hung tinh nhưng không nằm trong danh sách nhóm cụ thể
        if not is_grouped:
            grouped_result["Các Sao Khác"].append(star_obj)
            
    # Xóa các nhóm trống để JSON gọn hơn
    return {k: v for k, v in grouped_result.items() if len(v) > 0}

# Example Usage
if __name__ == "__main__":
    import json
    # Mock data
    mock_stars = [
        {"ten_sao": "9.Địa Tặc - Earth Thief", "phan_loai": "Hung Tinh", "y_nghia": "Xấu cho xuất hành..."},
        {"ten_sao": "1.Âm Đức", "phan_loai": "Cát Tinh", "y_nghia": "Tốt mọi việc"},
        {"ten_sao": "Trùng phục", "phan_loai": "Hung Tinh", "y_nghia": "Kỵ giá thú..."}
    ]
    
    result = group_stars_for_ui(mock_stars)
    print(json.dumps(result, ensure_ascii=False, indent=2))
