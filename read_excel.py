import pandas as pd
import json

file_path = "E:/Tu vi online/AI học tử vi/Bảng Cân Xương Tính Số Dựa theo Năm Tháng Ngày Sinh.xlsx"
df = pd.read_excel(file_path, sheet_name=None)
out = {}
for k, v in df.items():
    out[k] = v.to_dict(orient='records')

with open('E:/Tu vi online/can_luong.json', 'w', encoding='utf-8') as f:
    json.dump(out, f, ensure_ascii=False, indent=2)

print("Done")
