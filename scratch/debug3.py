import sys, json

for enc in ['utf-8', 'utf-8-sig', 'utf-16', 'cp1252']:
    try:
        with open(r'e:\Tu vi online\APIGateway_CS\Controllers\RbacController.cs', 'r', encoding=enc) as f:
            content = f.read()
        with open(r'e:\Tu vi online\scratch\debug_out.txt', 'w', encoding='utf-8') as out:
            out.write(f'Encoding: {enc}\n')
            out.write(f'Length: {len(content)}\n')
            out.write(f'Has CRLF: {chr(13)+chr(10) in content}\n')
            # Sample from around line 109
            lines = content.split('\n')
            out.write(f'Total lines: {len(lines)}\n')
            for i, line in enumerate(lines[105:115], start=106):
                out.write(f'{i}: {json.dumps(line)}\n')
        break
    except Exception as e:
        with open(r'e:\Tu vi online\scratch\debug_out.txt', 'a', encoding='utf-8') as out:
            out.write(f'{enc} failed: {e}\n')
