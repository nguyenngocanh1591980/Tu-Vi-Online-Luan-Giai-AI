import urllib.request
import json

output = []
try:
    req = urllib.request.Request('http://localhost:5000/api/v1/forum/users?pageSize=50')
    with urllib.request.urlopen(req) as resp:
        data = json.loads(resp.read().decode('utf-8'))
        users = data.get('items', []) or data.get('users', [])
        output.append(f"Total users found: {len(users)}")
        for u in users:
            uid = u.get('id')
            uname = u.get('username')
            role = u.get('role')
            badge = u.get('badge') or u.get('badgeText')
            output.append(f"User: id={uid}, username={uname}, role={role}, badge={badge}")
except Exception as e:
    output.append(f"Error querying users: {e}")

try:
    req2 = urllib.request.Request('http://localhost:5000/api/v1/forum/board-members?pageSize=10')
    with urllib.request.urlopen(req2) as resp2:
        data2 = json.loads(resp2.read().decode('utf-8'))
        items = data2.get('items', [])
        output.append(f"\nTotal board members (page 1): {len(items)}")
        for b in items:
            bid = b.get('id')
            bname = b.get('username') or b.get('name')
            group = b.get('groupLevel')
            rank = b.get('rank')
            output.append(f"BoardMember: id={bid}, username={bname}, group={group}, rank={rank}")
except Exception as e:
    output.append(f"Error querying board members: {e}")

with open(r'e:\Tu vi online\scratch\db_result.txt', 'w', encoding='utf-8') as f:
    f.write('\n'.join(output))
print("Done writing to db_result.txt")
