import psycopg2

def fix_duplicates():
    conn = psycopg2.connect(
        host="localhost",
        port=5432,
        dbname="TuvionlineManagerDB",
        user="postgres",
        password="postgres"
    )
    cur = conn.cursor()
    
    # Get all saved charts
    cur.execute('SELECT "Id", "UserId", "ChartName" FROM "SavedCharts" ORDER BY "Id" ASC')
    rows = cur.fetchall()
    
    seen = set()
    for row in rows:
        c_id, user_id, name = row
        name = name.strip() if name else "Chưa đặt tên"
        
        key = (user_id, name.lower())
        if key in seen:
            # duplicate found
            counter = 1
            new_name = f"{name} ({counter})"
            new_key = (user_id, new_name.lower())
            while new_key in seen:
                counter += 1
                new_name = f"{name} ({counter})"
                new_key = (user_id, new_name.lower())
            
            # Update the row
            print(f"Renaming duplicate {name} to {new_name} for user {user_id}")
            cur.execute('UPDATE "SavedCharts" SET "ChartName" = %s WHERE "Id" = %s', (new_name, c_id))
            seen.add(new_key)
        else:
            cur.execute('UPDATE "SavedCharts" SET "ChartName" = %s WHERE "Id" = %s', (name, c_id))
            seen.add(key)
            
    conn.commit()
    cur.close()
    conn.close()

if __name__ == "__main__":
    fix_duplicates()
