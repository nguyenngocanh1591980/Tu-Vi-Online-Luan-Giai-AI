import psycopg2
import bcrypt
import sys

try:
    conn = psycopg2.connect(host='localhost', port=5432, dbname='TuvionlineManagerDB', user='postgres', password='postgres')
    cur = conn.cursor()
    
    # Check if SuperAdmin exists
    cur.execute('SELECT "Id" FROM "Users" WHERE "Username" = %s', ('SuperAdmin',))
    row = cur.fetchone()
    
    if not row:
        password_hash = bcrypt.hashpw(b'Superadmin@1980', bcrypt.gensalt()).decode()
        
        insert_query = """
            INSERT INTO "Users" (
                "Username", "Role", "PasswordHash", "Email", "PreferredLanguage", "LanguageCode", "IsEmailVerified", "IsInvisible", "CoinBalance"
            ) VALUES (
                %s, %s, %s, %s, %s, %s, %s, %s, %s
            )
        """
        cur.execute(insert_query, (
            'SuperAdmin', 'Super_Admin', password_hash, 'superadmin@tuvionline.vn', 'vi', 'vi', True, False, 0
        ))
        conn.commit()
        print("Successfully created SuperAdmin")
    else:
        print("SuperAdmin already exists")
        
except Exception as e:
    print('Error:', e)
