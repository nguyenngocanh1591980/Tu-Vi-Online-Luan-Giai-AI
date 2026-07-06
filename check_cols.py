# -*- coding: utf-8 -*-
with open("E:/Tu vi online/frontend/lib/widgets/palace_cell.dart", "r", encoding="utf-8") as f:
    content = f.read()

import re
matches = re.finditer(r"Column\s*\((.*?)\)", content, re.DOTALL)
for i, m in enumerate(matches):
    print(f"Column {i}:\n{m.group(1)[:200]}...\n")

