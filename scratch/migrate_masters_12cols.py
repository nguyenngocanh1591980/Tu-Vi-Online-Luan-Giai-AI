import psycopg2
import sys
sys.stdout.reconfigure(encoding='utf-8')

conn = psycopg2.connect('postgresql://postgres:postgres@localhost:5432/TuviAIManagerDB')
cur = conn.cursor()

alter_sqls = [
    'ALTER TABLE "MasterProfiles" ADD COLUMN IF NOT EXISTS "Username" VARCHAR(100) DEFAULT \'\';',
    'ALTER TABLE "MasterProfiles" ADD COLUMN IF NOT EXISTS "TitleLogo" VARCHAR(255) DEFAULT \'/images/logo_dai_su.png\';',
    'ALTER TABLE "MasterProfiles" ADD COLUMN IF NOT EXISTS "JoinDate" TIMESTAMPTZ DEFAULT NOW();',
    'ALTER TABLE "MasterProfiles" ADD COLUMN IF NOT EXISTS "OnlineBookingDays" INT DEFAULT 0;',
    'ALTER TABLE "MasterProfiles" ADD COLUMN IF NOT EXISTS "OfflineBookingDays" INT DEFAULT 0;',
    'ALTER TABLE "MasterProfiles" ADD COLUMN IF NOT EXISTS "CancelledBookingDays" INT DEFAULT 0;',
    'ALTER TABLE "MasterProfiles" ADD COLUMN IF NOT EXISTS "TotalBookedClients" INT DEFAULT 0;',
    'ALTER TABLE "MasterProfiles" ADD COLUMN IF NOT EXISTS "WeeklyEarnings" NUMERIC(18, 2) DEFAULT 0;',
    'ALTER TABLE "MasterProfiles" ADD COLUMN IF NOT EXISTS "ThanksCount" INT DEFAULT 0;'
]

for sql in alter_sqls:
    cur.execute(sql)

conn.commit()
print("Columns added successfully.")

# Seed / update data for existing 12 masters
cur.execute('SELECT "Id", "UserId", "MasterName", "StarLevel", "RankTitle" FROM "MasterProfiles" ORDER BY "Id";')
rows = cur.fetchall()

sample_data = [
    ("thay_thienco", "Thầy Thiên Cơ", 1, "Nhất Đẳng", 15, 8, 2, 34, 12000000, 89),
    ("thay_thaiduong", "Thầy Thái Dương", 2, "Nhị Đẳng", 20, 10, 1, 45, 15500000, 112),
    ("ngocanh1", "Thầy Ngọc Anh", 3, "Tam Đẳng", 24, 12, 1, 58, 18500000, 142),
    ("thay_tuphu", "Thầy Tử Phủ", 3, "Tam Đẳng", 22, 9, 3, 50, 16000000, 98),
    ("thay_vukhuc", "Thầy Vũ Khúc", 4, "Tứ Đẳng", 26, 14, 0, 68, 22000000, 165),
    ("thay_dongam", "Thầy Đồng Âm", 5, "Ngũ Đẳng", 28, 15, 2, 75, 25000000, 180),
    ("thay_liemtrinh", "Thầy Liêm Trinh", 6, "Lục Đẳng", 30, 18, 1, 90, 32000000, 220),
    ("thay_thienluong", "Thầy Thiên Lương", 7, "Thất Đẳng", 32, 20, 2, 95, 35000000, 250),
    ("thay_thatsat", "Thầy Thất Sát", 8, "Bát Đẳng", 35, 22, 1, 105, 40000000, 290),
    ("thay_phaquan", "Thầy Phá Quân", 9, "Cửu Đẳng", 38, 24, 3, 115, 45000000, 320),
    ("thay_cumon", "Thầy Cự Môn", 10, "Thập Đẳng", 40, 25, 0, 130, 50000000, 380),
    ("thay_thamlang", "Thầy Tham Lang", 1, "Nhất Đẳng", 12, 6, 1, 28, 9500000, 64)
]

for i, r in enumerate(rows):
    m_id = r[0]
    s = sample_data[i % len(sample_data)]
    username = "ngocanh1" if r[1] == 12 or r[2] == "ngocanh1" else s[0]
    master_name = r[2] if r[2] else s[1]
    star_level = r[3] if r[3] else s[2]
    rank_title = r[4] if r[4] else s[3]
    
    cur.execute('''
        UPDATE "MasterProfiles"
        SET "Username" = %s,
            "MasterName" = %s,
            "StarLevel" = %s,
            "RankTitle" = %s,
            "TitleLogo" = '/images/logo_dai_su.png',
            "JoinDate" = NOW() - INTERVAL '%s days',
            "OnlineBookingDays" = %s,
            "OfflineBookingDays" = %s,
            "CancelledBookingDays" = %s,
            "TotalBookedClients" = %s,
            "WeeklyEarnings" = %s,
            "ThanksCount" = %s
        WHERE "Id" = %s;
    ''', (username, master_name, star_level, rank_title, (i + 1) * 30, s[4], s[5], s[6], s[7], s[8], s[9], m_id))

conn.commit()
print("MasterProfiles seeded with 12-column fields successfully.")

cur.execute('SELECT "Id", "Username", "MasterName", "RankTitle", "OnlineBookingDays", "WeeklyEarnings", "ThanksCount" FROM "MasterProfiles" LIMIT 3;')
for row in cur.fetchall():
    print(row)

cur.close()
conn.close()
