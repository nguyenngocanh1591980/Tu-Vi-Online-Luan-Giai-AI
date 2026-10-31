import re

with open('frontend/lib/screens/forum/category_topics_screen.dart', 'r', encoding='utf-8') as f:
    text = f.read()

pattern = r'  int\? _lastHandledRefreshTimestamp;\s+bool _isNavigating = false;\s+DateTime\? _lastNavigationTime;\s+void _navigateToTopic\(BuildContext context, Map<String, dynamic> topic\) \{[\s\S]*?\n  \}'

replacement = '''  int? _lastHandledRefreshTimestamp;
  DateTime? _lastNavigationTime;

  void _navigateToTopic(BuildContext context, Map<String, dynamic> topic) {
    final now = DateTime.now();
    // C\u01a1 ch\u1ebf Debounce 800ms an to\u00e0n (Safe Navigation Lock 2026): Ch\u1ed1ng click li\u00ean t\u1ee5c, kh\u00f4ng r\u00f2 r\u1ec9 b\u1ed9 nh\u1edb
    if (_lastNavigationTime != null && now.difference(_lastNavigationTime!).inMilliseconds < 800) {
      return;
    }

    final dynamic rawId = topic['id'] ?? topic['topicId'] ?? topic['Id'];
    final String topicTitle = (topic['title'] ?? topic['Title'] ?? '').toString();
    // C\u01a1 ch\u1ebf Fallback ID an to\u00e0n cho ch\u1ee7 \u0111\u1ec1 t\u0129nh: n\u1ebfu thi\u1ebfu ID th\u00ec d\u00f9ng hash title ho\u1eb7c ID 166
    final String id = (rawId != null && rawId.toString().trim().isNotEmpty)
        ? rawId.toString().trim()
        : (topicTitle.isNotEmpty ? (topicTitle.hashCode.abs() % 1000 + 1).toString() : '166');

    _lastNavigationTime = now;

    final String catSlug = widget.slug.isNotEmpty ? widget.slug : 'thong-bao-su-kien';
    final String catTitle = _categoryTitle.isNotEmpty ? _categoryTitle : 'Th\u00f4ng b\u00e1o - S\u1ef1 ki\u1ec7n';

    BreadcrumbStateService.updateCurrentTopic(
      topicId: id,
      categorySlug: catSlug,
      categoryTitle: catTitle,
      topicTitle: topicTitle,
    );

    context.push(
      '/forum/post/$id',
      extra: {
        'categorySlug': catSlug,
        'categoryTitle': catTitle,
        'topicTitle': topicTitle,
      },
    );
  }'''

new_text, count = re.subn(pattern, replacement, text)
print('Replaced count in category_topics_screen:', count)
assert count == 1, f"Expected 1 replacement, got {count}"

with open('frontend/lib/screens/forum/category_topics_screen.dart', 'w', encoding='utf-8') as f:
    f.write(new_text)
print('Successfully updated category_topics_screen.dart')
