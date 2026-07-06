import pandas as pd
df1 = pd.read_excel(r'E:\Tu vi online\AI học tử vi\Các Sao Lưu Tiểu Vận.xlsx')
df2 = pd.read_excel(r'E:\Tu vi online\AI học tử vi\Các Sao Lưu Đại Vận.xlsx')
with open(r'E:\Tu vi online\rules.txt', 'w', encoding='utf-8') as f:
    f.write('TIỂU VẬN:\n' + df1.to_string() + '\n\nĐẠI VẬN:\n' + df2.to_string())
