import docx
import json
import re

DOC_PATH = r"E:\Tu vi online\AI học tử vi\Thư Viện cho AI Học\Tầng 1- Dữ Liệu Chuẩn Hóa\Tổng Hợp Thần Sát Trạch Nhật Thường Dùng(Đã Chỉnh Lý).docx"
OUT_PATH = r"E:\Tu vi online\than_sat_db_strict.json"

doc = docx.Document(DOC_PATH)

stars = []
current_star = None

STATE_WAITING_FOR_STAR = 0
STATE_PARSING_MEANING = 1
STATE_PARSING_LOGIC = 2

state = STATE_WAITING_FOR_STAR
star_regex = re.compile(r"^\d+\.\s*(.+)")

# Bảng các giá trị hợp lệ để sanitize
VALID_CANS = ["giáp", "ất", "bính", "đinh", "mậu", "kỷ", "canh", "tân", "nhâm", "quý"]
VALID_CHIS = ["tý", "sửu", "dần", "mão", "thìn", "tỵ", "ngọ", "mùi", "thân", "dậu", "tuất", "hợi"]

def sanitize_can_chi(val):
    if not val:
        return []
    val = val.lower().strip()
    
    canchi_pairs = []
    for c in VALID_CANS:
        for ch in VALID_CHIS:
            if f"{c} {ch}" in val:
                canchi_pairs.append(f"{c.capitalize()} {ch.capitalize()}")
                val = val.replace(f"{c} {ch}", "")
            elif f"{c}{ch}" in val:
                canchi_pairs.append(f"{c.capitalize()} {ch.capitalize()}")
                val = val.replace(f"{c}{ch}", "")
                
    parts = re.split(r'[,;\n\t\s]+', val)
    res = canchi_pairs
    for p in parts:
        p = p.strip()
        if p in VALID_CANS or p in VALID_CHIS:
            p_cap = p.capitalize()
            if p_cap not in res:
                res.append(p_cap)
        elif p.isdigit():
            if p not in res:
                res.append(p)
    return res

def parse_table_pairs(table, header_col_1, header_col_2):
    """
    Parse bảng theo cặp cột. Hỗ trợ 1-nhiều (VD: Tháng | Ngày | Ngày).
    """
    pairs = []
    tbl_data = [[cell.text.strip() for cell in row.cells] for row in table.rows]
    if not tbl_data: return pairs, False
    
    first_row = [c.lower() for c in tbl_data[0]]
    
    # Map index: col_map is a list of (key_col_idx, [val_col_idx_1, val_col_idx_2, ...])
    col_map = []
    i = 0
    while i < len(first_row):
        if header_col_1 in first_row[i]:
            val_cols = []
            j = i + 1
            while j < len(first_row) and header_col_2 in first_row[j]:
                val_cols.append(j)
                j += 1
            if val_cols:
                col_map.append((i, val_cols))
            i = j
        else:
            i += 1
            
    if not col_map:
        # Fallback simple cases
        if len(first_row) == 2:
            col_map = [(0, [1])]
        elif len(first_row) == 4:
            col_map = [(0, [1]), (2, [3])]
        else:
            return pairs, False # Lỗi cấu trúc
            
    for row_idx in range(1, len(tbl_data)):
        row = tbl_data[row_idx]
        for key_col, val_cols in col_map:
            if key_col < len(row):
                key = row[key_col].strip()
                if not key: continue
                for v_col in val_cols:
                    if v_col < len(row):
                        val = row[v_col].strip()
                        if val:
                            pairs.append((key, val))
                            
    return pairs, True

def commit_star():
    global current_star, stars
    if current_star:
        # Check fail-safe
        if current_star["_found_table"] == 0:
            current_star["_needs_help"] = True
            current_star["logic_an_sao"] = {} # Clear logic
            
        stars.append(current_star)
        current_star = None

