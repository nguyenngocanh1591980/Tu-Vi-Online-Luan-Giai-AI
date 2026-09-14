import sys
import os

# Add parent directory to path to import core_engine
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

from core_engine import get_can_gio
from ho_ngoc_duc_almanac import calculate_almanac_full, CHI_12

def test_ngay_binh_ngo():
    # 16:00 is Thân hour. 
    # ((16 + 1) % 24) // 2 = (17) // 2 = 8
    # CHI_12[8] is "Thân"
    
    hour = 16
    hour_idx = ((hour + 1) % 24) // 2
    selected_hour_chi = CHI_12[hour_idx]
    
    # Ngày Bính Ngọ
    can_ngay = "Bính"
    chi_ngay = "Ngọ"
    
    can_gio = get_can_gio(can_ngay, selected_hour_chi)
    
    print(f"=============================")
    print(f"Ca test: Ngày {can_ngay} {chi_ngay} - {hour}:00")
    print(f"Địa Chi của Giờ: {selected_hour_chi}")
    print(f"Thiên Can của Giờ: {can_gio}")
    print(f"Kết quả hệ thống trả ra: Giờ {can_gio} {selected_hour_chi}")
    print(f"=============================")

if __name__ == "__main__":
    test_ngay_binh_ngo()
