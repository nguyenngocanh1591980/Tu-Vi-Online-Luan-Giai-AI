# -*- coding: utf-8 -*-
import re

with open("E:/Tu vi online/frontend/lib/widgets/center_info.dart", "r", encoding="utf-8") as f:
    content = f.read()

content = content.replace("import '../models/tu_vi_palace.dart';\n", "")
content = content.replace("final List<TuViPalace>? palaces;", "final List<Palace>? palaces;")

with open("E:/Tu vi online/frontend/lib/widgets/center_info.dart", "w", encoding="utf-8") as f:
    f.write(content)

