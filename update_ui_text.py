import json
import sys

if hasattr(sys.stdout, 'reconfigure'):
    sys.stdout.reconfigure(encoding='utf-8')

parsed_file = r"E:\Tu vi online\thansat_226_parsed.json"

with open(parsed_file, 'r', encoding='utf-8') as f:
    stars = json.load(f)

# Update the exact text as requested by the user
updates = {
    "12.Bất Tương": "Tốt mọi việc",
    "59.Kim Quĩ Hoàng Đạo": "Tốt mọi việc",
    "65.Lục Hợp": "Tốt mọi việc",
    "70.Minh Tinh": "Tốt mọi việc",
    
    # We must match exactly the text in the images for other stars
    "131.Mẫu Thương": "Tốt cho cầu tài, khai trương",
    "153.Phúc Tinh": "Tốt mọi việc",
    "162.Quan Nhật": "Tốt mọi việc",
    "189.Thiên Nguyện": "Tốt mọi việc",
    "192.Thiên Quan": "Tốt mọi việc",
    "193.Thiên Quý": "Tốt mọi việc",
    "196.Thiên Xá": "Tốt mọi việc",
    "208.Vương Nhật": "Tốt mọi việc",
    
    "9.Bát Long": "Xấu mọi việc",
    "15.Bệnh Phù": "Xấu mọi việc",
    "35.Cửu Hổ": "Xấu mọi việc",
    "57.Huyết Chi": "Xấu cho châm cứu, khởi tạo",
    "117.Lục Xà": "Xấu mọi việc",
    "145.Phá Bại": "Xấu mọi việc",
    "148.Phi Liêm": "Xấu mọi việc"
}

for star in stars:
    name = star["ten_sao"]
    for prefix, new_desc in updates.items():
        if name.startswith(prefix):
            print(f"Updating {name}: '{star['y_nghia']}' -> '{new_desc}'")
            star["y_nghia"] = new_desc

with open(parsed_file, 'w', encoding='utf-8') as f:
    json.dump(stars, f, ensure_ascii=False, indent=4)

print("Xong!")
