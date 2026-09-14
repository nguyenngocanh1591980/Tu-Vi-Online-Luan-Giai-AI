import docx

doc_path = r"E:\Tu vi online\AI học tử vi\Thư Viện cho AI Học\Tầng 1- Dữ Liệu Chuẩn Hóa\Tổng Hợp Thần Sát Trạch Nhật Thường Dùng(Đã Chỉnh Lý).docx"
doc = docx.Document(doc_path)

in_am_duc = False

for element in doc.element.body:
    if element.tag.endswith('p'):
        p = docx.text.paragraph.Paragraph(element, doc)
        text = p.text.strip()
        if "1.Âm Đức" in text or "1. Âm Đức" in text:
            in_am_duc = True
            print(f"[ĐOẠN VĂN] {text}")
        elif in_am_duc:
            if text and text[0].isdigit() and "." in text[:4]:
                break # Sang sao thứ 2
            print(f"[ĐOẠN VĂN] {text}")
    elif element.tag.endswith('tbl'):
        if in_am_duc:
            print("[BẢNG BIỂU]")
            table = docx.table.Table(element, doc)
            for row in table.rows:
                row_data = [cell.text.strip() for cell in row.cells]
                print(" | ".join(row_data))
