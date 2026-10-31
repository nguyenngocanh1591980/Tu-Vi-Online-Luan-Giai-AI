with open('frontend/lib/screens/forum/category_topics_screen.dart', 'r', encoding='utf-8') as f:
    text = f.read()

import re
text = re.sub(r"import '\.\./\.\./utils/boxed_snack_bar\.dart';\r?\n?", '', text)
with open('frontend/lib/screens/forum/category_topics_screen.dart', 'w', encoding='utf-8') as f:
    f.write(text)
print('Removed import cleanly')
