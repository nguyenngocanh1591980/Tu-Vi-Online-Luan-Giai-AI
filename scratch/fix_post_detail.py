with open(r'E:\Tu vi online\frontend\lib\screens\forum\post_detail_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Fix img.naturalWidth / naturalHeight
content = content.replace(
    '      int width = img.naturalWidth ?? 800;\n      int height = img.naturalHeight ?? 600;',
    '      int width = img.naturalWidth;\n      int height = img.naturalHeight;'
)

# 2. Fix line 950 to use _isUploadingReplyImage
content = content.replace(
    '  Future<void> _handleQuickReply() async {\n    if (_isSubmittingReply) return;',
    '  Future<void> _handleQuickReply() async {\n    if (_isSubmittingReply || _isUploadingReplyImage) return;'
)

# 3. Fix line 1012: _isDraftUnderlined -> _isSaveDraftUnderlined & _isPreviewUnderlined
content = content.replace(
    '        _showPreview = false;\n        _isDraftUnderlined = false;\n        _isSubmitUnderlined = false;',
    '        _showPreview = false;\n        _isSaveDraftUnderlined = false;\n        _isPreviewUnderlined = false;\n        _isSubmitUnderlined = false;'
)

with open(r'E:\Tu vi online\frontend\lib\screens\forum\post_detail_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print('Updated post_detail_screen.dart successfully')
