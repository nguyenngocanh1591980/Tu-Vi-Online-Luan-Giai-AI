import json

def update_next_5_stars_batch2():
    file_path = r"E:\Tu vi online\than_sat_db.json"
    strict_file_path = r"E:\Tu vi online\than_sat_db_strict.json"
    
    with open(file_path, "r", encoding="utf-8") as f:
        db = json.load(f)

    # 93. Nguyệt Tài
    nguyet_tai = {
        "thang_1": {"chi_ngay": ["Ngọ"]}, "thang_2": {"chi_ngay": ["Tỵ"]}, "thang_3": {"chi_ngay": ["Tỵ"]},
        "thang_4": {"chi_ngay": ["Mùi"]}, "thang_5": {"chi_ngay": ["Dậu"]}, "thang_6": {"chi_ngay": ["Hợi"]},
        "thang_7": {"chi_ngay": ["Ngọ"]}, "thang_8": {"chi_ngay": ["Tỵ"]}, "thang_9": {"chi_ngay": ["Tỵ"]},
        "thang_10": {"chi_ngay": ["Mùi"]}, "thang_11": {"chi_ngay": ["Dậu"]}, "thang_12": {"chi_ngay": ["Hợi"]}
    }

    # 106. Phúc Tinh
    phuc_tinh = {
        "theo_gio": {
            "can_ngay_giáp": {"can_chi_gio": ["Bính Dần"]},
            "can_ngay_ất": {"can_chi_gio": ["Đinh Sửu", "Đinh Hợi"]},
            "can_ngay_bính": {"can_chi_gio": ["Mậu Tý", "Mậu Tuất"]},
            "can_ngay_đinh": {"can_chi_gio": ["Kỷ Dậu"]},
            "can_ngay_mậu": {"can_chi_gio": ["Canh Thân"]},
            "can_ngay_kỷ": {"can_chi_gio": ["Tân Mùi"]},
            "can_ngay_canh": {"can_chi_gio": ["Nhâm Ngọ"]},
            "can_ngay_tân": {"can_chi_gio": ["Quý Tỵ"]},
            "can_ngay_nhâm": {"can_chi_gio": ["Giáp Thìn"]},
            "can_ngay_quý": {"can_chi_gio": ["Ất Mão"]}
        },
        "thang_1": {"chi_ngay": ["Dậu"]}, "thang_2": {"chi_ngay": ["Mão"]}, "thang_3": {"chi_ngay": ["Tuất"]},
        "thang_4": {"chi_ngay": ["Thìn"]}, "thang_5": {"chi_ngay": ["Hợi"]}, "thang_6": {"chi_ngay": ["Tỵ"]},
        "thang_7": {"chi_ngay": ["Tý"]}, "thang_8": {"chi_ngay": ["Ngọ"]}, "thang_9": {"chi_ngay": ["Sửu"]},
        "thang_10": {"chi_ngay": ["Mùi"]}, "thang_11": {"chi_ngay": ["Dần"]}, "thang_12": {"chi_ngay": ["Thân"]}
    }

    # 109. Tai Sát (Thiên Hỏa)
    tai_sat = {
        "thang_dần": {"chi_ngay": ["Tý"]}, "thang_mão": {"chi_ngay": ["Mão"]}, "thang_thìn": {"chi_ngay": ["Ngọ"]},
        "thang_tỵ": {"chi_ngay": ["Dậu"]}, "thang_ngọ": {"chi_ngay": ["Tý"]}, "thang_mùi": {"chi_ngay": ["Mão"]},
        "thang_thân": {"chi_ngay": ["Ngọ"]}, "thang_dậu": {"chi_ngay": ["Dậu"]}, "thang_tuất": {"chi_ngay": ["Tý"]},
        "thang_hợi": {"chi_ngay": ["Mão"]}, "thang_tý": {"chi_ngay": ["Ngọ"]}, "thang_sửu": {"chi_ngay": ["Dậu"]}
    }

    # 114. Thiên Ân
    thien_an = {
        "can_chi_ngay": [
            "Giáp Tý", "Ất Sửu", "Bính Dần", "Đinh Mão", "Mậu Thìn", "Kỷ Mão", "Canh Thìn", "Tân Tỵ",
            "Nhâm Ngọ", "Quý Mùi", "Kỷ Dậu", "Canh Tuất", "Tân Hợi", "Nhâm Tý", "Quý Sửu"
        ],
        "chi_ngay": ["Tý"]
    }

    # 137. Thiên Thương
    thien_thuong = {
        "thang_1": {"chi_ngay": ["Dần"]}, "thang_2": {"chi_ngay": ["Sửu"]}, "thang_3": {"chi_ngay": ["Tý"]},
        "thang_4": {"chi_ngay": ["Hợi"]}, "thang_5": {"chi_ngay": ["Tuất"]}, "thang_6": {"chi_ngay": ["Dậu"]},
        "thang_7": {"chi_ngay": ["Thân"]}, "thang_8": {"chi_ngay": ["Mùi"]}, "thang_9": {"chi_ngay": ["Ngọ"]},
        "thang_10": {"chi_ngay": ["Tỵ"]}, "thang_11": {"chi_ngay": ["Thìn"]}, "thang_12": {"chi_ngay": ["Mão"]}
    }

    updates = {
        "93.Nguyệt Tài": nguyet_tai,
        "106.Phúc Tinh": phuc_tinh,
        "109.Tai Sát": tai_sat,
        "114.Thiên Ân": thien_an,
        "137.Thiên Thương": thien_thuong
    }
    
    updated_count = 0
    for star in db:
        ten_sao = star.get("ten_sao", "")
        for key, logic in updates.items():
            if ten_sao.startswith(key):
                star["logic_an_sao"] = logic
                updated_count += 1
                print(f"✅ Đã cập nhật thành công: {ten_sao}")
                break

    with open(file_path, "w", encoding="utf-8") as f:
        json.dump(db, f, ensure_ascii=False, indent=2)
    with open(strict_file_path, "w", encoding="utf-8") as f:
        json.dump(db, f, ensure_ascii=False, indent=2)

    print(f"\n=> Tổng số sao cập nhật: {updated_count}/5")

if __name__ == "__main__":
    update_next_5_stars_batch2()
