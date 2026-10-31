import psycopg2
import sys

sys.stdout.reconfigure(encoding='utf-8')

try:
    conn = psycopg2.connect(
        dbname='TuviAIManagerDB',
        user='postgres',
        password='postgres',
        host='localhost',
        port=5432
    )
    cur = conn.cursor()
    cur.execute('SELECT "Id", "Username", "Role", "StarLevel", "RankTitle", "Badge", "BadgeType" FROM "Users" ORDER BY "Id";')
    rows = cur.fetchall()
    print(f'Total Users: {len(rows)}')
    for r in rows:
        print(r)
    conn.close()
except Exception as e:
    print('Error:', e)
