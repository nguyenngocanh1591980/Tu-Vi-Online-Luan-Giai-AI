import psycopg2

conn = psycopg2.connect(
    host="localhost",
    port=5432,
    database="TuvionlineManagerDB",
    user="postgres",
    password="postgres"
)
conn.autocommit = True
cur = conn.cursor()

# Get users
cur.execute('SELECT "Id", "Username", "Email" FROM "Users";')
users = cur.fetchall()
print("Current users in PostgreSQL DB:")
for u in users:
    print(f"ID: {u[0]}, Username: {u[1]}, Email: {u[2]}")
