# -*- coding: utf-8 -*-
with open("E:/Tu vi online/frontend/lib/widgets/palace_cell.dart", "r", encoding="utf-8") as f:
    content = f.read()

old_code = """                    Text(isFullMode ? palace.cornerLeft : palace.cornerLeft.replaceFirst('Năm ', 'năm '), style: TextStyle(fontSize: 9, fontFamily: 'Arial', color: _getBranchColor(palace.cungChi), fontWeight: FontWeight.bold)),"""
new_code = """                    Text(isFullMode ? palace.cornerLeft : palace.cornerLeft.replaceFirst('Năm ', 'năm '), style: TextStyle(fontSize: 9, fontFamily: 'Arial', color: _getBranchColor(palace.cornerLeft), fontWeight: FontWeight.bold)),"""

content = content.replace(old_code, new_code)

with open("E:/Tu vi online/frontend/lib/widgets/palace_cell.dart", "w", encoding="utf-8") as f:
    f.write(content)

