import docx
from lxml import etree

doc_path = r"E:\Tu vi online\AI học tử vi\Thư Viện cho AI Học\Tầng 1- Dữ Liệu Chuẩn Hóa\Tổng Hợp Thần Sát Trạch Nhật Thường Dùng(Đã Chỉnh Lý).docx"
doc = docx.Document(doc_path)

in_am_duc = False

for element in doc.element.body:
    if element.tag.endswith('p'):
        p = docx.text.paragraph.Paragraph(element, doc)
        text = p.text.strip()
        if "1.Âm Đức" in text or "1. Âm Đức" in text:
            in_am_duc = True
        elif in_am_duc and text and text[0].isdigit() and "." in text[:4]:
            break
            
    elif element.tag.endswith('tbl'):
        if in_am_duc:
            table = docx.table.Table(element, doc)
            cell = table.rows[0].cells[0]
            # Dump raw XML of the first cell
            xml_str = etree.tostring(cell._tc, encoding='unicode', pretty_print=True)
            print("XML CỦA CELL ĐẦU TIÊN:")
            print(xml_str[:1500]) # Print up to 1500 chars to avoid flooding
            break
