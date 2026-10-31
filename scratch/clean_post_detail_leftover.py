with open(r'E:\Tu vi online\frontend\lib\screens\forum\post_detail_screen.dart', 'r', encoding='utf-8') as f:
    lines = f.readlines()

# Target line indices:
# lines[833] is '  // Module 2: Trả lời kèm trích dẫn (Tự động bọc [quote] và ghim Nội quy nếu có)\n'
# lines[862] is '    quoteText += ...' up to line 874 '  }\n'

# Let's inspect around lines 830-880
clean_lines = []
skip = False
for i, l in enumerate(lines):
    if i == 833 and 'Tự động bọc [quote] và ghim Nội quy' in l:
        continue # remove duplicate comment
    if i >= 862 and i <= 873:
        continue # remove leftover code
    clean_lines.append(l)

with open(r'E:\Tu vi online\frontend\lib\screens\forum\post_detail_screen.dart', 'w', encoding='utf-8') as f:
    f.writelines(clean_lines)

print('Cleaned post_detail_screen.dart successfully!')
