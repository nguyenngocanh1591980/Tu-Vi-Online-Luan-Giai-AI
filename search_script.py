import os

count = 0
for r, d, files in os.walk('.'):
    d[:] = [x for x in d if x not in ['.git', 'node_modules', 'venv', 'env', '.vscode', '__pycache__', 'bin', 'obj', 'build', '.dart_tool']]
    for f in files:
        if f.endswith(('.dart', '.py', '.cs', '.json', '.html', '.md', '.txt')):
            path = os.path.join(r, f)
            try:
                with open(path, 'r', encoding='utf-8') as file:
                    content = file.read()
                if 'Tị' in content or 'tị' in content:
                    print(f'Found in {path}')
                    count += 1
            except:
                pass

print(f'Total matches: {count}')
