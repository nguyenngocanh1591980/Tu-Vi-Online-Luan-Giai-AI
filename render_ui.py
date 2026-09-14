import os
import sys

sys.path.append(r"E:\Tu vi online")
from core_engine import get_than_sat

def generate_html(gio_chi, tot, xau):
    html = f"""
    <div class="than-sat-container">
        <h2>Kết quả Thần Sát - Giờ {gio_chi.capitalize()}</h2>
        
        <div class="panel panel-cat">
            <h3>Cát Tinh (Tốt)</h3>
            <ul>
"""
    if not tot:
        html += '                <li class="empty-state"><i>Không có sao chiếu</i></li>\n'
    else:
        for sao in tot:
            # Check for "(Theo giờ)"
            if "(Theo giờ)" in sao:
                sao_name = sao.replace("(Theo giờ)", "").strip()
                html += f'                <li>{sao_name} <span class="badge badge-gio"><i class="icon-clock"></i> Giờ</span></li>\n'
            else:
                html += f'                <li>{sao}</li>\n'
                
    html += """            </ul>
        </div>
        
        <div class="panel panel-hung">
            <h3>Hung Tinh (Xấu)</h3>
            <ul>
"""
    if not xau:
        html += '                <li class="empty-state"><i>Không có sao chiếu</i></li>\n'
    else:
        for sao in xau:
            if "(Theo giờ)" in sao:
                sao_name = sao.replace("(Theo giờ)", "").strip()
                html += f'                <li>{sao_name} <span class="badge badge-gio"><i class="icon-clock"></i> Giờ</span></li>\n'
            else:
                html += f'                <li>{sao}</li>\n'
                
    html += """            </ul>
        </div>
    </div>
"""
    return html

# --- DATA FETCHING ---
tot_ty, xau_ty = get_than_sat('6', 'bính', 'bính', 'ngọ', selected_hour_chi='tý')
tot_mao, xau_mao = get_than_sat('6', 'bính', 'bính', 'ngọ', selected_hour_chi='mão')

css = """
<style>
    body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background-color: #f4f7f6; padding: 20px; }
    .than-sat-container { max-width: 800px; margin: 0 auto 30px; background: #fff; padding: 20px; border-radius: 12px; box-shadow: 0 4px 12px rgba(0,0,0,0.05); }
    .than-sat-container h2 { text-align: center; color: #333; margin-top: 0; }
    .panel { border-radius: 8px; padding: 15px; margin-bottom: 15px; }
    .panel h3 { margin-top: 0; border-bottom: 2px solid; padding-bottom: 10px; }
    .panel ul { list-style: none; padding-left: 0; }
    .panel li { padding: 8px 10px; margin-bottom: 5px; border-radius: 4px; background: rgba(255,255,255,0.7); display: flex; align-items: center; justify-content: space-between; }
    
    /* Colors */
    .panel-cat { background-color: #e8f5e9; border: 1px solid #c8e6c9; }
    .panel-cat h3 { color: #2e7d32; border-color: #a5d6a7; }
    .panel-cat li { color: #1b5e20; }
    
    .panel-hung { background-color: #ffebee; border: 1px solid #ffcdd2; }
    .panel-hung h3 { color: #c62828; border-color: #ef9a9a; }
    .panel-hung li { color: #b71c1c; }
    
    /* Badge */
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
    <title>UI Mockup - Thần Sát</title>
    {css}
</head>
<body>
    {generate_html('Tý', tot_ty, xau_ty)}
    {generate_html('Mão', tot_mao, xau_mao)}
</body>
</html>
"""

# Save to artifact directory directly
artifact_path = r"C:\Users\ngocanh\.gemini\antigravity\brain\1c4b8e39-d91f-4cfb-9e66-0281feb9a931\ui_mockup.html"
with open(artifact_path, "w", encoding="utf-8") as f:
    f.write(full_html)

print("Đã render HTML vào Artifact!")
