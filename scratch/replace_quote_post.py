with open(r'E:\Tu vi online\frontend\lib\screens\forum\post_detail_screen.dart', 'r', encoding='utf-8') as f:
    lines = f.readlines()

new_block = """  // Module 2: Trả lời kèm trích dẫn (Chuyển sang Màn hình Soạn thảo Đầy đủ - Hình 2)
  void _handleQuotePost({required String author, required String content, String? postTitle}) {
    String cleanContent = content
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll(RegExp(r'\\[quote(?:="[^"]*")?\\][\\s\\S]*?\\[\\/quote\\]', caseSensitive: false), '')
        .trim();

    // Góp ý 1 (Công nghệ 2026): Deep-link State Guard
    final draftProvider = Provider.of<DraftProvider>(context, listen: false);
    draftProvider.setPendingQuote(
      widget.id,
      author: author,
      content: cleanContent,
      title: postTitle ?? _topic?.title ?? '',
    );

    // Điều hướng sang Màn hình Soạn thảo Trả lời Đầy đủ (Hình 2)
    context.push(
      '/forum/topic/' + widget.id + '/reply',
      extra: {
        'quoteAuthor': author,
        'quoteContent': cleanContent,
        'initialTitle': postTitle != null && postTitle.isNotEmpty
            ? (postTitle.startsWith('Re:') ? postTitle : 'Re: ' + postTitle)
            : 'Re: ' + (_topic?.title ?? ''),
      },
    );
  }
"""

idx = -1
for i, l in enumerate(lines):
    if 'void _handleQuotePost(' in l:
        idx = i
        break

if idx != -1:
    end_idx = idx
    for j in range(idx, idx + 30):
        if lines[j].strip() == '}':
            end_idx = j + 1
            break
    print(f'Replacing lines {idx} to {end_idx}')
    lines[idx:end_idx] = [new_block]
    with open(r'E:\Tu vi online\frontend\lib\screens\forum\post_detail_screen.dart', 'w', encoding='utf-8') as f:
        f.writelines(lines)
    print('Replaced _handleQuotePost successfully!')
else:
    print('Index not found!')
