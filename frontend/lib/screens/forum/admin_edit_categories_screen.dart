import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../models/forum_category_model.dart';
import '../../providers/forum_category_provider.dart';
import '../../utils/boxed_snack_bar.dart';

/// AdminEditCategoriesScreen — Màn hình Chọn Chuyên mục để Sửa (Admin)
/// Chuẩn Boxed Layout: Nền tím đen #1E2640 liền mạch, đối chiếu theo Hình 2.
class AdminEditCategoriesScreen extends StatefulWidget {
  const AdminEditCategoriesScreen({super.key});

  @override
  State<AdminEditCategoriesScreen> createState() => _AdminEditCategoriesScreenState();
}

class _AdminEditCategoriesScreenState extends State<AdminEditCategoriesScreen> {
  final Set<ForumCategoryItem> _selectedForEdit = {};
  List<ForumCategoryItem> _g1 = [];
  List<ForumCategoryItem> _g2 = [];
  List<ForumCategoryItem> _g3 = [];
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      try {
        final provider = Provider.of<ForumCategoryProvider>(context, listen: false);
        _g1 = List<ForumCategoryItem>.from(provider.group1Categories);
        _g2 = List<ForumCategoryItem>.from(provider.group2Categories);
        _g3 = List<ForumCategoryItem>.from(provider.group3Categories);
      } catch (_) {}

