import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../models/forum_category_model.dart';
import '../../providers/forum_category_provider.dart';
import '../../providers/draft_provider.dart';
import '../../widgets/forum_table_widget.dart';
import '../../utils/boxed_snack_bar.dart';

/// AdminCreateCategoryScreen — Màn hình Tạo Chuyên mục / Lớp học (Admin)
/// Chuẩn Boxed Layout: Nền tím đen #1E2640 liền mạch 100%, không bị phân tách 3 khối.
class AdminCreateCategoryScreen extends StatefulWidget {
  const AdminCreateCategoryScreen({super.key});

  @override
  State<AdminCreateCategoryScreen> createState() => _AdminCreateCategoryScreenState();
}

class _AdminCreateCategoryScreenState extends State<AdminCreateCategoryScreen> {
  // State quản lý loại chuyên mục / lớp học đang tạo
  String currentFormType = 'Chuyên mục 1';
  String currentGroupTypeCode = 'ChuyenMuc1';

  // State biểu tượng bài viết (mặc định 'none' - Không dùng)
  String _selectedIcon = 'none';
  bool _isIconBarExpanded = false;

  // Controllers cho tiêu đề
  final TextEditingController _titleController = TextEditingController();
  bool _titleSubmitted = false;

  // Rich Text Editor Controller
  late final quill.QuillController _quillController;
  final FocusNode _editorFocusNode = FocusNode();
  final ScrollController _editorScrollController = ScrollController();
  bool _isFullscreen = false;
  String _selectedFontSize = 'Cỡ chữ';

  // State các tùy chọn BBCode
  bool _disableBBCode = false;
  bool _disableSmilies = false;
  bool _dontDetectUrls = false;

