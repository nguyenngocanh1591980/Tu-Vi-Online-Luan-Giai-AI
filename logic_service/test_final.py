import json
from ai_engine.ho_ngoc_duc_almanac import calculate_almanac_full

d1 = calculate_almanac_full(25, 6, 2026)
print("--- 25/06/2026 ---")
print("Month CC:", d1['month_stem_branch'])
print("Tiet Khi:", d1['tiet_khi'])
print("Sao 28:", d1['sao_28'])
print("Sao Tot:", d1['sao_tot'])
print("Sao Xau:", d1['sao_xau'])

d2 = calculate_almanac_full(29, 4, 2028)
print("\n--- 29/04/2028 ---")
print("Month CC:", d2['month_stem_branch'])
print("Tiet Khi:", d2['tiet_khi'])
print("Sao 28:", d2['sao_28'])
print("Sao Tot:", d2['sao_tot'])
print("Sao Xau:", d2['sao_xau'])
