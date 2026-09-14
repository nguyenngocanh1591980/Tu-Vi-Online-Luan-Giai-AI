import json

def fix_can_ngay_bug():
    file_path = r"E:\Tu vi online\than_sat_db.json"
    strict_file_path = r"E:\Tu vi online\than_sat_db_strict.json"
    
    with open(file_path, "r", encoding="utf-8") as f:
        db = json.load(f)
        
    VALID_CANS = ["Giáp", "Ất", "Bính", "Đinh", "Mậu", "Kỷ", "Canh", "Tân", "Nhâm", "Quý"]
    
    fixed_count = 0
    for star in db:
        modified = False
        if "logic_an_sao" in star:
            logic = star["logic_an_sao"]
            for k, v in logic.items():
                if isinstance(v, dict):
                    if "chi_ngay" in v:
                        cans_to_move = []
                        chis_to_keep = []
                        for item in v["chi_ngay"]:
                            if item in VALID_CANS:
                                cans_to_move.append(item)
                            else:
                                chis_to_keep.append(item)
                                
                        if cans_to_move:
                            if "can_ngay" not in v:
                                v["can_ngay"] = []
                            for c in cans_to_move:
                                if c not in v["can_ngay"]:
                                    v["can_ngay"].append(c)
                            
                            if chis_to_keep:
                                v["chi_ngay"] = chis_to_keep
                            else:
                                del v["chi_ngay"]
                            modified = True
        
        if modified:
            fixed_count += 1
            print(f"Fixed: {star['ten_sao']}")
            
    with open(file_path, "w", encoding="utf-8") as f:
        json.dump(db, f, ensure_ascii=False, indent=2)
    with open(strict_file_path, "w", encoding="utf-8") as f:
        json.dump(db, f, ensure_ascii=False, indent=2)
        
    print(f"\nTổng số sao đã sửa: {fixed_count}")

if __name__ == "__main__":
    fix_can_ngay_bug()
