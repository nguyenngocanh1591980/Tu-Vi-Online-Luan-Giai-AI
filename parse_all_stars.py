import docx
import json
import re

path = r"E:\Tu vi online\AI học tử vi\Thư Viện cho AI Học\Tầng 1- Dữ Liệu Chuẩn Hóa\Tổng Hợp Thần Sát Trạch Nhật Thường Dùng.docx"
doc = docx.Document(path)

cat_stars = []
hung_stars = []
current_name = None

heading_regex = re.compile(r'^\d+\s*[\.\:]\s*(.+)')

for p in doc.paragraphs:
    text = p.text.strip()
    if not text:
        continue
    
    m = heading_regex.match(text)
    if m:
        raw = m.group(1)
        name = raw.split('-')[0].split('–')[0].strip()
        current_name = name
    elif current_name:
        if 'Cát Tinh' in text:
            if current_name not in cat_stars:
                cat_stars.append(current_name)
            current_name = None
        elif 'Hung Tinh' in text:
            if current_name not in hung_stars:
                hung_stars.append(current_name)
            current_name = None

data = {
    "total_stars": len(cat_stars) + len(hung_stars),
    "cat_count": len(cat_stars),
    "hung_count": len(hung_stars),
    "cat_stars": cat_stars,
    "hung_stars": hung_stars
}

with open(r"E:\Tu vi online\docx_full_stats.json", "w", encoding="utf-8") as f:
    json.dump(data, f, ensure_ascii=False, indent=2)

print("Done parsing DOCX stats.")
