import docx
import sys

if hasattr(sys.stdout, 'reconfigure'):
    sys.stdout.reconfigure(encoding='utf-8')

doc_path = r"E:\Tu vi online\AI học tử vi\Thư Viện cho AI Học\Tầng 1- Dữ Liệu Chuẩn Hóa\Tổng Hợp Thần Sát Trạch Nhật Thường Dùng(Đã Chỉnh Lý).docx"
doc = docx.Document(doc_path)

found_part2 = False
for p in doc.paragraphs:
    text = p.text.strip()
    if "II) Các sao xấu đối với từng việc" in text:
        found_part2 = True
    
    if found_part2 and text:
        print(text)
