import docx

DOC_PATH = r"E:\Tu vi online\AI học tử vi\Thư Viện cho AI Học\Tầng 1- Dữ Liệu Chuẩn Hóa\Tổng Hợp Thần Sát Trạch Nhật Thường Dùng(Đã Chỉnh Lý).docx"

def inspect_phuc_tinh():
    doc = docx.Document(DOC_PATH)
    found = False
    for element in doc.element.body:
        if element.tag.endswith('p'):
            p = docx.text.paragraph.Paragraph(element, doc)
            if "106.Phúc Tinh" in p.text or "106. Phúc Tinh" in p.text:
                found = True
                print("Found Phúc Tinh!")
        elif element.tag.endswith('tbl') and found:
            table = docx.table.Table(element, doc)
            print("Found Table!")
            tbl_data = [[cell.text.strip().replace('\n', '\\n') for cell in row.cells] for row in table.rows]
            for row in tbl_data:
                print(" | ".join(row))
            print("---")
            if len(tbl_data) > 3 and "tháng" in tbl_data[0][0].lower():
                break

if __name__ == "__main__":
    inspect_phuc_tinh()
