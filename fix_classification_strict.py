import docx
import json
import re

path = r"E:\Tu vi online\AI học tử vi\Thư Viện cho AI Học\Tầng 1- Dữ Liệu Chuẩn Hóa\Tổng Hợp Thần Sát Trạch Nhật Thường Dùng.docx"
doc = docx.Document(path)

num_pattern = re.compile(r'^(\d+)\s*[\.\:]\s*(.+)')

stars = []
current = None

for p in doc.paragraphs:
    text = p.text.strip()
    if not text:
        continue
    
    m = num_pattern.match(text)
    if m:
        if current:
            stars.append(current)
        num = int(m.group(1))
        title = m.group(2).strip()
        # Clean name
        name = title.split('-')[0].split('–')[0].split('(')[0].split('/')[0].strip()
        current = {
            "num": num,
            "name": name,
            "title": text,
            "type": "Chưa rõ",
            "body": []
        }
    elif current:
        current["body"].append(text)

if current:
    stars.append(current)

# Deduplicate by number
clean = {}
for s in stars:
    clean[s["num"]] = s

# Strictly look for "Cát Tinh" or "Hung Tinh" line
for num, s in clean.items():
    body_text = "\n".join(s["body"])
    # Check first 3 lines of body
    head_body = "\n".join(s["body"][:3])
    if "Cát Tinh" in head_body or "Cát tinh" in head_body:
        s["type"] = "Cát Tinh"
    elif "Hung Tinh" in head_body or "Hung tinh" in head_body:
        s["type"] = "Hung Tinh"
    elif "Cát Tinh" in body_text:
        s["type"] = "Cát Tinh"
    elif "Hung Tinh" in body_text:
        s["type"] = "Hung Tinh"
    else:
        # Fallback list for known stars
        hung_names = ["Địa Hỏa", "Địa Tặc", "Thiên Cẩu", "Tiểu Hồng Sa", "Trùng Nhật", "Trùng Tang", "Bát Ma", "Cát Kì", "Khô Tiêu"]
        if any(hn in s["name"] for hn in hung_names):
            s["type"] = "Hung Tinh"
        else:
            s["type"] = "Cát Tinh"

cat_stars = [s for num, s in sorted(clean.items()) if s["type"] == "Cát Tinh"]
hung_stars = [s for num, s in sorted(clean.items()) if s["type"] == "Hung Tinh"]

final_out = {
    "total_stars": len(clean),
    "max_index": max(clean.keys()),
    "cat_count": len(cat_stars),
    "hung_count": len(hung_stars),
    "cat_stars": [f"{s['num']}. {s['name']}" for s in cat_stars],
    "hung_stars": [f"{s['num']}. {s['name']}" for s in hung_stars]
}

with open(r"E:\Tu vi online\final_182_classified.json", "w", encoding="utf-8") as f:
    json.dump(final_out, f, ensure_ascii=False, indent=2)

print(f"Total: {len(clean)}, Cat: {len(cat_stars)}, Hung: {len(hung_stars)}")
