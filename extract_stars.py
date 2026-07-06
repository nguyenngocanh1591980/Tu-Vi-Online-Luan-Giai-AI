# -*- coding: utf-8 -*-
with open("E:/Tu vi online/frontend/lib/AI học tử vi/an_hon_100_sao_bang_dart_co_the_chinh_sua.dart", "r", encoding="utf-8") as f:
    lines = f.readlines()

for i, line in enumerate(lines):
    if "List<String> chinhTinhNames =" in line or "List<String> chinhTinhElements =" in line:
        print(f"Line {i}: {line.strip()}")

