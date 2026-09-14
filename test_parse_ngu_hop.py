import docx
import json
from parse_docx_v2 import parse_table_pairs, sanitize_can_chi

DOC_PATH = r"E:\Tu vi online\AI học tử vi\Thư Viện cho AI Học\Tầng 1- Dữ Liệu Chuẩn Hóa\Tổng Hợp Thần Sát Trạch Nhật Thường Dùng(Đã Chỉnh Lý).docx"
doc = docx.Document(DOC_PATH)

in_ngu_hop = False
current_star = {"ten_sao": "75. Ngũ Hợp - 五合 - Five Combo", "logic_an_sao": {}}

for element in doc.element.body:
    if element.tag.endswith('p'):
        p = docx.text.paragraph.Paragraph(element, doc)
        if "75.Ngũ Hợp" in p.text:
            in_ngu_hop = True
        elif in_ngu_hop and p.text and p.text[0].isdigit() and "." in p.text[:4]:
            break
            
    elif element.tag.endswith('tbl'):
        if in_ngu_hop:
            table = docx.table.Table(element, doc)
            tbl_data = [[cell.text.strip().lower() for cell in row.cells] for row in table.rows]
            if not tbl_data: continue
            header = " ".join(tbl_data[0])
            
            if "can ngày" in header and ("giờ" in header or "can giờ" in header):
                pairs, success = parse_table_pairs(table, "can ngày", "giờ")
                if "theo_can_ngay_can_gio" not in current_star["logic_an_sao"]:
                    current_star["logic_an_sao"]["theo_can_ngay_can_gio"] = {}
                for k, v in pairs:
                    k_san = k.strip().capitalize()
                    if k_san not in current_star["logic_an_sao"]["theo_can_ngay_can_gio"]:
                        current_star["logic_an_sao"]["theo_can_ngay_can_gio"][k_san] = []
                    vals = sanitize_can_chi(v)
                    for val in vals:
                        if val not in current_star["logic_an_sao"]["theo_can_ngay_can_gio"][k_san]:
                            current_star["logic_an_sao"]["theo_can_ngay_can_gio"][k_san].append(val)

print(json.dumps(current_star, ensure_ascii=False, indent=2))
