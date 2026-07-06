import pandas as pd
import json

df = pd.read_excel('E:\\Tu vi online\\AI học tử vi\\Bảng Sao Hạn Theo Tuổi Năm Xem.xlsx', sheet_name=None)
with open('temp_sao_han.json', 'w', encoding='utf-8') as f:
    json.dump({k: v.to_dict(orient='records') for k, v in df.items()}, f, ensure_ascii=False, indent=2)
