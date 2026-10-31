import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../models/forum_category_model.dart';
import '../../providers/forum_category_provider.dart';
import '../../utils/boxed_snack_bar.dart';

/// AdminEditCategoryFormScreen — Màn hình Form Sửa Chuyên mục / Lớp học (Admin)
/// Chuẩn Boxed Layout: Nền tím đen #1E2640 liền mạch, đối chiếu theo Hình 3 & 4.
class AdminEditCategoryFormScreen extends StatefulWidget {
  final ForumCategoryItem category;

  const AdminEditCategoryFormScreen({
    super.key,
    required this.category,
  });

  @override
  State<AdminEditCategoryFormScreen> createState() => _AdminEditCategoryFormScreenState();
}

class _AdminEditCategoryFormScreenState extends State<AdminEditCategoryFormScreen> {
  // State biểu tượng bài viết (đổ sẵn icon hiện tại)
  late String _selectedIcon;
  bool _isIconBarExpanded = false;

  // Controllers cho tiêu đề (Đổ dữ liệu cũ theo Bước 2)
  late final TextEditingController _titleController;

  // Rich Text Editor Controller (Đổ dữ liệu mô tả cũ theo Bước 2)
  late final quill.QuillController _quillController;
  final FocusNode _editorFocusNode = FocusNode();
  final ScrollController _editorScrollController = ScrollController();
  bool _isFullscreen = false;
  String _selectedFontSize = 'Cỡ chữ';

  // State các tùy chọn BBCode
  bool _disableBBCode = false;
  bool _disableSmilies = false;
  bool _dontDetectUrls = false;

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // Data Binding nạp dữ liệu cũ vào TextEditingController
    _titleController = TextEditingController(text: widget.category.title);

    // Xử lý nạp icon cũ
    final rawIcon = widget.category.icon;
    if (rawIcon == '🔥' || rawIcon == 'fire') {
      _selectedIcon = 'fire';
    } else if (rawIcon == '⭐' || rawIcon == 'star') {
      _selectedIcon = 'star';
    } else if (rawIcon == '☢️' || rawIcon == 'radiation') {
      _selectedIcon = 'radiation';
    } else if (rawIcon == '💖' || rawIcon == 'heart') {
      _selectedIcon = 'heart';
    } else if (rawIcon == '💡' || rawIcon == 'sun') {
      _selectedIcon = 'sun';
    } else if (rawIcon == '❓' || rawIcon == 'question') {
      _selectedIcon = 'question';
    } else if (rawIcon == '⚠️' || rawIcon == 'warning') {
      _selectedIcon = 'warning';
    } else if (rawIcon == 'ℹ️' || rawIcon == 'info') {
      _selectedIcon = 'info';
    } else if (rawIcon == '📖' || rawIcon == 'book') {
      _selectedIcon = 'book';
    } else if (rawIcon == '🙏' || rawIcon == 'pray') {
      _selectedIcon = 'pray';
    } else if (rawIcon == 'document' || rawIcon == Icons.description_outlined) {
      _selectedIcon = 'document';
    } else {
      _selectedIcon = 'none';
    }

    // Nạp dữ liệu mô tả cũ vào Quill Editor
    final desc = widget.category.description;
    if (desc.isNotEmpty) {
      final doc = quill.Document()..insert(0, desc);
      _quillController = quill.QuillController(
        document: doc,
        selection: TextSelection.collapsed(offset: desc.length),
      );
    } else {
      _quillController = quill.QuillController.basic();
    }

