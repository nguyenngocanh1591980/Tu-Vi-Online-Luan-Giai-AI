import docx
import json
import re

path = r"E:\Tu vi online\AI học tử vi\Thư Viện cho AI Học\Tầng 1- Dữ Liệu Chuẩn Hóa\Tổng Hợp Thần Sát Trạch Nhật Thường Dùng.docx"
doc = docx.Document(path)

# Pattern for headings like "1.Âm Đức...", "2. Âm Quý...", etc.
num_pattern = re.compile(r'^(\d+)\s*[\.\:]\s*(.+)')

parsed_stars = []
current_star = None

for p in doc.paragraphs:
    text = p.text.strip()
    if not text:
        continue
    
    m = num_pattern.match(text)
    if m:
        num = int(m.group(1))
        title = m.group(2).strip()
        name = title.split('-')[0].split('–')[0].split('(')[0].split('/')[0].strip()
        
        current_star = {
            "num": num,
            "name": name,
            "title": text,
            "type": "Chưa rõ",
            "lines": []
        }
        parsed_stars.append(current_star)
    elif current_star:
        current_star["lines"].append(text)

# Deduplicate by number & title to ensure clean list
clean_stars = {}
for s in parsed_stars:
    num = s["num"]
    # If key exists, only overwrite if current has title or content
    if num not in clean_stars or len(s["lines"]) > 0:
        clean_stars[num] = s

# Post-process types (Cát Tinh vs Hung Tinh)
for num, s in clean_stars.items():
    content = " ".join(s["lines"])
    if "Cát Tinh" in content or "tốt" in content[:120].lower():
        s["type"] = "Cát Tinh"
    elif "Hung Tinh" in content or "kỵ" in content[:120].lower() or "xấu" in content[:120].lower():
        s["type"] = "Hung Tinh"
    else:
        # Default fallback classification based on star name meaning
        name_lower = s["name"].lower()
        if any(w in name_lower for w in ["đức", "hỷ", "hỉ", "bảo", "quý", "quí", "phú", "sinh", "lộc", "giải", "an", "phúc", "minh", "hoàng", "thắng"]):
            s["type"] = "Cát Tinh"
        else:
            e_type = "Hung Tinh"
            s["type"] = "Hung Tinh"

cat_list = [s for num, s in sorted(clean_stars.items()) if s["type"] == "Cát Tinh"]
hung_list = [s for num, s in sorted(clean_stars.items()) if s["type"] == "Hung Tinh"]

result = {
    "total_unique_numbered": len(clean_stars),
    "max_number": max(clean_stars.keys()),
    "cat_count": len(cat_list),
    "hung_count": len(hung_list),
    "cat_stars": [f"{s['num']}. {s['name']}" for s in cat_list],
    "hung_stars": [f"{s['num']}. {s['name']}" for s in hung_list],
    "all_stars": [{
        "num": s["num"],
        "name": s["name"],
        "type": s["type"],
        "title": s["title"]
    } for num, s in sorted(clean_stars.items())]
}

with open(r"E:\Tu vi online\exact_182_classified.json", "w", encoding="utf-8") as f:
    json.dump(result, f, ensure_ascii=False, indent=2)

print(f"Max number: {max(clean_stars.keys())}, Unique count: {len(clean_stars)}, Cat: {len(cat_list)}, Hung: {len(hung_list)}")
