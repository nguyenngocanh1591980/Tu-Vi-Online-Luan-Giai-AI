import os
import sys
import json
import re
import docx
from docx.document import Document
from docx.oxml.table import CT_Tbl
from docx.oxml.text.paragraph import CT_P
from docx.table import _Cell, Table
from docx.text.paragraph import Paragraph

sys.stdout.reconfigure(encoding='utf-8')

CAN = ["Giáp", "Ất", "Bính", "Đinh", "Mậu", "Kỷ", "Canh", "Tân", "Nhâm", "Quý"]
CHI = ["Tý", "Sửu", "Dần", "Mão", "Thìn", "Tỵ", "Ngọ", "Mùi", "Thân", "Dậu", "Tuất", "Hợi"]

def iter_block_items(parent):
    if isinstance(parent, Document):
        parent_elm = parent.element.body
    elif isinstance(parent, _Cell):
        parent_elm = parent._tc
    else:
        raise ValueError("Chỉ hỗ trợ Document hoặc _Cell")

    for child in parent_elm.iterchildren():
        if isinstance(child, CT_P):
            yield Paragraph(child, parent)
        elif isinstance(child, CT_Tbl):
            table = Table(child, parent)
            yield table
            for row in table.rows:
                for cell in row.cells:
                    yield from iter_block_items(cell)

def normalize_month(month_str):
    mapping = {
        "1": "Dần", "2": "Mão", "3": "Thìn", "4": "Tỵ",
        "5": "Ngọ", "6": "Mùi", "7": "Thân", "8": "Dậu",
        "9": "Tuất", "10": "Hợi", "11": "Tý", "12": "Sửu",
        "tháng 1": "Dần", "tháng 2": "Mão", "tháng 3": "Thìn", 
        "tháng 4": "Tỵ", "tháng 5": "Ngọ", "tháng 6": "Mùi", 
        "tháng 7": "Thân", "tháng 8": "Dậu", "tháng 9": "Tuất", 
        "tháng 10": "Hợi", "tháng 11": "Tý", "tháng 12": "Sửu"
    }
    m = month_str.strip().lower()
    if m in mapping:
        return mapping[m]
    for c in CHI:
        if c.lower() in m:
            return c
    return month_str.strip()

def parse_day_condition(val_str):
    val_str = val_str.strip()
    # Kiểm tra xem có phải dạng "Ngày 3", "Ngày 7", "Ngày 18", "Ngày27"
    lunar_days = re.findall(r'ngày\s*(\d+)', val_str, re.IGNORECASE)
    if lunar_days:
        return {"ngay_am_lich": [int(d) for d in lunar_days]}

    parts = [p.strip() for p in re.split(r'[,;\n\t]+', val_str) if p.strip()]
    cond_dict = {}
    for p in parts:
        p_lower = p.lower()
        if p.isdigit():
            cond_dict.setdefault("ngay_am_lich", []).append(int(p))
            continue

        
        is_can = any(c.lower() == p_lower for c in CAN)
        is_chi = any(c.lower() == p_lower for c in CHI)
        
        if is_can and not is_chi:
            cond_dict.setdefault("can_ngay", []).append(p.capitalize())
        elif is_chi and not is_can:
            cond_dict.setdefault("chi_ngay", []).append(p.capitalize())
        else:
            parts_space = p.split()
            if len(parts_space) == 2:
                if any(c.lower() == parts_space[0].lower() for c in CAN) and any(c.lower() == parts_space[1].lower() for c in CHI):
                    cond_dict.setdefault("can_chi_ngay", []).append(p.title())
                    continue
            
            # If all parts are CHI, add them all to chi_ngay (e.g. "Thìn Tuất")
            all_chi = all(any(c.lower() == part.lower() for c in CHI) for part in parts_space)
            if len(parts_space) > 1 and all_chi:
                for part in parts_space:
                    cond_dict.setdefault("chi_ngay", []).append(part.capitalize())
                continue
                
            # If all parts are CAN, add them all to can_ngay
            all_can = all(any(c.lower() == part.lower() for c in CAN) for part in parts_space)
            if len(parts_space) > 1 and all_can:
                for part in parts_space:
                    cond_dict.setdefault("can_ngay", []).append(part.capitalize())
                continue
                
            cond_dict.setdefault("khac", []).append(p)
    return cond_dict

