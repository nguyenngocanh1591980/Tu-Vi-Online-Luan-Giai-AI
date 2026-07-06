# -*- coding: utf-8 -*-
import re

with open("E:/Tu vi online/frontend/lib/widgets/center_info.dart", "r", encoding="utf-8") as f:
    content = f.read()

# The target line to replace contains `info.viewingYear.split(" (")[0]`
def replacer(match):
    # We want to replace the whole `_buildCellText('Năm Xem...')` call
    return "                                _buildCellText(info.viewingYear.contains('(') ? 'Năm Xem(${info.viewingYear.split(\"(\")[1].replaceAll(\")\", \"\")})\\n${info.viewingYear.split(\" (\")[0]}' : 'Năm Xem\\n${info.viewingYear}', isBold: true),"

content = re.sub(r"\s*_buildCellText\([^\n]*info\.viewingYear\.split[^\n]*\),", replacer, content)

with open("E:/Tu vi online/frontend/lib/widgets/center_info.dart", "w", encoding="utf-8") as f:
    f.write(content)

