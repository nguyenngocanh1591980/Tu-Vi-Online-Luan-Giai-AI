# -*- coding: utf-8 -*-
import re

with open("E:/Tu vi online/frontend/lib/widgets/tu_vi_chart.dart", "r", encoding="utf-8") as f:
    content = f.read()

content = content.replace("CenterInfo(info: data.native, isFullMode: isFullMode)", "CenterInfo(info: data.native, isFullMode: isFullMode, palaces: data.palaces)")

with open("E:/Tu vi online/frontend/lib/widgets/tu_vi_chart.dart", "w", encoding="utf-8") as f:
    f.write(content)

