import docx
import json
import re

doc_path = r"E:\Tu vi online\AI học tử vi\Thư Viện cho AI Học\Tầng 1- Dữ Liệu Chuẩn Hóa\Tổng Hợp Thần Sát Trạch Nhật Thường Dùng(Đã Chỉnh Lý).docx"
doc = docx.Document(doc_path)

stars = []
current_star = None

def parse_month_day_table(table_data):
    # Month-Day typically has 2 or 4 columns
    logic = {}
    for row in table_data:
        # Check pairs of cols: (0,1), (2,3)
        for i in range(0, len(row), 2):
            if i + 1 < len(row):
                thang = row[i].strip().lower()
                ngay = row[i+1].strip()
                if not thang or not ngay or thang == 'tháng' or ngay.lower() == 'ngày':
                    continue
                thang_key = f"thang_{thang}"
                if thang_key not in logic:
                    logic[thang_key] = {"chi_ngay": []}
                # Assuming ngay is Chi, but could be Can
                # Here we just put it in chi_ngay as string. We can refine later.
                if ngay not in logic[thang_key]["chi_ngay"]:
                    logic[thang_key]["chi_ngay"].append(ngay)
    return logic

def parse_day_hour_table(table_data):
    logic = {"theo_gio": {}}
    for row in table_data:
        for i in range(0, len(row), 2):
            if i + 1 < len(row):
                ngay = row[i].strip().lower()
                gio = row[i+1].strip()
                if not ngay or not gio or ngay == 'ngày' or gio.lower() == 'giờ':
                    continue
                ngay_key = f"chi_ngay_{ngay}"
                if ngay_key not in logic["theo_gio"]:
                    logic["theo_gio"][ngay_key] = {"chi_gio": []}
                if gio not in logic["theo_gio"][ngay_key]["chi_gio"]:
                    logic["theo_gio"][ngay_key]["chi_gio"].append(gio)
    return logic

# Regex to match star name e.g. "59.Kim Quĩ - 金櫃 - Golden Lock" or "59. Kim Quĩ"
star_regex = re.compile(r"^\d+\.\s*[\w\s]+")

for element in doc.element.body:
    if element.tag.endswith('p'):
        p = docx.text.paragraph.Paragraph(element, doc)
        text = p.text.strip()
        
        # Check if this paragraph is a star header
        # Usually like "1. Thiên Đức - 天德 - Heavenly Virtue"
        if text and text[0].isdigit() and '.' in text[:5] and len(text.split('.')[0]) < 4 and len(text) < 200:
            if current_star:
                stars.append(current_star)
            current_star = {
                "ten_sao": text,
                "phan_loai": "Không rõ",
                "y_nghia": [],
                "logic_an_sao": {},
                "ghi_chu": []
            }
        elif current_star:
            if text.lower() in ["cát tinh", "hung tinh"]:
                current_star["phan_loai"] = "Cát Tinh" if text.lower() == "cát tinh" else "Hung Tinh"
            elif text.startswith("Nên:") or text.startswith("Kỵ:") or text.startswith("Nên kỵ:") or text.startswith("Tránh xa"):
                current_star["y_nghia"].append(text)
            elif text and text != "Cách An Sao:":
                current_star["ghi_chu"].append(text)
                
            # If paragraph contains image (drawing), and we are in Kim Quĩ, hardcode the missing table
            if '59.Kim Quĩ' in current_star['ten_sao'] and '<w:drawing>' in element.xml:
                # Inject Kim Quĩ month-day table
                kq_md = parse_month_day_table([
                    ['1', 'Thìn', '7', 'Thìn'],
                    ['2', 'Ngọ', '8', 'Ngọ'],
                    ['3', 'Thân', '9', 'Thân'],
                    ['4', 'Tuất', '10', 'Tuất'],
                    ['5', 'Tý', '11', 'Tý'],
                    ['6', 'Dần', '12', 'Dần']
                ])
                current_star["logic_an_sao"].update(kq_md)

    elif element.tag.endswith('tbl'):
        if current_star:
            table = docx.table.Table(element, doc)
            tbl_data = []
            for row in table.rows:
                tbl_data.append([cell.text.strip() for cell in row.cells])
            
            # Identify table type
            header = " ".join(tbl_data[0]).lower() if tbl_data else ""
            if "tháng" in header and "ngày" in header:
                parsed_logic = parse_month_day_table(tbl_data)
                # Merge into logic_an_sao
                current_star["logic_an_sao"].update(parsed_logic)
            elif "ngày" in header and "giờ" in header:
                parsed_logic = parse_day_hour_table(tbl_data)
                if "theo_gio" not in current_star["logic_an_sao"]:
                    current_star["logic_an_sao"]["theo_gio"] = {}
                # Merge theo_gio
                for k, v in parsed_logic["theo_gio"].items():
                    current_star["logic_an_sao"]["theo_gio"][k] = v
            else:
                # Custom tables (e.g. Can Ngày, Chi Ngày)
                # For simplicity, we can leave them out or parse as chi_ngay array if it's a simple list
                pass

if current_star:
    stars.append(current_star)

# Fix Lỗ Ban Sát: it should be "theo_gio" as per image.
# Wait, Lỗ Ban Sát table has "Ngày | Giờ". Our script will parse it as "theo_gio". Let's verify.

with open(r"E:\Tu vi online\than_sat_db_new.json", "w", encoding="utf-8") as f:
    json.dump(stars, f, ensure_ascii=False, indent=2)

print("Tổng kết Report:")
print(f"Tổng số sao parse được: {len(stars)}")
c_count = sum(1 for s in stars if s['phan_loai'] == 'Cát Tinh')
h_count = sum(1 for s in stars if s['phan_loai'] == 'Hung Tinh')
print(f"Cát Tinh: {c_count} | Hung Tinh: {h_count} | Không rõ: {len(stars) - c_count - h_count}")

# Check specific stars
print("\n--- Kiểm chứng Kim Quỹ ---")
kq = next((s for s in stars if 'Kim Quĩ' in s['ten_sao']), None)
if kq:
    print(json.dumps(kq['logic_an_sao'], ensure_ascii=False, indent=2))

print("\n--- Kiểm chứng Lỗ Ban Sát ---")
lb = next((s for s in stars if 'Lỗ Ban Sát' in s['ten_sao']), None)
if lb:
    print(json.dumps(lb['logic_an_sao'], ensure_ascii=False, indent=2))
