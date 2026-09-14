import docx
import json
import re

path = r"E:\Tu vi online\AI học tử vi\Thư Viện cho AI Học\Tầng 1- Dữ Liệu Chuẩn Hóa\Tổng Hợp Thần Sát Trạch Nhật Thường Dùng.docx"
doc = docx.Document(path)

entries = []
num_pattern = re.compile(r'^(\d+)\s*[\.\:]\s*(.+)')

current = None
for p in doc.paragraphs:
    text = p.text.strip()
    if not text:
        continue
    m = num_pattern.match(text)
    if m:
        if current:
            entries.append(current)
        current = {
            "num": int(m.group(1)),
            "full_title": m.group(2).strip(),
            "name": m.group(2).strip().split('-')[0].split('–')[0].split('/')[0].strip(),
            "content": []
        }
    elif current:
        current["content"].append(text)

if current:
    entries.append(current)

# Determine Cát / Hung for each entry
for e in entries:
    text_blob = " ".join(e["content"]).lower()
    if "cát tinh" in text_blob or "tốt" in text_blob[:100] or "cát" in text_blob[:50]:
        e["type"] = "Cát Tinh"
    elif "hung tinh" in text_blob or "kỵ" in text_blob[:100] or "hung" in text_blob[:50]:
        e["type"] = "Hung Tinh"
    else:
        # Check title or general meaning
        if any(w in e["name"].lower() for w in ["hỉ", "đức", "bảo", "quí", "quý", "lộc", "phúc", "sinh", "hoàng", "thắng"]):
            e["type"] = "Cát Tinh"
        else:
            e["type"] = "Hung Tinh"

cat_entries = [e for e in entries if e["type"] == "Cát Tinh"]
hung_entries = [e for e in entries if e["type"] == "Hung Tinh"]

result = {
    "total_entries": len(entries),
    "cat_count": len(cat_entries),
    "hung_count": len(hung_entries),
    "cat_names": [f"{e['num']}. {e['name']}" for e in cat_entries],
    "hung_names": [f"{e['num']}. {e['name']}" for e in hung_entries],
    "all_entries": [{
        "num": e["num"],
        "name": e["name"],
        "type": e["type"],
        "title": e["full_title"]
    } for e in entries]
}

with open(r"E:\Tu vi online\full_182_classified.json", "w", encoding="utf-8") as f:
    json.dump(result, f, ensure_ascii=False, indent=2)

print(f"Total: {len(entries)}, Cat: {len(cat_entries)}, Hung: {len(hung_entries)}")
