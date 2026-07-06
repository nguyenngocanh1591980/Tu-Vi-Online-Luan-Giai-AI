import pandas as pd
import json

df = pd.read_excel('E:\\Tu vi online\\AI học tử vi\\Bảng An Phạm Giờ Sinh Ý nghĩa và Cách Hóa Giải.xlsx', sheet_name=None)
with open('temp_pham_gio.json', 'w', encoding='utf-8') as f:
    json.dump({k: v.to_dict(orient='records') for k, v in df.items()}, f, ensure_ascii=False, indent=2)
