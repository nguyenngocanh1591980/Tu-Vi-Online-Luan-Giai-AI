import json
with open('E:\\Tu vi online\\logic_service\\all_stars.json', 'r', encoding='utf-8') as f:
    data = json.load(f)
    print("all_stars type:", type(data))
    if isinstance(data, list):
        print("First 3 items:", json.dumps(data[:3], ensure_ascii=False, indent=2))