for element in doc.element.body:
    if element.tag.endswith('p'):
        p = docx.text.paragraph.Paragraph(element, doc)
        text = p.text.strip()
        if not text:
            continue
            
        # Kiểm tra nếu là bắt đầu một sao mới
        m = star_regex.match(text)
        if m and " - " in text or (text[0].isdigit() and "." in text[:4] and len(text.split(".")[0]) <= 3 and len(text) < 150):
            # Lưu sao cũ
            commit_star()
            
            ten_sao = text
            if ':' in ten_sao:
                ten_sao = ten_sao.split(':')[0].strip()
                
            current_star = {
                "ten_sao": ten_sao,
                "phan_loai": "Không rõ",
                "y_nghia_goc": "",
                "y_nghia_rut_gon": "[CẦN_AI_TÓM_TẮT]",
                "logic_an_sao": {},
                "_meanings_temp": [],
                "_found_table": 0,
                "_needs_help": False
            }
            state = STATE_PARSING_MEANING
            continue
            
        if current_star:
            t_lower = text.lower()
            if state == STATE_PARSING_MEANING:
                if t_lower == "cát tinh" or t_lower == "hung tinh":
                    current_star["phan_loai"] = "Cát Tinh" if t_lower == "cát tinh" else "Hung Tinh"
                elif t_lower.startswith("cách an sao"):
                    state = STATE_PARSING_LOGIC
                else:
                    current_star["_meanings_temp"].append(text)
            elif state == STATE_PARSING_LOGIC:
                pass # Bỏ qua text giải thích trong phần logic, chỉ đợi bảng

    elif element.tag.endswith('tbl'):
        if current_star and state == STATE_PARSING_LOGIC:
            table = docx.table.Table(element, doc)
            
            # Khắc phục lỗi Bảng Lồng Bảng (Nested Tables) như ở sao Âm Đức
            # Kiểm tra xem cell đầu tiên có chứa bảng con bên trong không
            if len(table.rows) > 0 and len(table.rows[0].cells) > 0:
                cell = table.rows[0].cells[0]
                if cell.tables: # Có bảng lồng bên trong
                    table = cell.tables[0] # Lấy bảng con thực sự
                    
            tbl_data = [[cell.text.strip().lower() for cell in row.cells] for row in table.rows]
            if not tbl_data:
                continue
                
            header = " ".join(tbl_data[0])
            
            if ("tháng" in header or "mùa" in header) and "ngày" in header:
                current_star["_found_table"] += 1
                header_key = "tháng" if "tháng" in header else "mùa"
                pairs, success = parse_table_pairs(table, header_key, "ngày")
                if not success: current_star["_needs_help"] = True
                
                SEASON_MAPPING = {
                    "xuân": ["dần", "mão", "thìn"],
                    "hạ": ["tỵ", "ngọ", "mùi"],
                    "thu": ["thân", "dậu", "tuất"],
                    "đông": ["hợi", "tý", "sửu"]
                }
                
                for k, v in pairs:
                    k_san = k.lower().replace('tháng', '').replace('mùa', '').replace('trong năm', '').strip()
                    if not k_san: continue
                    
                    target_months = []
                    # Check season
                    for s_k, s_m in SEASON_MAPPING.items():
                        if s_k in k_san:
                            target_months = s_m
                            break
                    
                    if not target_months:
                        if k_san.isdigit():
                            target_months = [k_san]
                        elif k_san in ["dần", "mão", "thìn", "tỵ", "ngọ", "mùi", "thân", "dậu", "tuất", "hợi", "tý", "sửu"]:
                            target_months = [k_san]
                        else:
                            target_months = [k_san] # fallback
                    
                    for month in target_months:
                        thang_key = f"thang_{month}"
                        if thang_key not in current_star["logic_an_sao"]:
                            current_star["logic_an_sao"][thang_key] = {}
                            
                        vals = sanitize_can_chi(v)
                        for val in vals:
                            target_sub_key = "chi_ngay"
                            if " " in val:
                                target_sub_key = "can_chi_ngay"
                            elif val.isdigit():
                                target_sub_key = "ngay_am_lich"
                            elif val.lower() in VALID_CANS:
                                target_sub_key = "can_ngay"
                                
                            if target_sub_key not in current_star["logic_an_sao"][thang_key]:
                                current_star["logic_an_sao"][thang_key][target_sub_key] = []
                            if val not in current_star["logic_an_sao"][thang_key][target_sub_key]:
                                current_star["logic_an_sao"][thang_key][target_sub_key].append(val)
                            
            elif "can ngày" in header and ("giờ" in header or "can giờ" in header):
                current_star["_found_table"] += 1
                pairs, success = parse_table_pairs(table, "can ngày", "giờ")
                if not success: current_star["_needs_help"] = True
                
                is_canchi = False
                for k, v in pairs:
                    vals = sanitize_can_chi(v)
                    for val in vals:
                        if " " in val:
                            is_canchi = True
                            break
                    if is_canchi: break
                            
                target_key = "theo_can_ngay_canchi_gio" if is_canchi else "theo_can_ngay_can_gio"
                
                if target_key not in current_star["logic_an_sao"]:
                    current_star["logic_an_sao"][target_key] = {}
                
                for k, v in pairs:
                    k_san = k.strip().capitalize()
                    if k_san not in current_star["logic_an_sao"][target_key]:
                        current_star["logic_an_sao"][target_key][k_san] = []
                        
                    vals = sanitize_can_chi(v)
                    for val in vals:
                        if val not in current_star["logic_an_sao"][target_key][k_san]:
                            current_star["logic_an_sao"][target_key][k_san].append(val)
                            
            elif "ngày" in header and "giờ" in header:
                current_star["_found_table"] += 1
                pairs, success = parse_table_pairs(table, "ngày", "giờ")
                if not success: current_star["_needs_help"] = True
                if "theo_gio" not in current_star["logic_an_sao"]:
                    current_star["logic_an_sao"]["theo_gio"] = {}
                for k, v in pairs:
                    k_san = k.lower().strip()
                    if k_san in VALID_CANS:
                        ngay_key = f"can_ngay_{k_san}"
                    else:
                        ngay_key = f"chi_ngay_{k_san}"
                        
                    if ngay_key not in current_star["logic_an_sao"]["theo_gio"]:
                        current_star["logic_an_sao"]["theo_gio"][ngay_key] = {"chi_gio": []}
                    vals = sanitize_can_chi(v)
                    for val in vals:
                        if val not in current_star["logic_an_sao"]["theo_gio"][ngay_key]["chi_gio"]:
                            current_star["logic_an_sao"]["theo_gio"][ngay_key]["chi_gio"].append(val)
            else:
                # Bảng dị thường, cấu trúc không khớp
                current_star["_needs_help"] = True
                
