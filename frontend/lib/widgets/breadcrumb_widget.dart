import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/breadcrumb_state_service.dart';
import '../services/ucp_state_service.dart';
import '../utils/uri_safe_extension.dart';
import '../utils/forum_text_helper.dart';

class BreadcrumbWidget extends StatefulWidget {
  const BreadcrumbWidget({super.key});

  @override
  State<BreadcrumbWidget> createState() => _BreadcrumbWidgetState();
}

class _BreadcrumbWidgetState extends State<BreadcrumbWidget> {
  bool _isLoggedIn = true; // Default to true to prevent flickering before check

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
    UcpStateService.navigationState.addListener(_onUcpStateChanged);
    BreadcrumbStateService.currentTopic.addListener(_onUcpStateChanged);
  }

  @override
  void dispose() {
    UcpStateService.navigationState.removeListener(_onUcpStateChanged);
    BreadcrumbStateService.currentTopic.removeListener(_onUcpStateChanged);
    super.dispose();
  }

  void _onUcpStateChanged() {
    if (mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {});
        }
      });
    }
  }

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    if (mounted) {
      setState(() {
        _isLoggedIn = token != null && token.isNotEmpty;
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    GoRouterState.of(context);
    _checkLoginStatus();
  }

  @override
  Widget build(BuildContext context) {
    // Lấy uri và state hiện tại từ go_router
    final routerState = GoRouterState.of(context);
    final uri = routerState.uri;
    final path = uri.path;

    // Không hiển thị thanh Breadcrumb và SubNavigation khi đang ở Trang chủ ('/')
    if (path == '/') {
      return const SizedBox.shrink();
    }

    final rawExtra = routerState.extra;
    final Map<String, dynamic>? extra = rawExtra is Map<String, dynamic>
        ? rawExtra
        : (rawExtra is Map ? Map<String, dynamic>.from(rawExtra) : null);

    // Phân tích và gán chuỗi breadcrumb dựa trên path
    List<Widget> breadcrumbs = [
      const Icon(Icons.home, color: Color(0xFF8B0000), size: 18),
      const SizedBox(width: 4),
      _buildCrumbText('Trang chủ', onTap: () => context.go('/')),
    ];

    if (path == '/apps' || path == '/applications') {
      breadcrumbs.addAll([
        _buildDivider(),
        _buildCrumbText('Ứng dụng'),
      ]);
    } else if (path == '/almanac') {
      breadcrumbs.addAll([
        _buildDivider(),
        _buildCrumbText('Ứng dụng', onTap: () => context.go('/apps')),
        _buildDivider(),
        _buildCrumbText('Lịch vạn sự'),
      ]);
    } else if (path == '/horoscope') {
      breadcrumbs.addAll([
        _buildDivider(),
        _buildCrumbText('Ứng dụng', onTap: () => context.go('/apps')),
        _buildDivider(),
        _buildCrumbText('Lá số Tử vi'),
      ]);
    } else if (path == '/forum') {
      breadcrumbs.addAll([
        _buildDivider(),
        _buildCrumbText('Diễn đàn'),
      ]);
    } else if (path == '/forum/create-category') {
      breadcrumbs.addAll([
        _buildDivider(),
        _buildCrumbText('Diễn đàn', onTap: () => context.go('/forum')),
        _buildDivider(),
        _buildCrumbText('Tạo thêm Chuyên mục và Lớp học Lý số mới (Admin)'),
      ]);
    } else if (path == '/forum/create-topic') {
      final qParams = uri.queryParameters;
        String slug = qParams['categorySlug'] ?? extra?['categorySlug'] as String? ?? 'thong-bao-su-kien';
      String? customTitle = qParams['categoryTitle'] ?? extra?['categoryTitle'] as String?;
      String title = _resolveCategoryTitle(slug, customTitle);

      breadcrumbs.addAll([
        _buildDivider(),
        _buildCrumbText('Diễn đàn', onTap: () => context.go('/forum')),
        _buildDivider(),
        _buildCrumbText(title, onTap: () => context.go('/forum/category/$slug')),
        _buildDivider(),
        _buildCrumbText(ForumTextHelper.getCreatePageTitle(slug)),
      ]);
    } else if (path == '/forum/edit-topics' ||
               path.endsWith('/edit-topics') ||
               path == '/forum/edit-topic-form' ||
               path.endsWith('/edit-topic-form')) {
      final qParams = uri.queryParameters;
  
      String slug = qParams['categorySlug'] ?? extra?['categorySlug'] as String? ?? '';
      if (slug.isEmpty && uri.pathSegments.contains('category')) {
        final catIdx = uri.pathSegments.indexOf('category');
        if (catIdx + 1 < uri.pathSegments.length) {
          slug = uri.pathSegments[catIdx + 1];
        }
      }
      if (slug.isEmpty) slug = 'thong-bao-su-kien';

      String? customTitle = qParams['categoryTitle'] ?? extra?['categoryTitle'] as String?;
      String title = _resolveCategoryTitle(slug, customTitle);

      breadcrumbs.addAll([
        _buildDivider(),
        _buildCrumbText('Diễn đàn', onTap: () => context.go('/forum')),
        _buildDivider(),
        _buildCrumbText(title, onTap: () => context.go('/forum/category/$slug')),
        _buildDivider(),
        _buildCrumbText(ForumTextHelper.getCreatePageTitle(slug, isEditMode: true)),
      ]);
    } else if (path == '/forum/delete-topics' ||
               path.endsWith('/delete-topics')) {
      final qParams = uri.queryParameters;

      String slug = qParams['categorySlug'] ?? extra?['categorySlug'] as String? ?? '';
      if (slug.isEmpty && uri.pathSegments.contains('category')) {
        final catIdx = uri.pathSegments.indexOf('category');
        if (catIdx + 1 < uri.pathSegments.length) {
          slug = uri.pathSegments[catIdx + 1];
        }
      }
      if (slug.isEmpty) slug = 'thong-bao-su-kien';

      String? customTitle = qParams['categoryTitle'] ?? extra?['categoryTitle'] as String?;
      String title = _resolveCategoryTitle(slug, customTitle);

      breadcrumbs.addAll([
        _buildDivider(),
        _buildCrumbText('Diễn đàn', onTap: () => context.go('/forum')),
        _buildDivider(),
        _buildCrumbText(title, onTap: () => context.go('/forum/category/')),
        _buildDivider(),
        _buildCrumbText(ForumTextHelper.getDeletePageTitle(slug)),
      ]);
    } else if (path == '/forum/delete-categories' || path == '/forum/admin-delete-categories') {
      breadcrumbs.addAll([
        _buildDivider(),
        _buildCrumbText('Diễn đàn', onTap: () => context.go('/forum')),
        _buildDivider(),
        _buildCrumbText('Xóa các Chuyên mục và Lớp học Lý số (Admin)'),
      ]);
    } else if (path == '/forum/edit-categories' || path == '/forum/admin-edit-categories' || path == '/forum/edit-category-form') {
      breadcrumbs.addAll([
        _buildDivider(),
        _buildCrumbText('Diễn đàn', onTap: () => context.go('/forum')),
        _buildDivider(),
        _buildCrumbText('Sửa Chuyên mục và Lớp học Lý số (Admin)'),
      ]);
    } else if (path == '/forum/new-posts') {
      breadcrumbs.addAll([
        _buildDivider(),
        _buildCrumbText('Diễn đàn', onTap: () => context.go('/forum')),
        _buildDivider(),
        _buildCrumbText('Bài viết mới'),
      ]);
    } else if (path == '/forum/unread-posts') {
      breadcrumbs.addAll([
        _buildDivider(),
        _buildCrumbText('Diễn đàn', onTap: () => context.go('/forum')),
        _buildDivider(),
        _buildCrumbText('Bài chưa xem'),
      ]);
    } else if (path == '/forum/your-posts' || path == '/forum/user-posts') {
      breadcrumbs.addAll([
        _buildDivider(),
        _buildCrumbText('Diễn đàn', onTap: () => context.go('/forum')),
        _buildDivider(),
        _buildCrumbText('Bài của bạn'),
      ]);
    } else if (path == '/forum/unanswered-posts') {
      breadcrumbs.addAll([
        _buildDivider(),
        _buildCrumbText('Diễn đàn', onTap: () => context.go('/forum')),
        _buildDivider(),
        _buildCrumbText('Bài chưa được trả lời'),
      ]);
    } else if (path == '/forum/search') {
      breadcrumbs.addAll([
        _buildDivider(),
        _buildCrumbText('Diễn đàn', onTap: () => context.go('/forum')),
        _buildDivider(),
        _buildCrumbText('Tìm kiếm'),
      ]);
    } else if (path == '/forum/faq') {
      breadcrumbs.addAll([
        _buildDivider(),
        _buildCrumbText('Diễn đàn', onTap: () => context.go('/forum')),
        _buildDivider(),
        _buildCrumbText('Hỏi đáp'),
      ]);
    } else if (path == '/forum/inbox' || path == '/forum/messages') {
      breadcrumbs.addAll([
        _buildDivider(),
        _buildCrumbText('Diễn đàn', onTap: () => context.go('/forum')),
        _buildDivider(),
        _buildCrumbText(
          'Thiết lập cá nhân',
          onTap: () {
            context.go('/forum/ucp');
            UcpStateService.reset();
            UcpStateService.onResetToOverview?.call();
          },
        ),
        _buildDivider(),
        _buildCrumbText(
          'Tin nhắn',
          onTap: () {
            context.go('/forum/ucp/messages');
            UcpStateService.setSubItem('Tin nhắn', 'Soạn tin nhắn');
            UcpStateService.onClearSubItem?.call();
          },
        ),
        _buildDivider(),
        _buildCrumbText('Soạn tin nhắn'),
      ]);
    } else if (path == '/forum/ucp' || path.startsWith('/forum/ucp/')) {
      final ucpState = UcpStateService.navigationState.value;
      var currentTab = ucpState.tab;
      var currentSub = ucpState.subItem;

      if (path == '/forum/ucp/system' || currentTab == 'Hệ thống') {
        currentTab = 'Hệ thống';
        if (currentSub == null || currentSub == 'Trang trước') {
          currentSub = 'Sửa thiết lập gửi bài viết';
        }
      } else if (path == '/forum/ucp/personal' || currentTab == 'Cá nhân') {
        currentTab = 'Cá nhân';
        if (currentSub == null || currentSub == 'Trang trước') {
          currentSub = 'Sửa thông tin cá nhân';
        }
      } else if (path == '/forum/ucp/messages' || currentTab == 'Tin nhắn') {
        currentTab = 'Tin nhắn';
        if (currentSub == null || currentSub == 'Trang trước') {
          currentSub = 'Soạn tin nhắn';
        }
      }

      breadcrumbs.addAll([
        _buildDivider(),
        _buildCrumbText('Diễn đàn', onTap: () => context.go('/forum')),
        _buildDivider(),
        _buildCrumbText(
          'Thiết lập cá nhân',
          onTap: () {
            if (path != '/forum/ucp') {
              context.go('/forum/ucp');
            }
            UcpStateService.reset();
            UcpStateService.onResetToOverview?.call();
          },
        ),
        _buildDivider(),
        if (currentSub != null) ...[
          _buildCrumbText(
            currentTab,
            onTap: () {
              if (currentTab == 'Hệ thống') {
                UcpStateService.setSubItem('Hệ thống', 'Sửa thiết lập gửi bài viết');
              } else if (currentTab == 'Cá nhân') {
                UcpStateService.setSubItem('Cá nhân', 'Sửa thông tin cá nhân');
              } else if (currentTab == 'Tin nhắn') {
                UcpStateService.setSubItem('Tin nhắn', 'Soạn tin nhắn');
              } else {
                UcpStateService.setTab(currentTab);
              }
              UcpStateService.onClearSubItem?.call();
            },
          ),
          _buildDivider(),
          _buildCrumbText(currentSub),
        ] else ...[
          _buildCrumbText(currentTab),
        ],
      ]);
    } else if (path == '/forum/members') {
      breadcrumbs.addAll([
        _buildDivider(),
        _buildCrumbText('Diễn đàn', onTap: () => context.go('/forum')),
        _buildDivider(),
        _buildCrumbText('Thành viên'),
      ]);
    } else if (path == '/forum/team' || path == '/forum/about-us') {
      breadcrumbs.addAll([
        _buildDivider(),
        _buildCrumbText('Diễn đàn', onTap: () => context.go('/forum')),
        _buildDivider(),
        _buildCrumbText('Chúng tôi'),
      ]);
    } else if (path == '/forum/recent-posts') {
      breadcrumbs.addAll([
        _buildDivider(),
        _buildCrumbText('Diễn đàn', onTap: () => context.go('/forum')),
        _buildDivider(),
        _buildCrumbText('Bài gần đây'),
      ]);
    } else if (path.startsWith('/forum/category') ||
               path == '/forum/thong-bao-su-kien' ||
               path == '/forum/kien-thuc-co-ban' ||
               path == '/forum/kien-thuc-tu-vi' ||
               path == '/forum/kien-thuc-tu-tru' ||
               path == '/forum/kien-thuc-don-toan' ||
               path == '/forum/kien-thuc-phong-thuy' ||
               path == '/forum/kien-thuc-sinh-trac' ||
               path == '/forum/ly-so-phuong-tay' ||
               path == '/forum/kien-thuc-ly-so-khac' ||
               path == '/forum/thu-ngo-y-kien' ||
               path == '/forum/lop-hoc-tu-vi' ||
               path == '/forum/lop-hoc-tu-tru' ||
               path == '/forum/lop-hoc-chiem-tinh' ||
               path == '/forum/lop-hoc-phong-thuy' ||
               path == '/forum/lop-hoc-tong-hop' ||
               path == '/forum/lop-hoc-dich-ly' ||
               path == '/forum/huong-nghiep' ||
               path == '/forum/xem-tu-vi' ||
               path == '/forum/xem-tu-tru' ||
               path == '/forum/xem-que' ||
               path == '/forum/xem-phong-thuy' ||
               path == '/forum/xem-ngay-luan-tuoi' ||
               path == '/forum/xem-ly-so-phuong-tay' ||
               path == '/forum/xem-tuong-dat-ten-sinh-trac' ||
               path == '/forum/xem-bang-cac-mon-khac' ||
               path == '/forum/co-hoc-van-hoa-tin-nguong' ||
               path == '/forum/cuoc-song-muon-mau' ||
               path == '/forum/cau-lac-bo-giao-luu-ket-ban') {
      final segments = uri.pathSegments;
      final slug = segments.length > 2 ? segments.last : path.replaceFirst('/forum/', '');
      String title = 'Thông báo - Sự kiện';
      if (slug.contains('huong-nghiep')) {
        title = 'Hướng nghiệp';
      } else if (slug.contains('cuoc-song-muon-mau') || slug.contains('cuoc-song')) {
        title = 'Cuộc sống muôn màu';
      } else if (slug.contains('cau-lac-bo') || slug.contains('giao-luu-ket-ban')) {
        title = 'Câu lạc bộ - Giao lưu - Kết bạn';
      } else if (slug.contains('xem-bang-cac-mon-khac') || slug.contains('cac-mon-khac')) {
        title = 'Xem bằng các môn khác';
      } else if (slug.contains('co-hoc') || slug.contains('van-hoa') || slug.contains('tin-nguong')) {
        title = 'Cổ học - Văn hóa - Tín ngưỡng';
      } else if (slug.contains('xem-ly-so-phuong-tay') || slug == 'xem-phuong-tay') {
        title = 'Xem Lý số Phương tây';
      } else if (slug.contains('xem-tuong') || slug.contains('dat-ten') || slug.contains('xem-tuong-dat-ten-sinh-trac')) {
        title = 'Xem tướng, đặt tên, sinh trắc';
      } else if (slug.contains('xem-tu-vi') || slug == 'tu-vi-xem') {
        title = 'Xem Tử vi';
      } else if (slug.contains('xem-tu-tru') || slug == 'tu-tru-xem') {
        title = 'Xem Tứ trụ';
      } else if (slug.contains('xem-que') || slug == 'que-xem') {
        title = 'Xem quẻ';
      } else if (slug.contains('xem-phong-thuy') || slug == 'phong-thuy-xem') {
        title = 'Xem Phong thủy';
      } else if (slug.contains('xem-ngay') || slug.contains('luan-tuoi') || slug == 'xem-ngay-luan-tuoi') {
        title = 'Xem ngày, luận tuổi';
      } else if (slug.contains('lop-hoc-tu-vi') || slug == 'lop-tu-vi') {
        title = 'Lớp học tử vi';
      } else if (slug.contains('lop-hoc-tu-tru') || slug == 'lop-tu-tru') {
        title = 'Lớp học tứ trụ';
      } else if (slug.contains('lop-hoc-chiem-tinh') || slug == 'lop-chiem-tinh' || slug.contains('chiem-tinh')) {
        title = 'Lớp học chiêm tinh';
      } else if (slug.contains('lop-hoc-phong-thuy') || slug == 'lop-phong-thuy') {
        title = 'Lớp học Phong thủy';
      } else if (slug.contains('lop-hoc-tong-hop') || slug == 'lop-tong-hop' || slug.contains('tong-hop')) {
        title = 'Lớp học tổng hợp';
      } else if (slug.contains('lop-hoc-dich-ly') || slug == 'lop-dich-ly' || slug.contains('dich-ly')) {
        title = 'Lớp học Dịch lý';
      } else if (slug.contains('sinh-trac')) {
        title = 'Kiến thức Sinh trắc';
      } else if (slug.contains('phuong-tay')) {
        title = 'Lý số Phương Tây';
      } else if (slug.contains('ly-so-khac')) {
        title = 'Kiến thức Lý số khác';
      } else if (slug.contains('thu-ngo') || slug.contains('y-kien')) {
        title = 'Thư ngỏ - Ý kiến';
      } else if (slug.contains('don-toan')) {
        title = 'Kiến thức Độn toán';
      } else if (slug.contains('phong-thuy')) {
        title = 'Kiến thức Phong thủy';
      } else if (slug.contains('tu-vi')) {
        title = 'Kiến thức Tử vi';
      } else if (slug.contains('tu-tru')) {
        title = 'Kiến thức Tứ trụ';
      } else if (slug.contains('co-ban') || slug == 'kien-thuc') {
        title = 'Kiến thức Cơ bản';
      }
      breadcrumbs.addAll([
        _buildDivider(),
        _buildCrumbText('Diễn đàn', onTap: () => context.go('/forum')),
        _buildDivider(),
        _buildCrumbText(title),
      ]);
    } else if (path.startsWith('/forum/member') || path.startsWith('/forum/user')) {
      final segments = uri.pathSegments;
      final username = segments.length > 2 ? segments.last : 'hoangnguyenhuu';
      breadcrumbs.addAll([
        _buildDivider(),
        _buildCrumbText('Diễn đàn', onTap: () => context.go('/forum')),
        _buildDivider(),
        _buildCrumbText('Thành viên'),
        _buildDivider(),
        _buildCrumbText(username),
      ]);
    } else if (path == '/contact') {
      breadcrumbs.addAll([
        _buildDivider(),
        _buildCrumbText('Diễn đàn', onTap: () => context.go('/forum')),
        _buildDivider(),
        _buildCrumbText('Liên hệ'),
      ]);
    } else if (path == '/login' || path == '/terms') {
      breadcrumbs.addAll([
        _buildDivider(),
        _buildCrumbText('Thành viên'),
        _buildDivider(),
        _buildCrumbText('Đăng nhập'),
      ]);
    } else if (path == '/forgot-password') {
      breadcrumbs.addAll([
        _buildDivider(),
        _buildCrumbText('Thành viên', onTap: () => context.go('/login')),
        _buildDivider(),
        _buildCrumbText('Đặt lại mật khẩu'),
      ]);
    } else if (path == '/resend-activation') {
      breadcrumbs.addAll([
        _buildDivider(),
        _buildCrumbText('Thành viên', onTap: () => context.go('/login')),
        _buildDivider(),
        _buildCrumbText('Kích hoạt tài khoản'),
      ]);
    } else if (path == '/verify') {
      breadcrumbs.addAll([
        _buildDivider(),
        _buildCrumbText('Xác thực Email'),
      ]);
    } else if (path == '/shared') {
      breadcrumbs.addAll([
        _buildDivider(),
        _buildCrumbText('Lá số chia sẻ'),
      ]);
    } else if (path.startsWith('/forum/post/') || path.startsWith('/forum/topic/')) {
      final qParams = uri.queryParameters;
      String topicId = '';
      if (uri.pathSegments.isNotEmpty) {
        final lastSeg = uri.pathSegments.last;
        if (lastSeg == 'reply' && uri.pathSegments.length >= 2) {
          topicId = uri.pathSegments[uri.pathSegments.length - 2];
        } else {
          topicId = lastSeg;
        }
      }

      // Navigation State Guard (Chuẩn 2026): Lấy từ extra hoặc fallback sang StateProvider toàn cục
      final cached = BreadcrumbStateService.getCachedTopic(topicId);
      final rawSlug = extra?['categorySlug'] as String? ?? qParams['categorySlug'] ?? cached?.categorySlug ?? '';
      final slug = rawSlug.isNotEmpty ? rawSlug : 'thong-bao-su-kien';
      final customTitle = extra?['categoryTitle'] as String? ?? qParams['categoryTitle'] ?? cached?.categoryTitle;
      final catTitle = (customTitle != null && customTitle.trim().isNotEmpty)
          ? customTitle.trim()
          : _resolveCategoryTitle(slug, null);

      final rawTopicTitle = extra?['topicTitle'] as String? ?? extra?['title'] as String? ?? qParams['title'] ?? cached?.topicTitle;
      final topicTitle = (rawTopicTitle != null && rawTopicTitle.trim().isNotEmpty)
          ? rawTopicTitle.trim()
          : 'Chi tiết bài viết';

      breadcrumbs.addAll([
        _buildDivider(),
        _buildCrumbText('Diễn đàn', onTap: () => context.go('/forum')),
        _buildDivider(),
        _buildCrumbText(catTitle, onTap: () {
          if (slug.isNotEmpty && slug != 'null') {
            context.go('/forum/category/$slug');
          } else {
            context.go('/forum');
          }
        }),
        _buildDivider(),
        _buildCrumbText(topicTitle),
      ]);
    }

    return SizedBox(
      width: double.infinity,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Thanh Breadcrumb đường dẫn
          Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: const BoxDecoration(
                    color: Color(0xFF131A30), // Nền Dark Navy tối thanh lịch
                    border: Border(
                      bottom: BorderSide(color: Colors.white24, width: 1),
                    ),
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: breadcrumbs,
                    ),
                  ),
                ),
                // 2. Thanh SubNavigation các chức năng diễn đàn
                if (_isLoggedIn) _buildLoggedInSubNavigation(path) else _buildSubNavigation(path),
        ],
      ),
    );
  }

  Widget _buildSubNavigation(String currentPath) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: const BoxDecoration(
        color: Color(0xFF1E2640), // Nền Tím Đen / Dark Navy đồng bộ Card nội dung
        border: Border(
          bottom: BorderSide(color: Colors.white24, width: 1),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildSubNavItem(
              Icons.description_outlined,
              Colors.lightBlueAccent,
              'Bài gần đây',
              isActive: currentPath == '/forum/recent-posts',
              onTap: () => context.go('/forum/recent-posts'),
            ),
            const SizedBox(width: 16),
            _buildSubNavItem(
              Icons.assignment_late,
              const Color(0xFFEF5350),
              'Bài chưa được trả lời',
              isActive: currentPath == '/forum/unanswered-posts',
              onTap: () => context.go('/forum/unanswered-posts'),
            ),
            const SizedBox(width: 16),
            _buildSubNavItem(
              Icons.search,
              const Color(0xFFEF5350),
              'Tìm kiếm',
              isActive: currentPath == '/forum/search',
              onTap: () => context.go('/forum/search'),
            ),
            const SizedBox(width: 16),
            _buildSubNavItem(
              Icons.help_outline,
              const Color(0xFFEF5350),
              'Hỏi đáp',
              isActive: currentPath == '/forum/faq',
              onTap: () => context.go('/forum/faq'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoggedInSubNavigation(String currentPath) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: const BoxDecoration(
        color: Color(0xFF1E2640), // Nền Tím Đen / Dark Navy đồng bộ Card nội dung
        border: Border(
          bottom: BorderSide(color: Colors.white24, width: 1),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildQuickLinksMenu(currentPath),
            const SizedBox(width: 16),
            _buildSubNavItem(
              Icons.description,
              const Color(0xFFEF5350),
              'Bài viết mới',
              isActive: currentPath == '/forum/new-posts',
              onTap: () => context.go('/forum/new-posts'),
            ),
            const SizedBox(width: 16),
            _buildSubNavItem(
              Icons.description_outlined,
              Colors.lightBlueAccent,
              'Bài gần đây',
              isActive: currentPath == '/forum/recent-posts',
              onTap: () => context.go('/forum/recent-posts'),
            ),
            const SizedBox(width: 16),
            _buildSubNavItem(
              Icons.file_present,
              const Color(0xFFEF5350),
              'Bài của bạn',
              isActive: currentPath == '/forum/your-posts' || currentPath == '/forum/user-posts',
              onTap: () => context.go('/forum/your-posts'),
            ),
            const SizedBox(width: 16),
            _buildSubNavItem(
              Icons.mark_as_unread,
              const Color(0xFFEF5350),
              'Bài chưa xem',
              isActive: currentPath == '/forum/unread-posts',
              onTap: () => context.go('/forum/unread-posts'),
            ),
            const SizedBox(width: 16),
            _buildSubNavItem(
              Icons.assignment_late,
              const Color(0xFFEF5350),
              'Bài chưa được trả lời',
              isActive: currentPath == '/forum/unanswered-posts',
              onTap: () => context.go('/forum/unanswered-posts'),
            ),
            const SizedBox(width: 16),
            _buildSubNavItem(
              Icons.search,
              const Color(0xFFEF5350),
              'Tìm kiếm',
              isActive: currentPath == '/forum/search',
              onTap: () => context.go('/forum/search'),
            ),
            const SizedBox(width: 16),
            _buildSubNavItem(
              Icons.help_outline,
              const Color(0xFFEF5350),
              'Hỏi đáp',
              isActive: currentPath == '/forum/faq',
              onTap: () => context.go('/forum/faq'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickLinksMenu(String currentPath) {
    final activeMap = {
      'dien_dan': currentPath == '/forum',
      'new_posts': currentPath == '/forum/new-posts',
      'recent_posts': currentPath == '/forum/recent-posts',
      'your_posts': currentPath == '/forum/your-posts' || currentPath == '/forum/user-posts',
      'unread_posts': currentPath == '/forum/unread-posts',
      'unanswered_posts': currentPath == '/forum/unanswered-posts',
      'search': currentPath == '/forum/search',
      'faq': currentPath == '/forum/faq',
      'members': currentPath == '/forum/members',
      'team': currentPath == '/forum/team' || currentPath == '/forum/about-us',
    };
    final isAnyActive = activeMap.values.any((v) => v);

    PopupMenuItem<String> buildMenuItem({
      required String value,
      required IconData icon,
      required String label,
      required bool isActive,
    }) {
      return PopupMenuItem<String>(
        value: value,
        height: 38,
        child: Row(
          children: [
            Icon(
              icon,
              color: isActive ? const Color(0xFFFFD700) : const Color(0xFFEF5350),
              size: 16,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: isActive ? const Color(0xFFFFD700) : Colors.white,
                  fontSize: 13.5,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
    }

    return Theme(
      data: Theme.of(context).copyWith(
        cardColor: const Color(0xFF131A30),
      ),
      child: PopupMenuButton<String>(
        tooltip: 'Liên kết',
        constraints: const BoxConstraints(minWidth: 200, maxWidth: 280),
        offset: const Offset(0, 32),
        color: const Color(0xFF131A30),
        popUpAnimationStyle: AnimationStyle(
          duration: const Duration(milliseconds: 150),
          reverseDuration: const Duration(milliseconds: 120),
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: Color(0xFF2E3B5F), width: 1),
        ),
        onSelected: (value) {
          switch (value) {
            case 'dien_dan':
              context.go('/forum');
              break;
            case 'new_posts':
              context.go('/forum/new-posts');
              break;
            case 'recent_posts':
              context.go('/forum/recent-posts');
              break;
            case 'your_posts':
              context.go('/forum/your-posts');
              break;
            case 'unread_posts':
              context.go('/forum/unread-posts');
              break;
            case 'unanswered_posts':
              context.go('/forum/unanswered-posts');
              break;
            case 'search':
              context.go('/forum/search');
              break;
            case 'faq':
              context.go('/forum/faq');
              break;
            case 'members':
              context.go('/forum/members');
              break;
            case 'team':
              context.go('/forum/team');
              break;
          }
        },
        itemBuilder: (context) => [
          buildMenuItem(
            value: 'dien_dan',
            icon: Icons.forum,
            label: 'Trang chủ Diễn đàn',
            isActive: activeMap['dien_dan'] ?? false,
          ),
          const PopupMenuDivider(height: 1),
          buildMenuItem(
            value: 'new_posts',
            icon: Icons.description,
            label: 'Bài viết mới',
            isActive: activeMap['new_posts'] ?? false,
          ),
          buildMenuItem(
            value: 'recent_posts',
            icon: Icons.description_outlined,
            label: 'Bài gần đây',
            isActive: activeMap['recent_posts'] ?? false,
          ),
          buildMenuItem(
            value: 'your_posts',
            icon: Icons.file_present,
            label: 'Bài của bạn',
            isActive: activeMap['your_posts'] ?? false,
          ),
          buildMenuItem(
            value: 'unread_posts',
            icon: Icons.mark_as_unread,
            label: 'Bài chưa xem',
            isActive: activeMap['unread_posts'] ?? false,
          ),
          buildMenuItem(
            value: 'unanswered_posts',
            icon: Icons.assignment_late,
            label: 'Bài chưa được trả lời',
            isActive: activeMap['unanswered_posts'] ?? false,
          ),
          buildMenuItem(
            value: 'search',
            icon: Icons.search,
            label: 'Tìm kiếm',
            isActive: activeMap['search'] ?? false,
          ),
          buildMenuItem(
            value: 'faq',
            icon: Icons.help_outline,
            label: 'Hỏi đáp',
            isActive: activeMap['faq'] ?? false,
          ),
          const PopupMenuDivider(height: 1),
          buildMenuItem(
            value: 'members',
            icon: Icons.group,
            label: 'Thành viên',
            isActive: activeMap['members'] ?? false,
          ),
          buildMenuItem(
            value: 'team',
            icon: Icons.security,
            label: 'Chúng tôi',
            isActive: activeMap['team'] ?? false,
          ),
        ],
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.menu,
                  color: isAnyActive ? const Color(0xFFFFD700) : const Color(0xFFEF5350),
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  'Liên kết',
                  style: TextStyle(
                    color: isAnyActive ? const Color(0xFFFFD700) : const Color(0xFFEF5350),
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.underline,
                    decorationColor: isAnyActive ? const Color(0xFFFFD700) : const Color(0xFFEF5350),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSubNavItem(
    IconData icon,
    Color iconColor,
    String text, {
    bool isActive = false,
    TextStyle? textStyle,
    VoidCallback? onTap,
  }) {
    final effectiveColor = isActive ? const Color(0xFFFFD700) : (textStyle?.color ?? Colors.grey[300]);
    final effectiveIconColor = isActive ? const Color(0xFFFFD700) : iconColor;

    return InkWell(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: effectiveIconColor, size: 16),
          const SizedBox(width: 6),
          Text(
            text,
            style: textStyle?.copyWith(color: effectiveColor) ??
                TextStyle(
                  color: effectiveColor,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                  fontSize: 14,
                  shadows: isActive
                      ? const [Shadow(color: Color(0xFFFFD700), blurRadius: 8)]
                      : null,
                ),
          ),
        ],
      ),
    );
  }

  String _resolveCategoryTitle(String slug, String? customTitle) {
    if (customTitle != null && customTitle.trim().isNotEmpty) {
      return customTitle.safeUriDecode();
    }
    if (slug.contains('huong-nghiep')) return 'Hướng nghiệp';
    if (slug.contains('cuoc-song-muon-mau') || slug.contains('cuoc-song')) return 'Cuộc sống muôn màu';
    if (slug.contains('cau-lac-bo') || slug.contains('giao-luu-ket-ban')) return 'Câu lạc bộ - Giao lưu - Kết bạn';
    if (slug.contains('xem-bang-cac-mon-khac') || slug.contains('cac-mon-khac')) return 'Xem bằng các môn khác';
    if (slug.contains('co-hoc') || slug.contains('van-hoa') || slug.contains('tin-nguong')) return 'Cổ học - Văn hóa - Tín ngưỡng';
    if (slug.contains('xem-ly-so-phuong-tay') || slug == 'xem-phuong-tay') return 'Xem Lý số Phương tây';
    if (slug.contains('xem-tuong') || slug.contains('dat-ten') || slug.contains('xem-tuong-dat-ten-sinh-trac')) return 'Xem tướng, đặt tên, sinh trắc';
    if (slug.contains('xem-tu-vi') || slug == 'tu-vi-xem') return 'Xem Tử vi';
    if (slug.contains('xem-tu-tru') || slug == 'tu-tru-xem') return 'Xem Tứ trụ';
    if (slug.contains('xem-que') || slug == 'que-xem') return 'Xem quẻ';
    if (slug.contains('xem-phong-thuy') || slug == 'phong-thuy-xem') return 'Xem Phong thủy';
    if (slug.contains('xem-ngay') || slug.contains('luan-tuoi') || slug == 'xem-ngay-luan-tuoi') return 'Xem ngày, luận tuổi';
    if (slug.contains('lop-hoc-tu-vi') || slug == 'lop-tu-vi') return 'Lớp học Tử vi';
    if (slug.contains('lop-hoc-tu-tru') || slug == 'lop-tu-tru') return 'Lớp học tứ trụ';
    if (slug.contains('lop-hoc-chiem-tinh') || slug == 'lop-chiem-tinh' || slug.contains('chiem-tinh')) return 'Lớp học chiêm tinh';
    if (slug.contains('lop-hoc-phong-thuy') || slug == 'lop-phong-thuy') return 'Lớp học Phong thủy';
    if (slug.contains('lop-hoc-tong-hop') || slug == 'lop-tong-hop' || slug.contains('tong-hop')) return 'Lớp học tổng hợp';
    if (slug.contains('lop-hoc-dich-ly') || slug == 'lop-dich-ly' || slug.contains('dich-ly')) return 'Lớp học Dịch lý';
    if (slug.contains('sinh-trac')) return 'Kiến thức Sinh trắc';
    if (slug.contains('phuong-tay')) return 'Lý số Phương Tây';
    if (slug.contains('ly-so-khac')) return 'Kiến thức Lý số khác';
    if (slug.contains('thu-ngo') || slug.contains('y-kien')) return 'Thư ngỏ - Ý kiến';
    if (slug.contains('don-toan')) return 'Kiến thức Độn toán';
    if (slug.contains('phong-thuy')) return 'Kiến thức Phong thủy';
    if (slug.contains('tu-vi')) return 'Kiến thức Tử vi';
    if (slug.contains('tu-tru')) return 'Kiến thức Tứ trụ';
    if (slug.contains('co-ban') || slug == 'kien-thuc' || slug.contains('kien-thuc')) return 'Kiến thức Cơ bản';
    return 'Thông báo - Sự kiện';
  }

  Widget _buildDivider() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 6),
      child: Icon(Icons.keyboard_arrow_left, color: Colors.white38, size: 16, textDirection: TextDirection.rtl),
    );
  }

  Widget _buildCrumbText(String text, {VoidCallback? onTap}) {
    final isClickable = onTap != null;
    return MouseRegion(
      cursor: isClickable ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: InkWell(
        onTap: onTap,
        child: Text(
          text,
          style: TextStyle(
            color: isClickable ? const Color(0xFFFFD700) : Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14.5,
          ),
        ),
      ),
    );
  }
}
