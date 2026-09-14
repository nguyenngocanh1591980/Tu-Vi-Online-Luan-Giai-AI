import json
from ai_engine.ho_ngoc_duc_almanac import calculate_almanac_full

d = calculate_almanac_full(20, 7, 2027)
print("Sao 28:", d['sao_28'])
print("Tiet Khi:", d['tiet_khi'])
