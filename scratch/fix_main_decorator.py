with open('AIEngine_Python/main.py', 'r', encoding='utf-8') as f:
    text = f.read()

# 1. Remove @app.get("/api/topics/{topic_id}") from get_category_title_by_slug
target1 = '@app.get("/api/topics/{topic_id}")\ndef get_category_title_by_slug(slug: str) -> str:'
repl1 = 'def get_category_title_by_slug(slug: str) -> str:'
assert target1 in text, "target1 not found"
text = text.replace(target1, repl1, 1)

# 2. Add @app.get("/api/topics/{topic_id}") to get_topic_detail
target2 = '@app.get("/api/forum/topics/{topic_id}")\ndef get_topic_detail(topic_id: str):'
repl2 = '@app.get("/api/topics/{topic_id}")\n@app.get("/api/forum/topics/{topic_id}")\ndef get_topic_detail(topic_id: str):'
assert target2 in text, "target2 not found"
text = text.replace(target2, repl2, 1)

with open('AIEngine_Python/main.py', 'w', encoding='utf-8') as f:
    f.write(text)

print('Successfully fixed decorators in main.py')
