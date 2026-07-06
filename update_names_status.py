# -*- coding: utf-8 -*-
import re

with open("E:/Tu vi online/frontend/lib/widgets/center_info.dart", "r", encoding="utf-8") as f:
    content = f.read()

# 1. Update dvNames
old_dvNames = """    List<String> dvNames = [
      'Lưu ĐV Mệnh', 'Lưu ĐV Phụ Mẫu', 'Lưu ĐV Phúc Đức', 'Lưu ĐV Điền Trạch', 
      'Lưu ĐV Quan Lộc', 'Lưu ĐV Nô Bộc', 'Lưu ĐV Thiên Di', 'Lưu ĐV Tật Ách', 
      'Lưu ĐV Tài Bạch', 'Lưu ĐV Tử Tức', 'Lưu ĐV Thê Thiếp', 'Lưu ĐV Huynh Đệ'
    ];"""

new_dvNames = """    List<String> dvNames = [
      'L.ĐV Mệnh', 'L.ĐV Phụ Mẫu', 'L.ĐV Phúc Đức', 'L.ĐV Điền Trạch', 
      'L.ĐV Quan Lộc', 'L.ĐV Nô Bộc', 'L.ĐV Thiên Di', 'L.ĐV Tật Ách', 
      'L.ĐV Tài Bạch', 'L.ĐV Tử Tức', 'L.ĐV Thê Thiếp', 'L.ĐV Huynh Đệ'
    ];"""

content = content.replace(old_dvNames, new_dvNames)

# 2. Update col2
old_col2 = "String col2 = 'Cung ${_capitalizeWords(palace.name)}';"
new_col2 = "String col2 = _capitalizeWords(palace.name);"
content = content.replace(old_col2, new_col2)

# 3. Update starName to include status
old_starName = "String starName = 'L.ĐV ${_capitalizeWords(rest)}';"
new_starName = "String starName = 'L.ĐV ${_capitalizeWords(rest)}' + (s.status.isNotEmpty ? '[${s.status}]' : '');"
content = content.replace(old_starName, new_starName)

with open("E:/Tu vi online/frontend/lib/widgets/center_info.dart", "w", encoding="utf-8") as f:
    f.write(content)

