import json

def inject():
    file_path = r"E:\Tu vi online\than_sat_db.json"
    strict_file_path = r"E:\Tu vi online\than_sat_db_strict.json"
    
    with open(file_path, "r", encoding="utf-8") as f:
        db = json.load(f)

    # 157. Trừ Thần
    tru_than = {
        "chi_ngay": ["Thân", "Dậu"]
    }

    # 168. Tứ Phế
    tu_phe = {
        "thang_dần": {"can_chi_ngay": ["Canh Thân", "Tân Dậu"]},
        "thang_mão": {"can_chi_ngay": ["Canh Thân", "Tân Dậu"]},
        "thang_thìn": {"can_chi_ngay": ["Canh Thân", "Tân Dậu"]},
        "thang_tỵ": {"can_chi_ngay": ["Nhâm Tý", "Quý Hợi"]},
        "thang_ngọ": {"can_chi_ngay": ["Nhâm Tý", "Quý Hợi"]},
        "thang_mùi": {"can_chi_ngay": ["Nhâm Tý", "Quý Hợi"]},
        "thang_thân": {"can_chi_ngay": ["Giáp Dần", "Ất Mão"]},
        "thang_dậu": {"can_chi_ngay": ["Giáp Dần", "Ất Mão"]},
        "thang_tuất": {"can_chi_ngay": ["Giáp Dần", "Ất Mão"]},
        "thang_hợi": {"can_chi_ngay": ["Bính Ngọ", "Đinh Tỵ"]},
        "thang_tý": {"can_chi_ngay": ["Bính Ngọ", "Đinh Tỵ"]},
        "thang_sửu": {"can_chi_ngay": ["Bính Ngọ", "Đinh Tỵ"]}
    }

    # 169. Tử Phù
    tu_phu = {
        "thang_1": {"chi_ngay": ["Mùi"]}, "thang_7": {"chi_ngay": ["Sửu"]},
        "thang_2": {"chi_ngay": ["Thân"]}, "thang_8": {"chi_ngay": ["Dần"]},
        "thang_3": {"chi_ngay": ["Dậu"]}, "thang_9": {"chi_ngay": ["Mão"]},
        "thang_4": {"chi_ngay": ["Tuất"]}, "thang_10": {"chi_ngay": ["Thìn"]},
        "thang_5": {"chi_ngay": ["Hợi"]}, "thang_11": {"chi_ngay": ["Tỵ"]},
        "thang_6": {"chi_ngay": ["Tý"]}, "thang_12": {"chi_ngay": ["Ngọ"]}
    }

    # 176. Tuế Phá
    tue_pha = {
        "theo_nam": {
            "nam_tý": {"chi_ngay": ["Ngọ"]}, "nam_ngọ": {"chi_ngay": ["Tý"]},
            "nam_sửu": {"chi_ngay": ["Mùi"]}, "nam_mùi": {"chi_ngay": ["Sửu"]},
            "nam_dần": {"chi_ngay": ["Thân"]}, "nam_thân": {"chi_ngay": ["Dần"]},
            "nam_mão": {"chi_ngay": ["Dậu"]}, "nam_dậu": {"chi_ngay": ["Mão"]},
            "nam_thìn": {"chi_ngay": ["Tuất"]}, "nam_tuất": {"chi_ngay": ["Thìn"]},
            "nam_tỵ": {"chi_ngay": ["Hợi"]}, "nam_hợi": {"chi_ngay": ["Tỵ"]}
        }
    }

    # 181. Vương Nhật
    vuong_nhat = {
        "thang_dần": {"can_ngay": ["Giáp", "Ất"], "chi_ngay": ["Dần", "Mão"]},
        "thang_mão": {"can_ngay": ["Giáp", "Ất"], "chi_ngay": ["Dần", "Mão"]},
        "thang_thìn": {"can_ngay": ["Giáp", "Ất"], "chi_ngay": ["Dần", "Mão"]},
        "thang_tỵ": {"can_ngay": ["Bính", "Đinh"], "chi_ngay": ["Tỵ", "Ngọ"]},
        "thang_ngọ": {"can_ngay": ["Bính", "Đinh"], "chi_ngay": ["Tỵ", "Ngọ"]},
        "thang_mùi": {"can_ngay": ["Bính", "Đinh"], "chi_ngay": ["Tỵ", "Ngọ"]},
        "thang_thân": {"can_ngay": ["Canh", "Tân"], "chi_ngay": ["Thân", "Dậu"]},
        "thang_dậu": {"can_ngay": ["Canh", "Tân"], "chi_ngay": ["Thân", "Dậu"]},
        "thang_tuất": {"can_ngay": ["Canh", "Tân"], "chi_ngay": ["Thân", "Dậu"]},
        "thang_hợi": {"can_ngay": ["Nhâm", "Quý"], "chi_ngay": ["Hợi", "Tý"]},
        "thang_tý": {"can_ngay": ["Nhâm", "Quý"], "chi_ngay": ["Hợi", "Tý"]},
        "thang_sửu": {"can_ngay": ["Nhâm", "Quý"], "chi_ngay": ["Hợi", "Tý"]}
    }

    updates = {
        "157.Trừ Thần": tru_than,
        "168.Tứ Phế": tu_phe,
        "169.Tử Phù": tu_phu,
        "176.Tuế Phá": tue_pha,
        "181.Vương Nhật": vuong_nhat
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
    inject()