def dict_merge(d1, d2):
    for k, v in d2.items():
        if isinstance(v, list):
            if k not in d1:
                d1[k] = []
            for item in v:
                if item not in d1[k]:
                    d1[k].append(item)
        elif isinstance(v, dict):
            if k not in d1:
                d1[k] = {}
            dict_merge(d1[k], v)
        else:
            d1[k] = v
    return d1

def parse_than_sat_db(docx_path, output_json_path):
    doc = docx.Document(docx_path)
    stars = []
    current_star = None
    parsing_mode = None
    is_hour_mode = False

    for block in iter_block_items(doc):
        if isinstance(block, Paragraph):
            text = block.text.strip()
            if not text:
                continue

            if re.match(r'^\d+\.\s*.*?-', text) or re.match(r'^\d+\.\s*[A-ZÀ-Ỹ]', text):
                if current_star:
                    stars.append(current_star)
                current_star = {
                    "ten_sao": text,
                    "phan_loai": "Chưa xác định",
                    "y_nghia": [],
                    "logic_an_sao": {},
                    "ghi_chu": []
                }
                parsing_mode = "PHAN_1"
                is_hour_mode = False
                hour_key_type = "can_ngay"
                continue
            
            if not current_star:
                continue

            if re.search(r'Cách\s+an\s+sao', text, re.IGNORECASE):
                parsing_mode = "PHAN_2"
                continue

            if current_star.get("phan_loai") != "Hung Tinh":
                if "chi ngày gặp với chi giờ" in text.lower():
                    is_hour_mode = True
                    hour_key_type = "chi_ngay"
                elif "nhật can sinh thời can" in text.lower() or "can ngày và chi giờ" in text.lower() or "nhật can và thời can" in text.lower():
                    is_hour_mode = True

            if parsing_mode == "PHAN_1":
                text_lower = text.strip().lower()
                cleaned_text = re.sub(r'^[-•·o+]\s*', '', text).strip()
                cleaned_lower = cleaned_text.lower()
                
                if cleaned_lower in ["cát tinh", "cát", "cát.", "cát:", "cát tinh.", "cát tinh:"]:
                    current_star["phan_loai"] = "Cát Tinh"
                elif cleaned_lower in ["hung tinh", "hung", "hung.", "hung:", "hung tinh.", "hung tinh:"]:
                    current_star["phan_loai"] = "Hung Tinh"
                else:
                    if "cát tinh" in text_lower or "cát" in text_lower:
                        if current_star["phan_loai"] == "Chưa xác định":
                            current_star["phan_loai"] = "Cát Tinh"
                    elif "hung tinh" in text_lower or "hung" in text_lower:
                        if current_star["phan_loai"] == "Chưa xác định":
                            current_star["phan_loai"] = "Hung Tinh"
                            
                    if cleaned_text:
                        current_star["y_nghia"].append(cleaned_text)
            
            elif parsing_mode in ["PHAN_2", "PHAN_3"]:
                cleaned_text = re.sub(r'^[-•·o+]\s*', '', text).strip()
                if cleaned_text:
                    current_star["ghi_chu"].append(cleaned_text)
                
        elif isinstance(block, Table):
            if current_star and parsing_mode in ["PHAN_2", "PHAN_3"]:
                logic = current_star.get("logic_an_sao", {})
                
                if len(block.rows) > 0:
                    raw_headers = [c.text.strip().lower() for c in block.rows[0].cells]
                    
                    # 1. CAN NĂM Mode (VD: 196. Kim Thần Thất Sát)
                    if any("can năm" in h for h in raw_headers):
                        col_type = ["can_nam" if "can năm" in h else "ngay" for h in raw_headers]
                        for row in block.rows[1:]:
                            cells = [c.text.strip() for c in row.cells]
                            current_can_nam = None
                            for i, cell_val in enumerate(cells):
                                if not cell_val: continue
                                ctype = col_type[i] if i < len(col_type) else "ngay"
                                if ctype == "can_nam":
                                    if any(c.lower() == cell_val.lower() for c in CAN):
                                        current_can_nam = cell_val.lower()
                                elif ctype == "ngay" and current_can_nam:
                                    t_can_nam = logic.setdefault("theo_can_nam", {})
                                    c_dict = t_can_nam.setdefault(current_can_nam, {})
                                    if any(c.lower() == cell_val.lower() for c in CHI):
                                        if cell_val.capitalize() not in c_dict.setdefault("chi_ngay", []):
                                            c_dict["chi_ngay"].append(cell_val.capitalize())
                                    elif any(c.lower() == cell_val.lower() for c in CAN):
                                        if cell_val.capitalize() not in c_dict.setdefault("can_ngay", []):
                                            c_dict["can_ngay"].append(cell_val.capitalize())

                    # 2. CHI NĂM Mode (VD: 176. Tuế Phá)
                    elif any(h == "năm" for h in raw_headers) and not any("tháng" in h or "mùa" in h or "can" in h for h in raw_headers):
                        col_type = ["nam" if h == "năm" else "ngay" for h in raw_headers]
                        for row in block.rows[1:]:
                            cells = [c.text.strip() for c in row.cells]
                            current_nam = None
                            for i, cell_val in enumerate(cells):
                                if not cell_val: continue
                                ctype = col_type[i] if i < len(col_type) else "ngay"
                                if ctype == "nam":
                                    if any(c.lower() == cell_val.lower() for c in CHI):
                                        current_nam = cell_val.lower()
                                elif ctype == "ngay" and current_nam:
                                    nam_key = f"nam_{current_nam}"
                                    t_nam = logic.setdefault("theo_nam", {})
                                    c_dict = t_nam.setdefault(nam_key, {})
                                    if any(c.lower() == cell_val.lower() for c in CHI):
                                        if cell_val.capitalize() not in c_dict.setdefault("chi_ngay", []):
                                            c_dict["chi_ngay"].append(cell_val.capitalize())
                                    elif any(c.lower() == cell_val.lower() for c in CAN):
                                        if cell_val.capitalize() not in c_dict.setdefault("can_ngay", []):
                                            c_dict["can_ngay"].append(cell_val.capitalize())

                    # 3. CAN THÁNG Mode (VD: 79. Ngũ Quỷ)
                    elif any("can tháng" in h for h in raw_headers):
                        col_type = ["can_thang" if "can tháng" in h else "ngay" for h in raw_headers]
                        for row in block.rows[1:]:
                            cells = [c.text.strip() for c in row.cells]
                            current_can_thang = None
                            for i, cell_val in enumerate(cells):
                                if not cell_val: continue
                                ctype = col_type[i] if i < len(col_type) else "ngay"
                                if ctype == "can_thang":
                                    if any(c.lower() == cell_val.lower() for c in CAN):
                                        current_can_thang = cell_val.lower()
                                elif ctype == "ngay" and current_can_thang:
                                    t_can_thang = logic.setdefault("theo_can_thang", {})
                                    c_dict = t_can_thang.setdefault(current_can_thang, {})
                                    if any(c.lower() == cell_val.lower() for c in CHI):
                                        if cell_val.capitalize() not in c_dict.setdefault("chi_ngay", []):
                                            c_dict["chi_ngay"].append(cell_val.capitalize())
                                    elif any(c.lower() == cell_val.lower() for c in CAN):
                                        if cell_val.capitalize() not in c_dict.setdefault("can_ngay", []):
                                            c_dict["can_ngay"].append(cell_val.capitalize())

                    # 4. CÁC NGÀY TRONG NĂM Mode (VD: 191. Ly Sào, 145. Tàn Bại)
                    elif any("trong năm" in h for h in raw_headers) or (len(raw_headers) > 1 and all(h == "ngày" for h in raw_headers)):
                        for row in block.rows:
                            cells = [c.text.strip() for c in row.cells]
                            for cell_val in cells:
                                if not cell_val or "ngày" in cell_val.lower(): continue
                                parts = cell_val.split()
                                if len(parts) == 2 and any(c.lower() == parts[0].lower() for c in CAN) and any(c.lower() == parts[1].lower() for c in CHI):
                                    can_chi_ngay = cell_val.title()
                                    if can_chi_ngay not in logic.setdefault("can_chi_ngay", []):
                                        logic["can_chi_ngay"].append(can_chi_ngay)

                    # 5. GIỜ Mode (Chi Ngày -> Giờ hoặc Can Ngày -> Giờ hoặc Bảng có cột Giờ)
                    elif any("chi ngày gặp với chi giờ" in h for h in raw_headers) or any("giờ" in h or "giở" in h for h in raw_headers):
                        # Xác định kiểu dựa trên nội dung dòng dữ liệu đầu tiên
                        start_row_idx = 1
                        if any("chi ngày gặp với chi giờ" in h for h in raw_headers) and len(block.rows) > 1:
                            if any("ngày" in c.text.lower() or "giờ" in c.text.lower() for c in block.rows[1].cells):
                                start_row_idx = 2
                                
                        row1_cells = [c.text.strip() for c in block.rows[start_row_idx].cells] if len(block.rows) > start_row_idx else []
                        first_val = row1_cells[0] if row1_cells else ""
                        
                        # 5.1. Nếu cột đầu là số 1..12 (VD: 214. Nhập Tòa Địa Phá) -> Tháng -> Giờ/Ngày
                        if first_val.isdigit():
                            col_type = ["thang" if i%2==0 else "gio" for i in range(len(raw_headers))]
                            for row_idx in range(start_row_idx, len(block.rows)):
                                cells = [c.text.strip() for c in block.rows[row_idx].cells]
                                current_thang = None
                                for i, cell_val in enumerate(cells):
                                    if not cell_val: continue
                                    ctype = col_type[i] if i < len(col_type) else ("thang" if i%2==0 else "gio")
                                    if ctype == "thang":
                                        current_thang = normalize_month(cell_val)
                                    elif ctype == "gio" and current_thang:
                                        thang_key = f"thang_{current_thang.lower()}"
                                        day_conds = parse_day_condition(cell_val)
                                        dict_merge(logic.setdefault(thang_key, {}), day_conds)

                        # 5.2. Nếu cột đầu là CAN (VD: 2. Âm Quý, 44. Dương Quý, 48. Hỉ Thần, 75. Ngũ Hợp, 106. Phúc Tinh, 133. Thiên Quan)
                        elif any(c.lower() == first_val.lower() for c in CAN):
                            for row_idx in range(start_row_idx, len(block.rows)):
                                cells = [c.text.strip() for c in block.rows[row_idx].cells]
                                current_can = None
                                for i, cell_val in enumerate(cells):
                                    if not cell_val: continue
                                    val_lower = cell_val.lower()
                                    if any(c.lower() == val_lower for c in CAN):
                                        current_can = cell_val.capitalize()
                                    elif current_can:
                                        key_can = f"can_ngay_{current_can.lower()}"
                                        if any(c.lower() == val_lower for c in CHI):
                                            logic.setdefault("theo_gio", {}).setdefault(key_can, {}).setdefault("chi_gio", []).append(cell_val.capitalize())
                                        else:
                                            parts = cell_val.split()
                                            if len(parts) == 2 and any(c.lower() == parts[0].lower() for c in CAN) and any(c.lower() == parts[1].lower() for c in CHI):
                                                logic.setdefault("theo_gio", {}).setdefault(key_can, {}).setdefault("can_chi_gio", []).append(cell_val.title())

                        # 5.3. Mặc định: Chi Ngày -> Chi Giờ (VD: 62. Lỗ Ban Sát, 18. Câu Trần, 19. Chích Thoái, 70. Minh Tinh, 73. Ngọc Thủ, 123. Thiên Hình, 127. Thiên Lao...)
                        else:
                            for row_idx in range(start_row_idx, len(block.rows)):
                                cells = [c.text.strip() for c in block.rows[row_idx].cells]
                                for i in range(0, len(cells)-1, 2):
                                    c_ngay = cells[i]
                                    c_gio = cells[i+1]
                                    if c_ngay and c_gio and any(c.lower() == c_ngay.lower() for c in CHI):
                                        key_chi = f"chi_ngay_{c_ngay.lower()}"
                                        # Có thể có nhiều chi giờ cách nhau khoảng trắng (VD: "Sửu Mùi")
                                        for g in c_gio.split():
                                            if any(c.lower() == g.lower() for c in CHI):
                                                if g.capitalize() not in logic.setdefault("theo_gio", {}).setdefault(key_chi, {}).setdefault("chi_gio", []):
                                                    logic["theo_gio"][key_chi]["chi_gio"].append(g.capitalize())

                    # 6. Standard Month - Day Mode
                    else:
                        is_lunar_day_table = any("ngày trong tháng" in h or "ngày âm lịch" in h or "các ngày trong" in h for h in raw_headers) and not any("tháng" in h and "ngày" not in h for h in raw_headers)
                        has_header = any("tháng" in h for h in raw_headers) or any("ngày" in h for h in raw_headers)
                        
                        col_type = []
                        if is_lunar_day_table:
                            col_type = ["ngay" for _ in raw_headers]
                        elif has_header:
                            for h in raw_headers:
                                if "tháng" in h: col_type.append("thang")
                                elif "giờ" in h: col_type.append("gio")
                                elif "ngày" in h: col_type.append("ngay")
                                else: col_type.append("unknown")
                        else:
                            col_type = ["thang" if i%2==0 else "ngay" for i in range(len(raw_headers))]
                        
                        # Xử lý bảng chỉ có 1 dòng (ví dụ: [['Ngày', 'Thân', 'Dậu']])
                        if len(block.rows) == 1 and raw_headers[0] in ["ngày", "chi ngày", "can ngày"]:
                            cells = [c.text.strip() for c in block.rows[0].cells]
                            for cell_val in cells[1:]:
                                if cell_val:
                                    day_conds = parse_day_condition(cell_val)
                                    dict_merge(logic, day_conds)
                        else:
                            start_idx = 1 if has_header else 0
                            for row_idx in range(start_idx, len(block.rows)):
                                cells = [c.text.strip() for c in block.rows[row_idx].cells]
                                current_thang = None
                                for i, cell_val in enumerate(cells):
                                    if not cell_val: continue
                                    ctype = col_type[i] if i < len(col_type) else ("thang" if i%2==0 else "ngay")
                                    
                                    if ctype == "thang":
                                        current_thang = normalize_month(cell_val)
                                    elif ctype == "ngay" or ctype == "unknown":
                                        if current_thang:
                                            thang_key = f"thang_{current_thang.lower()}"
                                            if thang_key not in logic:
                                                logic[thang_key] = {}
                                            day_conds = parse_day_condition(cell_val)
                                            dict_merge(logic[thang_key], day_conds)
                                        else:
                                            day_conds = parse_day_condition(cell_val)
                                            dict_merge(logic, day_conds)
                current_star["logic_an_sao"] = logic
                parsing_mode = "PHAN_3"

    if current_star:
        stars.append(current_star)

    cat_tinh = []
    hung_tinh = []
    sao_chua_ro_loai = []

    for star in stars:
        if star["phan_loai"] == "Cát Tinh":
            cat_tinh.append(star)
        elif star["phan_loai"] == "Hung Tinh":
            hung_tinh.append(star)
        else:
            sao_chua_ro_loai.append(star["ten_sao"])

    print(f"--- BÁO CÁO CẬP NHẬT ---")
    print(f"Tổng số mục đã quét: {len(stars)}")
    print(f"Số lượng Cát Tinh: {len(cat_tinh)}")
    print(f"Số lượng Hung Tinh: {len(hung_tinh)}")
    print(f"Số lượng KHÔNG THỂ PHÂN LOẠI: {len(sao_chua_ro_loai)}")
    if sao_chua_ro_loai:
        print("DANH SÁCH CÁC SAO BỊ LỖI PHÂN LOẠI CẦN CHECK LẠI:")
        for idx, sao in enumerate(sao_chua_ro_loai, 1):
            print(f"{idx}. {sao}")

    with open(output_json_path, "w", encoding="utf-8") as f:
        json.dump(stars, f, ensure_ascii=False, indent=4)

if __name__ == "__main__":
    input_path = r"E:\Tu vi online\AI học tử vi\Thư Viện cho AI Học\Tầng 1- Dữ Liệu Chuẩn Hóa\Tổng Hợp Thần Sát Trạch Nhật Thường Dùng(Đã Chỉnh Lý).docx"
    output_path = r"E:\Tu vi online\than_sat_db.json"
    
    if os.path.exists(input_path):
        parse_than_sat_db(input_path, output_path)
    else:
        print(f"Lỗi: Không tìm thấy file tại đường dẫn: {input_path}")
