import re

files = [
    r"e:\Tu vi online\frontend\lib\widgets\palace_cell.dart",
    r"e:\Tu vi online\frontend\lib\widgets\center_info.dart",
    r"e:\Tu vi online\frontend\lib\widgets\tu_vi_chart.dart",
]

def replace_font_size(match):
    if len(match.groups()) == 1:
        num = int(match.group(1))
        return f"fontSize: {num + 3}"
    elif len(match.groups()) == 2:
        num1 = int(match.group(1))
        num2 = int(match.group(2))
        return f"fontSize: isFullMode ? {num1 + 3} : {num2 + 3}"

for f in files:
    with open(f, 'r', encoding='utf-8') as file:
        content = file.read()
    
    # Replace fontSize: isFullMode ? 10 : 11
    content = re.sub(r'fontSize:\s*isFullMode\s*\?\s*(\d+)\s*:\s*(\d+)', replace_font_size, content)
    
    # Replace fontSize: 11
    content = re.sub(r'fontSize:\s*(\d+)', replace_font_size, content)
    
    with open(f, 'w', encoding='utf-8') as file:
        file.write(content)

print("Done")
