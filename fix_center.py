# -*- coding: utf-8 -*-
import re

with open("E:/Tu vi online/frontend/lib/widgets/center_info.dart", "r", encoding="utf-8") as f:
    content = f.read()

content = content.replace("fontSize: 9,", "fontSize: 11,")

lines = content.split("\n")
for i, line in enumerate(lines):
    if "TableRow(children: [" in line and "isBold: true" in lines[i+1]:
        lines[i+2] = "                                _buildCellText('Năm Xem (${info.viewingYear.split(\" (\")[0]})', isBold: true),"
        lines[i+3] = "                                _buildCellText('Đại Vận (${info.tuoiDaiVan} tuổi)', isBold: true),"
        break

with open("E:/Tu vi online/frontend/lib/widgets/center_info.dart", "w", encoding="utf-8") as f:
    f.write("\n".join(lines))

