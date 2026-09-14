import os
import sys
import json

sys.path.append(r"E:\Tu vi online")
from core_engine import get_than_sat

def categorize_stars(star_list, db_json):
    categories = {
        "Xây Dựng / Động Thổ": [],
        "Hôn Thú / Gia Đạo": [],
        "Công Danh / Tài Lộc": [],
        "Đi Lại / Xuất Hành": [],
        "Tang Sự": [],
        "Nhóm Khác": []
    }
    
    kw_xay_dung = ["động thổ", "xây cất", "cất nhà", "đào ao", "dỡ nhà", "tu tạo", "làm bếp"]
    kw_hon_thu = ["cưới hỏi", "giá thú", "kết hôn", "nạp tài", "ăn hỏi"]
    kw_cong_danh = ["cầu tài", "nhậm chức", "mở kho", "khai trương", "giao dịch", "ký hợp đồng"]
    kw_xuat_hanh = ["xuất hành", "đi xa", "dời chỗ", "nhập trạch"]
    kw_tang_su = ["an táng", "mai táng", "cải táng", "động thổ mộ"]

    for sao_full in star_list:
        sao_name = sao_full.replace("(Theo giờ)", "").strip()
        base_name = sao_name.split(' - ')[0] if ' - ' in sao_name else sao_name
        
        star_info = next((s for s in db_json if base_name in s["ten_sao"]), None)
        matched = False

        if star_info and "y_nghia" in star_info:
            text = " ".join(star_info["y_nghia"]).lower()
            if any(k in text for k in kw_xay_dung):
                categories["Xây Dựng / Động Thổ"].append(sao_full)
                matched = True
            if any(k in text for k in kw_hon_thu):
                categories["Hôn Thú / Gia Đạo"].append(sao_full)
                matched = True
            if any(k in text for k in kw_cong_danh):
                categories["Công Danh / Tài Lộc"].append(sao_full)
                matched = True
            if any(k in text for k in kw_xuat_hanh):
                categories["Đi Lại / Xuất Hành"].append(sao_full)
                matched = True
            if any(k in text for k in kw_tang_su):
                categories["Tang Sự"].append(sao_full)
                matched = True
                
        if not matched:
            categories["Nhóm Khác"].append(sao_full)
            
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
        
        # Check empty state
        is_empty = not tot_group and not xau_group
        opacity_class = "opacity-50" if is_empty else ""
        
        html += f"""
        <details class="accordion-group {opacity_class}">
            <summary class="accordion-header">[+] {group_name}</summary>
            <div class="accordion-content">
"""
        if is_empty:
            html += '                <div style="width: 100%; text-align: center; color: #9e9e9e; font-style: italic;">Không có biến động</div>\n'
        else:
            html += """
                <!-- PANEL CÁT TINH -->
                <div class="panel panel-cat">
                    <h3>Cát Tinh (Tốt)</h3>
                    <ul>
"""
            if not tot_group:
                html += '                        <li class="empty-state"><i>Không có sao chiếu</i></li>\n'
            else:
                for sao in tot_group:
                    s = sao.replace("(Theo giờ)", "").strip() if "(Theo giờ)" in sao else sao
                    badge = ' <span class="badge badge-gio"><i class="icon-clock"></i> Giờ</span>' if "(Theo giờ)" in sao else ""
                    html += f'                        <li>{s}{badge}</li>\n'
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
                    s = sao.replace("(Theo giờ)", "").strip() if "(Theo giờ)" in sao else sao
                    badge = ' <span class="badge badge-gio"><i class="icon-clock"></i> Giờ</span>' if "(Theo giờ)" in sao else ""
                    html += f'                        <li>{s}{badge}</li>\n'
                    
            html += """                    </ul>
                </div>
"""
        html += """            </div>
        </details>
"""
    html += "    </div>\n"
    return html

# --- DATA FETCHING ---
db_path = r'E:\Tu vi online\than_sat_db.json'
with open(db_path, 'r', encoding='utf-8') as f:
    db = json.load(f)

tot_ty, xau_ty = get_than_sat('6', 'bính', 'bính', 'ngọ', selected_hour_chi='tý')

css = """
<style>
    body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background-color: #f4f7f6; padding: 20px; }
    .than-sat-container { max-width: 800px; margin: 0 auto 30px; background: #fff; padding: 20px; border-radius: 12px; box-shadow: 0 4px 12px rgba(0,0,0,0.05); }
    .than-sat-container h2 { text-align: center; color: #333; margin-top: 0; padding-bottom: 10px; border-bottom: 2px solid #ddd; }
    
    .accordion-group { border: 1px solid #ddd; border-radius: 8px; margin-bottom: 10px; overflow: hidden; background: #fff; transition: opacity 0.3s; }
    .opacity-50 { opacity: 0.6; }
    .accordion-header { background: #f8f9fa; padding: 12px 15px; font-weight: bold; color: #0056b3; cursor: pointer; user-select: none; transition: background 0.2s; }
    .accordion-header:hover { background: #e9ecef; }
    .accordion-header::marker { content: ''; } 
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
    
    .panel-cat { background-color: #e8f5e9; border: 1px solid #c8e6c9; }
    .panel-cat h3 { color: #2e7d32; border-color: #a5d6a7; }
    .panel-cat li { color: #1b5e20; }
    
    .panel-hung { background-color: #ffebee; border: 1px solid #ffcdd2; }
    .panel-hung h3 { color: #c62828; border-color: #ef9a9a; }
    .panel-hung li { color: #b71c1c; }
    
    .badge { padding: 4px 8px; border-radius: 12px; font-size: 0.75em; font-weight: bold; }
    .badge-gio { background-color: #ff9800; color: white; }
    .panel-cat .badge-gio { background-color: #1976d2; }
    .empty-state { color: #9e9e9e !important; background: transparent !important; justify-content: center !important; }
</style>
"""

full_html = f"""
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <title>UI Mockup - Advanced Category</title>
    {css}
</head>
<body>
    {generate_than_sat_html('Tý', tot_ty, xau_ty, db)}
</body>
</html>
"""

with open(r"C:\Users\ngocanh\.gemini\antigravity\brain\1c4b8e39-d91f-4cfb-9e66-0281feb9a931\ui_mockup_advanced.html", "w", encoding="utf-8") as f:
    f.write(full_html)

# Cấu trúc dữ liệu phân nhóm ngày Bính Ngọ (Giờ Tý) ra console:
cat_grouped = categorize_stars(tot_ty, db)
hung_grouped = categorize_stars(xau_ty, db)

print("=== LOGIC PHÂN NHÓM (Ngày Bính Ngọ - Giờ Tý) ===")
for group in cat_grouped.keys():
    print(f"[{group}]")
    print("  * Cát Tinh:", cat_grouped[group])
    print("  * Hung Tinh:", hung_grouped[group])
