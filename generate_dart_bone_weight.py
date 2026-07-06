import pandas as pd
import math

file_path = "E:/Tu vi online/AI học tử vi/Bảng Cân Xương Tính Số Dựa theo Năm Tháng Ngày Sinh.xlsx"
df = pd.read_excel(file_path, sheet_name=0)

year_map = {}
month_map = {}
day_map = {}
hour_map = {}

for _, row in df.iterrows():
    # Year
    y_name = row.iloc[2]
    y_val = row.iloc[4]
    if pd.notna(y_name) and pd.notna(y_val):
        year_map[str(y_name).strip()] = float(y_val)
        
    # Month
    m_name = row.iloc[8]
    m_val = row.iloc[10]
    if pd.notna(m_name) and pd.notna(m_val):
        month_map[str(m_name).strip()] = float(m_val)
        
    # Day
    d_name = row.iloc[14]
    d_val = row.iloc[16]
    if pd.notna(d_name) and pd.notna(d_val):
        day_map[str(d_name).strip()] = float(d_val)
        
    # Hour
    h_name = row.iloc[20]
    h_val = row.iloc[22]
    if pd.notna(h_name) and pd.notna(h_val):
        hour_map[str(h_name).strip()] = float(h_val)

dart_code = f"""// AUTO-GENERATED

class BoneWeightData {{
  static const Map<String, double> yearWeight = {year_map};
  
  static const Map<String, double> monthWeight = {month_map};
  
  static const Map<String, double> dayWeight = {day_map};
  
  static const Map<String, double> hourWeight = {hour_map};
}}
"""

with open('E:/Tu vi online/frontend/lib/utils/bone_weight_data.dart', 'w', encoding='utf-8') as f:
    f.write(dart_code)

print("Done generating bone_weight_data.dart")
