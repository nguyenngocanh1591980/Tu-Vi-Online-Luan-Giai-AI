import json, sys
sys.stdout.reconfigure(encoding='utf-8')
db = json.load(open('AIEngine_Python/forum_topics_db.json', encoding='utf-8'))
for t in db:
    print(t.get('id'), "|", t.get('categorySlug'), "|", t.get('title'))
