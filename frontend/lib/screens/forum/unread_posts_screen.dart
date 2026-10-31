import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../utils/boxed_snack_bar.dart';
import '../../widgets/responsive_layout.dart';
import '../../widgets/mobile_bottom_nav.dart';

class UnreadPostsScreen extends StatefulWidget {
  const UnreadPostsScreen({super.key});

  @override
  State<UnreadPostsScreen> createState() => _UnreadPostsScreenState();
}

class _UnreadPostsScreenState extends State<UnreadPostsScreen> {
  int _currentMobileIndex = 2; // Tab Diễn đàn
  int _currentPage = 1;
  final TextEditingController _searchController = TextEditingController();
  bool _isNavigating = false;
  DateTime? _lastNavigationTime;

  void _navigateToTopic(BuildContext context, Map<String, dynamic> topic) {
    final now = DateTime.now();
    if (_isNavigating ||
        (_lastNavigationTime != null &&
            now.difference(_lastNavigationTime!).inMilliseconds < 500)) {
      return;
    }

    final dynamic rawId = topic['id'] ?? topic['topicId'] ?? topic['Id'];
    final String? id = (rawId != null && rawId.toString().trim().isNotEmpty)
        ? rawId.toString().trim()
        : null;

    if (id == null || id.isEmpty) {
      showErrorSnackBar(context, 'Dữ liệu chủ đề bị lỗi');
      return;
    }

    _isNavigating = true;
    _lastNavigationTime = now;

    context.push('/forum/post/').then((_) {
      if (mounted) {
        _isNavigating = false;
      }
    }).catchError((_) {
      if (mounted) {
        _isNavigating = false;
      }
    });
  }
  String _selectedJumpCategory = 'Chuyển đến';

  final List<String> _jumpCategories = [
    'Chuyển đến',
    'Thông báo - Sự kiện',
    'Kiến thức Cơ bản',
    'Kiến thức Tử vi',
    'Kiến thức Tứ trụ',
    'Kiến thức Độn toán',
    'Kiến thức Phong thủy',
    'Kiến thức Sinh trắc',
    'Lý số Phương Tây',
    'Kiến thức Lý số khác',
    'Thư ngỏ - Ý kiến',
    'Lớp học Lý số',
    '↳  Lớp học tử vi',
    '↳  Lớp học tứ trụ',
    '↳  Lớp học chiêm tinh',
    '↳  Lớp học Phong thủy',
    '↳  Lớp học tổng hợp',
    '↳  Lớp học Dịch lý',
    'Hướng nghiệp',
    'Xem Tử vi',
    'Xem Tứ trụ',
    'Xem quẻ',
    'Xem Phong thủy',
    'Xem ngày, luận tuổi',
    'Xem Lý số Phương tây',
    'Xem tướng, đặt tên, sinh trắc',
    'Xem bằng các môn khác',
    'Cổ học - Văn hóa - Tín ngưỡng',
    'Cuộc sống muôn màu',
    'Câu lạc bộ - Giao lưu - Kết bạn',
  ];

