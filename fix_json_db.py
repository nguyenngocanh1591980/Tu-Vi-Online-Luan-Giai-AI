import json

db_path = r'E:\Tu vi online\than_sat_db.json'
with open(db_path, 'r', encoding='utf-8') as f:
    db = json.load(f)

for s in db:
    if 'Bát Chuyên' in s['ten_sao']:
        s['phan_loai'] = 'Hung Tinh'
        if 'Hung Tinh.' in s['ghi_chu']:
            s['ghi_chu'].remove('Hung Tinh.')
    elif 'Bát Ma' in s['ten_sao']:
        s['phan_loai'] = 'Hung Tinh'
        if 'Hung Tin' in s['ghi_chu']:
            s['ghi_chu'].remove('Hung Tin')

with open(db_path, 'w', encoding='utf-8') as f:
    json.dump(db, f, ensure_ascii=False, indent=2)

print("Fixed")
