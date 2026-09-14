# -*- coding: utf-8 -*-
"""
Script: parse_24_tiet_khi.py
Nhiệm vụ: Bóc tách chính xác 100% nguyên văn 24 Tiết Khí từ tài liệu Word chuẩn hóa:
E:\Tu vi online\AI học tử vi\Thư Viện cho AI Học\Tầng 1- Dữ Liệu Chuẩn Hóa\Cách tính và ý nghĩa 24 tiết khí trong 1 năm(đã chỉnh lý).docx
và đồng bộ ra các file tiet_khi_db.json
"""

import os
import sys
import re
import json
import unicodedata
import docx

if hasattr(sys.stdout, 'reconfigure'):
    sys.stdout.reconfigure(encoding='utf-8')

# 24 Tiết Khí chuẩn theo vòng tuần hoàn thiên văn
STANDARD_24_TERMS = [
    'Lập Xuân', 'Vũ Thủy', 'Kinh Trập', 'Xuân Phân', 'Thanh Minh', 'Cốc Vũ',
    'Lập Hạ', 'Tiểu Mãn', 'Mang Chủng', 'Hạ Chí', 'Tiểu Thử', 'Đại Thử',
    'Lập Thu', 'Xử Thử', 'Bạch Lộ', 'Thu Phân', 'Hàn Lộ', 'Sương Giáng',
    'Lập Đông', 'Tiểu Tuyết', 'Đại Tuyết', 'Đông Chí', 'Tiểu Hàn', 'Đại Hàn'
]

def normalize_str(s: str) -> str:
    if not s:
        return ""
    s = unicodedata.normalize('NFC', s)
    s = s.replace('\u00a0', ' ')
    return s.strip()

def parse_docx(docx_path: str) -> dict:
    if not os.path.exists(docx_path):
        print(f"[TREO_CỜ][CẦN_HƯỚNG_DẪN]: Không tìm thấy file tài liệu chuẩn hóa: {docx_path}")
        sys.exit(1)

    doc = docx.Document(docx_path)
    paragraphs = [normalize_str(p.text) for p in doc.paragraphs if p.text.strip()]

    start_idx = -1
    for i, p in enumerate(paragraphs):
        if 'B:' in p and 'Ý nghĩa và cách tính 24 Tiết khí' in p:
            start_idx = i + 1
            break

    if start_idx == -1:
        print("[TREO_CỜ][CẦN_HƯỚNG_DẪN]: Không tìm thấy đề mục 'B: Ý nghĩa và cách tính 24 Tiết khí trong năm' trong file docx!")
        sys.exit(1)

    terms_data = {}
    current_term = None
    current_texts = []

    ignore_headers = [
        'Tiết khí mùa xuân 2026:', 'Tiết khí mùa hạ 2026', 'Tiết khí mùa thu 2026', 'Tiết khí mùa đông 2026',
        'Mùa xuân - mùa của cây cối đâm chồi nảy lộc', 'Tiết khí mùa hạ - mặt trời chói sáng', 'Tiết khí mùa đông lạnh buốt'
    ]

    num_pattern = re.compile(r'^(\d+)\s*\)\s*(?:Tiết\s*)?(.*?)(?::|$)', re.IGNORECASE)

    for p in paragraphs[start_idx:]:
        if p in ignore_headers:
            continue

        m = num_pattern.match(p)
        if m:
            num = int(m.group(1))
            if 1 <= num <= 24:
                if current_term:
                    terms_data[current_term] = '\n'.join(current_texts)
                current_term = STANDARD_24_TERMS[num - 1]

                colon_pos = p.find(':')
                if colon_pos != -1 and colon_pos < len(p) - 1:
                    first_line = p[colon_pos + 1:].strip()
                    current_texts = [first_line] if first_line else []
                else:
                    current_texts = []
                continue

        if current_term:
            current_texts.append(p)

    if current_term and current_texts:
        terms_data[current_term] = '\n'.join(current_texts)

    if len(terms_data) != 24:
        print(f"[TREO_CỜ][CẦN_HƯỚNG_DẪN]: Số lượng tiết khí bóc tách được ({len(terms_data)}) không đủ 24 tiết khí!")
        sys.exit(1)

    return terms_data

def main():
    base_dir = os.path.dirname(os.path.abspath(__file__))
    docx_path = os.path.join(
        base_dir,
        "AI học tử vi",
        "Thư Viện cho AI Học",
        "Tầng 1- Dữ Liệu Chuẩn Hóa",
        "Cách tính và ý nghĩa 24 tiết khí trong 1 năm(đã chỉnh lý).docx"
    )

    print(f"[*] Đang đọc dữ liệu từ: {docx_path}")
    terms_dict = parse_docx(docx_path)
    print(f"[+] Đã bóc tách thành công toàn bộ {len(terms_dict)}/24 Tiết Khí nguyên văn chuẩn hóa 100%!")

    target_locations = [
        os.path.join(base_dir, "tiet_khi_db.json"),
        os.path.join(base_dir, "AIEngine_Python", "tiet_khi_db.json"),
        os.path.join(base_dir, "logic_service", "tiet_khi_db.json"),
        os.path.join(base_dir, "logic_service", "ai_engine", "tiet_khi_db.json"),
    ]

    for loc in target_locations:
        os.makedirs(os.path.dirname(loc), exist_ok=True)
        with open(loc, "w", encoding="utf-8") as f:
            json.dump(terms_dict, f, ensure_ascii=False, indent=2)
        print(f"    -> Đã xuất CSDL: {loc}")

if __name__ == "__main__":
    main()
