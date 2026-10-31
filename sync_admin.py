import psycopg2
import json

try:
    conn = psycopg2.connect(host='localhost', port=5432, dbname='TuvionlineManagerDB', user='postgres', password='postgres')
    cur = conn.cursor()
    cur.execute('SELECT "Id", "Username", "Email", "Role", "CreatedAt" FROM "Users" WHERE "Username" ILIKE \'admin\'')
    row = cur.fetchone()
    
    if row:
        user_id, username, email, role, created_at = row
        new_user = {
            "id": user_id,
            "username": username,
            "email": email,
            "role": role,
            "posts": 0,
            "joinDate": created_at.strftime("%H:%M, %d/%m/%y"),
            "badgeText": "QU?N LÝ" if role == "Admin" else "H?I VIÊN",
            "badgeType": "badge_blue" if role == "Admin" else "badge_purple",
            "nameColor": "#EF5350" if role == "Admin" else "#AB47BC",
            "website": "",
            "isBold": True
        }
        
        with open('e:/Tu vi online/AIEngine_Python/forum_users_db.json', 'r', encoding='utf-8') as f:
            users = json.load(f)
            
        # Avoid duplicate
        users = [u for u in users if u['id'] != user_id]
        
        # Add to top
        users.insert(0, new_user)
        
        with open('e:/Tu vi online/AIEngine_Python/forum_users_db.json', 'w', encoding='utf-8') as f:
            json.dump(users, f, ensure_ascii=False, indent=4)
            
        print("Added Admin to forum_users_db.json!")
except Exception as e:
    print('Error:', e)
