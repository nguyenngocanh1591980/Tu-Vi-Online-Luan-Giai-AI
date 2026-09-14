import docx
import sys

if hasattr(sys.stdout, 'reconfigure'):
    sys.stdout.reconfigure(encoding='utf-8')

doc_path = r"E:\Tu vi online\AI học tử vi\Thư Viện cho AI Học\Tầng 1- Dữ Liệu Chuẩn Hóa\Tổng Hợp Thần Sát Trạch Nhật Thường Dùng(Đã Chỉnh Lý).docx"
doc = docx.Document(doc_path)

for i, p in enumerate(doc.paragraphs):
    text = p.text.strip()
    if "Bất Tương: Tốt mọi việc" in text or "Lục Hợp: Tốt mọi việc" in text:
        print(f"FOUND IN DOCX AT PARA {i}: {text}")
        
    if "74.Ngọc Vũ" in text or "85.Nguyệt Hoả" in text or "86.Nguyệt Hư" in text or "169.Tử Phù" in text:
        print(f"FOUND STAR AT PARA {i}: {text}")
