import os
import sys
import json

sys.path.append(r"E:\Tu vi online")
from core_engine import get_than_sat

def categorize_stars(star_list, db_json):
    """
    Groups:
    1. Xây Dựng
    2. Hôn Thú
    3. Công Danh/Tài Lộc
    4. Xuất Hành
    5. Tang Sự
    6. Nhóm Khác
    """
    categories = {
        "Xây Dựng / Động Thổ": [],
        "Hôn Thú / Cưới Hỏi": [],
        "Công Danh / Tài Lộc": [],
        "Xuất Hành / Di Chuyển": [],
        "Tang Sự / Mai Táng": [],
        "Nhóm Khác": []
    }
    
    # Define keywords
    kw_xay_dung = ["tu tạo", "động thổ", "thượng lương", "nhập trạch", "xây cất", "làm nhà", "phá thổ", "sửa nhà", "khởi công"]
    kw_hon_thu = ["giá thú", "kết hôn", "cưới hỏi", "nạp thái", "vấn danh", "cưới", "hôn nhân"]
    kw_cong_danh = ["khai trương", "giao dịch", "nhậm chức", "tài lộc", "cầu tài", "nạp tài", "mua bán", "khai thị", "nhập học", "phó nhậm"]
    kw_xuat_hanh = ["xuất hành", "đi xa", "xuất sư", "hành quân"]
    kw_tang_su = ["an táng", "mai táng", "tang lễ", "khấp khốc", "tẩm liệm", "đào huyệt"]

    for sao_full in star_list:
        sao_name = sao_full.replace("(Theo giờ)", "").strip()
        
        # Find in db_json
        matched = False
        star_info = next((s for s in db_json if s["ten_sao"].startswith(sao_name)), None)
        # Handle cases where sao_name has extra tags or prefixes not perfectly matching
        if not star_info:
            # try fuzzy match
            base_name = sao_name.split(' - ')[0] if ' - ' in sao_name else sao_name
            star_info = next((s for s in db_json if base_name in s["ten_sao"]), None)

        if star_info and "y_nghia" in star_info:
            text = " ".join(star_info["y_nghia"]).lower()
            
            # Xây dựng
            if any(k in text for k in kw_xay_dung):
                categories["Xây Dựng / Động Thổ"].append(sao_full)
                matched = True
            # Hôn Thú
            if any(k in text for k in kw_hon_thu):
                categories["Hôn Thú / Cưới Hỏi"].append(sao_full)
                matched = True
            # Công Danh
            if any(k in text for k in kw_cong_danh):
                categories["Công Danh / Tài Lộc"].append(sao_full)
                matched = True
            # Xuất Hành
            if any(k in text for k in kw_xuat_hanh):
                categories["Xuất Hành / Di Chuyển"].append(sao_full)
                matched = True
            # Tang Sự
            if any(k in text for k in kw_tang_su):
                categories["Tang Sự / Mai Táng"].append(sao_full)
                matched = True
                
        if not matched:
            categories["Nhóm Khác"].append(sao_full)
            
    # Deduplicate within categories (in case a star has multiple keywords matching the same category somehow)
    for k in categories:
        categories[k] = list(dict.fromkeys(categories[k]))
        
    return categories

def generate_than_sat_html(gio_chi, tot, xau, db_json):
    cat_grouped = categorize_stars(tot, db_json)
    hung_grouped = categorize_stars(xau, db_json)
    
    html = f"""
    <div class="than-sat-container">
        <h2>Kết quả Thần Sát - Giờ {gio_chi.capitalize()}</h2>
"""
    
    for group_name in cat_grouped.keys():
        tot_group = cat_grouped[group_name]
        xau_group = hung_grouped[group_name]
        
        # Only show accordion if there are stars in this group
        if not tot_group and not xau_group:
            continue
            
        html += f"""
        <details class="accordion-group">
            <summary class="accordion-header">[+] Nhóm {group_name}</summary>
            <div class="accordion-content">
                
                <!-- PANEL CÁT TINH -->
                <div class="panel panel-cat">
                    <h3>Cát Tinh (Tốt)</h3>
                    <ul>
"""
        if not tot_group:
            html += '                        <li class="empty-state"><i>Không có sao chiếu</i></li>\n'
        else:
            for sao in tot_group:
                if "(Theo giờ)" in sao:
                    s = sao.replace("(Theo giờ)", "").strip()
                    html += f'                        <li>{s} <span class="badge badge-gio"><i class="icon-clock"></i> Giờ</span></li>\n'
                else:
                    html += f'                        <li>{sao}</li>\n'
        html += """                    </ul>
                </div>
                
                <!-- PANEL HUNG TINH -->
                <div class="panel panel-hung">
                    <h3>Hung Tinh (Xấu)</h3>
                    <ul>
"""
        if not xau_group:
            html += '                        <li class="empty-state"><i>Không có sao chiếu</i></li>\n'
        else:
            for sao in xau_group:
                if "(Theo giờ)" in sao:
                    s = sao.replace("(Theo giờ)", "").strip()
                    html += f'                        <li>{s} <span class="badge badge-gio"><i class="icon-clock"></i> Giờ</span></li>\n'
                else:
                    html += f'                        <li>{sao}</li>\n'
                    
        html += """                    </ul>
                </div>
            </div>
        </details>
"""
    html += "    </div>\n"
    return html

