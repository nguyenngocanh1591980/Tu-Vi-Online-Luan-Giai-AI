import psycopg2

try:
    conn = psycopg2.connect(host='localhost', port=5432, dbname='TuvionlineManagerDB', user='postgres', password='postgres')
    conn.autocommit = False
    cur = conn.cursor()
    
    user_id = 5
    username = 'Admin'
    
    cur.execute('DELETE FROM "SavedCharts" WHERE "UserId" = %s', (user_id,))
    cur.execute('DELETE FROM "Transactions" WHERE "UserId" = %s', (user_id,))
    cur.execute('DELETE FROM "Posts" WHERE "UserId" = %s', (user_id,))
    
    cur.execute('DELETE FROM "ForumTopicReplies" WHERE "Author" = %s', (username,))
    cur.execute('DELETE FROM "ForumTopics" WHERE "Author" = %s', (username,))
    
    cur.execute('DELETE FROM "Users" WHERE "Id" = %s', (user_id,))
    
    conn.commit()
    print('Successfully deleted Admin user and related records from PostgreSQL.')
except Exception as e:
    conn.rollback()
    print('Error:', e)
