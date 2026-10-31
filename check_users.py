import psycopg2

try:
    conn = psycopg2.connect(host='localhost', port=5432, dbname='TuvionlineManagerDB', user='postgres', password='postgres')
    cur = conn.cursor()
    cur.execute('SELECT "Id", "Username", "Email" FROM "Users"')
    print(cur.fetchall())
except Exception as e:
    print('Error:', e)
