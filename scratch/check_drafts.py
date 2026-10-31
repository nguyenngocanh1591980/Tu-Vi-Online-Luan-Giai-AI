import psycopg2
import sys

sys.stdout.reconfigure(encoding='utf-8')
conn = psycopg2.connect(host='localhost', port=5432, dbname='TuvionlineManagerDB', user='postgres', password='postgres')
cur = conn.cursor()
cur.execute('SELECT "Id", "Username", "TopicId", "Title", "CreatedAt" FROM "ForumDrafts" ORDER BY "Id" DESC;')
rows = cur.fetchall()
print(f"Total drafts found: {len(rows)}")
for r in rows:
    print(r)
conn.close()
