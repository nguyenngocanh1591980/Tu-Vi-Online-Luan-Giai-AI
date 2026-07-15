import psycopg2

def delete_charts():
    conn = psycopg2.connect(
        host="localhost",
        port=5432,
        dbname="TuvionlineManagerDB",
        user="postgres",
        password="postgres"
    )
    cur = conn.cursor()
    
    cur.execute('DELETE FROM "SavedCharts"')
    deleted_count = cur.rowcount
    print(f"Deleted {deleted_count} charts.")
            
    conn.commit()
    cur.close()
    conn.close()

if __name__ == "__main__":
    delete_charts()
