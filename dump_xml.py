import docx

doc_path = r"E:\Tu vi online\AI học tử vi\Thư Viện cho AI Học\Tầng 1- Dữ Liệu Chuẩn Hóa\Tổng Hợp Thần Sát Trạch Nhật Thường Dùng(Đã Chỉnh Lý).docx"
doc = docx.Document(doc_path)

found = False
for element in doc.element.body:
    if element.tag.endswith('p'):
        p = docx.text.paragraph.Paragraph(element, doc)
        text = p.text.strip()
        if '59.Kim Quĩ' in text:
            found = True
        if found:
            print(f"P: {text}")
            if text.startswith("Thi lệ:"):
                # Print the XML of the next few siblings
                sibling = element.getnext()
                count = 0
                while sibling is not None and count < 10:
                    print(f"Sibling tag: {sibling.tag}")
                    if sibling.tag.endswith('tbl'):
                        print("FOUND TBL sibling!")
                    elif sibling.tag.endswith('p'):
                        print(f"P sibling text: {docx.text.paragraph.Paragraph(sibling, doc).text}")
                    else:
                        print(sibling.xml[:200]) # Print snippet of XML
                    sibling = sibling.getnext()
                    count += 1
                break
