import json

def update_next_5_stars():
    file_path = r"E:\Tu vi online\than_sat_db.json"
    strict_file_path = r"E:\Tu vi online\than_sat_db_strict.json"
    
    with open(file_path, "r", encoding="utf-8") as f:
        db = json.load(f)

    mau_thuong = {
        "thang_dần": {"chi_ngay": ["Hợi", "Tý"]},
        "thang_mão": {"chi_ngay": ["Hợi", "Tý"]},
        "thang_thìn": {"chi_ngay": ["Tỵ", "Ngọ"]},
        "thang_tỵ": {"chi_ngay": ["Dần", "Mão"]},
        "thang_ngọ": {"chi_ngay": ["Dần", "Mão"]},
        "thang_mùi": {"chi_ngay": ["Tỵ", "Ngọ"]},
        "thang_thân": {"chi_ngay": ["Thìn", "Tuất", "Sửu", "Mùi"]},
        "thang_dậu": {"chi_ngay": ["Thìn", "Tuất", "Sửu", "Mùi"]},
        "thang_tuất": {"chi_ngay": ["Tỵ", "Ngọ"]},
        "thang_hợi": {"chi_ngay": ["Thân", "Dậu"]},
        "thang_tý": {"chi_ngay": ["Thân", "Dậu"]},
        "thang_sửu": {"chi_ngay": ["Tỵ", "Ngọ"]}
    }

    minh_duong = {
        "thang_1": {"chi_ngay": ["Thìn"]}, "thang_2": {"chi_ngay": ["Mão"]}, "thang_3": {"chi_ngay": ["Dần"]},
        "thang_4": {"chi_ngay": ["Sửu"]}, "thang_5": {"chi_ngay": ["Tý"]}, "thang_6": {"chi_ngay": ["Hợi"]},
        "thang_7": {"chi_ngay": ["Tuất"]}, "thang_8": {"chi_ngay": ["Dậu"]}, "thang_9": {"chi_ngay": ["Thân"]},
        "thang_10": {"chi_ngay": ["Mùi"]}, "thang_11": {"chi_ngay": ["Ngọ"]}, "thang_12": {"chi_ngay": ["Tỵ"]},
        "theo_gio": {
            "chi_ngay_dần": {"chi_gio": ["Hợi", "Tý"]}, "chi_ngay_mão": {"chi_gio": ["Hợi", "Tý"]},
            "chi_ngay_thìn": {"chi_gio": ["Tỵ", "Ngọ"]}, "chi_ngay_tỵ": {"chi_gio": ["Dần", "Mão"]},
            "chi_ngay_ngọ": {"chi_gio": ["Dần", "Mão"]}, "chi_ngay_mùi": {"chi_gio": ["Tỵ", "Ngọ"]},
            "chi_ngay_thân": {"chi_gio": ["Thìn", "Tuất", "Sửu", "Mùi"]}, "chi_ngay_dậu": {"chi_gio": ["Thìn", "Tuất", "Sửu", "Mùi"]},
            "chi_ngay_tuất": {"chi_gio": ["Tỵ", "Ngọ"]}, "chi_ngay_hợi": {"chi_gio": ["Thân", "Dậu"]},
            "chi_ngay_tý": {"chi_gio": ["Thân", "Dậu"]}, "chi_ngay_sửu": {"chi_gio": ["Tỵ", "Ngọ"]}
        }
    }

    ngoc_vu = {
        "thang_1": {"chi_ngay": ["Mão"]}, "thang_2": {"chi_ngay": ["Dậu"]}, "thang_3": {"chi_ngay": ["Thìn"]},
        "thang_4": {"chi_ngay": ["Tuất"]}, "thang_5": {"chi_ngay": ["Tỵ"]}, "thang_6": {"chi_ngay": ["Hợi"]},
        "thang_7": {"chi_ngay": ["Ngọ"]}, "thang_8": {"chi_ngay": ["Tý"]}, "thang_9": {"chi_ngay": ["Mùi"]},
        "thang_10": {"chi_ngay": ["Sửu"]}, "thang_11": {"chi_ngay": ["Thân"]}, "thang_12": {"chi_ngay": ["Dần"]}
    }

    ngu_hop = {
        "can_chi_ngay": ["Giáp Dần", "Ất Mão", "Bính Dần", "Đinh Mão", "Mậu Dần", "Kỷ Mão", "Canh Dần", "Tân Mão", "Nhâm Dần"],
        "theo_gio": {
            "can_ngay_giáp": {"chi_gio": ["Tỵ"]}, "can_ngay_kỷ": {"chi_gio": ["Tý", "Tuất"]},
            "can_ngay_ất": {"chi_gio": ["Thìn"]}, "can_ngay_canh": {"chi_gio": ["Dậu"]},
            "can_ngay_bính": {"chi_gio": ["Mão"]}, "can_ngay_tân": {"chi_gio": ["Thân"]},
            "can_ngay_đinh": {"chi_gio": ["Dần"]}, "can_ngay_nhâm": {"chi_gio": ["Mùi"]},
            "can_ngay_mậu": {"chi_gio": ["Sửu"]}, "can_ngay_quý": {"chi_gio": ["Ngọ"]}
        }
    }

    ngu_hu = {
        "thang_dần": {"chi_ngay": ["Tỵ", "Dậu", "Sửu"]}, "thang_mão": {"chi_ngay": ["Tỵ", "Dậu", "Sửu"]}, "thang_thìn": {"chi_ngay": ["Tỵ", "Dậu", "Sửu"]},
        "thang_tỵ": {"chi_ngay": ["Thân", "Tý", "Thìn"]}, "thang_ngọ": {"chi_ngay": ["Thân", "Tý", "Thìn"]}, "thang_mùi": {"chi_ngay": ["Thân", "Tý", "Thìn"]},
        "thang_thân": {"chi_ngay": ["Hợi", "Mão", "Mùi"]}, "thang_dậu": {"chi_ngay": ["Hợi", "Mão", "Mùi"]}, "thang_tuất": {"chi_ngay": ["Hợi", "Mão", "Mùi"]},
        "thang_hợi": {"chi_ngay": ["Dần", "Ngọ", "Tuất"]}, "thang_tý": {"chi_ngay": ["Dần", "Ngọ", "Tuất"]}, "thang_sửu": {"chi_ngay": ["Dần", "Ngọ", "Tuất"]}
    }

    updates = {
        "68.Mẫu Thương": mau_thuong,
        "69.Minh Đường": minh_duong,
        "74.Ngọc Vũ": ngoc_vu,
        "75.Ngũ Hợp": ngu_hop,
        "76.Ngũ Hư": ngu_hu
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
    update_next_5_stars()