    _quillController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _quillController.dispose();
    _editorFocusNode.dispose();
    _editorScrollController.dispose();
    super.dispose();
  }

  String _getPlainTextDescription() {
    final raw = _quillController.document.toPlainText();
    return raw.trimRight();
  }

  void _handlePreview() {
    final previewTitle = _titleController.text.trim().isEmpty
        ? widget.category.title
        : _titleController.text.trim();
    final previewDesc = _getPlainTextDescription();

    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          backgroundColor: const Color(0xFF1E2640),
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(color: Color(0xFF2E3B5F)),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 850),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Xem trước chuyên mục sau khi sửa',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white70),
                        onPressed: () => Navigator.of(ctx).pop(),
                        tooltip: 'Đóng',
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF161F36),
                      border: Border.all(color: const Color(0xFF2E3B5F)),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFF8E9BAE), width: 1.5),
                            color: Colors.white.withValues(alpha: 0.04),
                          ),
                          child: Center(
                            child: _getMappedIcon() is String && (_getMappedIcon() as String).isNotEmpty
                                ? Text(_getMappedIcon() as String, style: const TextStyle(fontSize: 16))
                                : const Icon(Icons.description_outlined, color: Color(0xFF8E9BAE), size: 18),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                previewTitle,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                previewDesc,
                                style: const TextStyle(fontSize: 13, color: Colors.white70, height: 1.3),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2A3450),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                          side: const BorderSide(color: Color(0xFF3F4E75)),
                        ),
                      ),
                      child: const Text('Đóng xem trước'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleConfirmEdit() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      showErrorSnackBar(context, 'Tên chuyên mục không được để trống');
      return;
    }

    final desc = _getPlainTextDescription();

    setState(() {
      _isSubmitting = true;
    });

    final updatedCategory = ForumCategoryItem(
      title: title,
      description: desc,
      icon: _getMappedIcon(),
      groupType: widget.category.groupType,
      topics: widget.category.topics,
      posts: widget.category.posts,
      isHighlighted: widget.category.isHighlighted,
      lastPost: widget.category.lastPost,
    );

    try {
      final provider = Provider.of<ForumCategoryProvider>(context, listen: false);
      final success = await provider.updateCategory(widget.category.title, updatedCategory);

      if (!mounted) return;

      if (success) {
        showSuccessSnackBar(context, 'Đã cập nhật chuyên mục thành công!');
        // Tự động quay về trang chủ diễn đàn (Hình 5) và fetch lại DB
        context.go('/forum');
      } else {
        showErrorSnackBar(context, 'Cập nhật thất bại, vui lòng kiểm tra kết nối Backend Docker');
      }
    } catch (e) {
      if (mounted) {
        showErrorSnackBar(context, 'Lỗi cập nhật: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Widget _buildPageHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF131A30),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF2A3450), width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: const [
                Icon(Icons.edit_note, color: Color(0xFFFFD700), size: 22),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Sửa Chuyên mục và Lớp học Lý số (Admin)',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFFD700),
                      letterSpacing: 0.5,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          InkWell(
            onTap: () => context.go('/forum'),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.arrow_back_ios, color: Color(0xFF90CAF9), size: 14),
                SizedBox(width: 4),
                Text(
                  'Về Diễn đàn',
                  style: TextStyle(
                    color: Color(0xFF90CAF9),
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _getSelectedIconDisplay() {
    switch (_selectedIcon) {
      case 'fire':
        return const Text('🔥', style: TextStyle(fontSize: 16));
      case 'star':
        return const Text('⭐', style: TextStyle(fontSize: 16));
      case 'radiation':
        return const Text('☢️', style: TextStyle(fontSize: 16));
      case 'heart':
        return const Text('💖', style: TextStyle(fontSize: 16));
      case 'sun':
        return const Text('💡', style: TextStyle(fontSize: 16));
      case 'question':
        return const Text('❓', style: TextStyle(fontSize: 16));
      case 'warning':
        return const Text('⚠️', style: TextStyle(fontSize: 16));
      case 'info':
        return const Text('ℹ️', style: TextStyle(fontSize: 16));
      case 'book':
        return const Text('📖', style: TextStyle(fontSize: 16));
      case 'pray':
        return const Text('🙏', style: TextStyle(fontSize: 16));
      case 'document':
        return Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white70, width: 1.2),
          ),
          child: const Icon(Icons.description_outlined, size: 14, color: Colors.white),
        );
      case 'none':
      default:
        return const Text('Không dùng', style: TextStyle(color: Colors.white70, fontSize: 13));
    }
  }

  dynamic _getMappedIcon() {
    switch (_selectedIcon) {
      case 'fire':
        return '🔥';
      case 'star':
        return '⭐';
      case 'radiation':
        return '☢️';
      case 'heart':
        return '💖';
      case 'sun':
        return '💡';
      case 'question':
        return '❓';
      case 'warning':
        return '⚠️';
      case 'info':
        return 'ℹ️';
      case 'book':
        return '📖';
      case 'pray':
        return '🙏';
      case 'document':
      case 'none':
      default:
        return Icons.description_outlined;
    }
  }

  Widget _buildRadioIconItem(String value, Widget contentWidget) {
    return InkWell(
      onTap: () {
        setState(() {
          _selectedIcon = value;
        });
      },
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ignore: deprecated_member_use
            Radio<String>(
              value: value,
              // ignore: deprecated_member_use
              groupValue: _selectedIcon,
              activeColor: Colors.tealAccent,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
              // ignore: deprecated_member_use
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _selectedIcon = val;
                  });
                }
              },
            ),
            const SizedBox(width: 4),
            contentWidget,
            const SizedBox(width: 6),
          ],
        ),
      ),
    );
  }

  Widget _buildIconRadioBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: const Color(0xFF161F36),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF2E3B5F)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _isIconBarExpanded = !_isIconBarExpanded;
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                children: [
                  const Text(
                    'Biểu tượng Chuyên mục và Lớp học Lý số',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF222B45),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: const Color(0xFF2E3B5F)),
                    ),
                    child: _getSelectedIconDisplay(),
                  ),
                  const Spacer(),
                  Icon(
                    _isIconBarExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: Colors.white70,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          if (_isIconBarExpanded) ...[
            const SizedBox(height: 8),
            const Divider(color: Color(0xFF2E3B5F), height: 1),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 1. Không dùng
                  _buildRadioIconItem('none', const Text('Không dùng', style: TextStyle(color: Colors.white70, fontSize: 13))),
                  // 2. Lửa 🔥
                  _buildRadioIconItem('fire', const Text('🔥', style: TextStyle(fontSize: 16))),
                  // 3. Sao ⭐
                  _buildRadioIconItem('star', const Text('⭐', style: TextStyle(fontSize: 16))),
                  // 4. Phóng xạ ☢️
                  _buildRadioIconItem('radiation', const Text('☢️', style: TextStyle(fontSize: 16))),
                  // 5. Trái tim 💖
                  _buildRadioIconItem('heart', const Text('💖', style: TextStyle(fontSize: 16))),
                  // 6. Bóng đèn 💡
                  _buildRadioIconItem('sun', const Text('💡', style: TextStyle(fontSize: 16))),
                  // 7. Dấu hỏi ❓
                  _buildRadioIconItem('question', const Text('❓', style: TextStyle(fontSize: 16))),
                  // 8. Chấm than tam giác ⚠️
                  _buildRadioIconItem('warning', const Text('⚠️', style: TextStyle(fontSize: 16))),
                  // 9. Thông tin ℹ️
                  _buildRadioIconItem('info', const Text('ℹ️', style: TextStyle(fontSize: 16))),
                  // 10. Sách 📖
                  _buildRadioIconItem('book', const Text('📖', style: TextStyle(fontSize: 16))),
                  // 11. Chắp tay 🙏
                  _buildRadioIconItem('pray', const Text('🙏', style: TextStyle(fontSize: 16))),
                  // 12. Icon tài liệu trong vòng tròn
                  _buildRadioIconItem(
                    'document',
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white70, width: 1.2),
                      ),
                      child: const Icon(Icons.description_outlined, size: 14, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDynamicTitleField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Sửa Label theo Bước 2: "Tên Chuyên Cần Sửa"
        const Text(
          'Tên Chuyên Cần Sửa',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _titleController,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Nhập tên chuyên mục cần sửa...',
            hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
            filled: true,
            fillColor: const Color(0xFF161F36),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: const BorderSide(color: Color(0xFF2E3B5F)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: const BorderSide(color: Color(0xFF1E88E5), width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRichTextEditor() {
    final style = _quillController.getSelectionStyle();
    final bool isBold = style.containsKey(quill.Attribute.bold.key);
    final bool isItalic = style.containsKey(quill.Attribute.italic.key);
    final bool isUnderline = style.containsKey(quill.Attribute.underline.key);
    final bool isUl = style.containsKey(quill.Attribute.ul.key);
    final bool isOl = style.containsKey(quill.Attribute.ol.key);
    final bool isQuote = style.containsKey(quill.Attribute.blockQuote.key);
    final bool isCode = style.containsKey(quill.Attribute.inlineCode.key);
    final bool isLink = style.containsKey(quill.Attribute.link.key);
    final bool isCodeBlock = style.containsKey(quill.Attribute.codeBlock.key);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF161F36),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF2E3B5F)),
      ),
      child: Column(
        children: [
          // Toolbar đầy đủ chuẩn BBCode
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: const BoxDecoration(
              color: Color(0xFF222B45),
              borderRadius: BorderRadius.vertical(top: Radius.circular(3)),
              border: Border(bottom: BorderSide(color: Color(0xFF2E3B5F))),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  // 1. B (Bold)
                  _buildToolbarButton(
                    'B',
                    isBold: true,
                    isActive: isBold,
                    onTap: () {
                      _quillController.formatSelection(
                        isBold ? quill.Attribute.clone(quill.Attribute.bold, null) : quill.Attribute.bold,
                      );
                    },
                  ),
                  const SizedBox(width: 4),
                  // 2. I (Italic)
                  _buildToolbarButton(
                    'I',
                    isItalic: true,
                    isActive: isItalic,
                    onTap: () {
                      _quillController.formatSelection(
                        isItalic ? quill.Attribute.clone(quill.Attribute.italic, null) : quill.Attribute.italic,
                      );
                    },
                  ),
                  const SizedBox(width: 4),
                  // 3. U (Underline)
                  _buildToolbarButton(
                    'U',
                    isUnderline: true,
                    isActive: isUnderline,
                    onTap: () {
                      _quillController.formatSelection(
                        isUnderline ? quill.Attribute.clone(quill.Attribute.underline, null) : quill.Attribute.underline,
                      );
                    },
                  ),
                  _buildToolbarDivider(),

                  // 4. Cỡ chữ ▾
                  Container(
                    height: 26,
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A3450),
                      border: Border.all(color: const Color(0xFF3F4E75)),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedFontSize,
                        dropdownColor: const Color(0xFF2A3450),
                        icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF90CAF9), size: 16),
                        style: const TextStyle(color: Color(0xFF90CAF9), fontSize: 12),
                        items: const [
                          DropdownMenuItem(value: 'Cỡ chữ', child: Text('Cỡ chữ')),
                          DropdownMenuItem(value: 'Nhỏ', child: Text('Nhỏ')),
                          DropdownMenuItem(value: 'Vừa', child: Text('Vừa')),
                          DropdownMenuItem(value: 'Lớn', child: Text('Lớn')),
                          DropdownMenuItem(value: 'Rất lớn', child: Text('Rất lớn')),
                        ],
                        onChanged: (v) {
                          if (v == null) return;
                          setState(() => _selectedFontSize = v);
                          if (v == 'Nhỏ') {
                            _quillController.formatSelection(quill.Attribute.fromKeyValue('size', 'small'));
                          } else if (v == 'Vừa') {
                            _quillController.formatSelection(quill.Attribute.clone(quill.Attribute.size, null));
                          } else if (v == 'Lớn') {
                            _quillController.formatSelection(quill.Attribute.fromKeyValue('size', 'large'));
                          } else if (v == 'Rất lớn') {
                            _quillController.formatSelection(quill.Attribute.fromKeyValue('size', 'huge'));
                          }
                        },
                      ),
                    ),
                  ),
                  _buildToolbarDivider(),

                  // 5. A ▾ (Màu chữ)
                  PopupMenuButton<Color>(
                    tooltip: 'Màu chữ',
                    padding: EdgeInsets.zero,
                    color: const Color(0xFF222B45),
                    itemBuilder: (context) => const [
                      PopupMenuItem(value: Colors.white, child: Text('Trắng (Mặc định)', style: TextStyle(color: Colors.white))),
                      PopupMenuItem(value: Color(0xFFEF5350), child: Text('Đỏ', style: TextStyle(color: Color(0xFFEF5350)))),
                      PopupMenuItem(value: Color(0xFFFFD700), child: Text('Vàng', style: TextStyle(color: Color(0xFFFFD700)))),
                      PopupMenuItem(value: Color(0xFF4DD0E1), child: Text('Xanh lam', style: TextStyle(color: Color(0xFF4DD0E1)))),
                      PopupMenuItem(value: Color(0xFF81C784), child: Text('Xanh lá', style: TextStyle(color: Color(0xFF81C784)))),
                    ],
                    onSelected: (color) {
                      final hex = '#${color.value.toRadixString(16).substring(2)}';
                      _quillController.formatSelection(quill.Attribute.fromKeyValue('color', hex));
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Text('A', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                          Icon(Icons.arrow_drop_down, color: Colors.white70, size: 16),
                        ],
                      ),
                    ),
                  ),
                  _buildToolbarDivider(),

                  // 6. Bullet List & Numbered List
                  _buildToolbarIconButton(
                    Icons.format_list_bulleted,
                    isActive: isUl,
                    tooltip: 'Danh sách không thứ tự',
                    onTap: () {
                      _quillController.formatSelection(
                        isUl ? quill.Attribute.clone(quill.Attribute.ul, null) : quill.Attribute.ul,
                      );
                    },
                  ),
                  const SizedBox(width: 4),
                  _buildToolbarIconButton(
                    Icons.format_list_numbered,
                    isActive: isOl,
                    tooltip: 'Danh sách có thứ tự',
                    onTap: () {
                      _quillController.formatSelection(
                        isOl ? quill.Attribute.clone(quill.Attribute.ol, null) : quill.Attribute.ol,
                      );
                    },
                  ),
                  const SizedBox(width: 4),
                  // 7. Quote
                  _buildToolbarIconButton(
                    Icons.format_quote,
                    isActive: isQuote,
                    tooltip: 'Trích dẫn',
                    onTap: () {
                      _quillController.formatSelection(
                        isQuote ? quill.Attribute.clone(quill.Attribute.blockQuote, null) : quill.Attribute.blockQuote,
                      );
                    },
                  ),
                  const SizedBox(width: 4),
                  // 8. Mắt / Ẩn (Spoiler)
                  _buildToolbarIconButton(
                    Icons.visibility_off,
                    isActive: isCode,
                    tooltip: 'Spoiler / Văn bản ẩn',
                    onTap: () {
                      _quillController.formatSelection(
                        isCode ? quill.Attribute.clone(quill.Attribute.inlineCode, null) : quill.Attribute.inlineCode,
                      );
                    },
                  ),
                  _buildToolbarDivider(),

                  // 9. Link & Unlink
                  _buildToolbarIconButton(
                    Icons.link,
                    isActive: isLink,
                    tooltip: 'Chèn liên kết',
                    onTap: _showLinkDialog,
                  ),
                  const SizedBox(width: 4),
                  _buildToolbarIconButton(
                    Icons.link_off,
                    tooltip: 'Bỏ liên kết',
                    onTap: () {
                      _quillController.formatSelection(quill.Attribute.clone(quill.Attribute.link, null));
                    },
                  ),
                  const SizedBox(width: 4),
                  // 10. Image
                  _buildToolbarIconButton(
                    Icons.photo_outlined,
                    tooltip: 'Chèn ảnh',
                    onTap: () {
                      final index = _quillController.selection.baseOffset;
                      if (index >= 0) {
                        _quillController.replaceText(index, 0, '[Hình ảnh]', null);
                      }
                    },
                  ),
                  const SizedBox(width: 4),
                  // 11. Table
                  _buildToolbarIconButton(
                    Icons.table_chart_outlined,
                    tooltip: 'Bảng',
                    onTap: () {
                      final index = _quillController.selection.baseOffset;
                      if (index >= 0) {
                        _quillController.replaceText(index, 0, '\n| Tiêu đề 1 | Tiêu đề 2 |\n|---|---|\n| Dữ liệu 1 | Dữ liệu 2 |\n', null);
                      }
                    },
                  ),
                  const SizedBox(width: 4),
                  // 12. Smile & Smile ▾
                  PopupMenuButton<String>(
                    tooltip: 'Biểu tượng cảm xúc',
                    padding: EdgeInsets.zero,
                    color: const Color(0xFF222B45),
                    itemBuilder: (context) => const [
                      PopupMenuItem(value: '😊', child: Text('😊 Mặt cười')),
                      PopupMenuItem(value: '👍', child: Text('👍 Thích')),
                      PopupMenuItem(value: '⭐', child: Text('⭐ Sao')),
                      PopupMenuItem(value: '🔥', child: Text('🔥 Lửa')),
                      PopupMenuItem(value: '💖', child: Text('💖 Trái tim')),
                    ],
                    onSelected: (emoji) {
                      final index = _quillController.selection.baseOffset;
                      if (index >= 0) {
                        _quillController.replaceText(index, 0, emoji, null);
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.sentiment_satisfied_alt, color: Colors.white70, size: 16),
                          SizedBox(width: 2),
                          Icon(Icons.arrow_drop_down, color: Colors.white70, size: 16),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  // 13. Youtube
                  _buildToolbarIconButton(
                    Icons.smart_display,
                    tooltip: 'Chèn video Youtube',
                    onTap: () {
                      final index = _quillController.selection.baseOffset;
                      if (index >= 0) {
                        _quillController.replaceText(index, 0, '[Video/Youtube]', null);
                      }
                    },
                  ),
                  _buildToolbarDivider(),

                  // 14. Undo & Redo
                  _buildToolbarIconButton(
                    Icons.undo,
                    tooltip: 'Hoàn tác',
                    onTap: () {
                      if (_quillController.hasUndo) {
                        _quillController.undo();
                      }
                    },
                  ),
                  const SizedBox(width: 4),
                  _buildToolbarIconButton(
                    Icons.redo,
                    tooltip: 'Làm lại',
                    onTap: () {
                      if (_quillController.hasRedo) {
                        _quillController.redo();
                      }
                    },
                  ),
                  const SizedBox(width: 4),
                  // 15. Fullscreen
                  _buildToolbarIconButton(
                    Icons.fullscreen,
                    isActive: _isFullscreen,
                    tooltip: 'Toàn màn hình / Mở rộng',
                    onTap: () {
                      setState(() {
                        _isFullscreen = !_isFullscreen;
                      });
                    },
                  ),
                  const SizedBox(width: 4),
                  // 16. Source / Doc
                  _buildToolbarIconButton(
                    Icons.description_outlined,
                    isActive: isCodeBlock,
                    tooltip: 'Khối mã nguồn / Tài liệu',
                    onTap: () {
                      _quillController.formatSelection(
                        isCodeBlock ? quill.Attribute.clone(quill.Attribute.codeBlock, null) : quill.Attribute.codeBlock,
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          // Editor content area
          Container(
            height: _isFullscreen ? 360 : 180,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: const Color(0xFF161B2E),
            child: quill.QuillEditor.basic(
              controller: _quillController,
              focusNode: _editorFocusNode,
              scrollController: _editorScrollController,
              config: quill.QuillEditorConfig(
                placeholder: 'Nhập nội dung mô tả hoặc thông tin chi tiết...',
                padding: EdgeInsets.zero,
                scrollable: true,
                autoFocus: false,
                expands: false,
                customStyles: const quill.DefaultStyles(
                  paragraph: quill.DefaultTextBlockStyle(
                    TextStyle(color: Colors.white, fontSize: 13),
                    quill.HorizontalSpacing(0, 0),
                    quill.VerticalSpacing(0, 0),
                    quill.VerticalSpacing.zero,
                    null,
                  ),
                  placeHolder: quill.DefaultTextBlockStyle(
                    TextStyle(color: Colors.white38, fontSize: 13),
                    quill.HorizontalSpacing(0, 0),
                    quill.VerticalSpacing(0, 0),
                    quill.VerticalSpacing.zero,
                    null,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showLinkDialog() {
    final textController = TextEditingController(text: 'https://lyso.vn');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E2640),
        title: const Text('Chèn liên kết', style: TextStyle(color: Colors.white, fontSize: 16)),
        content: TextField(
          controller: textController,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            labelText: 'Địa chỉ URL',
            labelStyle: TextStyle(color: Colors.tealAccent),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy', style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
            onPressed: () {
              final url = textController.text.trim();
              if (url.isNotEmpty) {
                _quillController.formatSelection(quill.Attribute.fromKeyValue('link', url));
              }
              Navigator.pop(ctx);
            },
            child: const Text('Chèn', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbarDivider() {
    return Container(
      width: 1,
      height: 18,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      color: const Color(0xFF3F4E75),
    );
  }

  Widget _buildToolbarButton(String text, {bool isBold = false, bool isItalic = false, bool isUnderline = false, bool isActive = false, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(3),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: isActive ? Colors.teal : const Color(0xFF2A3450),
          border: Border.all(color: isActive ? Colors.tealAccent : const Color(0xFF3F4E75)),
          borderRadius: BorderRadius.circular(3),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            fontStyle: isItalic ? FontStyle.italic : FontStyle.normal,
            decoration: isUnderline ? TextDecoration.underline : TextDecoration.none,
          ),
        ),
      ),
    );
  }

  Widget _buildToolbarIconButton(IconData icon, {bool isActive = false, String? tooltip, VoidCallback? onTap}) {
    Widget button = InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(3),
      child: Container(
        decoration: BoxDecoration(
          color: isActive ? Colors.teal.withValues(alpha: 0.3) : Colors.transparent,
          border: isActive ? Border.all(color: Colors.tealAccent, width: 1) : null,
          borderRadius: BorderRadius.circular(3),
        ),
        padding: const EdgeInsets.all(4.0),
        child: Icon(icon, color: isActive ? Colors.tealAccent : Colors.white70, size: 16),
      ),
    );
    if (tooltip != null) {
      return Tooltip(message: tooltip, child: button);
    }
    return button;
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton(
          onPressed: _handlePreview,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2A3450),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
              side: const BorderSide(color: Color(0xFF3F4E75)),
            ),
          ),
          child: const Text('Xem trước', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        ),
        const SizedBox(width: 16),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _handleConfirmEdit,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00897B),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
              side: const BorderSide(color: Color(0xFF26A69A)),
            ),
          ),
          child: _isSubmitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('Xác nhận Sửa', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        ),
      ],
    );
  }

  Widget _buildOptionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tùy chọn',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 8),
        _buildOptionCheckbox('Tắt các thẻ BBCode', _disableBBCode, (val) => setState(() => _disableBBCode = val ?? false)),
        _buildOptionCheckbox('Tắt Biểu tượng vui', _disableSmilies, (val) => setState(() => _disableSmilies = val ?? false)),
        _buildOptionCheckbox('Đừng tự động nhận diện các địa chỉ URL', _dontDetectUrls, (val) => setState(() => _dontDetectUrls = val ?? false)),
      ],
    );
  }

  Widget _buildOptionCheckbox(String label, bool value, ValueChanged<bool?> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          Checkbox(
            value: value,
            activeColor: const Color(0xFF1E88E5),
            checkColor: Colors.white,
            side: const BorderSide(color: Color(0xFF8E9BAE), width: 1.5),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
            visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            onChanged: onChanged,
          ),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildForumFooter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF161F36),
            border: Border.all(color: const Color(0xFF2E3B5F)),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.home, color: Color(0xFFEF5350), size: 16),
              const SizedBox(width: 4),
              InkWell(
                onTap: () {
                  try {
                    context.go('/');
                  } catch (_) {}
                },
                child: const Text('Trang chủ', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFEF5350))),
              ),
              const SizedBox(width: 8),
              const Text('<', style: TextStyle(color: Colors.white38, fontSize: 12)),
              const SizedBox(width: 8),
              InkWell(
                onTap: () {
                  try {
                    context.go('/forum');
                  } catch (_) {}
                },
                child: const Text('Diễn đàn', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFEF5350))),
              ),
              const SizedBox(width: 8),
              const Text('<', style: TextStyle(color: Colors.white38, fontSize: 12)),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Sửa Chuyên mục và Lớp học Lý số (Admin)',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white70),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        const Text(
          'Powered by phpBB® Forum Software © phpBB Limited',
          style: TextStyle(fontSize: 12, color: Colors.white38),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            InkWell(
              onTap: () {},
              child: const Text(
                'Chính sách bảo mật',
                style: TextStyle(fontSize: 12, color: Color(0xFFEF5350)),
              ),
            ),
            const SizedBox(width: 6),
            const Text('|', style: TextStyle(fontSize: 12, color: Colors.white38)),
            const SizedBox(width: 6),
            InkWell(
              onTap: () {},
              child: const Text(
                'Điều khoản tham gia',
                style: TextStyle(fontSize: 12, color: Color(0xFFEF5350)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        color: const Color(0xFF1E2640),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Tiêu đề Header
            _buildPageHeader(),
            const SizedBox(height: 16),

            // Chú ý: KHỐI 3 NÚT TẠO MỚI (HÌNH 4) ĐÃ ĐƯỢC XÓA BỎ HOÀN TOÀN Ở ĐÂY THEO YÊU CẦU BƯỚC 2

            // Dải biểu tượng (nhãn "Biểu tượng Chuyên mục và Lớp học Lý số")
            _buildIconRadioBar(),
            const SizedBox(height: 16),

            // Trường nhập tiêu đề (nhãn "Tên Chuyên Cần Sửa", đã nạp sẵn dữ liệu cũ)
            _buildDynamicTitleField(),
            const SizedBox(height: 16),

            // Trình soạn thảo mô tả (đã nạp sẵn dữ liệu cũ)
            _buildRichTextEditor(),
            const SizedBox(height: 20),

            // Cụm nút: "Xem trước" và "Xác nhận Sửa"
            _buildActionButtons(),
            const SizedBox(height: 20),

            const Divider(color: Color(0xFF2E3B5F), height: 1),
            const SizedBox(height: 16),

            // Cụm tùy chọn
            _buildOptionsSection(),
            const SizedBox(height: 24),

            // Footer bản quyền diễn đàn
            _buildForumFooter(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
