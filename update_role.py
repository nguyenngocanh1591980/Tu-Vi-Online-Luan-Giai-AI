import psycopg2

try:
    conn = psycopg2.connect(host='localhost', port=5432, dbname='TuviAIManagerDB', user='postgres', password='postgres')
    cur = conn.cursor()
    cur.execute('UPDATE "Users" SET "Role" = %s WHERE "Username" = %s', ('Super_Admin', 'SuperAdmin'))
    conn.commit()
    print("Role updated to Super_Admin!")
except Exception as e:
    print('Error:', e)
