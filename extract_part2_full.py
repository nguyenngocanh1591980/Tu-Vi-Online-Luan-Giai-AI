import docx
import sys
import re

if hasattr(sys.stdout, 'reconfigure'):
    sys.stdout.reconfigure(encoding='utf-8')

doc_path = r"E:\Tu vi online\AI học tử vi\Thư Viện cho AI Học\Tầng 1- Dữ Liệu Chuẩn Hóa\Tổng Hợp Thần Sát Trạch Nhật Thường Dùng(Đã Chỉnh Lý).docx"
doc = docx.Document(doc_path)

capture = False
for i, p in enumerate(doc.paragraphs):
    text = p.text.strip()
    if "II) Các sao xấu đối với từng việc" in text:
        capture = True
        print("FOUND PART 2")
        
    if capture:
        print(text)
        
        # Stop after reaching end of document or finding a new major section
        if len(text) > 0 and text.startswith("---") or i > len(doc.paragraphs) - 10:
            break
