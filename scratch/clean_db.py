import psycopg2
import json
import os
import urllib.request

def run_cleanup():
    conn = psycopg2.connect(
        host='localhost',
        port=5432,
        database='TuvionlineManagerDB',
        user='postgres',
        password='postgres'
    )
    cur = conn.cursor()

    # 1. Backup before delete
    cur.execute('SELECT "Id", "Title", "Content", "Type", "CategorySlug", "Author", "Icon", "Replies", "Views", "CreatedAt" FROM "ForumTopics";')
    rows = cur.fetchall()
    backup_topics = []
    deleted_ids = []
    for r in rows:
        deleted_ids.append(r[0])
        backup_topics.append({
            'id': r[0],
            'title': r[1],
            'content': r[2],
            'type': r[3],
            'categorySlug': r[4],
            'author': r[5],
            'icon': r[6],
            'replies': r[7],
            'views': r[8],
            'createdAt': str(r[9])
        })

    cur.execute('SELECT "Id", "TopicId", "Author", "Content", "CreatedAt" FROM "ForumTopicReplies";')
    replies_rows = cur.fetchall()
    backup_replies = []
    for r in replies_rows:
        backup_replies.append({
            'id': r[0],
            'topicId': r[1],
            'author': r[2],
            'content': r[3],
            'createdAt': str(r[4])
        })

    os.makedirs('scratch', exist_ok=True)
    with open('scratch/backup_deleted_topics.json', 'w', encoding='utf-8') as f:
        json.dump({'topics': backup_topics, 'replies': backup_replies}, f, ensure_ascii=False, indent=2)

    print(f"BACKUP_SUCCESS: {len(backup_topics)} topics and {len(backup_replies)} replies backed up.")

    # 2. Transaction-Safe Delete
    cur.execute('BEGIN TRANSACTION;')
    cur.execute('DELETE FROM "ForumTopicReplies";')
    cur.execute('DELETE FROM "ForumTopics";')
    cur.execute('COMMIT;')
    conn.commit()

    cur.execute('SELECT COUNT(*) FROM "ForumTopics";')
    remaining = cur.fetchone()[0]
    cur.close()
    conn.close()

    # 3. Clean json persistent storage
    json_path = 'AIEngine_Python/forum_topics_db.json'
    with open(json_path, 'w', encoding='utf-8') as f:
        json.dump([], f, ensure_ascii=False, indent=2)

    print(f"DELETE_SUCCESS: Remaining records in PostgreSQL Docker: {remaining}")

    # 4. Trigger SignalR batch delete broadcast
    try:
        req = urllib.request.Request(
            "http://localhost:5000/api/v1/forum/broadcast/topic-updated",
            data=json.dumps({
                "action": "batch_delete",
                "ids": deleted_ids,
                "categorySlug": "thong-bao-su-kien"
            }).encode("utf-8"),
            headers={"Content-Type": "application/json"},
            method="POST"
        )
        with urllib.request.urlopen(req, timeout=2.0) as resp:
            print("SIGNALR_BROADCAST_SUCCESS: Broadcasted batch_delete to APIGateway_CS.")
    except Exception as e:
        print(f"SignalR broadcast note: {e} (APIGateway may not be running locally or port is different)")

if __name__ == '__main__':
    run_cleanup()
