import json

def update_next_4_stars():
    file_path = r"E:\Tu vi online\than_sat_db.json"
    strict_file_path = r"E:\Tu vi online\than_sat_db_strict.json"
    
    with open(file_path, "r", encoding="utf-8") as f:
        db = json.load(f)

    ngu_phu = {
        "theo_gio": {
            "chi_ngay_dần": {"chi_gio": ["Hợi"]}, "chi_ngay_mão": {"chi_gio": ["Dần"]},
            "chi_ngay_thìn": {"chi_gio": ["Tỵ"]}, "chi_ngay_tỵ": {"chi_gio": ["Thân"]},
            "chi_ngay_ngọ": {"chi_gio": ["Hợi"]}, "chi_ngay_mùi": {"chi_gio": ["Dần"]},
            "chi_ngay_thân": {"chi_gio": ["Tỵ"]}, "chi_ngay_dậu": {"chi_gio": ["Thân"]},
            "chi_ngay_tuất": {"chi_gio": ["Hợi"]}, "chi_ngay_hợi": {"chi_gio": ["Dần"]},
            "chi_ngay_tý": {"chi_gio": ["Tỵ"]}, "chi_ngay_sửu": {"chi_gio": ["Thân"]}
        },
        "thang_1": {"chi_ngay": ["Hợi"]}, "thang_2": {"chi_ngay": ["Dần"]}, "thang_3": {"chi_ngay": ["Tỵ"]},
        "thang_4": {"chi_ngay": ["Thân"]}, "thang_5": {"chi_ngay": ["Hợi"]}, "thang_6": {"chi_ngay": ["Dần"]},
        "thang_7": {"chi_ngay": ["Tỵ"]}, "thang_8": {"chi_ngay": ["Thân"]}, "thang_9": {"chi_ngay": ["Hợi"]},
        "thang_10": {"chi_ngay": ["Dần"]}, "thang_11": {"chi_ngay": ["Tỵ"]}, "thang_12": {"chi_ngay": ["Thân"]}
    }

    nguyet_duc = {
        "thang_1": {"can_ngay": ["Bính"]}, "thang_2": {"can_ngay": ["Giáp"]}, "thang_3": {"can_ngay": ["Nhâm"]},
        "thang_4": {"can_ngay": ["Canh"]}, "thang_5": {"can_ngay": ["Bính"]}, "thang_6": {"can_ngay": ["Giáp"]},
        "thang_7": {"can_ngay": ["Nhâm"]}, "thang_8": {"can_ngay": ["Canh"]}, "thang_9": {"can_ngay": ["Bính"]},
        "thang_10": {"can_ngay": ["Giáp"]}, "thang_11": {"can_ngay": ["Nhâm"]}, "thang_12": {"can_ngay": ["Canh"]}
    }

    nguyet_hoa = {
        "thang_1": {"chi_ngay": ["Tỵ"]}, "thang_2": {"chi_ngay": ["Thìn"]}, "thang_3": {"chi_ngay": ["Mão"]},
        "thang_4": {"chi_ngay": ["Dần"]}, "thang_5": {"chi_ngay": ["Sửu"]}, "thang_6": {"chi_ngay": ["Tý"]},
        "thang_7": {"chi_ngay": ["Hợi"]}, "thang_8": {"chi_ngay": ["Tuất"]}, "thang_9": {"chi_ngay": ["Dậu"]},
        "thang_10": {"chi_ngay": ["Thân"]}, "thang_11": {"chi_ngay": ["Mùi"]}, "thang_12": {"chi_ngay": ["Ngọ"]}
    }

    nguyet_hu = {
        "thang_dần": {"truc_ngay": ["Bế"], "chi_ngay": ["Sửu"]},
        "thang_mão": {"truc_ngay": ["Nguy"], "chi_ngay": ["Tuất"]},
        "thang_thìn": {"truc_ngay": ["Bình"], "chi_ngay": ["Mùi"]},
        "thang_tỵ": {"truc_ngay": ["Bế"], "chi_ngay": ["Thìn"]},
        "thang_ngọ": {"truc_ngay": ["Nguy"], "chi_ngay": ["Sửu"]},
        "thang_mùi": {"truc_ngay": ["Bình"], "chi_ngay": ["Tuất"]},
        "thang_thân": {"truc_ngay": ["Bế"], "chi_ngay": ["Mùi"]},
        "thang_dậu": {"truc_ngay": ["Nguy"], "chi_ngay": ["Thìn"]},
        "thang_tuất": {"truc_ngay": ["Bình"], "chi_ngay": ["Sửu"]},
        "thang_hợi": {"truc_ngay": ["Bế"], "chi_ngay": ["Tuất"]},
        "thang_tý": {"truc_ngay": ["Nguy"], "chi_ngay": ["Mùi"]},
        "thang_sửu": {"truc_ngay": ["Bình"], "chi_ngay": ["Thìn"]}
    }

    updates = {
        "78.Ngũ Phú": ngu_phu,
        "81.Nguyệt Đức": nguyet_duc,
        "85.Nguyệt Hoả": nguyet_hoa,
        "86.Nguyệt Hư": nguyet_hu
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

    print(f"\n=> Tổng số sao cập nhật: {updated_count}/4")

if __name__ == "__main__":
    update_next_4_stars()
