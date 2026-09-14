import json

def update_ngu_hop_again():
    file_path = r"E:\Tu vi online\than_sat_db.json"
    strict_file_path = r"E:\Tu vi online\than_sat_db_strict.json"
    
    with open(file_path, "r", encoding="utf-8") as f:
        db = json.load(f)

    ngu_hop = {
        "can_chi_ngay": ["Giáp Dần", "Ất Mão", "Bính Dần", "Đinh Mão", "Mậu Dần", "Kỷ Mão", "Canh Dần", "Tân Mão", "Nhâm Dần"],
        "theo_can_ngay_can_gio": {
            "Giáp": ["Kỷ"], "Kỷ": ["Giáp"],
            "Ất": ["Canh"], "Canh": ["Ất"],
            "Bính": ["Tân"], "Tân": ["Bính"],
            "Đinh": ["Nhâm"], "Nhâm": ["Đinh"],
            "Mậu": ["Quý"], "Quý": ["Mậu"]
        }
    }

    for star in db:
        ten_sao = star.get("ten_sao", "")
        if ten_sao.startswith("75.Ngũ Hợp") or ten_sao.startswith("75. Ngũ Hợp"):
            star["logic_an_sao"] = ngu_hop
            print(f"✅ Đã cập nhật thành công: {ten_sao}")
            break

    with open(file_path, "w", encoding="utf-8") as f:
        json.dump(db, f, ensure_ascii=False, indent=2)
    with open(strict_file_path, "w", encoding="utf-8") as f:
        json.dump(db, f, ensure_ascii=False, indent=2)

if __name__ == "__main__":
    update_ngu_hop_again()
