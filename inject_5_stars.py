import json

def update_stars():
    file_path = r"E:\Tu vi online\than_sat_db.json"
    strict_file_path = r"E:\Tu vi online\than_sat_db_strict.json"
    
    with open(file_path, "r", encoding="utf-8") as f:
        db = json.load(f)

    # Define logics
    bat_chuyen = {"can_chi_ngay": ["Đinh Mùi", "Quý Sửu", "Giáp Dần", "Ất Mão", "Kỷ Mùi", "Canh Thân"]}
    
    binh_bao = {}
    months = ["1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "11", "12"]
    days_per_month = [
        ["Tý", "Sửu", "Dần", "Mão"], ["Hợi", "Tý", "Sửu", "Dần"], ["Tuất", "Hợi", "Tý", "Sửu"],
        ["Dậu", "Tuất", "Hợi", "Tý"], ["Thân", "Dậu", "Tuất", "Hợi"], ["Mùi", "Thân", "Dậu", "Tuất"],
        ["Ngọ", "Mùi", "Thân", "Dậu"], ["Tỵ", "Ngọ", "Mùi", "Thân"], ["Thìn", "Tỵ", "Ngọ", "Mùi"],
        ["Mão", "Thìn", "Tỵ", "Ngọ"], ["Dần", "Mão", "Thìn", "Tỵ"], ["Sửu", "Dần", "Mão", "Thìn"]
    ]
    for m, days in zip(months, days_per_month):
        binh_bao[f"thang_{m}"] = {"chi_ngay": days}
        
    cuu_khong = {
        "thang_1": {"chi_ngay": ["Thìn"]}, "thang_2": {"chi_ngay": ["Sửu"]}, "thang_3": {"chi_ngay": ["Tuất"]},
        "thang_4": {"chi_ngay": ["Mùi"]}, "thang_5": {"chi_ngay": ["Thìn"]}, "thang_6": {"chi_ngay": ["Sửu"]},
        "thang_7": {"chi_ngay": ["Tuất"]}, "thang_8": {"chi_ngay": ["Mùi"]}, "thang_9": {"chi_ngay": ["Thìn"]},
        "thang_10": {"chi_ngay": ["Sửu"]}, "thang_11": {"chi_ngay": ["Tuất"]}, "thang_12": {"chi_ngay": ["Mùi"]}
    }

    hi_than = {
        "theo_gio": {
            "can_ngay_giáp": {"chi_gio": ["Dần"]}, "can_ngay_ất": {"chi_gio": ["Tuất"]},
            "can_ngay_bính": {"chi_gio": ["Thân"]}, "can_ngay_đinh": {"chi_gio": ["Ngọ"]},
            "can_ngay_mậu": {"chi_gio": ["Thìn"]}, "can_ngay_kỷ": {"chi_gio": ["Dần"]},
            "can_ngay_canh": {"chi_gio": ["Tuất"]}, "can_ngay_tân": {"chi_gio": ["Thân"]},
            "can_ngay_nhâm": {"chi_gio": ["Ngọ"]}, "can_ngay_quý": {"chi_gio": ["Thìn"]}
        }
    }
    
    hoang_vu = {
        "thang_dần": {"chi_ngay": ["Tỵ", "Dậu", "Sửu"]}, "thang_mão": {"chi_ngay": ["Tỵ", "Dậu", "Sửu"]}, "thang_thìn": {"chi_ngay": ["Tỵ", "Dậu", "Sửu"]},
        "thang_tỵ": {"chi_ngay": ["Thân", "Tý", "Thìn"]}, "thang_ngọ": {"chi_ngay": ["Thân", "Tý", "Thìn"]}, "thang_mùi": {"chi_ngay": ["Thân", "Tý", "Thìn"]},
        "thang_thân": {"chi_ngay": ["Hợi", "Mão", "Mùi"]}, "thang_dậu": {"chi_ngay": ["Hợi", "Mão", "Mùi"]}, "thang_tuất": {"chi_ngay": ["Hợi", "Mão", "Mùi"]},
        "thang_hợi": {"chi_ngay": ["Dần", "Ngọ", "Tuất"]}, "thang_tý": {"chi_ngay": ["Dần", "Ngọ", "Tuất"]}, "thang_sửu": {"chi_ngay": ["Dần", "Ngọ", "Tuất"]}
    }

    # Map name hints to logics
    updates = {
        "7.Bát Chuyên": bat_chuyen,
        "15. Binh Bảo": binh_bao,
        "25.Cửu Không": cuu_khong,
        "48.Hỉ Thần": hi_than,
        "51.Hoang Vu": hoang_vu
    }
    
    updated_count = 0
    for star in db:
        ten_sao = star.get("ten_sao", "")
        for key, logic in updates.items():
            if key in ten_sao:
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
    update_stars()
