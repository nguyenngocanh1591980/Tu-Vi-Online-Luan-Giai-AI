"""
Unit tests cho Lịch Vạn Sự (Hồ Ngọc Đức & Tiết khí Ngũ Hổ Độn)
"""


from ai_engine.ho_ngoc_duc_almanac import calculate_almanac_full

def test_almanac_2028_08_01_blind_spot():
    """
    Test case điểm mù Tiết Khí:
    Ngày 01/08/2028 Dương lịch:
    - Bắt buộc trả về Âm lịch: 11/06 Âm lịch
    - Can Chi tháng: Kỷ Mùi (Tiết khí qua Tiểu Thử nhưng chưa sang Lập Thu)
    """
    res = calculate_almanac_full(1, 8, 2028, 0, 0)
    assert res['lunar_date'].startswith("11/6")
    assert res['month_stem_branch'] == "Kỷ Mùi"
    assert res['solar_date'] in ["01/08/2028", "01-08-2028", "1 tháng 8 năm 2028"]

def test_almanac_2026_07_31():
    """
    Test case 31/07/2026 Dương lịch:
    - Trả về Âm lịch: 18/06/2026
    - Can Chi ngày: Bính Ngọ
    - Can Chi tháng: Ất Mùi
    - Can Chi năm: Bính Ngọ
    """
    res = calculate_almanac_full(31, 7, 2026, 0, 0)
    assert res['lunar_date'].startswith("18/6")
    assert res['day_stem_branch'] == "Bính Ngọ"
    assert res['month_stem_branch'] == "Ất Mùi"
    assert res['year_stem_branch'] == "Bính Ngọ"

def test_almanac_required_fields():
    """
    Kiểm tra trả đủ 5 trường thông tin bổ sung:
    (1) Giờ xuất hành Lý Thuần Phong
    (2) Giờ Hoàng/Hắc đạo
    (3) Trực
    (4) Ngày kỵ
    (5) Sinh khắc Ngũ hành
    """
    res = calculate_almanac_full(1, 8, 2026, 12, 0)
    assert 'dong_1_gio_xuat_hanh' in res
    assert len(res['dong_1_gio_xuat_hanh']) == 12
    assert 'dong_2_gio_hoang_hac_dao' in res
    assert 'hoang_dao' in res['dong_2_gio_hoang_hac_dao']
    assert 'hac_dao' in res['dong_2_gio_hoang_hac_dao']
    assert 'dong_3_truc' in res
    assert 'dong_4_ngay_ky' in res
    assert 'dong_5_ngu_hanh' in res
