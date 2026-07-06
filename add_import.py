# -*- coding: utf-8 -*-
import re

with open("E:/Tu vi online/frontend/lib/widgets/center_info.dart", "r", encoding="utf-8") as f:
    content = f.read()

content = content.replace("import '../models/tu_vi_palace.dart';", "import '../models/tu_vi_palace.dart';\nimport '../widgets/palace_cell.dart';")

with open("E:/Tu vi online/frontend/lib/widgets/center_info.dart", "w", encoding="utf-8") as f:
    f.write(content)

