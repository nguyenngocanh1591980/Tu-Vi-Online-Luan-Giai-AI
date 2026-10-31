import 'package:flutter/gestures.dart' as import_gestures;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/forum_category_model.dart';

class ForumTableWidget extends StatelessWidget {
  final String headerTitle;
  final String column4Header;
  final List<dynamic> forums;
  final void Function(BuildContext context, String title)? onCategoryTap;
  final bool isDeleteMode;
  final Set<dynamic>? selectedForDeletion;
  final void Function(dynamic item, bool? isSelected)? onItemSelectionToggle;

  const ForumTableWidget({
    super.key,
    required this.headerTitle,
    this.column4Header = 'Bài cuối',
    required this.forums,
    this.onCategoryTap,
    this.isDeleteMode = false,
    this.selectedForDeletion,
    this.onItemSelectionToggle,
  });

  static Widget buildForumIcon(dynamic forum) {
    final String title = forum is ForumCategoryItem ? forum.title : (forum['title'] ?? '');
    final dynamic icon = forum is ForumCategoryItem ? forum.icon : forum['icon'];
    final isRed = title == 'Kiến thức Tứ trụ';
    final circleBorder = isRed ? const Color(0xFFEF5350) : const Color(0xFF8E9BAE);
    final iconColor = isRed ? const Color(0xFFEF5350) : const Color(0xFF8E9BAE);

    Widget iconWidget;
    if (icon is IconData) {
      iconWidget = Icon(icon, color: iconColor, size: 18);
    } else if (icon is String) {
      iconWidget = Text(icon, style: const TextStyle(fontSize: 16));
    } else if (icon is Widget) {
      iconWidget = icon;
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
      child: Center(
        child: iconWidget,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget tableContent = Container(
      decoration: BoxDecoration(
        color: const Color(0xFF161F36), // Nền panel
        border: Border.all(color: const Color(0xFF2E3B5F)), // Khung viền #2E3B5F
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
                SizedBox(
                  width: 250,
                  child: Text(
                    column4Header,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
          // Danh sách Chuyên mục con
          ...forums.map((forum) {
            final isLast = forums.last == forum;
            final String title = forum is ForumCategoryItem ? forum.title : (forum['title'] ?? '');
            final String description = forum is ForumCategoryItem ? forum.description : (forum['description'] ?? '');
            final int topics = forum is ForumCategoryItem ? forum.topics : (forum['topics'] ?? 0);
            final int posts = forum is ForumCategoryItem ? forum.posts : (forum['posts'] ?? 0);
            final bool isHighlighted = forum is ForumCategoryItem ? forum.isHighlighted : (forum['isHighlighted'] == true);
            final Map<String, dynamic>? lastPost = forum is ForumCategoryItem ? forum.lastPost : (forum['lastPost'] as Map<String, dynamic>?);
            final String? onlineUsers = forum is Map<String, dynamic> ? forum['onlineUsers'] : null;

            final bool isSelected = isDeleteMode && (selectedForDeletion?.contains(forum) ?? false);

            final VoidCallback? categoryTap;
            if (isDeleteMode) {
              categoryTap = () {
                if (onItemSelectionToggle != null) {
                  onItemSelectionToggle!(forum, !isSelected);
                }
              };
            } else if (onCategoryTap != null) {
              categoryTap = () => onCategoryTap!(context, title);
            } else {
              categoryTap = () {
                final slug = getCategorySlug(title);
                GoRouter.of(context).push('/forum/category/$slug');
              };
            }

            Widget leadingWidget;
            if (isDeleteMode) {
              leadingWidget = SizedBox(
                width: 32,
                height: 32,
                child: Center(
                  child: Checkbox(
                    value: isSelected,
                    activeColor: const Color(0xFFEF5350),
                    checkColor: Colors.white,
                    side: const BorderSide(color: Color(0xFF8E9BAE), width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
                    onChanged: (val) {
                      if (onItemSelectionToggle != null) {
                        onItemSelectionToggle!(forum, val);
                      }
                    },
                  ),
                ),
              );
            } else {
              // Bọc vùng Icon bằng InkWell độc lập
              leadingWidget = InkWell(
                onTap: categoryTap,
                borderRadius: BorderRadius.circular(16),
                child: buildForumIcon(forum),
              );
            }

            return Container(
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF3B1E22)
                    : (isHighlighted ? const Color(0xFF382E1E) : const Color(0xFF161F36)),
                border: isLast ? null : const Border(bottom: BorderSide(color: Color(0xFF2E3B5F))),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Cột 1 (Hình 1): Nút Icon và Tên chuyên mục bọc InkWell độc lập
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        leadingWidget,
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              InkWell(
                                onTap: categoryTap,
                                borderRadius: BorderRadius.circular(4),
                                child: Text(
                                  title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: isSelected
                                        ? const Color(0xFFEF5350)
                                        : (isHighlighted ? const Color(0xFFFFD54F) : Colors.white),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                description,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 13, color: Colors.white70, height: 1.3),
                              ),
                              if (onlineUsers != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  onlineUsers,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 12, color: Color(0xFFEF5350), fontWeight: FontWeight.w500),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Cột 2 & Cột 3 (Hình 2): Thống kê Chủ đề và Bài viết tĩnh, vô hiệu hóa click
                  SizedBox(
                    width: 65,
                    child: Text(
                      '$topics',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 13, color: Colors.white70),
                    ),
                  ),
                  SizedBox(
                    width: 70,
                    child: Text(
                      '$posts',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 13, color: Colors.white70),
                    ),
                  ),
                  // Cột 4 (Hình 3 & 4): Bài cuối với 2 Link điều hướng độc lập & Text tĩnh thời gian
                  SizedBox(
                    width: 250,
                    child: (lastPost == null || lastPost.isEmpty || (lastPost['title'] == null && lastPost['author'] == null))
                        ? const Text('Chưa có bài viết', style: TextStyle(fontSize: 12, color: Colors.white38, fontStyle: FontStyle.italic))
                        : _LastPostLink(lastPost: lastPost),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 650) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: 750,
              child: tableContent,
            ),
          );
        }
        return tableContent;
      },
    );
  }

  static String getCategorySlug(String title) {
    final t = title.toLowerCase();
    if (t.contains('thông báo')) return 'thong-bao-su-kien';
    if (t.contains('cơ bản')) return 'kien-thuc-co-ban';
    if (t == 'kiến thức tử vi' || (t.contains('tử vi') && t.contains('kiến thức'))) return 'kien-thuc-tu-vi';
    if (t.contains('tứ trụ') && t.contains('kiến thức')) return 'kien-thuc-tu-tru';
    if (t.contains('độn toán')) return 'kien-thuc-don-toan';
    if (t.contains('phong thủy') && t.contains('kiến thức')) return 'kien-thuc-phong-thuy';
    if (t.contains('sinh trắc') && t.contains('kiến thức')) return 'kien-thuc-sinh-trac';
    if (t.contains('phương tây') && t.contains('lý số')) return 'ly-so-phuong-tay';
    if (t.contains('lý số khác')) return 'kien-thuc-ly-so-khac';
    if (t.contains('thư ngỏ') || t.contains('ý kiến')) return 'thu-ngo-y-kien';
    if (t.contains('lớp học tử vi') || t == 'lớp tử vi') return 'lop-hoc-tu-vi';
    if (t.contains('lớp học tứ trụ') || t == 'lớp tứ trụ') return 'lop-hoc-tu-tru';
    if (t.contains('lớp học chiêm tinh') || t.contains('chiêm tinh')) return 'lop-hoc-chiem-tinh';
    if (t.contains('lớp học phong thủy')) return 'lop-hoc-phong-thuy';
    if (t.contains('lớp học tổng hợp')) return 'lop-hoc-tong-hop';
    if (t.contains('lớp học dịch lý') || t.contains('dịch lý')) return 'lop-hoc-dich-ly';
    if (t.contains('hướng nghiệp')) return 'huong-nghiep';
    if (t.contains('xem tử vi')) return 'xem-tu-vi';
    if (t.contains('xem tứ trụ')) return 'xem-tu-tru';
    if (t.contains('xem quẻ')) return 'xem-que';
    if (t.contains('xem phong thủy')) return 'xem-phong-thuy';
    if (t.contains('xem ngày') || t.contains('luận tuổi')) return 'xem-ngay-luan-tuoi';
    if (t.contains('xem lý số')) return 'xem-ly-so-phuong-tay';
    if (t.contains('tướng') || t.contains('đặt tên')) return 'xem-tuong-dat-ten-sinh-trac';
    if (t.contains('môn khác')) return 'xem-bang-cac-mon-khac';
    if (t.contains('cổ học') || t.contains('văn hóa')) return 'co-hoc-van-hoa-tin-nguong';
    if (t.contains('cuộc sống')) return 'cuoc-song-muon-mau';
    if (t.contains('câu lạc bộ') || t.contains('giao lưu')) return 'cau-lac-bo-giao-luu-ket-ban';
    return 'thong-bao-su-kien';
  }
}

class _LastPostLink extends StatefulWidget {
  final Map<String, dynamic> lastPost;
  const _LastPostLink({super.key, required this.lastPost});

  @override
  State<_LastPostLink> createState() => _LastPostLinkState();
}

class _LastPostLinkState extends State<_LastPostLink> {
  late import_gestures.TapGestureRecognizer _titleRecognizer;
  late import_gestures.TapGestureRecognizer _authorRecognizer;
  bool _isTitleHovered = false;
  bool _isAuthorHovered = false;

  @override
  void initState() {
    super.initState();
    final postId = widget.lastPost['postId'] ?? widget.lastPost['id'] ?? '1';
    _titleRecognizer = import_gestures.TapGestureRecognizer()
      ..onTap = () {
        GoRouter.of(context).push('/forum/post/$postId');
      };
    final author = widget.lastPost['author'] ?? 'nncuong';
    _authorRecognizer = import_gestures.TapGestureRecognizer()
      ..onTap = () {
        GoRouter.of(context).push('/forum/member/$author');
      };
  }

  @override
  void dispose() {
    _titleRecognizer.dispose();
    _authorRecognizer.dispose();
    super.dispose();
  }

  String formatTime(String timeStr) {
    return timeStr;
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.lastPost['title']?.toString() ?? '';
    final author = widget.lastPost['author']?.toString() ?? '';
    final timeStr = widget.lastPost['time']?.toString() ?? '';
    final authorColor = widget.lastPost['authorColor'] is Color
        ? widget.lastPost['authorColor'] as Color
        : const Color(0xFFEF5350);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // RichText cho Tiêu đề bài và Tên tác giả (Hình 3, 4 & 10)
        RichText(
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          text: TextSpan(
            style: const TextStyle(fontSize: 12, color: Colors.white60, height: 1.4),
            children: [
              if (title.isNotEmpty) ...[
                TextSpan(
                  text: '$title\n',
                  mouseCursor: SystemMouseCursors.click,
                  onEnter: (_) {
                    if (mounted) setState(() => _isTitleHovered = true);
                  },
                  onExit: (_) {
                    if (mounted) setState(() => _isTitleHovered = false);
                  },
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: Colors.white,
                    decoration: _isTitleHovered
                        ? TextDecoration.underline
                        : TextDecoration.none,
                  ),
                  recognizer: _titleRecognizer,
                ),
              ],
              const TextSpan(text: 'gửi bởi '),
              TextSpan(
                text: author,
                mouseCursor: SystemMouseCursors.click,
                onEnter: (_) {
                  if (mounted) setState(() => _isAuthorHovered = true);
                },
                onExit: (_) {
                  if (mounted) setState(() => _isAuthorHovered = false);
                },
                style: TextStyle(
                  color: authorColor,
                  fontWeight: FontWeight.bold,
                  decoration: _isAuthorHovered
                      ? TextDecoration.underline
                      : TextDecoration.none,
                ),
                recognizer: _authorRecognizer,
              ),
              const TextSpan(
                text: ' ↗',
                style: TextStyle(fontSize: 11, color: Colors.white54),
              ),
            ],
          ),
        ),
        // Đoạn thời gian tách thành Text tĩnh nằm ngoài vùng bấm
        if (timeStr.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            formatTime(timeStr),
            style: const TextStyle(fontSize: 12, color: Colors.white54),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }
}
