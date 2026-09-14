import json

def inject():
    file_path = r"E:\Tu vi online\than_sat_db.json"
    strict_file_path = r"E:\Tu vi online\than_sat_db_strict.json"
    
    with open(file_path, "r", encoding="utf-8") as f:
        db = json.load(f)

    # 139. Thiên Xá
    thien_xa = {
        "thang_1": {"chi_ngay": ["Dần"]}, "thang_2": {"chi_ngay": ["Dần"]}, "thang_3": {"chi_ngay": ["Dần"]},
        "thang_4": {"chi_ngay": ["Ngọ"]}, "thang_5": {"chi_ngay": ["Ngọ"]}, "thang_6": {"chi_ngay": ["Ngọ"]},
        "thang_7": {"chi_ngay": ["Thân"]}, "thang_8": {"chi_ngay": ["Thân"]}, "thang_9": {"chi_ngay": ["Thân"]},
        "thang_10": {"chi_ngay": ["Tý"]}, "thang_11": {"chi_ngay": ["Tý"]}, "thang_12": {"chi_ngay": ["Tý"]},
        "theo_gio": {
            "can_ngay_giáp": {"chi_gio": ["Mão"]},
            "can_ngay_ất": {"chi_gio": ["Sửu"]},
            "can_ngay_bính": {"chi_gio": ["Dậu"]},
            "can_ngay_đinh": {"chi_gio": ["Mùi"]},
            "can_ngay_mậu": {"chi_gio": ["Tỵ"]},
            "can_ngay_kỷ": {"chi_gio": ["Mão"]},
            "can_ngay_canh": {"chi_gio": ["Sửu", "Hợi"]},
            "can_ngay_tân": {"chi_gio": ["Dậu"]},
            "can_ngay_nhâm": {"chi_gio": ["Sửu", "Mùi"]},
            "can_ngay_quý": {"chi_gio": ["Thìn", "Tỵ"]}
        }
    }

    # 143. Thổ Kỵ
    tho_ky = {
        "thang_dần": {"chi_ngay": ["Dần", "Hợi"], "ngay_am_lich": ["6"]},
        "thang_mão": {"chi_ngay": ["Tỵ", "Hợi"], "ngay_am_lich": ["23"]},
        "thang_thìn": {"chi_ngay": ["Thân", "Hợi"], "ngay_am_lich": ["12"]},
        "thang_tỵ": {"chi_ngay": ["Hợi", "Dần"], "ngay_am_lich": ["8"]},
        "thang_ngọ": {"chi_ngay": ["Mão", "Dần"], "ngay_am_lich": ["16"]},
        "thang_mùi": {"chi_ngay": ["Ngọ", "Dần"], "ngay_am_lich": ["24"]},
        "thang_thân": {"chi_ngay": ["Dậu", "Tỵ"], "ngay_am_lich": ["9"]},
        "thang_dậu": {"chi_ngay": ["Tý", "Tỵ"], "ngay_am_lich": ["27"]},
        "thang_tuất": {"chi_ngay": ["Thìn", "Tỵ"], "ngay_am_lich": ["4"]},
        "thang_hợi": {"chi_ngay": ["Mùi", "Thân"], "ngay_am_lich": ["14"]},
        "thang_tý": {"chi_ngay": ["Tuất", "Thân"], "ngay_am_lich": ["20"]},
        "thang_sửu": {"chi_ngay": ["Sửu", "Thân"], "ngay_am_lich": ["6"]}
    }

    # 145. Tàn Bại
    tan_bai = {
        "can_chi_ngay": [
            "Giáp Thìn", "Ất Tỵ", "Bính Thân", "Đinh Hợi", "Mậu Tuất",
            "Kỷ Sửu", "Canh Thìn", "Tân Tỵ", "Nhâm Thân", "Quý Hợi"
        ]
    }

    # 146. Thiên Địa Trục
    thien_dia_truc = {
        "thang_mùa xuân": {"can_chi_ngay": ["Ất Hợi"]},
        "thang_mùa hạ": {"can_chi_ngay": ["Đinh Hợi"]},
        "thang_mùa thu": {"can_chi_ngay": ["Tân Hợi"]},
        "thang_mùa đông": {"can_chi_ngay": ["Quý Hợi"]}
    }

    # 155. Tiểu Hồng Sa
    tieu_hong_sa = {
        "thang_1": {"chi_ngay": ["Dậu"]}, "thang_4": {"chi_ngay": ["Dậu"]}, "thang_7": {"chi_ngay": ["Dậu"]}, "thang_10": {"chi_ngay": ["Dậu"]},
        "thang_2": {"chi_ngay": ["Tỵ"]}, "thang_5": {"chi_ngay": ["Tỵ"]}, "thang_8": {"chi_ngay": ["Tỵ"]}, "thang_11": {"chi_ngay": ["Tỵ"]},
        "thang_3": {"chi_ngay": ["Sửu"]}, "thang_6": {"chi_ngay": ["Sửu"]}, "thang_9": {"chi_ngay": ["Sửu"]}, "thang_12": {"chi_ngay": ["Sửu"]}
    }

    updates = {
        "139.Thiên Xá": thien_xa,
        "143.Thổ Kỵ": tho_ky,
        "145. Tàn Bại": tan_bai,
        "146. Thiên Địa Trục": thien_dia_truc,
        "155.Tiểu Hồng Sa": tieu_hong_sa
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
