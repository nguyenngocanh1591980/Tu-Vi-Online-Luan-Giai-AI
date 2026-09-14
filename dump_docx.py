import docx

doc_path = r"E:\Tu vi online\AI học tử vi\Thư Viện cho AI Học\Tầng 1- Dữ Liệu Chuẩn Hóa\Tổng Hợp Thần Sát Trạch Nhật Thường Dùng(Đã Chỉnh Lý).docx"
doc = docx.Document(doc_path)

found = False
count = 0
for element in doc.element.body:
    if count > 20:
        break
    if element.tag.endswith('p'):
        p = docx.text.paragraph.Paragraph(element, doc)
        text = p.text.strip()
        if '59.Kim Quĩ' in text or '59. Kim Quĩ' in text or '58.Kim Đường' in text:
            found = True
        if found:
            print(f"P: {text}")
            count += 1
    elif element.tag.endswith('tbl'):
        table = docx.table.Table(element, doc)
        if found:
            print(f"TBL (rows={len(table.rows)}):")
            for r in table.rows:
                print([c.text.strip() for c in r.cells])
            count += 1
