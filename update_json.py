import json

# Update users
with open('e:/Tu vi online/AIEngine_Python/forum_users_db.json', 'r', encoding='utf-8') as f:
    users = json.load(f)

# Keep everyone EXCEPT 'Admin' (ID 5)
users = [u for u in users if u['id'] != 5]

with open('e:/Tu vi online/AIEngine_Python/forum_users_db.json', 'w', encoding='utf-8') as f:
    json.dump(users, f, ensure_ascii=False, indent=4)

# Update stats
with open('e:/Tu vi online/AIEngine_Python/forum_stats_db.json', 'r', encoding='utf-8') as f:
    stats = json.load(f)

stats['general_stats']['members_count'] = len(users)

with open('e:/Tu vi online/AIEngine_Python/forum_stats_db.json', 'w', encoding='utf-8') as f:
    json.dump(stats, f, ensure_ascii=False, indent=4)

print('Updated JSON files successfully.')
