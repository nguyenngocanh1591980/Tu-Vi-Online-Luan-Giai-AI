# -*- coding: utf-8 -*-
import re

with open("E:/Tu vi online/frontend/lib/widgets/center_info.dart", "r", encoding="utf-8") as f:
    content = f.read()

# Fix the startsWith check
content = content.replace("s.name.startsWith('L.DV ')", "s.name.startsWith('L.ĐV ')")
content = content.replace("else if (cleanName.startsWith('L.DV '))", "else if (cleanName.startsWith('L.DV '))") # leave the fallback

with open("E:/Tu vi online/frontend/lib/widgets/center_info.dart", "w", encoding="utf-8") as f:
    f.write(content)

