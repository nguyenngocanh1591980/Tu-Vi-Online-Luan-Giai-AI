import json
import re

with open('e:/Tu vi online/temp_parsed_status.json', 'r', encoding='utf-8') as f:
    parsed_status = json.load(f)

with open('e:/Tu vi online/frontend/lib/AI học tử vi/star_data.dart', 'r', encoding='utf-8') as f:
    dart_code = f.read()

# Parse elements from existing dart code
elements = {}
for line in dart_code.split('\n'):
    match = re.search(r"'([^']+)':\s*StarData\('([^']+)',", line)
    if match:
        elements[match.group(1)] = match.group(2)

new_map_lines = []
new_map_lines.append('const Map<String, StarData> phuTinhData = {')

for star, el in elements.items():
    star_status = parsed_status.get(star, {})
    if star not in parsed_status:
        for k in parsed_status.keys():
            if k.replace(' ', '') == star.replace(' ', ''):
                star_status = parsed_status[k]
                break
                
    map_str_parts = []
    for k, v in star_status.items():
        map_str_parts.append(f"{k}: '{v}'")
    map_str = '{' + ', '.join(map_str_parts) + '}'
    
    new_map_lines.append(f"  '{star}': StarData('{el}', {map_str}),")

new_map_lines.append('};')

new_map_text = '\n'.join(new_map_lines)

dart_code_new = re.sub(r'const Map<String, StarData> phuTinhData = \{.*?\};', new_map_text, dart_code, flags=re.DOTALL)

with open('e:/Tu vi online/frontend/lib/AI học tử vi/star_data.dart', 'w', encoding='utf-8') as f:
    f.write(dart_code_new)

print('Updated star_data.dart successfully!')
