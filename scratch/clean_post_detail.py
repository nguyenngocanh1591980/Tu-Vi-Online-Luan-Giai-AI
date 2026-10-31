with open(r'E:\Tu vi online\frontend\lib\screens\forum\post_detail_screen.dart', 'r', encoding='utf-8') as f:
    text = f.read()

# 1. Remove fields declaration
text = text.replace(
    '  bool _showPreview = false;\n  bool _isPreviewUnderlined = false;\n  bool _isSaveDraftUnderlined = false;\n',
    ''
)

# 2. Remove _handleSaveDraft and _handleTogglePreview
old_methods = '''  // Module 3: Tương tác nút Lưu bản nháp (Confirm Dialog & Lưu PostgreSQL Docker)
  Future<void> _handleSaveDraft() async {
    setState(() {
      _isSaveDraftUnderlined = true;
    });

    final text = _quickReplyController.text.trim();
    if (text.isEmpty) {
      setState(() {
        _replyValidationError = 'Vui lòng nhập nội dung bản nháp trước khi lưu.';
        _isSaveDraftUnderlined = false;
      });
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E2640),
        title: const Text('Xác nhận lưu bản nháp', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        content: const Text(
          'Bạn có chắc chắn lưu bản nháp lại không? (Y/N)',
          style: TextStyle(color: Colors.white70, fontSize: 13.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('N (Không)', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD32F2F)),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Y (Có)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (!mounted) return;

    if (confirmed != true) {
      setState(() {
        _isSaveDraftUnderlined = false;
      });
      return;
    }

    try {
      final draftProvider = Provider.of<DraftProvider>(context, listen: false);
      final draftTitle = _quickReplyTitleController.text.trim().isNotEmpty
          ? _quickReplyTitleController.text.trim()
          : 'Food Lion Weekly Ad: Check Out Weekly Grocery Highlights';
      final topicTitle = _topic?.title ?? 'Talkshow hướng nghiệp tháng 7/2026';
      final tid = int.tryParse(widget.id) ?? 165;

      await draftProvider.saveDraft(
        username: _currentUsername,
        topicId: tid,
        topicTitle: topicTitle,
        title: draftTitle,
        content: text,
      );

      if (mounted) {
        _quickReplyController.clear();
        setState(() {
          _isSaveDraftUnderlined = false;
          _showPreview = false;
        });
        context.push('/forum/ucp/drafts');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaveDraftUnderlined = false;
          _replyValidationError = 'Lỗi lưu bản nháp: $e';
        });
      }
    }
  }

  // Module 3: Tương tác nút Xem trước
  void _handleTogglePreview() {
    setState(() {
      _isPreviewUnderlined = true;
      _showPreview = !_showPreview;
    });
  }'''

text = text.replace(old_methods, '')

# 3. Clean up line in _handleQuickReply where those fields were reset
text = text.replace(
    '        _showPreview = false;\n        _isSaveDraftUnderlined = false;\n        _isPreviewUnderlined = false;\n',
    ''
)

# 4. Remove _showPreview block in _buildQuickReplySection
text = text.replace(
    '          if (_showPreview) ...[\n            const SizedBox(height: 10),\n            _buildPreviewBox(),\n          ],\n',
    ''
)

with open(r'E:\Tu vi online\frontend\lib\screens\forum\post_detail_screen.dart', 'w', encoding='utf-8') as f:
    f.write(text)

print('Cleaned up unused fields and methods in post_detail_screen.dart!')