  // Danh sách 25 chủ đề thực tế từ Hình 4 bảo toàn 100%
  final List<Map<String, dynamic>> _posts = [
    {
      'id': 1,
      'title': 'Một năm quá nhiều áp lực, kính mong được xem lá số và cho lời khuyên',
      'author': 'thikthii',
      'time': '18:35, 29/05/26',
      'category': 'Xem Tử vi',
      'replies': 1,
      'views': 30,
      'lastPostAuthor': 'vtsaucy',
      'lastPostTime': '06:06, 07/09/26',
      'pages': null,
    },
    {
      'id': 2,
      'title': 'Lá số phật thích ca mâu ni',
      'author': 'nguyenkienbk',
      'time': '20:00, 16/09/23',
      'category': 'Xem Tử vi',
      'replies': 38,
      'views': 15582,
      'lastPostAuthor': 'sunrise',
      'lastPostTime': '08:21, 07/09/26',
      'pages': null,
    },
    {
      'id': 3,
      'title': 'THAM TỌA QUANG QUÝ là hiện thân của cát hướng và thiện nghiệp(nguoivikhieu.net)',
      'author': 'Thien-Su',
      'time': '20:30, 21/04/24',
      'category': 'Xem Tử vi',
      'replies': 125,
      'views': 16315,
      'lastPostAuthor': 'sunrise',
      'lastPostTime': '08:06, 07/09/26',
      'pages': [1, '...', 11, 12, 13],
    },
    {
      'id': 4,
      'title': 'MỆNH VCD CHỈ CÓ 1 CÂU MUỐN HỎI ĐÁP',
      'author': 'Mac Hieu',
      'time': '19:42, 22/04/24',
      'category': 'Xem Tử vi',
      'replies': 1,
      'views': 32,
      'lastPostAuthor': 'Mai Hữu Trao Vương',
      'lastPostTime': '06:06, 07/09/26',
      'pages': null,
    },
    {
      'id': 5,
      'title': 'Mệnh - Thân-Thê-Phu bị Không Kiếp xâm phạm nơi cần giải?',
      'author': 'changhye',
      'time': '22:58, 25/11/24',
      'category': 'Xem Tử vi',
      'replies': 36,
      'views': 4366,
      'lastPostAuthor': 'vuonhoa',
      'lastPostTime': '05:25, 07/09/26',
      'pages': [1, 2, 3, 4],
    },
    {
      'id': 6,
      'title': 'Kính nhờ anh Bradley xem giúp em với ạ.',
      'author': 'ngbaolac',
      'time': '08:35, 12/03/25',
      'category': 'Xem Tử vi',
      'replies': 16,
      'views': 232,
      'lastPostAuthor': 'aaaaa12',
      'lastPostTime': '04:47, 07/09/26',
      'pages': [1, 2, 3],
    },
    {
      'id': 7,
      'title': 'Tìm giờ sinh chính xác',
      'author': 'saominhtrang',
      'time': '20:25, 23/04/25',
      'category': 'Xem Tử vi',
      'replies': 14,
      'views': 252,
      'lastPostAuthor': 'saominhtrang',
      'lastPostTime': '03:49, 07/09/26',
      'pages': [1, 2],
    },
    {
      'id': 8,
      'title': 'Mong muốn được giải đoán lá số Thái Dương Hãm Lại nghịch',
      'author': 'chuotchuot1607',
      'time': '15:48, 23/05/25',
      'category': 'Xem Tử vi',
      'replies': 6,
      'views': 166,
      'lastPostAuthor': 'chuotchuot1607',
      'lastPostTime': '03:19, 07/09/26',
      'pages': null,
    },
    {
      'id': 9,
      'title': 'Bát cháo hành',
      'author': 'Mai Hữu Trao Vương',
      'time': '18:31, 12/07/25',
      'category': 'Cuộc sống muôn màu',
      'replies': 2,
      'views': 23,
      'lastPostAuthor': 'Mai Hữu Trao Vương',
      'lastPostTime': '03:06, 07/09/26',
      'pages': null,
    },
    {
      'id': 10,
      'title': 'Hợi vận Thái tuế có đáng sợ không ạ?',
      'author': 'dothikieunga',
      'time': '15:52, 23/07/25',
      'category': 'Xem Tử vi',
      'replies': 4,
      'views': 24,
      'lastPostAuthor': 'vuonhoa',
      'lastPostTime': '03:01, 07/09/26',
      'pages': null,
    },
    {
      'id': 11,
      'title': 'Lá số thứ',
      'author': 'Mai Hữu Trao Vương',
      'time': '18:41, 10/08/25',
      'category': 'Xem Tử vi',
      'replies': 3,
      'views': 172,
      'lastPostAuthor': 'vuonhoa',
      'lastPostTime': '02:51, 07/09/26',
      'pages': null,
    },
    {
      'id': 12,
      'title': 'Cảm live Rơ ca',
      'author': 'phithienkim',
      'time': '02:26, 05/09/25',
      'category': 'Bàn cờ cuộc đời - Giao lưu - Kết bạn',
      'replies': 50,
      'views': 1000,
      'lastPostAuthor': 'vuonhoa',
      'lastPostTime': '02:35, 07/09/26',
      'pages': [1, 2, 3, 4, 5, 6],
    },
    {
      'id': 13,
      'title': 'Nhờ các bậc tiền bối giúp em lá số này với ạ(30-40) đoạn có đi giàu có h p . Nghe nói âm dương tối kị kình đà',
      'author': 'saominhtrang',
      'time': '02:18, 11/08/25',
      'category': 'Xem Tử vi',
      'replies': 2,
      'views': 42,
      'lastPostAuthor': 'vuonhoa',
      'lastPostTime': '02:18, 07/09/26',
      'pages': null,
    },
    {
      'id': 14,
      'title': 'Lá số con trai em liệu có xuất ngoại được ko?',
      'author': 'conmemin',
      'time': '10:14, 11/08/25',
      'category': 'Xem Tử vi',
      'replies': 4,
      'views': 56,
      'lastPostAuthor': 'conmemin',
      'lastPostTime': '01:58, 07/09/26',
      'pages': null,
    },
    {
      'id': 15,
      'title': 'Phụ nữ mang Thai có nên Cắm phòng cúng?',
      'author': 'thangcon1',
      'time': '08:04, 11/08/25',
      'category': 'Câu lạc bộ - Giao lưu - Kết bạn',
      'replies': 0,
      'views': 4,
      'lastPostAuthor': 'thangcon1',
      'lastPostTime': '01:04, 07/09/26',
      'pages': null,
    },
    {
      'id': 16,
      'title': 'Hòa Thượng Thích Minh Châu',
      'author': 'phithienkim',
      'time': '15:43, 05/09/25',
      'category': 'Cổ học - Văn hóa - Tín ngưỡng',
      'replies': 140,
      'views': 13744,
      'lastPostAuthor': 'ams',
      'lastPostTime': '01:02, 07/09/26',
      'pages': [1, '...', 11, 12, 13, 14],
    },
    {
      'id': 17,
      'title': 'Kính nhờ các Thầy định hướng giúp con ạ',
      'author': 'meomay16',
      'time': '00:25, 07/09/26',
      'category': 'Xem Tử vi',
      'replies': 1,
      'views': 48,
      'lastPostAuthor': 'meomay16',
      'lastPostTime': '00:43, 07/09/26',
      'pages': null,
    },
    {
      'id': 18,
      'title': 'Thiên tài John Forbes Nash-Mệnh VCD-Cung Di hoành tráng',
      'author': 'hongnguyen88',
      'time': '14:00, 16/08/25',
      'category': 'Xem Tử vi',
      'replies': 252,
      'views': 25225,
      'lastPostAuthor': 'hongnguyen88',
      'lastPostTime': '23:56, 06/09/26',
      'pages': [1, '...', 24, 25, 26],
    },
    {
      'id': 19,
      'title': 'Lá số Cự Lương Thìn Tuất',
      'author': 'minhhuy14',
      'time': '22:58, 27/08/25',
      'category': 'Xem Tử vi',
      'replies': 2,
      'views': 84,
      'lastPostAuthor': 'minhhuy14',
      'lastPostTime': '23:48, 06/09/26',
      'pages': null,
    },
    {
      'id': 20,
      'title': 'Xin nhờ mọi người xem giúp mệnh lại quan là tới liêm phá này với ạ',
      'author': 'hailuanhviet',
      'time': '18:03, 10/08/26',
      'category': 'Xem Tử vi',
      'replies': 3,
      'views': 119,
      'lastPostAuthor': 'hailuanhviet',
      'lastPostTime': '23:42, 06/09/26',
      'pages': null,
    },
    {
      'id': 21,
      'title': 'Bao giờ lấy được vợ',
      'author': 'phithienkim',
      'time': '20:53, 03/09/26',
      'category': 'Xem Tử vi',
      'replies': 6,
      'views': 124,
      'lastPostAuthor': 'nguyenkienbk',
      'lastPostTime': '23:37, 06/09/26',
      'pages': null,
    },
    {
      'id': 22,
      'title': 'PHÁ QUÂN: cùng tắc, xung phong...',
      'author': 'nguyenkien',
      'time': '14:48, 12/07/26',
      'category': 'Xem Tử vi',
      'replies': 60,
      'views': 5211,
      'lastPostAuthor': 'nguyenkien',
      'lastPostTime': '23:36, 06/09/26',
      'pages': [1, '...', 4, 5, 6],
    },
    {
      'id': 23,
      'title': 'Khi nào cảm thấy đối thời quan ăn uống và vận động?',
      'author': 'thangcon1',
      'time': '21:05, 05/09/26',
      'category': 'Câu lạc bộ - Giao lưu - Kết bạn',
      'replies': 0,
      'views': 7,
      'lastPostAuthor': 'thangcon1',
      'lastPostTime': '23:35, 06/09/26',
      'pages': null,
    },
    {
      'id': 24,
      'title': 'Bàn về lúc đại hạn, có phải là một dạng man thư vô cùng?',
      'author': 'giaothuyqn',
      'time': '07:07, 05/09/26',
      'category': 'Xem Tử vi',
      'replies': 16,
      'views': 1429,
      'lastPostAuthor': 'barretter',
      'lastPostTime': '23:29, 06/09/26',
      'pages': [1, 2],
    },
    {
      'id': 25,
      'title': 'Lá số Trạng Trình, 1 trong các nhà tiên tri nổi danh nhất thế giới',
      'author': 'mangxoi76',
      'time': '14:59, 13/08/26',
      'category': 'Xem Tử vi',
      'replies': 128,
      'views': 29359,
      'lastPostAuthor': 'barretter',
      'lastPostTime': '23:14, 06/09/26',
      'pages': [1, '...', 24, 25, 26],
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onMobileNavTapped(int index) {
    setState(() {
      _currentMobileIndex = index;
    });
  }

  // --- Layout Tổng Thể — MainLayout đã bọc sẵn 1024px ---
  Widget _buildBody(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Tiêu đề khối
          _buildPageHeader(),
          const SizedBox(height: 14),

          // 2. Thanh công cụ tìm kiếm và phân trang trên
          _buildSearchAndPaginationBar(isTop: true),
          const SizedBox(height: 12),

          // 3. Bảng Danh Sách 25 Bài Viết
          _buildPostsTable(),
          const SizedBox(height: 12),

          // 4. Thanh phân trang và điều hướng dưới
          _buildSearchAndPaginationBar(isTop: false),
          const SizedBox(height: 24),

          // 5. Khối Khám phá thêm
          _buildExploreMore(),
          const SizedBox(height: 28),

          // 6. Footer diễn đàn
          _buildForumFooter(),
        ],
      ),
    );
  }

  // --- 1. Tiêu Đề Màn Hình ---
  Widget _buildPageHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Bài chưa xem',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: () => context.go('/forum/search'),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Text(
                '< Quay về tìm kiếm nâng cao',
                style: TextStyle(
                  color: Color(0xFFEF5350),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- 2 & 4. Thanh Công Cụ & Cụm Phân Trang (Hình 4) ---
  Widget _buildSearchAndPaginationBar({required bool isTop}) {
    if (isTop) {
      return Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 12,
        runSpacing: 10,
        children: [
          // Khung tìm kiếm nội bộ
          Container(
            height: 34,
            constraints: const BoxConstraints(maxWidth: 260),
            decoration: BoxDecoration(
              color: const Color(0xFF131A30),
              border: Border.all(color: const Color(0xFF2E3B5F)),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(fontSize: 13, color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: 'Tìm trong những kết quả',
                      hintStyle: TextStyle(fontSize: 12.5, color: Colors.white38),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      isDense: true,
                    ),
                  ),
                ),
                Container(
                  height: 34,
                  width: 32,
                  decoration: const BoxDecoration(
                    border: Border(left: BorderSide(color: Color(0xFF2E3B5F))),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.search, size: 16, color: Colors.white70),
                    padding: EdgeInsets.zero,
                    onPressed: () {},
                  ),
                ),
                Container(
                  height: 34,
                  width: 32,
                  decoration: const BoxDecoration(
                    border: Border(left: BorderSide(color: Color(0xFF2E3B5F))),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.settings, size: 16, color: Colors.white70),
                    padding: EdgeInsets.zero,
                    onPressed: () {},
                  ),
                ),
              ],
            ),
          ),

          // Cụm phân trang trên chuẩn Hình 4:
          // "Đánh dấu tất cả các forum là đã đọc • Có 114 bài này, nằm với 12 trang [ 1 ] [ 2 ] [ 3 ] [ > ]"
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 6,
            children: [
              InkWell(
                onTap: () {},
                child: const Text(
                  'Đánh dấu tất cả các forum là đã đọc',
                  style: TextStyle(
                    color: Color(0xFFEF5350),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const Text('•', style: TextStyle(color: Colors.white38, fontSize: 12)),
              const Text(
                'Có 114 bài này, nằm với 12 trang',
                style: TextStyle(color: Colors.white70, fontSize: 12.5),
              ),
              _buildPageBox('1', isActive: _currentPage == 1, onTap: () => setState(() => _currentPage = 1)),
              _buildPageBox('2', isActive: _currentPage == 2, onTap: () => setState(() => _currentPage = 2)),
              _buildPageBox('3', isActive: _currentPage == 3, onTap: () => setState(() => _currentPage = 3)),
              _buildPageBox('>', isActive: false, onTap: () {
                if (_currentPage < 12) setState(() => _currentPage++);
              }),
            ],
          ),
        ],
      );
    } else {
      // Thanh phân trang phía dưới chuẩn Hình 4
      return Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 6,
                children: [
                  const Text(
                    'Có 114 bài này, nằm với 12 trang',
                    style: TextStyle(color: Colors.white70, fontSize: 12.5),
                  ),
                  _buildPageBox('1', isActive: _currentPage == 1, onTap: () => setState(() => _currentPage = 1)),
                  _buildPageBox('2', isActive: _currentPage == 2, onTap: () => setState(() => _currentPage = 2)),
                  _buildPageBox('3', isActive: _currentPage == 3, onTap: () => setState(() => _currentPage = 3)),
                  _buildPageBox('>', isActive: false, onTap: () {
                    if (_currentPage < 12) setState(() => _currentPage++);
                  }),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              InkWell(
                onTap: () => context.go('/forum/search'),
                child: const Text(
                  '< Quay về tìm kiếm nâng cao',
                  style: TextStyle(
                    color: Color(0xFFEF5350),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              // Dropdown "Chuyển đến"
              Container(
                height: 34,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF131A30),
                  border: Border.all(color: const Color(0xFF2E3B5F)),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedJumpCategory,
                    dropdownColor: const Color(0xFF131A30),
                    style: const TextStyle(fontSize: 13, color: Colors.white),
                    icon: const Icon(Icons.arrow_drop_down, color: Colors.white70),
                    items: _jumpCategories.map((cat) {
                      return DropdownMenuItem<String>(
                        value: cat,
                        child: Text(
                          cat,
                          style: TextStyle(
                            color: cat.startsWith('↳') ? Colors.white70 : Colors.white,
                            fontWeight: cat.startsWith('↳') ? FontWeight.normal : FontWeight.bold,
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _selectedJumpCategory = val;
                        });
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
        ],
      );
    }
  }

  Widget _buildPageBox(String text, {required bool isActive, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFEF5350) : const Color(0xFF131A30),
          border: Border.all(color: isActive ? const Color(0xFFEF5350) : const Color(0xFF2E3B5F)),
          borderRadius: BorderRadius.circular(3),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isActive ? Colors.white : Colors.white70,
          ),
        ),
      ),
    );
  }

  // --- 3. Bảng Danh Sách 25 Bài Viết ---
  Widget _buildPostsTable() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E2640),
        border: Border.all(color: const Color(0xFF2E3B5F)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        children: [
          // Header của bảng (Chủ đề, Trả lời, Xem, Bài cuối)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xFF131A30),
              borderRadius: BorderRadius.vertical(top: Radius.circular(5)),
              border: Border(bottom: BorderSide(color: Color(0xFF2E3B5F), width: 1.5)),
            ),
            child: Row(
              children: const [
                Expanded(
                  flex: 5,
                  child: Text(
                    'Chủ đề',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13.5),
                  ),
                ),
                SizedBox(
                  width: 70,
                  child: Text(
                    'Trả lời',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13.5),
                  ),
                ),
                SizedBox(
                  width: 70,
                  child: Text(
                    'Xem',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13.5),
                  ),
                ),
                SizedBox(
                  width: 170,
                  child: Text(
                    'Bài cuối',
                    textAlign: TextAlign.left,
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13.5),
                  ),
                ),
              ],
            ),
          ),

          // Danh sách 25 dòng
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _posts.length,
            separatorBuilder: (context, index) => const Divider(
              height: 1,
              thickness: 1,
              color: Color(0xFF2E3B5F),
            ),
            itemBuilder: (context, index) {
              final post = _posts[index];
              return _buildPostRow(post, index);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPostRow(Map<String, dynamic> post, int index) {
    final List<dynamic>? pages = post['pages'];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      color: index % 2 == 0 ? const Color(0xFF1E2640) : const Color(0xFF1A223A),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Cột 1: Thông tin chủ đề
          Expanded(
            flex: 5,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon phong bì / bài viết
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () => _navigateToTopic(context, post),
                    child: Container(
                      margin: const EdgeInsets.only(top: 2, right: 10),
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: const Color(0xFF131A30),
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFF2E3B5F)),
                        ),
                        child: const Icon(
                          Icons.mark_as_unread_outlined,
                          size: 16,
                          color: Color(0xFFEF5350),
                        ),
                      ),
                    ),
                  ),
                ),

                // Nội dung Tiêu đề & tác giả & phân trang
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _HoverableUnreadPostTitle(
                        title: post['title'] ?? '',
                        onTap: () => _navigateToTopic(context, post),
                      ),
                      const SizedBox(height: 4),
                      RichText(
                        text: TextSpan(
                          style: const TextStyle(fontSize: 12, color: Colors.white60),
                          children: [
                            const TextSpan(text: 'gửi bởi '),
                            TextSpan(
                              text: post['author'],
                              style: const TextStyle(
                                color: Color(0xFFEF5350),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextSpan(text: ' » ${post['time']} » trong '),
                            TextSpan(
                              text: post['category'],
                              style: const TextStyle(
                                color: Color(0xFFEF5350),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Phân trang nhỏ bên trong bài viết
                      if (pages != null && pages.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.description, size: 12, color: Colors.white38),
                            const SizedBox(width: 4),
                            Wrap(
                              spacing: 4,
                              children: pages.map((p) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF131A30),
                                    border: Border.all(color: const Color(0xFF2E3B5F)),
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                  child: Text(
                                    '$p',
                                    style: const TextStyle(fontSize: 10.5, color: Colors.white70),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Cột 2: Trả lời
          SizedBox(
            width: 70,
            child: Text(
              '${post['replies']}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          // Cột 3: Xem
          SizedBox(
            width: 70,
            child: Text(
              '${post['views']}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.white70,
              ),
            ),
          ),

          // Cột 4: Bài cuối
          SizedBox(
            width: 170,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('gửi bởi ', style: TextStyle(fontSize: 12, color: Colors.white60)),
                    Flexible(
                      child: Text(
                        post['lastPostAuthor'],
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFFEF5350),
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: () => _navigateToTopic(context, post),
                        child: const Icon(Icons.arrow_forward_ios, size: 9, color: Color(0xFFEF5350)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  post['lastPostTime'],
                  style: const TextStyle(fontSize: 11.5, color: Colors.white54),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- 5. Khối Khám Phá Thêm (Hình 4: "Nguồn Mở", "Thiết kế và nghệ thuật thị giác", "Thuốc nhuộm & Chất nhuộm") ---
  Widget _buildExploreMore() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E2640),
        border: Border.all(color: const Color(0xFF2E3B5F)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Khám phá thêm
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFF131A30),
              borderRadius: BorderRadius.vertical(top: Radius.circular(5)),
              border: Border(bottom: BorderSide(color: Color(0xFF2E3B5F), width: 1.5)),
            ),
            child: const Text(
              'Khám phá thêm',
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          _buildExploreItem('Nguồn Mở'),
          _buildExploreItem('Thiết kế và nghệ thuật thị giác'),
          _buildExploreItem('Thuốc nhuộm & Chất nhuộm', isLast: true),
        ],
      ),
    );
  }

  Widget _buildExploreItem(String title, {bool isLast = false}) {
    return InkWell(
      onTap: () {},
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: isLast ? null : const Border(bottom: BorderSide(color: Color(0xFF2E3B5F))),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 14, color: Colors.white),
            ),
            const Icon(Icons.chevron_right, color: Colors.white54, size: 18),
          ],
        ),
      ),
    );
  }

  // --- 6. Footer Diễn Đàn ---
  Widget _buildForumFooter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF131A30),
            border: Border.all(color: const Color(0xFF2E3B5F)),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            runSpacing: 10,
            children: [
              // Breadcrumb mini
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.home, color: Color(0xFFEF5350), size: 16),
                  const SizedBox(width: 4),
                  InkWell(
                    onTap: () => context.go('/'),
                    child: const Text('Trang chủ', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFEF5350))),
                  ),
                  const SizedBox(width: 6),
                  const Text('•', style: TextStyle(color: Colors.white38, fontSize: 12)),
                  const SizedBox(width: 6),
                  InkWell(
                    onTap: () => context.go('/forum'),
                    child: const Text('Diễn đàn', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFEF5350))),
                  ),
                ],
              ),
              // Links hỗ trợ
              Wrap(
                spacing: 12,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _buildFooterLink(Icons.mail, 'Liên hệ'),
                  _buildFooterLink(Icons.share, 'Chia sẻ'),
                  _buildFooterLink(Icons.security, 'Chúng tôi'),
                  _buildFooterLink(Icons.group, 'Thành viên'),
                  _buildFooterLink(Icons.delete, 'Xóa hết cookie'),
                  const Text('Múi giờ UTC+07:00', style: TextStyle(fontSize: 12, color: Colors.white54)),
                ],
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
        RichText(
          text: const TextSpan(
            style: TextStyle(fontSize: 12, color: Color(0xFFEF5350)),
            children: [
              TextSpan(text: 'Chính sách bảo mật'),
              TextSpan(text: ' | ', style: TextStyle(color: Colors.white38)),
              TextSpan(text: 'Điều khoản tham gia'),
            ],
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildFooterLink(IconData icon, String text) {
    return InkWell(
      onTap: () {},
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFFEF5350)),
          const SizedBox(width: 4),
          Text(text, style: const TextStyle(fontSize: 12.5, color: Color(0xFFEF5350))),
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
        desktopBody: _buildBody(context),
      ),
    );
  }
}

class _HoverableUnreadPostTitle extends StatefulWidget {
  final String title;
  final VoidCallback onTap;

  const _HoverableUnreadPostTitle({
    required this.title,
    required this.onTap,
  });

  @override
  State<_HoverableUnreadPostTitle> createState() => _HoverableUnreadPostTitleState();
}

class _HoverableUnreadPostTitleState extends State<_HoverableUnreadPostTitle> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final displayColor = _isHovered ? const Color(0xFF1E88E5) : const Color(0xFFEF5350);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Text(
          widget.title,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.bold,
            color: displayColor,
            height: 1.3,
            decoration: _isHovered ? TextDecoration.underline : null,
            decorationColor: displayColor,
          ),
        ),
      ),
    );
  }
}
