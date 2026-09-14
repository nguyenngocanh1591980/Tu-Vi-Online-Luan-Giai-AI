import json
with open('E:\\Tu vi online\\logic_service\\shen_sha_list.json', 'r', encoding='utf-8') as f:
    try:
        data = json.load(f)
        print("utf-8 success:", data[:5])
    except Exception as e:
        print("utf-8 failed", e)

with open('E:\\Tu vi online\\logic_service\\all_stars.json', 'r', encoding='utf-8') as f:
    try:
        data = json.load(f)
        for k in list(data.keys())[:2]:
            print(k, data[k][:2])
    except Exception as e:
        print("all_stars failed", e)
