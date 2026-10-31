import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../models/forum_category_model.dart';
import '../../providers/forum_category_provider.dart';
import '../../services/forum_category_repository.dart';
import '../../utils/boxed_snack_bar.dart';
import '../../widgets/forum_table_widget.dart';

/// AdminDeleteCategoriesScreen — Màn hình Xóa Chuyên mục và Lớp học Lý số hàng loạt (Admin)
/// Chuẩn Boxed Layout: Nền tím đen #1E2640 liền mạch.
class AdminDeleteCategoriesScreen extends StatefulWidget {
  const AdminDeleteCategoriesScreen({super.key});

  @override
  State<AdminDeleteCategoriesScreen> createState() => _AdminDeleteCategoriesScreenState();
}

class _AdminDeleteCategoriesScreenState extends State<AdminDeleteCategoriesScreen> {
  final Set<ForumCategoryItem> _selectedForDeletion = {};
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

  void _toggleItemSelection(dynamic item, bool? isSelected) {
    if (item is! ForumCategoryItem) return;
    setState(() {
      if (isSelected == true) {
        _selectedForDeletion.add(item);
      } else {
        _selectedForDeletion.removeWhere((e) => e.title == item.title);
      }
    });
  }

  void _handlePreview() {
    if (_selectedForDeletion.isEmpty) {
      showErrorSnackBar(context, 'Vui lòng chọn ít nhất một chuyên mục để xem trước');
      return;
    }

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
                        'Danh sách các mục được chọn xóa (${_selectedForDeletion.length})',
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
                    headerTitle: 'Các chuyên mục / lớp học sẽ xóa',
                    column4Header: 'Bài cuối',
                    forums: _selectedForDeletion.toList(),
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

  void _handleConfirmDelete() {
    if (_selectedForDeletion.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn ít nhất một chuyên mục cần xóa')),
      );
      return;
    }

    final String confirmMessage = _selectedForDeletion.length == 1
        ? 'Bạn chắc chắn muốn xóa chuyên mục [${_selectedForDeletion.first.title}] này không (Y/N)'
        : 'Bạn chắc chắn muốn xóa ${_selectedForDeletion.length} chuyên mục/lớp học đã chọn khỏi hệ thống không (Y/N)?';

    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          backgroundColor: const Color(0xFF1E2640),
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(color: Color(0xFF2E3B5F)),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.warning_amber_rounded, color: Color(0xFFEF5350), size: 24),
                      SizedBox(width: 10),
                      Text(
                        'Bạn muốn xóa không?',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    confirmMessage,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // [N] (Hủy)
                      ElevatedButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2A3450),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                            side: const BorderSide(color: Color(0xFF3F4E75)),
                          ),
                        ),
                        child: const Text('N (Hủy)', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 12),
                      // [Y] (Đồng ý)
                      ElevatedButton(
                        onPressed: () async {
                          Navigator.of(ctx).pop();
                          final deletedItems = List<ForumCategoryItem>.from(_selectedForDeletion);
                          final firstTitle = deletedItems.isNotEmpty ? deletedItems.first.title : '';

                          try {
                            final provider = Provider.of<ForumCategoryProvider>(context, listen: false);
                            await provider.removeCategories(deletedItems);
                          } catch (_) {
                            await HttpForumCategoryRepository().deleteCategories(deletedItems);
                          }

                          setState(() {
                            _g1.removeWhere((item) => deletedItems.any((d) => d.title == item.title));
                            _g2.removeWhere((item) => deletedItems.any((d) => d.title == item.title));
                            _g3.removeWhere((item) => deletedItems.any((d) => d.title == item.title));
                            _selectedForDeletion.clear();
                          });

                          if (!mounted) return;
                          final msg = deletedItems.length == 1
                              ? 'Đã xóa thành công chuyên mục [$firstTitle]!'
                              : 'Đã xóa thành công ${deletedItems.length} chuyên mục/lớp học!';
                          showSuccessSnackBar(context, msg);
                          try {
                            context.go('/forum');
                          } catch (_) {}
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFC62828),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                            side: const BorderSide(color: Color(0xFFEF5350)),
                          ),
                        ),
                        child: const Text('Y (Đồng ý)', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
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
                Icon(Icons.remove_circle_outline, color: Color(0xFFFFD700), size: 22),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Xóa các Chuyên mục và Lớp học Lý số (Admin)',
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

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF161F36),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF2E3B5F)),
      ),
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
            onPressed: _handlePreview,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E88E5),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
                side: const BorderSide(color: Color(0xFF42A5F5)),
              ),
            ),
            child: const Text('Xem trước', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          ),
          const SizedBox(width: 16),
          ElevatedButton(
            onPressed: _handleConfirmDelete,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFC62828),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
                side: const BorderSide(color: Color(0xFFEF5350)),
              ),
            ),
            child: const Text('Xác nhận xóa (Y/N)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  // --- FOOTER DIỄN ĐÀN (BƯỚC 3: BREADCRUMB VÀ BẢN QUYỀN PHPBB) ---
  Widget _buildForumFooter(BuildContext context) {
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
                  'Xóa các Chuyên mục và Lớp học Lý số (Admin)',
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
            // Tiêu đề Header (Top Bar chuẩn motif Hình 4)
            _buildPageHeader(context),
            const SizedBox(height: 12),

            // Dòng câu hỏi ở đỉnh danh sách
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                'Bạn định xóa chuyên mục hay lớp học lý số nào ?',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Bảng Chuyên mục 1 (Checkbox mode)
            ForumTableWidget(
              headerTitle: 'Chuyên mục 1',
              column4Header: 'Bài cuối',
              forums: _g1,
              isDeleteMode: true,
              selectedForDeletion: _selectedForDeletion,
              onItemSelectionToggle: _toggleItemSelection,
            ),
            const SizedBox(height: 16),

            // Bảng Lớp học Lý số (Checkbox mode)
            ForumTableWidget(
              headerTitle: 'Lớp học Lý số',
              column4Header: 'Bài cuối',
              forums: _g2,
              isDeleteMode: true,
              selectedForDeletion: _selectedForDeletion,
              onItemSelectionToggle: _toggleItemSelection,
            ),
            const SizedBox(height: 16),

            // Bảng Chuyên mục 2 (Checkbox mode)
            ForumTableWidget(
              headerTitle: 'Chuyên mục 2',
              column4Header: 'Bài cuối',
              forums: _g3,
              isDeleteMode: true,
              selectedForDeletion: _selectedForDeletion,
              onItemSelectionToggle: _toggleItemSelection,
            ),
            const SizedBox(height: 20),

            // Thanh công cụ đáy
            _buildBottomBar(),
            const SizedBox(height: 24),

            // Footer Diễn đàn (Breadcrumb và bản quyền phpBB)
            _buildForumFooter(context),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
