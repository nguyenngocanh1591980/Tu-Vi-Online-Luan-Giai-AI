import json
import sys

if hasattr(sys.stdout, 'reconfigure'):
    sys.stdout.reconfigure(encoding='utf-8')

with open('E:\\Tu vi online\\thansat_226_parsed.json', 'r', encoding='utf-8') as f:
    db = json.load(f)

for star in db:
    if "Bất Tương" in star["ten_sao"] or "Kim Quỹ Hoàng Đạo" in star["ten_sao"] or "74.Ngọc Vũ" in star["ten_sao"] or "85.Nguyệt Hoả" in star["ten_sao"] or "86.Nguyệt Hư" in star["ten_sao"] or "169.Tử Phù" in star["ten_sao"]:
        print(f"STAR: {star['ten_sao']}")
        print(f"Ý nghĩa hiện tại: {star['y_nghia']}")
        print("---")
