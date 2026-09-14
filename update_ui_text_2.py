import json
import sys
import re

if hasattr(sys.stdout, 'reconfigure'):
    sys.stdout.reconfigure(encoding='utf-8')

parsed_file = r"E:\Tu vi online\thansat_226_parsed.json"

with open(parsed_file, 'r', encoding='utf-8') as f:
    stars = json.load(f)

# Update the exact text as requested by the user
updates = {
    "Mẫu Thương": "Tốt cho cầu tài, khai trương",
    "Phúc Tinh": "Tốt mọi việc",
    "Quan Nhật": "Tốt mọi việc",
    "Thiên Nguyện": "Tốt mọi việc",
    "Thiên Quan": "Tốt mọi việc",
    "Thiên Quý": "Tốt mọi việc",
    "Thiên Xá": "Tốt mọi việc",
    "Vương Nhật": "Tốt mọi việc",
    
    "Bát Long": "Xấu mọi việc",
    "Bệnh Phù": "Xấu mọi việc",
    "Cửu Hổ": "Xấu mọi việc",
    "Huyết Chi": "Xấu cho châm cứu, khởi tạo",
    "Lục Xà": "Xấu mọi việc",
    "Phá Bại": "Xấu mọi việc",
    "Phi Liêm": "Xấu mọi việc"
}

for star in stars:
    name = star["ten_sao"]
    for prefix, new_desc in updates.items():
        if prefix in name:
            print(f"Updating {name}: '{star['y_nghia']}' -> '{new_desc}'")
            star["y_nghia"] = new_desc

with open(parsed_file, 'w', encoding='utf-8') as f:
    json.dump(stars, f, ensure_ascii=False, indent=4)

print("Xong!")
