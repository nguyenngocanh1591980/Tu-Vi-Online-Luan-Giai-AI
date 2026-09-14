import docx
import sys
import re
import json
from docx.document import Document as _Document
from docx.oxml.text.paragraph import CT_P
from docx.oxml.table import CT_Tbl
from docx.table import _Cell, Table
from docx.text.paragraph import Paragraph

if hasattr(sys.stdout, 'reconfigure'):
    sys.stdout.reconfigure(encoding='utf-8')

def iter_block_items(parent):
    if isinstance(parent, _Document):
        parent_elm = parent.element.body
    elif isinstance(parent, _Cell):
        parent_elm = parent._tc
    else:
        raise ValueError("something's not right")

    for child in parent_elm.iterchildren():
        if isinstance(child, CT_P):
            yield Paragraph(child, parent)
        elif isinstance(child, CT_Tbl):
            yield Table(child, parent)

doc_path = r"E:\Tu vi online\AI học tử vi\Thư Viện cho AI Học\Tầng 1- Dữ Liệu Chuẩn Hóa\Tổng Hợp Thần Sát Trạch Nhật Thường Dùng(Đã Chỉnh Lý).docx"
doc = docx.Document(doc_path)

stars = []
current_star = None
current_section = None
needs_guidance = []

for block in iter_block_items(doc):
    if isinstance(block, Paragraph):
        text = block.text.strip()
        if not text:
            continue
            
        # Kiểm tra xem có phải bắt đầu sao mới không (VD: "1.Âm Đức - ...")
        # Regex linh hoạt để bắt số thứ tự đầu dòng
        match = re.match(r'^(\d+)\.\s*(.*)', text)
        if match and not ("I)" in text or "II)" in text):
            # Nếu đã có sao trước đó, kiểm tra xem nó có logic an sao chưa
            if current_star:
                if not current_star.get("logic_an_sao"):
                    current_star["logic_an_sao"] = []
                    current_star["flags"].append("[CẦN_HƯỚNG_DẪN]")
                    needs_guidance.append(current_star["ten_sao"])
                stars.append(current_star)
                
            ten_sao_full = text
            current_star = {
                "ten_sao": ten_sao_full,
                "phan_loai": "",
                "y_nghia": "",
                "logic_an_sao": [],
                "flags": []
            }
            current_section = "PHAN_LOAI"
            continue
            
        if current_star:
            if current_section == "PHAN_LOAI":
                if "Cát Tinh" in text or "Cát tinh" in text:
                    current_star["phan_loai"] = "Cát Tinh"
                    current_section = "Y_NGHIA"
                elif "Hung Tinh" in text or "Hung tinh" in text:
                    current_star["phan_loai"] = "Hung Tinh"
                    current_section = "Y_NGHIA"
                else:
                    # Đôi khi không có dòng Phân Loại rõ ràng, nhảy sang Ý Nghĩa
                    if text.startswith("Ý nghĩa Sao") or text.startswith("Ý Nghĩa Sao"):
                        current_star["y_nghia"] = text
                        current_section = "Y_NGHIA"
            elif current_section == "Y_NGHIA":
                if text.startswith("Cách An Sao"):
                    current_section = "CACH_AN_SAO"
                else:
                    current_star["y_nghia"] += "\n" + text
            elif current_section == "CACH_AN_SAO":
                # Bỏ qua các text ngoài bảng
                pass

    elif isinstance(block, Table):
        if current_star and current_section == "CACH_AN_SAO":
            # Extract table
            table_data = []
            for row in block.rows:
                row_data = [cell.text.strip().replace('\n', ' ') for cell in row.cells]
                table_data.append(row_data)
            
            # Lưu bảng vào logic
            current_star["logic_an_sao"] = table_data
            # Hết bảng thì khóa không nhận thêm cho sao này (cho đến sao tiếp theo)
            current_section = "DONE"

# Xử lý sao cuối cùng
if current_star:
    if not current_star.get("logic_an_sao"):
        current_star["logic_an_sao"] = []
        current_star["flags"].append("[CẦN_HƯỚNG_DẪN]")
        needs_guidance.append(current_star["ten_sao"])
    stars.append(current_star)

# Xóa các newline dư thừa ở đầu/cuối ý nghĩa
for s in stars:
    s["y_nghia"] = s["y_nghia"].strip()
    if s["y_nghia"].startswith("Ý nghĩa Sao:") or s["y_nghia"].startswith("Ý nghĩa Sao :"):
        s["y_nghia"] = re.sub(r'^Ý nghĩa Sao\s*:\s*', '', s["y_nghia"])

# Output ra file JSON
output_file = "thansat_226_parsed.json"
with open(output_file, "w", encoding="utf-8") as f:
    json.dump(stars, f, ensure_ascii=False, indent=4)

print("Đã bóc tách thành công vào file:", output_file)
print(f"Tổng số sao bóc tách được: {len(stars)}")

print("\n--- DANH SÁCH CÁC SAO [CẦN_HƯỚNG_DẪN] (Không có bảng biểu hoặc lỗi) ---")
if needs_guidance:
    for name in needs_guidance:
        print(f"- {name}")
else:
    print("Không có sao nào cần hướng dẫn! Tất cả đều có bảng biểu.")
print("----------------------------------------------------------------------")

