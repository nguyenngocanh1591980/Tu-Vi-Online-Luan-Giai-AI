import docx
import sys
import re

if hasattr(sys.stdout, 'reconfigure'):
    sys.stdout.reconfigure(encoding='utf-8')

doc_path = r"E:\Tu vi online\AI học tử vi\Thư Viện cho AI Học\Tầng 1- Dữ Liệu Chuẩn Hóa\Tổng Hợp Thần Sát Trạch Nhật Thường Dùng(Đã Chỉnh Lý).docx"
doc = docx.Document(doc_path)

def normalize_text(text):
    return text.replace(" ", "").replace(":", "").lower()

text_to_find = {
    "12.Bất Tương": "bấttươngtốtmọiviệc",
    "74.Ngọc Vũ": "tốtchomọiviệc,đặcbiệtlànhữnghoạtđộngcótínhrủirocao.nên", # Từ hình 4
    "85.Nguyệt Hoả": "ngàyđạicát,rấtthuậnlợiđểlàmnhà", # Từ hình 2
    "86.Nguyệt Hư": "nên:tutrạch,tạotrạch", # Từ hình 3
    "169.Tử Phù": "tốtchomọiviệcgặpcấptrênvềcôngviệc;làmcáccôngviệcliênquanđếnchínhquyền" # Từ hình 5
}

for i, p in enumerate(doc.paragraphs):
    text = p.text.strip()
    norm = normalize_text(text)
    
    if text:
        # Check against target strings
        for star, target in text_to_find.items():
            if target in norm:
                print(f"FOUND POTENTIAL MATCH FOR {star} at PARA {i}: {text}")
                
        # Let's also print all 'Ý nghĩa Sao' blocks that match some keywords to manually find them
        if "Ý nghĩa Sao" in text:
            if "Ngày đại cát, rất thuận lợi để làm nhà" in text:
                print(f"FOUND HINH 2 MATCH at PARA {i}: {text}")
            if "Nên: Tu trạch, tạo trạch, đính hôn" in text:
                print(f"FOUND HINH 3 MATCH at PARA {i}: {text}")
            if "Tốt cho mọi việc, đặc biệt là những hoạt động có tính rủi ro cao" in text:
                print(f"FOUND HINH 4 MATCH at PARA {i}: {text}")
            if "Tốt cho mọi việc gặp cấp trên về công việc; làm các công việc liên quan đến chính quyền" in text:
                print(f"FOUND HINH 5 MATCH at PARA {i}: {text}")
