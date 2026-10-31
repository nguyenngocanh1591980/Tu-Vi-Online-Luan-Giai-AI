with open(r'E:\Tu vi online\frontend\lib\screens\forum\post_reply_screen.dart', 'r', encoding='utf-8') as f:
    text = f.read()

# 1. Remove unused import
text = text.replace("import 'package:shared_preferences/shared_preferences.dart';\n", '')

# 2. Fix time and imageUrl on topicDetail
text = text.replace(
    "'time': topicDetail.time,\n              'imageUrl': topicDetail.imageUrl,",
    "'time': topicDetail.createdAt ?? topicDetail.lastTime,\n              'imageUrl': null,"
)

# 3. Fix unnecessary underscores in errorBuilder
text = text.replace(
    'errorBuilder: (_, __, ___) => const SizedBox(),',
    'errorBuilder: (context, error, stackTrace) => const SizedBox(),'
)

with open(r'E:\Tu vi online\frontend\lib\screens\forum\post_reply_screen.dart', 'w', encoding='utf-8') as f:
    f.write(text)

print('Updated post_reply_screen.dart successfully!')
