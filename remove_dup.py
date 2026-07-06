# -*- coding: utf-8 -*-
with open("E:/Tu vi online/frontend/lib/widgets/center_info.dart", "r", encoding="utf-8") as f:
    content = f.read()

# find the last occurrence
first = content.find("List<Widget> _buildTheoTieuVanList(BuildContext context) {")
last = content.rfind("List<Widget> _buildTheoTieuVanList(BuildContext context) {")

if first != last and first != -1:
    end_of_last = content.find("Widget _buildCompactCenterInfo", last)
    if end_of_last != -1:
        content = content[:last] + content[end_of_last:]

with open("E:/Tu vi online/frontend/lib/widgets/center_info.dart", "w", encoding="utf-8") as f:
    f.write(content)

