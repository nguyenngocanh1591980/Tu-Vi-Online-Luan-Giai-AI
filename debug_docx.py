import docx
import re
from docx.document import Document as _Document
from docx.oxml.text.paragraph import CT_P
from docx.oxml.table import CT_Tbl
from docx.table import _Cell, Table
from docx.text.paragraph import Paragraph
import sys

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

capture = False
for block in iter_block_items(doc):
    if isinstance(block, Paragraph):
        text = block.text.strip()
        if "74.Ngọc Vũ" in text or "85.Nguyệt Hoả" in text or "86.Nguyệt Hư" in text or "169.Tử Phù" in text:
            capture = True
            print("=======================")
            print(f"FOUND: {text}")
        elif capture and re.match(r'^(\d+)\.\s*(.*)', text):
            capture = False
            
        if capture:
            if text:
                print(f"P: {text}")
    elif isinstance(block, Table):
        if capture:
            print(f"TABLE: {len(block.rows)} rows")
