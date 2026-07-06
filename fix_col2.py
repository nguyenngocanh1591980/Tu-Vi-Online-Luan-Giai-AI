# -*- coding: utf-8 -*-
import re

with open("E:/Tu vi online/frontend/lib/widgets/center_info.dart", "r", encoding="utf-8") as f:
    content = f.read()

old_col2 = "String col2 = _capitalizeWords(palace.name);"
new_col2 = """String cleanPalaceName = palace.name.replaceAll(RegExp(r'\\s*\\([^)]*\\)'), '').trim();
      String col2 = _capitalizeWords(cleanPalaceName);"""

content = content.replace(old_col2, new_col2)

with open("E:/Tu vi online/frontend/lib/widgets/center_info.dart", "w", encoding="utf-8") as f:
    f.write(content)

