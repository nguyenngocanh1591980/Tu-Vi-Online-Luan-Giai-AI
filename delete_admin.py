import psycopg2

try:
    conn = psycopg2.connect(host='localhost', port=5432, dbname='TuvionlineManagerDB', user='postgres', password='postgres')
    conn.autocommit = False
    cur = conn.cursor()
    
    user_id = 5
    
    # Try to delete from related tables first
    cur.execute('DELETE FROM "SavedCharts" WHERE "UserId" = %s', (user_id,))
    cur.execute('DELETE FROM "Transactions" WHERE "UserId" = %s', (user_id,))
    cur.execute('DELETE FROM "Contracts" WHERE "UserId" = %s', (user_id,))
    
    # Forum related tables
    cur.execute('DELETE FROM "ForumTopicReplies" WHERE "AuthorId" = %s', (user_id,))
    cur.execute('DELETE FROM "ForumTopics" WHERE "AuthorId" = %s', (user_id,))
    cur.execute('DELETE FROM "Posts" WHERE "AuthorId" = %s', (user_id,))
    
    cur.execute('DELETE FROM "Users" WHERE "Id" = %s', (user_id,))
    
    conn.commit()
    print('Successfully deleted Admin user and related records from PostgreSQL.')
except Exception as e:
    conn.rollback()
    print('Error:', e)
