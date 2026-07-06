# -*- coding: utf-8 -*-
with open("E:/Tu vi online/frontend/lib/widgets/palace_cell.dart", "r", encoding="utf-8") as f:
    content = f.read()

# Fix the alignment of the Column holding PhiHoa
old_col = """                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.center,"""
new_col = """                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,"""
content = content.replace(old_col, new_col)

# Fix textAlign in _buildModifierText
old_text_align = """        textAlign: TextAlign.center,"""
new_text_align = """        textAlign: TextAlign.left,"""
content = content.replace(old_text_align, new_text_align)

with open("E:/Tu vi online/frontend/lib/widgets/palace_cell.dart", "w", encoding="utf-8") as f:
    f.write(content)