commit_star()

# Process meanings & cleanup
final_stars = []
needs_help_count = 0
success_count = 0

for s in stars:
    # Build y_nghia_goc
    raw_meaning = " ".join(s["_meanings_temp"]).strip()
    s["y_nghia_goc"] = raw_meaning
    del s["_meanings_temp"]
    
    # Xử lý tóm tắt
    if not raw_meaning:
        s["y_nghia_rut_gon"] = ""
    elif len(raw_meaning.split('.')) <= 2 and len(raw_meaning) < 50:
        s["y_nghia_rut_gon"] = raw_meaning # Đủ ngắn để tự động nhận làm rút gọn
    else:
        pass # Giữ nguyên [CẦN_AI_TÓM_TẮT]
        
    del s["_found_table"]
    
    if s["_needs_help"]:
        needs_help_count += 1
        print(f"\033[91m[CẦN HƯỚNG DẪN]\033[0m {s['ten_sao']} - Cấu trúc bảng không rõ ràng hoặc không có bảng.")
        s["logic_an_sao"] = {} # Không đoán mò
    else:
        success_count += 1
        
    del s["_needs_help"]
    final_stars.append(s)

with open(OUT_PATH, "w", encoding="utf-8") as f:
    json.dump(final_stars, f, ensure_ascii=False, indent=2)

print("\n" + "="*50)
print("BÁO CÁO KẾT QUẢ BÓC TÁCH (STRICT MODE)")
print("="*50)
print(f"Tổng số sao quét được: {len(final_stars)}")
print(f"\033[92mThành công (Bảng chuẩn):\033[0m {success_count}")
print(f"\033[91mBị treo cờ [CẦN HƯỚNG DẪN]:\033[0m {needs_help_count}")
print(f"Dữ liệu đã được lưu tại: {OUT_PATH}")
print("="*50)