      if (_g1.isEmpty && _g2.isEmpty && _g3.isEmpty) {
        final defaultProvider = ForumCategoryProvider();
        _g1 = List<ForumCategoryItem>.from(defaultProvider.group1Categories);
        _g2 = List<ForumCategoryItem>.from(defaultProvider.group2Categories);
        _g3 = List<ForumCategoryItem>.from(defaultProvider.group3Categories);
      }
    }
  }

  void _toggleItemSelection(ForumCategoryItem item, bool? isSelected) {
    setState(() {
      if (isSelected == true) {
        _selectedForEdit.add(item);
      } else {
        _selectedForEdit.removeWhere((e) => e.title == item.title);
      }
    });
  }

  void _handleConfirmEdit() {
    // Logic Validation (Cực kỳ quan trọng theo quy chuẩn Bước 1)
    if (_selectedForEdit.isEmpty || _selectedForEdit.length > 1) {
      showBoxedSnackBar(
        context,
        'Bạn chỉ được chọn 1 mục để sửa chữa, xin vui lòng lựa chọn lại',
        backgroundColor: const Color(0xFFC62828),
      );
      try {
        final screenWidth = MediaQuery.of(context).size.width;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            width: screenWidth > 1024 ? 1024 : null,
            backgroundColor: const Color(0xFFC62828),
            content: const Text(
              'Bạn chỉ được chọn 1 mục để sửa chữa, xin vui lòng lựa chọn lại',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        );
      } catch (_) {}
      return;
    }

    final ForumCategoryItem selectedItem = _selectedForEdit.first;
    // Chuyển hướng sang màn hình Form Sửa (Hình 3) và truyền toàn bộ Data Object
    context.push('/forum/edit-category-form', extra: selectedItem);
  }

  Widget _buildForumIcon(ForumCategoryItem forum) {
    final isRed = forum.title == 'Kiến thức Tứ trụ';
    final circleBorder = isRed ? const Color(0xFFEF5350) : const Color(0xFF8E9BAE);
    final iconColor = isRed ? const Color(0xFFEF5350) : const Color(0xFF8E9BAE);

    Widget iconWidget;
    if (forum.icon is IconData) {
      iconWidget = Icon(forum.icon as IconData, color: iconColor, size: 18);
    } else if (forum.icon is String && (forum.icon as String).isNotEmpty && (forum.icon as String) != 'none' && (forum.icon as String) != 'description_outlined') {
      iconWidget = Text(forum.icon as String, style: const TextStyle(fontSize: 16));
    } else {
      iconWidget = Icon(Icons.description_outlined, color: iconColor, size: 18);
    }

    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: circleBorder, width: 1.5),
        color: Colors.white.withValues(alpha: 0.04),
      ),
      child: Center(child: iconWidget),
    );
  }

  Widget _buildCategoryTable({
    required String headerTitle,
    required List<ForumCategoryItem> items,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF161F36),
        border: Border.all(color: const Color(0xFF2E3B5F)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        children: [
          // Table Header (Đỏ sẫm #8B0000)
          Container(
            decoration: const BoxDecoration(
              color: Color(0xFF8B0000),
              borderRadius: BorderRadius.vertical(top: Radius.circular(3)),
            ),
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    headerTitle,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
                const SizedBox(
                  width: 65,
                  child: Text('Chủ đề', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                ),
                const SizedBox(
                  width: 70,
                  child: Text('Bài viết', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                ),
                const SizedBox(
                  width: 250,
                  child: Text('Bài cuối', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                ),
              ],
            ),
          ),
          // Các hàng danh sách chuyên mục
          ...items.map((item) {
            final isLast = items.last == item;
            final isSelected = _selectedForEdit.any((e) => e.title == item.title);
            final isHighlighted = item.isHighlighted;

            return Container(
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF1A3B5C)
                    : (isHighlighted ? const Color(0xFF382E1E) : const Color(0xFF161F36)),
                border: isLast ? null : const Border(bottom: BorderSide(color: Color(0xFF2E3B5F))),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Cột 1: Checkbox + Icon + Tiêu đề & Mô tả
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 32,
                          height: 32,
                          child: Center(
                            child: Checkbox(
                              value: isSelected,
                              activeColor: const Color(0xFF1E88E5),
                              checkColor: Colors.white,
                              side: const BorderSide(color: Color(0xFF8E9BAE), width: 1.5),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
                              onChanged: (val) => _toggleItemSelection(item, val),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _buildForumIcon(item),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: isSelected
                                      ? const Color(0xFF90CAF9)
                                      : (isHighlighted ? const Color(0xFFFFD54F) : Colors.white),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                item.description,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 13, color: Colors.white70, height: 1.3),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Cột 2: Chủ đề
                  SizedBox(
                    width: 65,
                    child: Text(
                      '${item.topics}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 13, color: Colors.white70),
                    ),
                  ),
                  // Cột 3: Bài viết
                  SizedBox(
                    width: 70,
                    child: Text(
                      '${item.posts}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 13, color: Colors.white70),
                    ),
                  ),
                  // Cột 4: Bài cuối
                  const SizedBox(
                    width: 250,
                    child: Text(
                      'Chưa có bài viết',
                      style: TextStyle(fontSize: 12, color: Colors.white38),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildPageHeader(BuildContext context) {
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
                Icon(Icons.edit_note, color: Color(0xFFFFD700), size: 24),
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

  Widget _buildFooterButtons(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton(
            onPressed: () {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              } else {
                try {
                  context.go('/forum');
                } catch (_) {}
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2A3450),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
                side: const BorderSide(color: Color(0xFF3F4E75)),
              ),
            ),
            child: const Text('Trở về Trang chủ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          ),
          const SizedBox(width: 16),
          ElevatedButton(
            onPressed: _handleConfirmEdit,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E88E5), // Nền màu xanh blue chuẩn
              foregroundColor: Colors.white, // Chữ màu trắng chuẩn
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
                side: const BorderSide(color: Color(0xFF42A5F5)),
              ),
            ),
            child: const Text('Xác nhận Sửa', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _buildForumFooter(BuildContext context) {
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
        decoration: BoxDecoration(
          color: const Color(0xFF1E2640),
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Tiêu đề Header
            _buildPageHeader(context),
            const SizedBox(height: 12),

            // Câu hỏi hướng dẫn (Bước 1)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                'Bạn định sửa chuyên mục hay lớp học lý số nào ?',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Bảng Chuyên mục 1
            if (_g1.isNotEmpty) ...[
              _buildCategoryTable(
                headerTitle: 'Chuyên mục 1',
                items: _g1,
              ),
              const SizedBox(height: 16),
            ],

            // Bảng Lớp học Lý số
            if (_g2.isNotEmpty) ...[
              _buildCategoryTable(
                headerTitle: 'Lớp học lý số',
                items: _g2,
              ),
              const SizedBox(height: 16),
            ],

            // Bảng Chuyên mục 2
            if (_g3.isNotEmpty) ...[
              _buildCategoryTable(
                headerTitle: 'Chuyên mục 2',
                items: _g3,
              ),
              const SizedBox(height: 16),
            ],

            // Footer Nút thao tác (Trở về Trang chủ + Xác nhận Sửa)
            _buildFooterButtons(context),
            const SizedBox(height: 12),

            // Footer bản quyền diễn đàn
            _buildForumFooter(context),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
