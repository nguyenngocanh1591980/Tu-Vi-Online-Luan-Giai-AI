import os
import json
import re

_CACHED_MEANINGS = None

def get_meanings():
    global _CACHED_MEANINGS
    if _CACHED_MEANINGS is not None:
        return _CACHED_MEANINGS
        
    meanings = {}
    
    # Load from the new parsed JSON
    BASE_DIR = os.path.dirname(os.path.abspath(os.path.dirname(__file__)))
    json_path = os.path.join(BASE_DIR, "thansat_226_parsed.json")
    
    if os.path.exists(json_path):
        try:
            with open(json_path, 'r', encoding='utf-8') as f:
                db = json.load(f)
                for star in db:
                    name = star.get("ten_sao", "")
                    meaning = star.get("y_nghia", "")
                    if isinstance(meaning, list):
                        meaning = " ".join([str(x) for x in meaning])
                    
                    # Normalize name just like ho_ngoc_duc_almanac.py does
                    # 1.Âm Đức - 陰德 - Yin Virtue -> Âm Đức
                    if ' - ' in name:
                        name = name.split(' - ')[0].strip()
                    name = re.sub(r'\(.*?\)', '', name).strip()
                    name = re.sub(r'^\d+\.', '', name).strip()
                    name = name.replace("Hỷ", "Hỉ").strip()
                    
                    meanings[name] = meaning
        except Exception as e:
            print(f"Error loading meanings from JSON: {e}")
            
    _CACHED_MEANINGS = meanings
    return _CACHED_MEANINGS

def get_stars_from_local_data(day, month, year, month_chi, year_can, year_chi, day_can, day_chi, jd, lunar_day):
    """
    Fallback function
    """
    sao_tot = []
    sao_xau = []
    
    # General calculation logic without early break or overwrite
    try:
        from than_sat_rules import get_ngoc_hap_than_sat
        res = get_ngoc_hap_than_sat(
            month_chi.strip().lower(),
            year_can.strip().lower(),
            year_chi.strip().lower(),
            day_can.strip().lower(),
            day_chi.strip().lower(),
            jd,
            lunar_day
        )
        sao_tot.extend(res.get("sao_tot", []))
        sao_xau.extend(res.get("sao_xau", []))
    except Exception as e:
        print(f"Error in general calculation: {e}")

    # Khử trùng lặp cuối cùng
    return list(dict.fromkeys(sao_tot)), list(dict.fromkeys(sao_xau))