# --- DATA FETCHING ---
db_path = r'E:\Tu vi online\than_sat_db.json'
with open(db_path, 'r', encoding='utf-8') as f:
    db = json.load(f)

tot_ty, xau_ty = get_than_sat('6', 'bính', 'bính', 'ngọ', selected_hour_chi='tý')
tot_mao, xau_mao = get_than_sat('6', 'bính', 'bính', 'ngọ', selected_hour_chi='mão')

css = """
<style>
    body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background-color: #f4f7f6; padding: 20px; }
    .than-sat-container { max-width: 800px; margin: 0 auto 30px; background: #fff; padding: 20px; border-radius: 12px; box-shadow: 0 4px 12px rgba(0,0,0,0.05); }
    .than-sat-container h2 { text-align: center; color: #333; margin-top: 0; padding-bottom: 10px; border-bottom: 2px solid #ddd; }
    
    /* Accordion Details & Summary */
    .accordion-group { border: 1px solid #ddd; border-radius: 8px; margin-bottom: 10px; overflow: hidden; background: #fff; }
    .accordion-header { background: #f8f9fa; padding: 12px 15px; font-weight: bold; color: #0056b3; cursor: pointer; user-select: none; transition: background 0.2s; }
    .accordion-header:hover { background: #e9ecef; }
    .accordion-header::marker { content: ''; } /* Hide default arrow in some browsers */
    details[open] .accordion-header { background: #e9ecef; border-bottom: 1px solid #ddd; }
    
    .accordion-content { padding: 15px; display: flex; flex-direction: column; gap: 15px; background: #fafafa; }
    @media (min-width: 600px) {
        .accordion-content { flex-direction: row; }
        .panel { flex: 1; margin-bottom: 0 !important; }
    }
    
    .panel { border-radius: 8px; padding: 15px; }
    .panel h3 { margin-top: 0; border-bottom: 2px solid; padding-bottom: 10px; }
    .panel ul { list-style: none; padding-left: 0; margin-bottom: 0; }
    .panel li { padding: 8px 10px; margin-bottom: 5px; border-radius: 4px; background: rgba(255,255,255,0.7); display: flex; align-items: center; justify-content: space-between; }
    
    /* Colors (Cát Tinh = Xanh / Hung Tinh = Đỏ) */
    .panel-cat { background-color: #e8f5e9; border: 1px solid #c8e6c9; }
    .panel-cat h3 { color: #2e7d32; border-color: #a5d6a7; }
    .panel-cat li { color: #1b5e20; }
    
    .panel-hung { background-color: #ffebee; border: 1px solid #ffcdd2; }
    .panel-hung h3 { color: #c62828; border-color: #ef9a9a; }
    .panel-hung li { color: #b71c1c; }
    
    /* Badge "Giờ" */
    .badge { padding: 4px 8px; border-radius: 12px; font-size: 0.75em; font-weight: bold; }
    .badge-gio { background-color: #ff9800; color: white; }
    .panel-cat .badge-gio { background-color: #1976d2; }
    
    /* Empty State */
    .empty-state { color: #9e9e9e !important; background: transparent !important; justify-content: center !important; }
</style>
"""

full_html = f"""
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <title>UI Mockup - Accordion Thần Sát</title>
    {css}
</head>
<body>
    {generate_than_sat_html('Tý', tot_ty, xau_ty, db)}
    {generate_than_sat_html('Mão', tot_mao, xau_mao, db)}
</body>
</html>
"""

# Save to artifact directory
artifact_path = r"C:\Users\ngocanh\.gemini\antigravity\brain\1c4b8e39-d91f-4cfb-9e66-0281feb9a931\ui_mockup_accordion.html"
with open(artifact_path, "w", encoding="utf-8") as f:
    f.write(full_html)

# Extract and print just the Xây Dựng block for Giờ Tý to console as requested
print("--- TEST LOG XÂY DỰNG ---")
html_output = generate_than_sat_html('Tý', tot_ty, xau_ty, db)
lines = html_output.split('\n')
in_xaydung = False
for line in lines:
    if "Nhóm Xây Dựng" in line:
        in_xaydung = True
    if in_xaydung:
        print(line)
    if in_xaydung and "</details>" in line:
        break
