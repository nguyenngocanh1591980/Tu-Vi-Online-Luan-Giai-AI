with open(r'E:\Tu vi online\frontend\lib\screens\forum\post_detail_screen.dart', 'r', encoding='utf-8') as f:
    text = f.read()

# 1. Replace _handleQuotePost
old_fn = '''  // Module 2: Trả lời kèm trích dẫn (Tự động bọc [quote] và ghim Nội quy nếu có)
  void _handleQuotePost({required String author, required String content}) {
    String cleanContent = content
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll(RegExp(r'\\[quote(?:="[^"]*")?\\][\\s\\S]*?\\[\\/quote\\]', caseSensitive: false), '')
        .trim();
    final rules = (_topic?.rules ?? '').trim();
    String quoteText = '';
    if (rules.isNotEmpty) {
      quoteText += '[quote="Nội quy"]\\n$rules\\n[/quote]\\n\\n';
    }
    quoteText += '[quote="$author"]\\n$cleanContent\\n[/quote]\\n\\n';

    setState(() {
      if (_quickReplyController.text.trim().isEmpty) {
        _quickReplyController.text = quoteText;
      } else {
        _quickReplyController.text = '\${_quickReplyController.text}\\n\\n$quoteText';
      }
    });

    _quickReplyFocusNode.requestFocus();
  }'''

new_fn = '''  // Module 2: Trả lời kèm trích dẫn (Chuyển sang Màn hình Soạn thảo Đầy đủ - Hình 2)
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
      '/forum/topic/\${widget.id}/reply',
      extra: {
        'quoteAuthor': author,
        'quoteContent': cleanContent,
        'initialTitle': postTitle != null && postTitle.isNotEmpty
            ? (postTitle.startsWith('Re:') ? postTitle : 'Re: \$postTitle')
            : 'Re: \${_topic?.title ?? ""}',
      },
    );
  }'''

norm_text = text.replace('\r\n', '\n')
norm_old = old_fn.replace('\r\n', '\n')
norm_new = new_fn.replace('\r\n', '\n')

if norm_old in norm_text:
    norm_text = norm_text.replace(norm_old, norm_new, 1)
    print('Replaced _handleQuotePost')
else:
    print('Failed to find _handleQuotePost')

# 2. Remove _buildPreviewBox
old_preview_box = '''  // Module 2: Khung Xem trước bản nháp khi bấm "Soạn thảo đầy đủ & Xem trước"
  Widget _buildPreviewBox() {
    final previewContent = _quickReplyController.text;
    final previewTitle = _quickReplyTitleController.text.trim().isNotEmpty
        ? _quickReplyTitleController.text.trim()
        : 'Re: ${_topic?.title ?? "Trả lời"}';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFF1E88E5), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.visibility, size: 16, color: Color(0xFF1E88E5)),
              SizedBox(width: 6),
              Text(
                'Bản xem trước:',
                style: TextStyle(
                  color: Color(0xFF1E88E5),
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            previewTitle,
            style: const TextStyle(
              color: Color(0xFFC62828),
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'gửi bởi $_currentUsername • Vừa xong',
            style: const TextStyle(color: Color(0xFF757575), fontSize: 11),
          ),
          const Divider(color: Color(0xFFEEEEEE), height: 16),
          _buildFormattedContent(previewContent),
        ],
      ),
    );
  }'''

norm_old_box = old_preview_box.replace('\r\n', '\n')
if norm_old_box in norm_text:
    norm_text = norm_text.replace(norm_old_box, '', 1)
    print('Removed _buildPreviewBox')
else:
    print('Failed to find _buildPreviewBox')

with open(r'E:\Tu vi online\frontend\lib\screens\forum\post_detail_screen.dart', 'w', encoding='utf-8') as f:
    f.write(norm_text)
