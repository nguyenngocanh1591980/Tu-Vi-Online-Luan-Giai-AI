# -*- coding: utf-8 -*-
import re
import sys
sys.stdout.reconfigure(encoding="utf-8")

files = [
    "E:/Tu vi online/frontend/lib/widgets/center_info.dart",
    "E:/Tu vi online/frontend/lib/widgets/palace_cell.dart",
    "E:/Tu vi online/frontend/lib/AI học tử vi/an_hon_100_sao_bang_dart_co_the_chinh_sua.dart"
]

for file in files:
    try:
        with open(file, "r", encoding="utf-8") as f:
            content = f.read()
            count_dv = content.count("L.DV")
            count_ddv = content.count("L.ĐV")
            print(f"{file.split('/')[-1]}: L.DV={count_dv}, L.ĐV={count_ddv}")
    except Exception as e:
        print(e)

