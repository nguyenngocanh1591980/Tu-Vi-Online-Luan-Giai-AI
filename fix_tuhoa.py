# -*- coding: utf-8 -*-
with open("E:/Tu vi online/frontend/lib/widgets/palace_cell.dart", "r", encoding="utf-8") as f:
    content = f.read()

old_block = """    Color textColor = isGreen ? Colors.green.shade800 : Colors.indigo.shade800;
    if (text.contains('L~C') || text.contains('L?C') || text.contains('QUY?N') || text.contains('QUY?N') || text.contains('KHOA')) {
      textColor = Colors.green; // M?c
    } else if (text.contains('K') || text.contains('K?')) {
      textColor = Colors.black; // Th?y
    }"""

new_block = """    Color textColor = isGreen ? Colors.green.shade800 : Colors.indigo.shade800;
    String upper = text.toUpperCase();
    if (upper.contains('LỘC') || upper.contains('L~C') || upper.contains('L?C')) {
      textColor = Colors.green; // Mộc
    } else if (upper.contains('QUYỀN') || upper.contains('QUY?N')) {
      textColor = Colors.green; // Mộc
    } else if (upper.contains('KHOA')) {
      textColor = Colors.black; // Thủy (KHOA is THUY)
    } else if (upper.contains('KỴ') || upper.contains('KỊ') || upper.contains('K?') || upper.contains('KY')) {
      textColor = Colors.black; // Thủy
    }"""

content = content.replace(old_block, new_block)

# Also fix _buildModifierTextCompact if it has hardcoded colors
old_compact = """        style: TextStyle(
          fontSize: 10,
          fontFamily: 'Arial',
          color: text.startsWith('P.') ? Colors.green.shade700 : Colors.red,
        ),"""

new_compact = """        style: TextStyle(
          fontSize: 10,
          fontFamily: 'Arial',
          color: _getPhiHoaColor(text),
        ),"""

helper = """  Color _getPhiHoaColor(String text) {
    String upper = text.toUpperCase();
    if (upper.contains('LỘC') || upper.contains('L~C') || upper.contains('L?C')) return Colors.green;
    if (upper.contains('QUYỀN') || upper.contains('QUY?N')) return Colors.green;
    if (upper.contains('KHOA')) return Colors.black;
    if (upper.contains('KỴ') || upper.contains('KỊ') || upper.contains('K?') || upper.contains('KY')) return Colors.black;
    return text.startsWith('P.') ? Colors.green.shade700 : Colors.red;
  }

  Widget _buildModifierTextCompact"""

content = content.replace(old_compact, new_compact)
content = content.replace("  Widget _buildModifierTextCompact", helper)

with open("E:/Tu vi online/frontend/lib/widgets/palace_cell.dart", "w", encoding="utf-8") as f:
    f.write(content)

