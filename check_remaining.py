import json

file_path = r"E:\Tu vi online\than_sat_db_strict.json"
with open(file_path, "r", encoding="utf-8") as f:
    db = json.load(f)

flagged = []
for star in db:
    logic = star.get("logic_an_sao", {})
    if not logic:
        flagged.append(star.get("ten_sao", ""))

print(f"Còn lại {len(flagged)} sao chưa có logic:")
for i, name in enumerate(flagged, 1):
    print(f"{i}. {name}")
