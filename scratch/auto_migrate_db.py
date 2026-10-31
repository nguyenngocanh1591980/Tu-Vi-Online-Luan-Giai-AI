import psycopg2
import sys

sys.stdout.reconfigure(encoding='utf-8')

dang_vi_map = [
    "Nhất Đẳng", "Nhị Đẳng", "Tam Đẳng", "Tứ Đẳng", "Ngũ Đẳng",
    "Lục Đẳng", "Thất Đẳng", "Bát Đẳng", "Cửu Đẳng", "Thập Đẳng"
]

try:
    conn = psycopg2.connect(
        dbname='TuviAIManagerDB',
        user='postgres',
        password='postgres',
        host='localhost',
        port=5432
    )
    cur = conn.cursor()
    
    # 1. Chuẩn hóa MasterProfiles
    cur.execute('SELECT "Id", "MasterName", "StarLevel", "RankTitle", "TitleLogo" FROM "MasterProfiles";')
    masters = cur.fetchall()
    for m in masters:
        m_id, name, star, title, logo = m
        safe_star = max(1, min(10, star if star else 1))
        proper_title = dang_vi_map[safe_star - 1]
        proper_logo = f"/images/logo_dai_su_{safe_star}.png"
        
        cur.execute(
            'UPDATE "MasterProfiles" SET "StarLevel" = %s, "RankTitle" = %s, "TitleLogo" = %s WHERE "Id" = %s;',
            (safe_star, proper_title, proper_logo, m_id)
        )
    
    # 2. Chuẩn hóa Users có role User thành badge_purple
    cur.execute('''
        UPDATE "Users" 
        SET "BadgeType" = 'badge_purple',
            "Badge" = CASE 
                WHEN "StarLevel" > 1 THEN 'Thành viên - ' || "StarLevel" || ' sao' 
                ELSE 'Thành viên' 
            END
        WHERE "Role" = 'User' AND ("RankTitle" = 'Thành viên' OR "RankTitle" IS NULL);
    ''')
    
    conn.commit()
    print("Database auto-migration completed successfully!")
    
    # Check MasterProfiles
    cur.execute('SELECT "Id", "MasterName", "StarLevel", "RankTitle", "TitleLogo" FROM "MasterProfiles" ORDER BY "Id";')
    for r in cur.fetchall():
        print("Master:", r)
        
    conn.close()
except Exception as e:
    print("Error:", e)
