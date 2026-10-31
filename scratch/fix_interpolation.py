with open(r'E:\Tu vi online\frontend\lib\screens\forum\post_detail_screen.dart', 'r', encoding='utf-8') as f:
    text = f.read()

old_block = """    // Điều hướng sang Màn hình Soạn thảo Trả lời Đầy đủ (Hình 2)
    context.push(
      '/forum/topic/' + widget.id + '/reply',
      extra: {
        'quoteAuthor': author,
        'quoteContent': cleanContent,
        'initialTitle': postTitle != null && postTitle.isNotEmpty
            ? (postTitle.startsWith('Re:') ? postTitle : 'Re: ' + postTitle)
            : 'Re: ' + (_topic?.title ?? ''),
      },
    );"""

new_block = """    // Điều hướng sang Màn hình Soạn thảo Trả lời Đầy đủ (Hình 2)
    context.push(
      '/forum/topic/${widget.id}/reply',
      extra: {
        'quoteAuthor': author,
        'quoteContent': cleanContent,
        'initialTitle': postTitle != null && postTitle.isNotEmpty
            ? (postTitle.startsWith('Re:') ? postTitle : 'Re: $postTitle')
            : 'Re: ${_topic?.title ?? ""}',
      },
    );"""

text = text.replace(old_block, new_block)

with open(r'E:\Tu vi online\frontend\lib\screens\forum\post_detail_screen.dart', 'w', encoding='utf-8') as f:
    f.write(text)

print('Updated post_detail_screen.dart string interpolation!')
