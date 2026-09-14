import docx
import json
import re

path = r"E:\Tu vi online\AI học tử vi\Thư Viện cho AI Học\Tầng 1- Dữ Liệu Chuẩn Hóa\Tổng Hợp Thần Sát Trạch Nhật Thường Dùng.docx"
doc = docx.Document(path)

# Extract all paragraphs and also heading styles
all_items = []

# Pattern to catch numbers like "1.", "1. ", "182.", etc.
num_pattern = re.compile(r'^(\d+)\s*[\.\:]\s*(.+)')

items_by_num = {}

for p in doc.paragraphs:
    text = p.text.strip()
    if not text:
        continue
    
    m = num_pattern.match(text)
    if m:
        num = int(m.group(1))
        content = m.group(2).strip()
        items_by_num[num] = {
            "num": num,
            "raw": text,
            "title": content,
            "type": "Unknown",
            "paragraph_text": text
        }

# Let's inspect all 182 headings by scanning the document paragraph by paragraph
entries = []
current_entry = None

for p in doc.paragraphs:
    text = p.text.strip()
    if not text:
        continue
    
    m = num_pattern.match(text)
    if m:
        if current_entry:
            entries.append(current_entry)
        num = int(m.group(1))
        title_part = m.group(2).strip()
        # Clean title
        clean_name = title_part.split('-')[0].split('–')[0].split('/')[0].strip()
        current_entry = {
            "num": num,
            "name": clean_name,
            "full_title": title_part,
            "type": "Chưa rõ",
            "meaning": "",
            "lines": []
        }
    elif current_entry:
        current_entry["lines"].append(text)
        if "Cát Tinh" in text and current_entry["type"] == "Chưa rõ":
            current_entry["type"] = "Cát Tinh"
        elif "Hung Tinh" in text and current_entry["type"] == "Chưa rõ":
            current_entry["type"] = "Hung Tinh"

if current_entry:
    entries.append(current_entry)

# Analyze entries
cat_list = [e for e in entries if e["type"] == "Cát Tinh"]
hung_list = [e for e in entries if e["type"] == "Hung Tinh"]
other_list = [e for e in entries if e["type"] == "Chưa rõ"]

out_data = {
    "total_found_entries": len(entries),
    "cat_count": len(cat_list),
    "hung_count": len(hung_list),
    "other_count": len(other_list),
    "entries": [{
        "num": e["num"],
        "name": e["name"],
        "full_title": e["full_title"],
        "type": e["type"]
    } for e in entries]
}

with open(r"E:\Tu vi online\docx_182_parsed.json", "w", encoding="utf-8") as f:
    json.dump(out_data, f, ensure_ascii=False, indent=2)

print(f"Total entries found: {len(entries)}. Cat: {len(cat_list)}, Hung: {len(hung_list)}, Other: {len(other_list)}")