  @override
  void initState() {
    super.initState();
    _quillController = quill.QuillController.basic();
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

  // Dynamic label dựa trên currentFormType
  String getLabelText() {
    if (currentFormType == 'Chuyên mục 1') return 'Tên Chuyên mục 1 tạo mới';
    if (currentFormType == 'Lớp học Lý số') return 'Tên Lớp học Lý số mới';
    if (currentFormType == 'Chuyên mục 2') return 'Tên Chuyên mục 2 tạo mới';
    return 'Tiêu đề:'; // Fallback
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent, // Tuân thủ Rule 7 Layout
      child: Container(
        color: const Color(0xFF1E2640), // Nền tím đen chuẩn trải dài liền mạch 100% (Bước 1)
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- BƯỚC 2: THANH BAR TIÊU ĐỀ ---
            _buildPageHeader(),
            const SizedBox(height: 16),

            // --- 3 NÚT BẤM CHUYỂN ĐỔI CHUYÊN MỤC ---
            _buildTypeToggleButtons(),
            const SizedBox(height: 16),

            // --- BƯỚC 3 HÀNH ĐỘNG 1: DẢI RADIO BUTTON ICON NGUYÊN BẢN (HÌNH 4 + BỔ SUNG) ---
            _buildIconRadioBar(),
            const SizedBox(height: 16),

            // --- TRƯỜNG NHẬP TIÊU ĐỀ ĐỘNG THEO STATE ---
            _buildDynamicTitleField(),
            const SizedBox(height: 16),

            // --- BƯỚC 3 HÀNH ĐỘNG 2: TOOLBAR NGUYÊN BẢN (HÌNH 5) + VÙNG NHẬP LIỆU ---
            _buildRichTextEditor(),
            const SizedBox(height: 20),

            // --- 2 NÚT HÀNH ĐỘNG: XEM TRƯỚC, XÁC NHẬN ---
            _buildActionButtons(),
            const SizedBox(height: 20),

            const Divider(color: Color(0xFF2E3B5F), height: 1),
            const SizedBox(height: 16),

            // --- CỤM TÙY CHỌN (ĐÃ XÓA CHECKBOX THÔNG BÁO) ---
            _buildOptionsSection(),
            const SizedBox(height: 24),

            // --- FOOTER DIỄN ĐÀN (KHÔI PHỤC THEO HÌNH 1, LOẠI BỎ HÌNH 2) ---
            _buildForumFooter(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // --- BƯỚC 2 HÀNH ĐỘNG 1: THANH BAR TIÊU ĐỀ MÀN HÌNH ---
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
                Icon(Icons.add_circle_outline, color: Color(0xFFFFD700), size: 22),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Tạo thêm Chuyên mục và Lớp học Lý số mới (Admin)',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFFD700), // Vàng hoàng gia sang trọng
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
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- 3 NÚT BẤM CHUYỂN ĐỔI CHUYÊN MỤC ---
  Widget _buildTypeToggleButtons() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
      decoration: BoxDecoration(
        color: const Color(0xFF151C33),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF2E3B5F)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildTypeButton('Tạo thêm Chuyên mục 1 mới', 'Chuyên mục 1', 'ChuyenMuc1'),
            const SizedBox(width: 8),
            _buildTypeButton('Tạo thêm Lớp học Lý số mới', 'Lớp học Lý số', 'LopHoc'),
            const SizedBox(width: 8),
            _buildTypeButton('Tạo thêm Chuyên mục 2 mới', 'Chuyên mục 2', 'ChuyenMuc2'),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeButton(String title, String type, String code) {
    final bool isSelected = currentFormType == type;
    return ElevatedButton(
      onPressed: () {
        setState(() {
          currentFormType = type;
          currentGroupTypeCode = code;
        });
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? Colors.teal : const Color(0xFF2A3450),
        foregroundColor: Colors.white,
        elevation: isSelected ? 2 : 0,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
          side: BorderSide(
            color: isSelected ? Colors.tealAccent : const Color(0xFF3F4E75),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
      ),
      child: Text(
        title,
        style: TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  // --- BƯỚC 1: THANH CHỌN BIỂU TƯỢNG DẠNG THU GỌN (COLLAPSIBLE - HÌNH 1) ---
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

  Widget _buildIconRadioBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
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
            borderRadius: BorderRadius.circular(4),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                children: [
                  const Text(
                    'Biểu tượng Chuyên mục hoặc Lớp học mới',
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
                  // 6. Bóng đèn / Mặt trời 💡
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
                  // 12. Bổ sung: Icon tài liệu trong vòng tròn (media_1790996965580.png)
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
                setState(() {
                  _selectedIcon = val ?? 'none';
                });
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

  // --- TRƯỜNG NHẬP TIÊU ĐỀ ĐỘNG ---
  Widget _buildDynamicTitleField() {
    final bool hasError = _titleSubmitted && _titleController.text.trim().isEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          getLabelText(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _titleController,
          onChanged: (_) {
            if (_titleSubmitted) {
              setState(() {});
            }
          },
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            isDense: true,
            hintText: 'Nhập ${getLabelText().toLowerCase()}...',
            hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
            errorText: hasError ? 'Vui lòng nhập tên chuyên mục tạo mới' : null,
            errorStyle: const TextStyle(color: Color(0xFFEF5350), fontSize: 12),
            filled: true,
            fillColor: const Color(0xFF161B2E),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: BorderSide(
                color: hasError ? const Color(0xFFEF5350) : const Color(0xFF3F4E75),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: BorderSide(
                color: hasError ? const Color(0xFFEF5350) : Colors.tealAccent,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // --- BƯỚC 3 HÀNH ĐỘNG 2: TOOLBAR NGUYÊN BẢN (HÌNH 5 / HÌNH 7) + VÙNG SOẠN THẢO QUILL ---
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
        color: const Color(0xFF161B2E),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFF3F4E75)),
      ),
      child: Column(
        children: [
          // Toolbar gốc đầy đủ Hình 7
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

          // Vùng soạn thảo Rich Text Editor
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

  // --- 2 NÚT HÀNH ĐỘNG: XEM TRƯỚC, XÁC NHẬN ---
  Widget _buildActionButtons() {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 10,
      runSpacing: 8,
      children: [
        _buildActionButton('Xem trước', onTap: _handlePreview),
        _buildActionButton('Xác nhận', isPrimary: true, onTap: _handleConfirm),
      ],
    );
  }

  Widget _buildActionButton(String title, {bool isPrimary = false, VoidCallback? onTap}) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: isPrimary ? Colors.teal : const Color(0xFF2A3450),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
          side: BorderSide(
            color: isPrimary ? Colors.tealAccent : const Color(0xFF3F4E75),
          ),
        ),
      ),
      child: Text(
        title,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }

  // --- CỤM TÙY CHỌN (ĐÃ XÓA CHECKBOX THÔNG BÁO) ---
  Widget _buildOptionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tùy chọn',
          style: TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        _buildCheckboxRow('Tắt các thẻ BBCode', _disableBBCode, (v) {
          setState(() => _disableBBCode = v ?? false);
        }),
        _buildCheckboxRow('Tắt Biểu tượng vui', _disableSmilies, (v) {
          setState(() => _disableSmilies = v ?? false);
        }),
        _buildCheckboxRow('Đừng tự động nhận diện các địa chỉ URL', _dontDetectUrls, (v) {
          setState(() => _dontDetectUrls = v ?? false);
        }),
      ],
    );
  }

  Widget _buildCheckboxRow(String label, bool value, ValueChanged<bool?> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: Checkbox(
              value: value,
              activeColor: Colors.teal,
              checkColor: Colors.white,
              side: const BorderSide(color: Color(0xFF3F4E75)),
              onChanged: onChanged,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ],
      ),
    );
  }

  // --- FOOTER DIỄN ĐÀN (HÌNH 1 ĐÃ XÓA KHỐI LIÊN KẾT HÌNH 2) ---
  Widget _buildForumFooter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF161F36), // Nền panel
            border: Border.all(color: const Color(0xFF2E3B5F)), // Viền #2E3B5F
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.home, color: Color(0xFFEF5350), size: 16),
              const SizedBox(width: 4),
              InkWell(
                onTap: () => context.go('/'),
                child: const Text('Trang chủ', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFEF5350))),
              ),
              const SizedBox(width: 8),
              const Text('<', style: TextStyle(color: Colors.white38, fontSize: 12)),
              const SizedBox(width: 8),
              InkWell(
                onTap: () => context.go('/forum'),
                child: const Text('Diễn đàn', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFEF5350))),
              ),
              const SizedBox(width: 8),
              const Text('<', style: TextStyle(color: Colors.white38, fontSize: 12)),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Tạo thêm Chuyên mục và Lớp học Lý số mới (Admin)',
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

  void _handlePreview() {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      setState(() {
        _titleSubmitted = true;
      });
      showErrorSnackBar(context, 'Vui lòng nhập tên chuyên mục để xem trước');
      return;
    }

    final descriptionText = _quillController.document.toPlainText().trim();
    final description = descriptionText.isNotEmpty
        ? descriptionText
        : 'Chuyên mục mới được tạo bởi Admin';

    final previewItem = ForumCategoryItem(
      title: title,
      description: description,
      icon: _getMappedIcon(),
      topics: 0,
      posts: 0,
      groupType: currentGroupTypeCode,
      lastPost: null,
    );

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
                      Text(
                        'Xem trước: $currentFormType',
                        style: const TextStyle(
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
                  // Tái sử dụng component ForumTableWidget chuẩn DRY
                  ForumTableWidget(
                    headerTitle: currentFormType,
                    column4Header: 'Bài cuối',
                    forums: [previewItem],
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

  void _handleSaveDraft() {
    final titleText = _titleController.text.trim();
    final title = titleText.isNotEmpty
        ? titleText
        : 'Bản nháp ($currentFormType - ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')})';

    final descriptionText = _quillController.document.toPlainText().trim();
    final description = descriptionText.isNotEmpty
        ? descriptionText
        : 'Nội dung bản nháp';

    final draftItem = ForumCategoryItem(
      title: title,
      description: description,
      icon: _getMappedIcon(),
      topics: 0,
      posts: 0,
      groupType: currentGroupTypeCode,
      lastPost: {
        'title': 'Bản nháp lưu lúc',
        'author': 'Admin',
        'authorColor': const Color(0xFFEF5350),
        'time': 'Vừa xong',
      },
    );

    try {
      Provider.of<DraftProvider>(context, listen: false).addDraft(draftItem);
    } catch (e) {
      debugPrint('Error saving draft: $e');
    }

    showSuccessSnackBar(context, 'Đã lưu bản nháp thành công!');
    context.go('/forum/ucp/drafts');
  }

  Future<void> _handleConfirm() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      setState(() {
        _titleSubmitted = true;
      });
      showErrorSnackBar(context, 'Vui lòng nhập tên chuyên mục tạo mới');
      return;
    }

    final descriptionText = _quillController.document.toPlainText().trim();
    final description = descriptionText.isNotEmpty
        ? descriptionText
        : 'Chuyên mục mới được tạo bởi Admin';

    final newItem = ForumCategoryItem(
      title: title,
      description: description,
      icon: _getMappedIcon(),
      topics: 0,
      posts: 0,
      groupType: currentGroupTypeCode,
      lastPost: {
        'title': 'Chưa có bài viết',
        'author': 'Admin',
        'authorColor': const Color(0xFFEF5350),
        'time': 'Vừa xong',
      },
    );

    bool success = false;
    try {
      success = await Provider.of<ForumCategoryProvider>(context, listen: false).addCategory(newItem);
    } catch (e) {
      debugPrint('Error adding category: $e');
    }

    if (!mounted) return;

    if (success) {
      showSuccessSnackBar(context, 'Tạo $currentFormType mới thành công!');
      context.go('/forum');
    } else {
      showErrorSnackBar(context, 'Lỗi: Không thể lưu $currentFormType vào cơ sở dữ liệu server.');
    }
  }
}

