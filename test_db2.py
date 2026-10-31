import psycopg2
import sys
import io

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

try:
    conn = psycopg2.connect(host='localhost', port=5432, dbname='TuviAIManagerDB', user='postgres', password='postgres')
    cur = conn.cursor()
    cur.execute('SELECT "Id", "Username", "Role" FROM "Users"')
    for row in cur.fetchall():
        print(row)
except Exception as e:
    print('Error:', e)
