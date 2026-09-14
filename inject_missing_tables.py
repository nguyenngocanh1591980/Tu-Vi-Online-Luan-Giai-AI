import json
import os
import sys

if hasattr(sys.stdout, 'reconfigure'):
    sys.stdout.reconfigure(encoding='utf-8')

parsed_file = r"E:\Tu vi online\thansat_226_parsed.json"

with open(parsed_file, 'r', encoding='utf-8') as f:
    stars = json.load(f)

# Hardcoded data for the 4 missing tables
missing_tables = {
    "74.Ngọc Vũ": [
        ["Tháng", "Ngày", "Tháng", "Ngày"],
        ["1", "Mão", "7", "Ngọ"],
        ["2", "Dậu", "8", "Tý"],
        ["3", "Thìn", "9", "Mùi"],
        ["4", "Tuất", "10", "Sửu"],
        ["5", "Tỵ", "11", "Thân"],
        ["6", "Hợi", "12", "Dần"]
    ],
    "85.Nguyệt Hoả(Độc Hỏa)": [
        ["Tháng", "Ngày", "Tháng", "Ngày"],
        ["1", "Tỵ", "7", "Hợi"],
        ["2", "Thìn", "8", "Tuất"],
        ["3", "Mão", "9", "Dậu"],
        ["4", "Dần", "10", "Thân"],
        ["5", "Sửu", "11", "Mùi"],
        ["6", "Tý", "12", "Ngọ"]
    ],
    "86.Nguyệt Hư (Nguyệt Sát)": [
        ["Tháng", "Ngày", "Tháng", "Ngày"],
        ["Dần", "Sửu", "Thân", "Mùi"],
        ["Mão", "Tuất", "Dậu", "Thìn"],
        ["Thìn", "Mùi", "Tuất", "Sửu"],
        ["Tỵ", "Thìn", "Hợi", "Tuất"],
        ["Ngọ", "Sửu", "Tý", "Mùi"],
        ["Mùi", "Tuất", "Sửu", "Thìn"]
    ],
    "169.Tử Phù": [
        ["Tháng", "Ngày", "Tháng", "Ngày"],
        ["1", "Mùi", "7", "Sửu"],
        ["2", "Thân", "8", "Dần"],
        ["3", "Dậu", "9", "Mão"],
        ["4", "Tuất", "10", "Thìn"],
        ["5", "Hợi", "11", "Tỵ"],
        ["6", "Tý", "12", "Ngọ"]
    ]
}

for star in stars:
    # Find matching star
    for key, table in missing_tables.items():
        if star['ten_sao'].startswith(key):
            # Clean up the flags
            if "[CẦN_HƯỚNG_DẪN]" in star['flags']:
                star['flags'].remove("[CẦN_HƯỚNG_DẪN]")
            star['logic_an_sao'] = table
            print(f"Updated table for: {star['ten_sao']}")

with open(parsed_file, 'w', encoding='utf-8') as f:
    json.dump(stars, f, ensure_ascii=False, indent=4)

print("Xong!")
