import docx
import json

path = r"E:\Tu vi online\AI học tử vi\Thư Viện cho AI Học\Tầng 1- Dữ Liệu Chuẩn Hóa\Tổng Hợp Thần Sát Trạch Nhật Thường Dùng.docx"
doc = docx.Document(path)

headings = []
for p in doc.paragraphs:
    if p.text.strip():
        # Check if style is Heading or text starts with number
        text = p.text.strip()
        if p.style.name.startswith('Heading') or any(text.startswith(f"{i}.") or text.startswith(f"{i} ") for i in range(1, 200)):
            headings.append(text)

# Also check tables
table_headings = []
for t in doc.tables:
    for row in t.rows:
        for cell in row.cells:
            text = cell.text.strip()
            if any(text.startswith(f"{i}.") for i in range(1, 200)):
                if text not in headings and text not in table_headings:
                    table_headings.append(text)

all_h = headings + table_headings

out = {
    "total_headings": len(all_h),
    "headings": all_h
}

with open(r"E:\Tu vi online\word_headings.json", "w", encoding="utf-8") as f:
    json.dump(out, f, ensure_ascii=False, indent=2)

print(f"Total headings extracted: {len(all_h)}")
