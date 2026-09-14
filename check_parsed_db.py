import json
import sys

if hasattr(sys.stdout, 'reconfigure'):
    sys.stdout.reconfigure(encoding='utf-8')

with open('E:\\Tu vi online\\thansat_226_parsed.json', 'r', encoding='utf-8') as f:
    db = json.load(f)

for star in db[:5]:
    print(star['ten_sao'])
    print(star['y_nghia'])
    print("---")
