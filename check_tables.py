import psycopg2

try:
    conn = psycopg2.connect(host='localhost', port=5432, dbname='TuvionlineManagerDB', user='postgres', password='postgres')
    conn.autocommit = True
    cur = conn.cursor()
    
    tables = ['Contracts', 'Posts', 'Transactions', 'ForumTopics', 'ForumTopicReplies']
    for t in tables:
        cur.execute(f"SELECT column_name FROM information_schema.columns WHERE table_name='{t}'")
        cols = cur.fetchall()
        print(f"{t}:", cols)
except Exception as e:
    print('Error:', e)
