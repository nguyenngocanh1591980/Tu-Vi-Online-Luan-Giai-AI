import psycopg2

try:
    conn = psycopg2.connect(host='localhost', port=5432, dbname='TuvionlineManagerDB', user='postgres', password='postgres')
    conn.autocommit = True
    cur = conn.cursor()
    
    cur.execute('SELECT table_name FROM information_schema.tables WHERE table_schema=\'public\'')
    tables = cur.fetchall()
    print('Tables:', tables)
    
    cur.execute('SELECT "Id", "Username", "Email" FROM "Users" WHERE "Username" ILIKE \'admin\'')
    print('Users:', cur.fetchall())
except Exception as e:
    print('Error:', e)
