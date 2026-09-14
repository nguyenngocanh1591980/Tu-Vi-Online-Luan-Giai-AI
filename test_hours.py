import sys
import json
sys.path.append(r'E:\Tu vi online\logic_service')
from ai_engine.ho_ngoc_duc_almanac import calculate_almanac_full

print("Finding which hour gives exactly the stars in the screenshot...")
target_sao_tot = ['Đại Hồng Sa', 'Lục Hợp', 'Minh Tinh', 'Quan Nhật']
target_sao_xau = ['Bệnh Phù', 'Huyết Chi', 'Phá Bại – Destructive', 'Thiên Lao', 'Thọ Tử', 'Thổ Kỵ']

for h in range(0, 24, 2):
    res = calculate_almanac_full(31, 7, 2026, h, 0)
    print(f"--- Giờ {h}:00 ---")
    
    tot = [s for s in res['sao_tot'] if s not in ['Minh Đường', 'Thiên Hình', 'Kim Quĩ']]
    xau = [s for s in res['sao_xau'] if s not in ['Minh Đường', 'Thiên Hình', 'Kim Quĩ']]
    print("sao_tot:", res['sao_tot'])
    print("sao_xau:", res['sao_xau'])
