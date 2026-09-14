import docx

doc_path = r"E:\Tu vi online\AI học tử vi\Thư Viện cho AI Học\Tầng 1- Dữ Liệu Chuẩn Hóa\Tổng Hợp Thần Sát Trạch Nhật Thường Dùng(Đã Chỉnh Lý).docx"
doc = docx.Document(doc_path)

for element in doc.element.body:
    if element.tag.endswith('p'):
        p = docx.text.paragraph.Paragraph(element, doc)
        if 'Thi lệ: “Chánh thất khóa long' in p.text:
            sibling = element.getnext()
            for _ in range(4):
                if sibling is not None:
                    print(sibling.xml)
                    sibling = sibling.getnext()
            break
