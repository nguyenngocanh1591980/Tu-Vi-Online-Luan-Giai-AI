import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/forum_stats_model.dart';
import '../../models/forum_category_model.dart';
import '../../providers/forum_stats_provider.dart';
import '../../providers/forum_category_provider.dart';
import '../../services/signalr_service.dart';
import '../../widgets/responsive_layout.dart';
import '../../widgets/mobile_bottom_nav.dart';
import '../../widgets/share_dialog.dart';

class ForumHomeScreen extends StatefulWidget {
  const ForumHomeScreen({super.key});

  @override
  State<ForumHomeScreen> createState() => _ForumHomeScreenState();
}

class _ForumHomeScreenState extends State<ForumHomeScreen> {
  int _currentMobileIndex = 2; // Diễn đàn
  bool _isLoggedIn = false;
  late final ValueNotifier<String> _currentTimeNotifier;
  String _lastVisitTimeString = 'Lần ghé thăm trước: Chưa có';
  Timer? _clockTimer;

  static String _formatDateTime(DateTime dt) {
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final y = (dt.year % 100).toString().padLeft(2, '0');
    return '$hh:$mm, $d/$m/$y';
  }

  @override
  void initState() {
    super.initState();
    _currentTimeNotifier = ValueNotifier<String>('Hôm nay, ${_formatDateTime(DateTime.now())}');
    _startClockTimer();
    _initVisitAndLoginStatus();
    _setupSignalR();
  }

  StreamSubscription<String?>? _reconnectSub;

  void _onCategoryUpdatedSignalR(List<Object?>? args) {
    if (mounted) {
      try {
        Provider.of<ForumCategoryProvider>(context, listen: false).initData();
      } catch (_) {}
    }
  }

  void _setupSignalR() {
    signalRService.listenToCategoryUpdated(_onCategoryUpdatedSignalR);
    _reconnectSub?.cancel();
    _reconnectSub = signalRService.onReconnected.listen((_) {
      if (mounted) {
        try {
          Provider.of<ForumCategoryProvider>(context, listen: false).initData();
        } catch (_) {}
      }
    });
  }

