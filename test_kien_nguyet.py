import json
import sys
from core_engine import get_than_sat, get_thang_kien

def run_mock_test():
    print("="*60)
    print("MOCK TEST: KIẾN NGUYỆT MAPPING (Tháng Âm Lịch Số -> Địa Chi)")
    print("="*60)
    
    thang_so = "6"
    can_nam = "Bính"
    
    # Test case: Tháng 6 Âm (Mùi). 
    # Bàng Phế (Mùi -> Nhâm/Quý)
    # Bạch Hổ Hắc Đạo (Tháng 6/Thìn -> Thìn)
    # Do đó ta chọn Ngày Nhâm Thìn.
    can_ngay = "nhâm"
    chi_ngay = "thìn"
    gio = "tý"
    
    print(f"[INPUT] Tháng Âm Lịch: {thang_so}")
    print(f"[INPUT] Năm: {can_nam}")
    print(f"[INPUT] Ngày: {can_ngay.capitalize()} {chi_ngay.capitalize()}")
    
    thang_kien = get_thang_kien(thang_so)
    print(f"\n[MAPPING] Gọi hàm get_thang_kien({thang_so}) -> Kết quả: '{thang_kien.capitalize()}'")
    print(f"-> Engine sẽ dùng '{thang_kien}' để tra cứu trong DB.\n")
    
    print("Đang gọi hàm get_than_sat()...")
    
    sao_tot, sao_xau = get_than_sat(thang_so, can_nam, can_ngay, chi_ngay, selected_hour_chi=gio)
    
    print("\n[KẾT QUẢ TRẢ VỀ TỪ CORE ENGINE]")
    print("--- Cát Tinh ---")
    for s in sao_tot:
        print(f" - {s}")
        
    print("\n--- Hung Tinh ---")
    bang_phe_found = False
    bach_ho_found = False
    for s in sao_xau:
        print(f" - {s}")
        if "Bàng Phế" in s: bang_phe_found = True
        if "Bạch Hổ" in s: bach_ho_found = True
        
    print("\n[VERDICT]")
    if bang_phe_found and bach_ho_found:
        print("✅ SUCCESS: Đã tìm thấy Bàng Phế và Bạch Hổ Hắc Đạo!")
        print("-> Thuật toán Kiến Nguyệt Mapping đã hoạt động chính xác.")
    else:
        print("❌ FAILED: Thiếu Bàng Phế hoặc Bạch Hổ Hắc Đạo.")
        
if __name__ == "__main__":
    run_mock_test()
