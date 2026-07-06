# -*- coding: utf-8 -*-
import sys
sys.stdout.reconfigure(encoding="utf-8")
with open("E:/Tu vi online/frontend/lib/AI học tử vi/an_hon_100_sao_bang_dart_co_the_chinh_sua.dart", "r", encoding="utf-8") as f:
    lines = f.readlines()

for i, line in enumerate(lines):
    if "HÓA LỘC" in line or "HÓA QUYỀN" in line or "HÓA KHOA" in line or "HÓA KỴ" in line or "HOA LOC" in line or "HOA QUYEN" in line or "HOA KHOA" in line or "HOA KY" in line:
        print(f"Line {i}: {line.strip()}")