  void _startClockTimer() {
    _clockTimer?.cancel();
    if (WidgetsBinding.instance.runtimeType.toString().contains('Test')) {
      return;
    }
    _clockTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      final nowFormatted = 'Hôm nay, ${_formatDateTime(DateTime.now())}';
      if (_currentTimeNotifier.value != nowFormatted) {
        _currentTimeNotifier.value = nowFormatted;
      }
    });
  }

  Future<void> _initVisitAndLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? prefs.getString('jwt_token');

    final currentCustom = prefs.getString('current_login_time');
    final prevVisitFromDb = prefs.getString('previous_visit_time');
    final lastVisitCustom = (prevVisitFromDb != null && prevVisitFromDb.isNotEmpty)
        ? prevVisitFromDb
        : prefs.getString('last_visit_time');

    if (currentCustom != null && currentCustom.isNotEmpty) {
      _currentTimeNotifier.value = 'Hôm nay, $currentCustom';
    }

    String lastVisitStr;
    if (lastVisitCustom != null && lastVisitCustom.isNotEmpty) {
      lastVisitStr = 'Lần ghé thăm trước: $lastVisitCustom';
    } else {
      lastVisitStr = 'Lần ghé thăm trước: Chưa có';
    }

    // Cập nhật mốc ghé thăm cho các phiên sau
    final currentVisitFormatted = _formatDateTime(DateTime.now());
    await prefs.setString('last_visit_time', currentVisitFormatted);

    if (mounted) {
      setState(() {
        _isLoggedIn = token != null && token.isNotEmpty;
        _lastVisitTimeString = lastVisitStr;
      });
    }
  }

  @override
  void dispose() {
    _reconnectSub?.cancel();
    signalRService.removeCategoryUpdatedListener(_onCategoryUpdatedSignalR);
    _clockTimer?.cancel();
    _currentTimeNotifier.dispose();
    super.dispose();
  }

  // ===========================================================================
  // DỮ LIỆU TĨNH CHUẨN XÁC 100% THEO HÌNH 2 VÀ YÊU CẦU NGHIÊM NGẶT CỦA USER
  // ===========================================================================

  // Bảng 1: Thông báo & Kiến thức (Chuẩn xác 100% theo Hình 1 media_1790350843499.png)
  final Map<String, dynamic> _group1 = {
    'headerTitle': 'Chuyên mục 1',
    'column4Header': 'Bài cuối',
    'forums': [
      {
        'icon': Icons.description_outlined,
        'title': 'Thông báo - Sự kiện',
        'description': 'Thông báo chính thức của Ban quản trị diễn đàn Lý Số Việt Nam',
        'topics': 0,
        'posts': 0,
        'lastPost': null
      },
      {
        'icon': Icons.description_outlined,
        'title': 'Kiến thức Cơ bản',
        'description': 'Trao đổi kiến thức cơ bản về Lý số: thiên văn, lịch pháp, âm dương, ngũ hành, can chi, bát quái, hà đồ, lạc thư, ...',
        'topics': 0,
        'posts': 0,
        'lastPost': null
      },
      {
        'icon': Icons.description_outlined,
        'title': 'Kiến thức Tử vi',
        'description': 'Trao đổi kiến thức về bộ môn tử vi',
        'topics': 0,
        'posts': 0,
        'lastPost': null
      },
      {
        'icon': Icons.description_outlined,
        'title': 'Kiến thức Tứ trụ',
        'description': 'Trao đổi kiến thức về tứ trụ (tử bình, bát tự)',
        'topics': 0,
        'posts': 0,
        'lastPost': null
      },
      {
        'icon': Icons.description_outlined,
        'title': 'Kiến thức Độn toán',
        'description': 'Trao đổi kiến thức về các môn độn toán: mai hoa, lục hào, thái ất, kỳ môn...',
        'topics': 0,
        'posts': 0,
        'lastPost': null
      },
      {
        'icon': Icons.description_outlined,
        'title': 'Kiến thức Phong thủy',
        'description': 'Trao đổi kiến thức về Phong thủy, địa lý',
        'topics': 0,
        'posts': 0,
        'lastPost': null
      },
      {
        'icon': Icons.description_outlined,
        'title': 'Kiến thức Sinh trắc',
        'description': 'Trao đổi kiến thức về sinh trắc, tướng pháp, chi tay, danh tính, chữ viết, tâm lý, điềm mộng',
        'topics': 0,
        'posts': 0,
        'lastPost': null
      },
      {
        'icon': Icons.description_outlined,
        'title': 'Lý số Phương Tây',
        'description': 'Trao đổi kiến thức về các môn Lý số của Phương Tây: Tử vi, Thần số, ...',
        'topics': 0,
        'posts': 0,
        'lastPost': null
      },
      {
        'icon': Icons.description_outlined,
        'title': 'Kiến thức Lý số khác',
        'description': 'Kiến thức chung về Lý số hoặc chưa được phân loại',
        'topics': 0,
        'posts': 0,
        'lastPost': null
      },
      {
        'icon': Icons.description_outlined,
        'title': 'Thư ngỏ - Ý kiến',
        'description': 'Gửi lời tri ân, thư ngỏ và đóng góp ý kiến về diễn đàn',
        'topics': 0,
        'posts': 0,
        'lastPost': null
      },
    ]
  };

  // Bảng 2: Lớp học Lý số (Chuẩn xác 100% theo Hình media_1790350755082.png)
  // Ghi chú: Giao diện phpBB gốc cột 4 mang tên "Bài cuối", chỉ hiển thị tác giả và thời gian, không có dòng tiêu đề bài viết.
  final Map<String, dynamic> _group2 = {
    'headerTitle': 'Lớp học Lý số',
    'column4Header': 'Bài cuối',
    'forums': [
      {
        'icon': Icons.description_outlined,
        'title': 'Lớp học tử vi',
        'description': 'Chuyên mục dành cho lớp học tử vi',
        'topics': 0,
        'posts': 0,
        'lastPost': null
      },
      {
        'icon': Icons.description_outlined,
        'title': 'Lớp học tứ trụ',
        'description': 'Lớp học tứ trụ cơ bản, dành cho người mới bắt đầu',
        'topics': 0,
        'posts': 0,
        'lastPost': null
      },
      {
        'icon': Icons.description_outlined,
        'title': 'Lớp học chiêm tinh',
        'description': 'Khu vực dành riêng cho lớp học V.',
        'topics': 0,
        'posts': 0,
        'isHighlighted': true, // Dòng nổi bật nền be/vàng
        'lastPost': null
      },
      {
        'icon': Icons.description_outlined,
        'title': 'Lớp học Phong thủy',
        'description': 'Khu vực dành riêng cho lớp học IV',
        'topics': 0,
        'posts': 0,
        'lastPost': null
      },
      {
        'icon': Icons.description_outlined,
        'title': 'Lớp học tổng hợp',
        'description': 'Khu vực thực hành luận đoán của các học viên. Các thành viên có thể giao lưu.',
        'topics': 0,
        'posts': 0,
        'lastPost': null
      },
      {
        'icon': Icons.description_outlined,
        'title': 'Lớp học Dịch lý',
        'description': 'Chuyên mục dành cho lớp học quẻ dịch',
        'topics': 0,
        'posts': 0,
        'lastPost': null
      },
    ]
  };

  // Bảng 3: Khu vực Luận giải (Chuẩn xác 100% theo Hình 2 media_1790350885836.png)
  final Map<String, dynamic> _group3 = {
    'headerTitle': 'Chuyên mục 2',
    'column4Header': 'Bài cuối',
    'forums': [
      {
        'icon': Icons.description_outlined,
        'title': 'Hướng nghiệp',
        'description': 'Tư vấn hướng nghiệp: chọn ngành, chọn nghề, chọn trường.',
        'topics': 0,
        'posts': 0,
        'isHighlighted': true, // Dòng nổi bật nền be sẫm
        'lastPost': null
      },
      {
        'icon': Icons.description_outlined,
        'title': 'Xem Tử vi',
        'description': 'Xem, hỏi đáp, luận giải về tử vi',
        'topics': 0,
        'posts': 0,
        'lastPost': null
      },
      {
        'icon': Icons.description_outlined,
        'title': 'Xem Tứ trụ',
        'description': 'Hỏi đáp, luận giải, trao đổi về tử bình (tứ trụ, bát tự)',
        'topics': 0,
        'posts': 0,
        'lastPost': null
      },
      {
        'icon': Icons.description_outlined,
        'title': 'Xem quẻ',
        'description': 'Hỏi đáp, luận giải về các môn gieo quẻ: Lục nhâm, Thái Ất, Lục hào, Mai hoa ...',
        'topics': 0,
        'posts': 0,
        'lastPost': null
      },
      {
        'icon': Icons.description_outlined,
        'title': 'Xem Phong thủy',
        'description': 'Hỏi đáp, tư vấn về phong thủy, địa lý',
        'topics': 0,
        'posts': 0,
        'lastPost': null
      },
      {
        'icon': Icons.description_outlined,
        'title': 'Xem ngày, luận tuổi',
        'description': 'Xem ngày tốt, luận tuổi theo âm dương, ngũ hành, can chi, bát quái, cửu cung',
        'topics': 0,
        'posts': 0,
        'lastPost': null
      },
      {
        'icon': Icons.description_outlined,
        'title': 'Xem Lý số Phương tây',
        'description': 'Hỏi đáp về tử vi tây phương, thần số học',
        'topics': 0,
        'posts': 0,
        'lastPost': null
      },
      {
        'icon': Icons.description_outlined,
        'title': 'Xem tướng, đặt tên, sinh trắc',
        'description': 'Các bài viết trao đổi học thuật về môn tướng pháp, chỉ tay...',
        'topics': 0,
        'posts': 0,
        'lastPost': null
      },
      {
        'icon': Icons.description_outlined,
        'title': 'Xem bằng các môn khác',
        'description': 'Xem và luận đoán bằng các môn Lý số khác, chưa phân loại',
        'topics': 0,
        'posts': 0,
        'lastPost': null
      },
      {
        'icon': Icons.description_outlined,
        'title': 'Cổ học - Văn hóa - Tín ngưỡng',
        'description': 'Trao đổi về y học, võ thuật, văn hóa, phong tục, tín ngưỡng',
        'topics': 0,
        'posts': 0,
        'lastPost': null
      },
      {
        'icon': Icons.description_outlined,
        'title': 'Cuộc sống muôn màu',
        'description': 'Chia sẻ thơ ca, nhạc họa, các trải nghiệm của cuộc sống',
        'topics': 0,
        'posts': 0,
        'lastPost': null
      },
      {
        'icon': Icons.description_outlined,
        'title': 'Câu lạc bộ - Giao lưu - Kết bạn',
        'description': 'Dành cho thành viên giao lưu, kết bạn, buôn chuyện',
        'topics': 0,
        'posts': 0,
        'lastPost': null
      },
    ]
  };

  // Ánh xạ tiêu đề sang slug để điều hướng
  void _navigateToCategory(BuildContext context, String title) {
    final t = title.toLowerCase();
    String slug = 'thong-bao-su-kien';
    if (t.contains('thông báo')) {
      slug = 'thong-bao-su-kien';
    } else if (t.contains('cơ bản')) {
      slug = 'kien-thuc-co-ban';
    } else if (t == 'kiến thức tử vi' || (t.contains('tử vi') && t.contains('kiến thức'))) {
      slug = 'kien-thuc-tu-vi';
    } else if (t.contains('tứ trụ') && t.contains('kiến thức')) {
      slug = 'kien-thuc-tu-tru';
    } else if (t.contains('độn toán')) {
      slug = 'kien-thuc-don-toan';
    } else if (t.contains('phong thủy') && t.contains('kiến thức')) {
      slug = 'kien-thuc-phong-thuy';
    } else if (t.contains('sinh trắc') && t.contains('kiến thức')) {
      slug = 'kien-thuc-sinh-trac';
    } else if (t.contains('phương tây') && t.contains('lý số')) {
      slug = 'ly-so-phuong-tay';
    } else if (t.contains('lý số khác')) {
      slug = 'kien-thuc-ly-so-khac';
    } else if (t.contains('thư ngỏ') || t.contains('ý kiến')) {
      slug = 'thu-ngo-y-kien';
    } else if (t.contains('lớp học tử vi') || (t.contains('tử vi') && t.contains('lớp'))) {
      slug = 'lop-hoc-tu-vi';
    } else if (t.contains('lớp học tứ trụ') || (t.contains('tứ trụ') && t.contains('lớp'))) {
      slug = 'lop-hoc-tu-tru';
    } else if (t.contains('chiêm tinh')) {
      slug = 'lop-hoc-chiem-tinh';
    } else if (t.contains('phong thủy') && t.contains('lớp')) {
      slug = 'lop-hoc-phong-thuy';
    } else if (t.contains('đồng hóa') || t.contains('tổng hợp')) {
      slug = 'lop-hoc-tong-hop';
    } else if (t.contains('dịch lý')) {
      slug = 'lop-hoc-dich-ly';
    } else if (t.contains('hướng nghiệp')) {
      slug = 'huong-nghiep';
    } else if (t == 'xem tử vi' || (t.contains('xem') && t.contains('tử vi'))) {
      slug = 'xem-tu-vi';
    } else if (t.contains('xem') && t.contains('tứ trụ')) {
      slug = 'xem-tu-tru';
    } else if (t.contains('xem quẻ') || t.contains('quẻ')) {
      slug = 'xem-que';
    } else if (t.contains('xem') && t.contains('phong thủy')) {
      slug = 'xem-phong-thuy';
    } else if (t.contains('ngày') || t.contains('luận tuổi')) {
      slug = 'xem-ngay-luan-tuoi';
    } else if (t.contains('xem') && t.contains('phương tây')) {
      slug = 'xem-ly-so-phuong-tay';
    } else if (t.contains('tướng') || t.contains('đặt tên')) {
      slug = 'xem-tuong-dat-ten-sinh-trac';
    } else if (t.contains('môn khác') || t.contains('bằng các môn khác')) {
      slug = 'xem-bang-cac-mon-khac';
    } else if (t.contains('cổ học') || t.contains('văn hóa') || t.contains('tín ngưỡng')) {
      slug = 'co-hoc-van-hoa-tin-nguong';
    } else if (t.contains('cuộc sống') || t.contains('muôn màu')) {
      slug = 'cuoc-song-muon-mau';
    } else if (t.contains('câu lạc bộ') || t.contains('kết bạn') || t.contains('giao lưu')) {
      slug = 'cau-lac-bo-giao-luu-ket-ban';
    }
    context.go('/forum/category/$slug');
  }

  void _onMobileNavTapped(int index) {
    setState(() {
      _currentMobileIndex = index;
    });
  }

  Map<String, dynamic> _getMergedGroup(
    Map<String, dynamic> baseGroup,
    List<ForumCategoryItem> dynamicItems,
  ) {
    if (dynamicItems.isEmpty) return baseGroup;
    final merged = Map<String, dynamic>.from(baseGroup);
    final List baseForums = (baseGroup['forums'] as List? ?? []);
    final forums = dynamicItems.map((item) {
      final existing = baseForums.cast<Map<String, dynamic>?>().firstWhere(
        (f) => f?['title'] == item.title,
        orElse: () => null,
      );
      return {
        'icon': item.icon,
        'title': item.title,
        'description': item.description,
        'topics': item.topics,
        'posts': item.posts,
        'isHighlighted': item.isHighlighted || (existing?['isHighlighted'] == true),
        'lastPost': item.lastPost ?? existing?['lastPost'],
        'onlineUsers': existing?['onlineUsers'],
      };
    }).toList();
    merged['forums'] = forums;
    return merged;
  }

  // --- CẤU TRÚC GIAO DIỆN — MainLayout đã bọc sẵn 1024px + bo góc + nền tím ---
  Widget _buildBody(BuildContext context) {
    ForumCategoryProvider? catProvider;
    try {
      catProvider = Provider.of<ForumCategoryProvider>(context);
    } catch (_) {}

    final g1 = _getMergedGroup(_group1, catProvider?.group1Categories ?? []);
    final g2 = _getMergedGroup(_group2, catProvider?.group2Categories ?? []);
    final g3 = _getMergedGroup(_group3, catProvider?.group3Categories ?? []);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Tiêu đề và Menu Navigation
          _buildForumHeader(),
          const SizedBox(height: 16),

          // 2. Bảng 1: Thông báo & Kiến thức
          _buildForumTable(g1),
          const SizedBox(height: 16),

          // 3. Bảng 2: Lớp học Lý số
          _buildForumTable(g2),
          const SizedBox(height: 16),

          // 4. Bảng 3: Khu vực Luận giải
          _buildForumTable(g3),
          const SizedBox(height: 24),

          // 5. Khối Đang trực tuyến
          _buildOnlineUsers(),
          const SizedBox(height: 24),

          // 6. Khối Thống kê
          _buildStatistics(),
          const SizedBox(height: 24),

          // 7. Khối Khám phá thêm
          _buildExploreMore(),
          const SizedBox(height: 32),

          // 8. Footer diễn đàn
          _buildForumFooter(),
        ],
      ),
    );
  }

  // --- 1. Tiêu đề và Menu Navigation ---
  Widget _buildForumHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tiêu đề banner chữ vàng rực rỡ có đổ bóng
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          decoration: BoxDecoration(
            color: const Color(0xFF161F36), // Nền panel tím đen
            border: Border.all(color: const Color(0xFF2E3B5F)),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            'Diễn đàn Tử Vi Online -AI',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: const Color(0xFFFFD700), // Màu vàng rực
              shadows: [
                Shadow(
                  color: const Color(0xFFFFD700).withValues(alpha: 0.8),
                  blurRadius: 12,
                  offset: const Offset(0, 0),
                ),
                Shadow(
                  color: Colors.amber.withValues(alpha: 0.5),
                  blurRadius: 20,
                  offset: const Offset(0, 0),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),

        // Dòng thời gian và thao tác người dùng (2 Row trong 1 Column)
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Row 1: Trái ("Hôm nay, HH:mm, dd/MM/yy") - Phải ("Lần ghé thăm trước: ...")
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ValueListenableBuilder<String>(
                  valueListenable: _currentTimeNotifier,
                  builder: (context, currentTime, _) {
                    return Text(currentTime, style: const TextStyle(color: Colors.white70, fontSize: 13));
                  },
                ),
                Text(_lastVisitTimeString, style: const TextStyle(color: Colors.white70, fontSize: 13)),
              ],
            ),
            const SizedBox(height: 8),
            // Row kết hợp: Bên trái là 3 nút chức năng Admin (chụm sát lề trái), Bên phải là text Đánh dấu đã xem
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        context.push('/forum/create-category');
                      },
                      icon: const Icon(Icons.add_circle_outline, color: Colors.white, size: 16),
                      label: const Text(
                        'Chuyên Mục và Lớp Học Mới',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        shape: const StadiumBorder(),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        context.push('/forum/edit-categories');
                      },
                      icon: const Icon(Icons.edit_outlined, color: Colors.white, size: 16),
                      label: const Text(
                        'Sửa Chuyên Mục Và Lớp học',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.brown,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        shape: const StadiumBorder(),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        context.push('/forum/delete-categories');
                      },
                      icon: const Icon(Icons.delete_outline, color: Colors.white, size: 16),
                      label: const Text(
                        'Xóa Chuyên mục và Lớp học',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE53935),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        shape: const StadiumBorder(),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.only(left: 12.0),
                  child: InkWell(
                    onTap: () {},
                    child: const Text(
                      'Đánh dấu đã xem tất cả các chuyên mục',
                      style: TextStyle(color: Color(0xFFEF5350), fontSize: 12.5, fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
],
    );
  }

  // --- BẢNG CHUYÊN MỤC (Nền #161F36, Viền #2E3B5F, Tiêu đề #8B0000) ---
  Widget _buildForumIcon(Map<String, dynamic> forum) {
    final iconVal = forum['icon'];
    if (iconVal is String && iconVal.isNotEmpty) {
      return Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFF8E9BAE), width: 1.5),
          color: Colors.white.withValues(alpha: 0.04),
        ),
        child: Center(
          child: Text(
            iconVal,
            style: const TextStyle(fontSize: 16),
          ),
        ),
      );
    }

    final isRed = forum['title'] == 'Kiến thức Tứ trụ';
    final circleBorder = isRed ? const Color(0xFFEF5350) : const Color(0xFF8E9BAE);
    final iconColor = isRed ? const Color(0xFFEF5350) : const Color(0xFF8E9BAE);

    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: circleBorder, width: 1.5),
        color: Colors.white.withValues(alpha: 0.04),
      ),
      child: Center(
        child: Icon(
          Icons.description_outlined,
          color: iconColor,
          size: 18,
        ),
      ),
    );
  }

  Widget _buildForumTable(Map<String, dynamic> group) {
    final String headerTitle = group['headerTitle'] ?? 'Chuyên mục';
    final List forums = group['forums'] as List;

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
                    group['column4Header'] ?? 'Bài cuối',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
          // Danh sách Chuyên mục con
          ...forums.map((forum) {
            final isLast = forums.last == forum;
            final isHighlighted = forum['isHighlighted'] == true;
            return InkWell(
              onTap: () => _navigateToCategory(context, forum['title']),
              child: Container(
                decoration: BoxDecoration(
                  color: isHighlighted ? const Color(0xFF382E1E) : const Color(0xFF161F36),
                  border: isLast ? null : const Border(bottom: BorderSide(color: Color(0xFF2E3B5F))),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Cột 1: Chuyên mục (Icon + Title + Description)
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildForumIcon(forum),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CategoryTitleLink(
                                  title: forum['title']?.toString() ?? '',
                                  isHighlighted: isHighlighted,
                                  onTap: () => _navigateToCategory(context, forum['title']),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  forum['description'],
                                  style: const TextStyle(fontSize: 13, color: Colors.white70, height: 1.3),
                                ),
                                if (forum['onlineUsers'] != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    forum['onlineUsers'],
                                    style: const TextStyle(fontSize: 12, color: Color(0xFFEF5350), fontWeight: FontWeight.w500),
                                  ),
                                ],
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
                        '${forum['topics']}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 13, color: Colors.white70),
                      ),
                    ),
                    // Cột 3: Bài viết
                    SizedBox(
                      width: 70,
                      child: Text(
                        '${forum['posts']}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 13, color: Colors.white70),
                      ),
                    ),
                    // Cột 4: Bài cuối
                    SizedBox(
                      width: 250,
                      child: forum['lastPost'] == null
                          ? const Text('-', style: TextStyle(fontSize: 12, color: Colors.white38))
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (forum['lastPost']['title'] != null && forum['lastPost']['title'].toString().isNotEmpty) ...[
                                  Text(
                                    forum['lastPost']['title'] ?? '',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                ],
                                RichText(
                                  text: TextSpan(
                                    style: const TextStyle(fontSize: 12, color: Colors.white60),
                                    children: [
                                      const TextSpan(text: 'gửi bởi '),
                                      TextSpan(
                                        text: forum['lastPost']['author'] ?? '',
                                        style: TextStyle(
                                          color: forum['lastPost']['authorColor'] ?? const Color(0xFFEF5350),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const TextSpan(
                                        text: ' ↗',
                                        style: TextStyle(fontSize: 11, color: Colors.white54),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  forum['lastPost']['time'] ?? '',
                                  style: const TextStyle(fontSize: 12, color: Colors.white54),
                                ),
                              ],
                            ),
                    ),
                  ],
                ),
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

  // --- Khối Đang trực tuyến (Cập nhật động theo thời gian thực từ Backend/Provider) ---
  Widget _buildOnlineUsers() {
    ForumStatsProvider? provider;
    try {
      provider = Provider.of<ForumStatsProvider>(context, listen: false);
    } catch (_) {
      provider = null;
    }

    if (provider == null) {
      return _buildOnlineUsersContent(ForumOnlineStats.defaults());
    }

    return Consumer<ForumStatsProvider>(
      builder: (context, statsProvider, _) {
        return _buildOnlineUsersContent(statsProvider.onlineStats);
      },
    );
  }

  Widget _buildOnlineUsersContent(ForumOnlineStats online) {
    final List<InlineSpan> userSpans = [];
    if (online.users.isNotEmpty) {
      for (int i = 0; i < online.users.length; i++) {
        final u = online.users[i];
        userSpans.add(
          TextSpan(
            text: u.name,
            style: TextStyle(
              color: u.color ?? Colors.white70,
              fontWeight: u.isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        );
        if (i < online.users.length - 1) {
          userSpans.add(const TextSpan(text: ', '));
        }
      }
    } else {
      userSpans.add(
        const TextSpan(
          text: 'Chưa có thành viên đăng ký nào trực tuyến',
          style: TextStyle(fontStyle: FontStyle.italic, color: Colors.white38),
        ),
      );
    }

    final List<InlineSpan> legendSpans = [
      const TextSpan(text: 'Chú thích: ', style: TextStyle(fontWeight: FontWeight.bold, fontStyle: FontStyle.italic)),
    ];
    if (online.rolesLegend.isNotEmpty) {
      for (int i = 0; i < online.rolesLegend.length; i++) {
        final r = online.rolesLegend[i];
        legendSpans.add(
          TextSpan(
            text: r.name,
            style: TextStyle(
              color: r.color,
              fontStyle: r.isItalic ? FontStyle.italic : FontStyle.normal,
            ),
          ),
        );
        if (i < online.rolesLegend.length - 1) {
          legendSpans.add(const TextSpan(text: ', '));
        }
      }
    } else {
      legendSpans.addAll([
        const TextSpan(text: 'Ban tư vấn', style: TextStyle(color: Color(0xFFFFA726), fontStyle: FontStyle.italic)),
        const TextSpan(text: ', CLB Lý số Hà Nội, CLB Lý số Sài Gòn, '),
        const TextSpan(text: 'CLB Phong thủy TL', style: TextStyle(color: Color(0xFFFFD54F), fontStyle: FontStyle.italic)),
        const TextSpan(text: ', '),
        const TextSpan(text: 'Cặp đôi Lý số', style: TextStyle(color: Color(0xFFE57373), fontStyle: FontStyle.italic)),
        const TextSpan(text: ', '),
        const TextSpan(text: 'Ban quản trị', style: TextStyle(color: Color(0xFFEF5350), fontStyle: FontStyle.italic)),
        const TextSpan(text: ', Học Phong thủy online, Học Tử vi online, '),
        const TextSpan(text: 'Hội viên Kim cương', style: TextStyle(color: Color(0xFFF06292), fontStyle: FontStyle.italic)),
        const TextSpan(text: ', LSHQ: Quẻ dịch, LSHQ: Tứ trụ nâng cao, LSHQ: Phong thủy, LSHQ: Tứ trụ, LSHQ: Tử vi, '),
        const TextSpan(text: 'LSHQ: Am tường Lý số', style: TextStyle(color: Color(0xFFEF5350), fontStyle: FontStyle.italic)),
        const TextSpan(text: ', '),
        const TextSpan(text: 'Quản lý', style: TextStyle(color: Color(0xFF42A5F5), fontStyle: FontStyle.italic)),
        const TextSpan(text: ', '),
        const TextSpan(text: 'Trao đổi học thuật', style: TextStyle(color: Color(0xFF66BB6A), fontStyle: FontStyle.italic)),
        const TextSpan(text: ', '),
        const TextSpan(text: 'Tư vấn Phong Thủy', style: TextStyle(color: Color(0xFFFFA726), fontStyle: FontStyle.italic)),
        const TextSpan(text: ', '),
        const TextSpan(text: 'Tư vấn Tứ trụ', style: TextStyle(color: Color(0xFFFFA726), fontStyle: FontStyle.italic)),
        const TextSpan(text: ', '),
        const TextSpan(text: 'Điều hành', style: TextStyle(color: Color(0xFF42A5F5), fontStyle: FontStyle.italic)),
      ]);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Đang trực tuyến',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFFEF5350)),
        ),
        const SizedBox(height: 8),
        Text.rich(
          TextSpan(
            style: const TextStyle(fontSize: 13, color: Colors.white70, height: 1.5),
            children: [
              const TextSpan(text: 'Có tổng số '),
              TextSpan(text: '${online.totalOnline}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              const TextSpan(text: ' thành viên trực tuyến : '),
              TextSpan(text: '${online.registeredCount}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              const TextSpan(text: ' đã đăng ký, '),
              TextSpan(text: '${online.hiddenCount}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              const TextSpan(text: ' ẩn và '),
              TextSpan(text: '${online.guestCount}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              TextSpan(text: ' khách (dựa trên số người hoạt động trong ${online.activeWindowMinutes} phút vừa qua)'),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Lượt người ghé thăm đông nhất là ${online.mostOnlineCount} vào lúc ${online.mostOnlineTime}',
          style: const TextStyle(fontSize: 13, color: Colors.white60),
        ),
        const SizedBox(height: 12),
        Text.rich(
          TextSpan(
            style: const TextStyle(fontSize: 13, color: Colors.white70, height: 1.5),
            children: [
              const TextSpan(text: 'Các thành viên trực tuyến: '),
              ...userSpans,
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text.rich(
          TextSpan(
            style: const TextStyle(fontSize: 12, color: Colors.white70, height: 1.5),
            children: legendSpans,
          ),
        ),
      ],
    );
  }

  // --- Khối Thống kê (Cập nhật động theo thời gian thực từ Backend/Provider) ---
  Widget _buildStatistics() {
    ForumStatsProvider? provider;
    try {
      provider = Provider.of<ForumStatsProvider>(context, listen: false);
    } catch (_) {
      provider = null;
    }

    if (provider == null) {
      return _buildStatisticsContent(ForumGeneralStats.defaults());
    }

    return Consumer<ForumStatsProvider>(
      builder: (context, statsProvider, _) {
        return _buildStatisticsContent(statsProvider.generalStats);
      },
    );
  }

  Widget _buildStatisticsContent(ForumGeneralStats stats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Thống kê',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFFEF5350)),
        ),
        const SizedBox(height: 8),
        Text.rich(
          TextSpan(
            style: const TextStyle(fontSize: 13, color: Colors.white70, height: 1.5),
            children: [
              const TextSpan(text: 'Số bài viết: '),
              TextSpan(text: '${stats.postsCount}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              const TextSpan(text: ' • Số chủ đề: '),
              TextSpan(text: '${stats.topicsCount}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              const TextSpan(text: ' • Số thành viên: '),
              TextSpan(text: '${stats.membersCount}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              const TextSpan(text: ' • Thành viên mới nhất: '),
              TextSpan(text: stats.newestMember, style: const TextStyle(color: Color(0xFFEF5350), fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ],
    );
  }

  // --- Khối Khám phá thêm (Chuẩn xác 100% theo Hình 4 media_1790350958240.png) ---
  Widget _buildExploreMore() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF161F36), // Nền panel
        border: Border.all(color: const Color(0xFF2E3B5F)), // Viền #2E3B5F
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Color(0xFF182239),
              border: Border(bottom: BorderSide(color: Color(0xFF2E3B5F))),
            ),
            width: double.infinity,
            child: const Text(
              'Khám phá thêm',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
            ),
          ),
          _buildExploreItem('Từ điển & Bách khoa toàn thư'),
          _buildExploreItem('Đạo Phật'),
          _buildExploreItem('Lịch sử', isLast: true),
        ],
      ),
    );
  }

  Widget _buildExploreItem(String title, {bool isLast = false}) {
    return InkWell(
      onTap: () {},
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: isLast ? null : const Border(bottom: BorderSide(color: Color(0xFF2E3B5F))),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontSize: 14, color: Colors.white70)),
            const Icon(Icons.chevron_right, color: Colors.white54, size: 20),
          ],
        ),
      ),
    );
  }

  // --- 8. Footer Diễn Đàn (Chuẩn xác 100% theo Hình media_1790351008145.png) ---
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
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            runSpacing: 12,
            children: [
              // Cột trái: Breadcrumb (Trang chủ < Diễn đàn) - Không hiện checkbox khi unlogged
              Row(
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
                ],
              ),
              // Cột phải: Menu liên kết theo đúng ảnh gốc: Liên hệ, Chia sẻ, Chúng tôi, Thành viên, Xóa hết cookie, Múi giờ UTC+07:00
              Wrap(
                spacing: 12,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _buildFooterLink(Icons.mail_outline, 'Liên hệ', () {}),
                  _buildFooterLink(Icons.share, 'Chia sẻ', () => ShareHelper.share(context)),
                  _buildFooterLink(Icons.shield_outlined, 'Chúng tôi', () {}),
                  _buildFooterLink(Icons.group, 'Thành viên', () => context.go('/members')),
                  _buildFooterLink(Icons.delete_outline, 'Xóa hết cookie', () {}),
                  const Text('Múi giờ UTC+07:00', style: TextStyle(fontSize: 12, color: Colors.white54)),
                ],
              )
            ],
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Powered by phpBB® Forum Software © phpBB Limited',
          style: TextStyle(fontSize: 13, color: Colors.white54),
        ),
        const SizedBox(height: 6),
        RichText(
          text: const TextSpan(
            style: TextStyle(fontSize: 13, color: Color(0xFFEF5350)),
            children: [
              TextSpan(text: 'Chính sách bảo mật'),
              TextSpan(text: ' | ', style: TextStyle(color: Colors.white38)),
              TextSpan(text: 'Điều khoản tham gia'),
            ],
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildFooterLink(IconData icon, String text, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFFEF5350)),
          const SizedBox(width: 4),
          Text(text, style: const TextStyle(fontSize: 13, color: Color(0xFFEF5350))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(color: Colors.transparent, child: 
      
      ResponsiveLayout(
        mobileBody: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildBody(context),
            MobileBottomNavBar(
              currentIndex: _currentMobileIndex,
              onTap: _onMobileNavTapped,
            ),
          ],
        ),
        desktopBody: SingleChildScrollView(child: _buildBody(context)),
      ),
    );
  }
}

/// Widget Tiêu đề Chuyên mục dạng Link theo Hình 5
/// Bọc bằng InkWell + RichText, có đường gạch chân khi hover, con trỏ bàn tay
class CategoryTitleLink extends StatefulWidget {
  final String title;
  final bool isHighlighted;
  final VoidCallback onTap;

  const CategoryTitleLink({
    super.key,
    required this.title,
    required this.isHighlighted,
    required this.onTap,
  });

  @override
  State<CategoryTitleLink> createState() => _CategoryTitleLinkState();
}

class _CategoryTitleLinkState extends State<CategoryTitleLink> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final baseColor = widget.isHighlighted ? const Color(0xFFFFD54F) : Colors.white;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: InkWell(
        onTap: widget.onTap,
        hoverColor: Colors.transparent,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: RichText(
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          text: TextSpan(
            text: widget.title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: baseColor,
              decoration: _isHovered ? TextDecoration.underline : TextDecoration.none,
              decorationColor: baseColor,
            ),
          ),
        ),
      ),
    );
  }
}
