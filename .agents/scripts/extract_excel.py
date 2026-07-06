import sys
import os
import pandas as pd
import json

if sys.stdout.encoding != 'utf-8':
    sys.stdout.reconfigure(encoding='utf-8')

def extract_excel(file_path):
    try:
        xls = pd.ExcelFile(file_path)
        all_text = []
        for sheet_name in xls.sheet_names:
            df = pd.read_excel(xls, sheet_name=sheet_name)
            all_text.append(f"## Sheet: {sheet_name}")
            all_text.append(df.to_markdown(index=False))
        
        md_content = "\n\n".join(all_text)
        
        # Tạo tên file từ file gốc
        base_name = os.path.basename(file_path)
        title = os.path.splitext(base_name)[0]
        safe_name = title.lower().replace(' ', '-').replace(':', '').replace('/', '-')
        
        yaml_header = f"---\nname: {safe_name}\ndescription: Dữ liệu bảng từ {title}\ntier: 1\n---\n# {title}\n\n"
        
        out_dir = r"E:\Tu vi online\.agents\skill"
        os.makedirs(out_dir, exist_ok=True)
        out_path = os.path.join(out_dir, f"{safe_name}.md")
        
        with open(out_path, "w", encoding="utf-8") as f:
            f.write(yaml_header + md_content)
        print(f"Đã xuất thành công: {out_path}")
    except Exception as e:
        print(f"Error reading {file_path}: {e}")

if __name__ == "__main__":
    if len(sys.argv) > 1:
        extract_excel(sys.argv[1])
    else:
        print("Usage: python extract_excel.py <path_to_excel_file>")
