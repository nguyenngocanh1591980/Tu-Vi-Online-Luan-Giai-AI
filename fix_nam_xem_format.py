# -*- coding: utf-8 -*-
import re

with open("E:/Tu vi online/frontend/lib/widgets/center_info.dart", "r", encoding="utf-8") as f:
    content = f.read()

content = content.replace("textAlign: TextAlign.left),                                _buildCellText(info.viewingYear", "textAlign: TextAlign.left),\n                                _buildCellText(info.viewingYear")

with open("E:/Tu vi online/frontend/lib/widgets/center_info.dart", "w", encoding="utf-8") as f:
    f.write(content)

