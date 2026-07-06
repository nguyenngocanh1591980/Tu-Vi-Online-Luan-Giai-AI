# -*- coding: utf-8 -*-
with open("E:/Tu vi online/frontend/lib/widgets/palace_cell.dart", "r", encoding="utf-8") as f:
    content = f.read()

# Fix 1: Alignment and FittedBox
old_align = """                            alignment: Alignment.bottomCenter,
                            child: SingleChildScrollView(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,"""

new_align = """                            alignment: Alignment.bottomLeft,
                            child: SingleChildScrollView(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,"""

content = content.replace(old_align, new_align)

# Fix 2: Color bug in _buildModifierText
old_color1 = """    Color textColor = isGreen ? Colors.green.shade800 : Colors.indigo.shade800;
    String upper = text.toUpperCase();
    if (upper.contains('LỘC') || upper.contains('L~C') || upper.contains('L?C')) {"""

new_color1 = """    Color textColor = isGreen ? Colors.green.shade800 : Colors.indigo.shade800;
    String prefix = text.split(':')[0].toUpperCase();
    if (prefix.contains('LỘC') || prefix.contains('L~C') || prefix.contains('L?C')) {"""

content = content.replace(old_color1, new_color1)
content = content.replace("upper.contains('QUYỀN')", "prefix.contains('QUYỀN')")
content = content.replace("upper.contains('QUY?N')", "prefix.contains('QUY?N')")
content = content.replace("upper.contains('KHOA')", "prefix.contains('KHOA')")
content = content.replace("upper.contains('KỴ')", "prefix.contains('KỴ')")
content = content.replace("upper.contains('KỊ')", "prefix.contains('KỊ')")
content = content.replace("upper.contains('K?')", "prefix.contains('K?')")
content = content.replace("upper.contains('KY')", "prefix.contains('KY')")

# Fix 3: Color bug in _getPhiHoaColor
old_color2 = """  Color _getPhiHoaColor(String text) {
    String upper = text.toUpperCase();
    if (upper.contains('LỘC') || upper.contains('L~C') || upper.contains('L?C')) return Colors.green;"""

new_color2 = """  Color _getPhiHoaColor(String text) {
    String prefix = text.split(':')[0].toUpperCase();
    if (prefix.contains('LỘC') || prefix.contains('L~C') || prefix.contains('L?C')) return Colors.green;"""

content = content.replace(old_color2, new_color2)

with open("E:/Tu vi online/frontend/lib/widgets/palace_cell.dart", "w", encoding="utf-8") as f:
    f.write(content)

