import json
db = json.load(open('than_sat_db_new.json', encoding='utf-8'))
for s in db:
    if s['phan_loai'] == 'Không rõ':
        print(f"--- {s['ten_sao']} ---")
        print("Ý nghĩa:", s['y_nghia'])
        print("Ghi chú:", s['ghi_chu'])
