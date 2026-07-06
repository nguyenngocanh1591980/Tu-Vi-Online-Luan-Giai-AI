# -*- coding: utf-8 -*-
with open("E:/Tu vi online/frontend/lib/widgets/palace_cell.dart", "r", encoding="utf-8") as f:
    content = f.read()

# Fix _buildModifierText
old_block1 = """    } else if (upper.contains('KHOA')) {
      textColor = Colors.black; // Thủy (KHOA is THUY)"""
new_block1 = """    } else if (upper.contains('KHOA')) {
      textColor = Colors.green; // Mộc"""

content = content.replace(old_block1, new_block1)

# Fix _getPhiHoaColor
old_block2 = """    if (upper.contains('KHOA')) return Colors.black;"""
new_block2 = """    if (upper.contains('KHOA')) return Colors.green;"""

content = content.replace(old_block2, new_block2)

with open("E:/Tu vi online/frontend/lib/widgets/palace_cell.dart", "w", encoding="utf-8") as f:
    f.write(content)

