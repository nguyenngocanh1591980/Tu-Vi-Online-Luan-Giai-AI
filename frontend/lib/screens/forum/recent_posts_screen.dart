import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class RecentPostsScreen extends StatefulWidget {
  const RecentPostsScreen({super.key});

  @override
  State<RecentPostsScreen> createState() => _RecentPostsScreenState();
}

class _RecentPostsScreenState extends State<RecentPostsScreen> {
  int _currentPage = 1;
  final int _totalPages = 12;
  final TextEditingController _searchController = TextEditingController();
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

  // Danh sách 25 chủ đề thực tế từ Hình 5 bảo toàn 100%
  final List<Map<String, dynamic>> _posts = [
    {
      'title': 'Lá số phật thích ca mâu ni',
      'author': 'nguyenkienbk',
      'time': '20:00, 16/09/23',
      'category': 'Xem Tử vi',
      'replies': 38,
      'views': 15582,
      'lastAuthor': 'sunrise',
      'lastTime': '08:21, 07/09/26',
      'pages': null,
    },
    {
      'title': 'THAM TỌA QUANG QUÝ tự hiệu thân can cát hướng xin thiện nghiệp(nguoivikhieu.net)',
      'author': 'Thien-Su',
      'time': '20:30, 21/04/24',
      'category': 'Xem Tử vi',
      'replies': 125,
      'views': 16315,
      'lastAuthor': 'banhbeo',
      'lastTime': '05:38, 07/09/26',
      'pages': null,
    },
    {
      'title': 'MỆNH VCD CHỈ CÓ 1 CÂU MUỐN HỎI ĐÁP',
      'author': 'Mac Hieu',
      'time': '19:42, 22/04/24',
      'category': 'Xem Tử vi',
      'replies': 1,
      'views': 25,
      'lastAuthor': 'Mai Hữu Trao Vương',
      'lastTime': '05:32, 07/09/26',
      'pages': null,
    },
    {
      'title': 'Mệnh - Thân-Thê-Phu bị Không Kiếp xâm phạm nơi cần giải?',
      'author': 'changhye',
      'time': '22:58, 25/11/24',
      'category': 'Xem Tử vi',
      'replies': 36,
      'views': 4366,
      'lastAuthor': 'vuonhoa',
      'lastTime': '05:25, 07/09/26',
      'pages': null,
    },
    {
      'title': 'Kính nhờ anh Bradley xem giúp em với ạ.',
      'author': 'ngbaolac',
      'time': '08:35, 12/03/25',
      'category': 'Xem Tử vi',
      'replies': 16,
      'views': 232,
      'lastAuthor': 'aaaaa12',
      'lastTime': '04:47, 07/09/26',
      'pages': [1, 2, 3],
    },
    {
      'title': 'Tìm giờ sinh chính xác',
      'author': 'saominhtrang',
      'time': '20:25, 23/04/25',
      'category': 'Xem Tử vi',
      'replies': 14,
      'views': 252,
      'lastAuthor': 'saominhtrang',
      'lastTime': '03:49, 07/09/26',
      'pages': [1, 2, 3],
    },
    {
      'title': 'Mong muốn được giải đoán lá số Thái Dương Hãm Lại nghịch',
      'author': 'chuotchuot1607',
      'time': '15:48, 23/05/25',
      'category': 'Xem Tử vi',
      'replies': 6,
      'views': 166,
      'lastAuthor': 'chuotchuot1607',
      'lastTime': '03:19, 07/09/26',
      'pages': null,
    },
    {
      'title': 'Bát cháo hành',
      'author': 'Mai Hữu Trao Vương',
      'time': '18:31, 12/07/25',
      'category': 'Cuộc sống muôn màu',
      'replies': 2,
      'views': 23,
      'lastAuthor': 'Mai Hữu Trao Vương',
      'lastTime': '03:06, 07/09/26',
      'pages': null,
    },
    {
      'title': 'Hợi vận Thái tuế có đáng sợ không ạ?',
      'author': 'dothikieunga',
      'time': '15:52, 23/07/25',
      'category': 'Xem Tử vi',
      'replies': 4,
      'views': 24,
      'lastAuthor': 'vuonhoa',
      'lastTime': '03:01, 07/09/26',
      'pages': null,
    },
    {
      'title': 'Lá số thứ',
      'author': 'Mai Hữu Trao Vương',
      'time': '18:41, 10/08/25',
      'category': 'Xem Tử vi',
      'replies': 3,
      'views': 172,
      'lastAuthor': 'vuonhoa',
      'lastTime': '02:51, 07/09/26',
      'pages': null,
    },
    {
      'title': 'Cảm live Rơ ca',
      'author': 'phithienkim',
      'time': '02:26, 05/09/25',
      'category': 'Bàn cờ cuộc đời',
      'replies': 50,
      'views': 1000,
      'lastAuthor': 'vuonhoa',
      'lastTime': '02:35, 07/09/26',
      'pages': [1, 2, 3, 4, 5, 6],
    },
    {
      'title': 'Nhờ các bậc tiền bối giúp em lá số này với ạ(30-40) đoạn có đi giàu có h p. Nghe nói âm dương tối kị kinh đà',
      'author': 'saominhtrang',
      'time': '02:18, 11/08/25',
      'category': 'Xem Tử vi',
      'replies': 2,
      'views': 42,
      'lastAuthor': 'vuonhoa',
      'lastTime': '02:18, 07/09/26',
      'pages': null,
    },
    {
      'title': 'Lá số con trai em liệu có xuất ngoại được ko?',
      'author': 'conmemin',
      'time': '10:14, 11/08/25',
      'category': 'Xem Tử vi',
      'replies': 4,
      'views': 56,
      'lastAuthor': 'conmemin',
      'lastTime': '01:58, 07/09/26',
      'pages': null,
    },
    {
      'title': 'Phụ nữ mang Thai có nên Cắm phòng cúng?',
      'author': 'thangcon1',
      'time': '08:04, 11/08/25',
      'category': 'Giao lưu - Kết bạn',
      'replies': 0,
      'views': 4,
      'lastAuthor': 'thangcon1',
      'lastTime': '01:04, 07/09/26',
      'pages': null,
    },
    {
      'title': 'Hòa Thượng Thích Minh Châu',
      'author': 'phithienkim',
      'time': '15:43, 05/09/25',
      'category': 'Cổ học - Văn hóa - Tín ngưỡng',
      'replies': 140,
      'views': 13744,
      'lastAuthor': 'ams',
      'lastTime': '01:02, 07/09/26',
      'pages': [1, 2, 3, 4, 14],
    },
    {
      'title': 'Kính nhờ các Thầy định hướng giúp con ạ',
      'author': 'meomay16',
      'time': '00:25, 07/09/26',
      'category': 'Xem Tử vi',
      'replies': 1,
      'views': 48,
      'lastAuthor': 'meomay16',
      'lastTime': '00:43, 07/09/26',
      'pages': null,
    },
    {
      'title': 'Thiên tài John Forbes Nash-Mệnh VCD-Cung Di hoành tráng',
      'author': 'hongnguyen88',
      'time': '14:00, 16/08/25',
      'category': 'Xem Tử vi',
      'replies': 252,
      'views': 25225,
      'lastAuthor': 'hongnguyen88',
      'lastTime': '23:56, 06/09/26',
      'pages': [1, '...', 24, 25, 26],
    },
    {
      'title': 'Lá số Cự Lương Thìn Tuất',
      'author': 'minhhuy14',
      'time': '22:58, 27/08/25',
      'category': 'Xem Tử vi',
      'replies': 2,
      'views': 84,
      'lastAuthor': 'minhhuy14',
      'lastTime': '23:48, 06/09/26',
      'pages': null,
    },
    {
      'title': 'Xin nhờ mọi người xem giúp mệnh lại quan là tới liêm phá này với ạ',
      'author': 'hailuanhviet',
      'time': '18:03, 10/08/26',
      'category': 'Xem Tử vi',
      'replies': 3,
      'views': 119,
      'lastAuthor': 'hailuanhviet',
      'lastTime': '23:42, 06/09/26',
      'pages': null,
    },
    {
      'title': 'Bao giờ lấy được vợ',
      'author': 'phithienkim',
      'time': '20:53, 03/09/26',
      'category': 'Xem Tử vi',
      'replies': 6,
      'views': 124,
      'lastAuthor': 'nguyenkienbk',
      'lastTime': '23:37, 06/09/26',
      'pages': null,
    },
    {
      'title': 'PHÚ QUÂN: cùng tắc, xung phong...',
      'author': 'nguyenkien',
      'time': '14:48, 12/07/26',
      'category': 'Xem Tử vi',
      'replies': 60,
      'views': 5211,
      'lastAuthor': 'nguyenkien',
      'lastTime': '23:36, 06/09/26',
      'pages': [1, 2, 3, 4, 5, 6],
    },
    {
      'title': 'Khi nào cảm thấy đối thời quan ăn uống và vận động?',
      'author': 'thangcon1',
      'time': '21:05, 05/09/26',
      'category': 'Giao lưu - Kết bạn',
      'replies': 0,
      'views': 7,
      'lastAuthor': 'thangcon1',
      'lastTime': '23:35, 06/09/26',
      'pages': null,
    },
    {
      'title': 'Bàn về lúc đại hạn, có phải là một dạng ma thuật vô cùng?',
      'author': 'giaothuyqn',
      'time': '07:07, 05/09/26',
      'category': 'Xem Tử vi',
      'replies': 16,
      'views': 1429,
      'lastAuthor': 'barretter',
      'lastTime': '23:29, 06/09/26',
      'pages': [1, 2],
    },
    {
      'title': 'Lá số Trạng Trình, 1 trong các nhà tiên tri nổi danh nhất thế giới',
      'author': 'mangxoi76',
      'time': '14:59, 13/08/26',
      'category': 'Xem Tử vi',
      'replies': 128,
      'views': 29359,
      'lastAuthor': 'barretter',
      'lastTime': '23:14, 06/09/26',
      'pages': [1, '...', 24, 25, 26],
    },
    {
      'title': 'Bị các thầy bên chuyên đề qua mọng và đổi lại đất tát nó là cứ sao ạ, vi xin được xem xét a',
      'author': 'greenapples88',
      'time': '10:44, 06/09/26',
      'category': 'Xem Tử vi',
      'replies': 1,
      'views': 47,
      'lastAuthor': 'greenapples88',
      'lastTime': '23:14, 06/09/26',
      'pages': null,
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      body: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1024),
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.only(top: 0, bottom: 24.0),
              decoration: BoxDecoration(
                color: const Color(0xFF1E2640),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(8)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    spreadRadius: 2,
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(8)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 1. Tiêu đề khối "Bài gần đây"
                      _buildHeaderTitle(),
                      const SizedBox(height: 10),

                      // 2. Link "Quay về tìm kiếm nâng cao" trên
                      _buildBackToAdvancedSearch(),
                      const SizedBox(height: 10),

                      // 3. Thanh tìm kiếm và phân trang trên
                      _buildSearchAndPaginationBar(),
                      const SizedBox(height: 10),

                      // 4. Bảng danh sách bài viết
                      _buildPostsTable(),
                      const SizedBox(height: 10),

                      // 5. Thanh tìm kiếm và phân trang dưới
                      _buildSearchAndPaginationBar(),
                      const SizedBox(height: 10),

                      // 6. Link quay về tìm kiếm & Jump dropdown dưới
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildBackToAdvancedSearch(),
                          _buildJumpDropdown(),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // 7. Khối Khám phá thêm (3 mục chuẩn xác: Nâng Cấp Gói, Thuật Thư kim, Thẻ Công Cụ)
                      _buildExploreMoreSection(),
                      const SizedBox(height: 24),

                      // 8. Footer diễn đàn
                      _buildForumFooter(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- 1. Tiêu đề ---
  Widget _buildHeaderTitle() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF131A30),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF2E3B5F), width: 1),
      ),
      child: const Row(
        children: [
          Icon(Icons.history, color: Color(0xFFFFD700), size: 20),
          SizedBox(width: 8),
          Text(
            'Bài gần đây',
            style: TextStyle(
              color: Color(0xFFFFD700),
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  // --- 2. Link Quay về tìm kiếm nâng cao ---
  Widget _buildBackToAdvancedSearch() {
    return InkWell(
      onTap: () => context.go('/forum/search'),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.chevron_left, size: 16, color: Color(0xFF90CAF9)),
          SizedBox(width: 4),
          Text(
            'Quay về tìm kiếm nâng cao',
            style: TextStyle(
              color: Color(0xFF90CAF9),
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // --- 3 & 5. Thanh Tìm Kiếm Trong Cột & Phân Trang ---
  Widget _buildSearchAndPaginationBar() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isCompact = constraints.maxWidth < 650;

        final searchBox = Container(
          width: isCompact ? double.infinity : 220,
          height: 30,
          decoration: BoxDecoration(
            color: const Color(0xFF131A30),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: const Color(0xFF2E3B5F)),
          ),
          child: Row(
            children: [
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                  decoration: const InputDecoration(
                    hintText: 'Tìm trong những cột...',
                    hintStyle: TextStyle(color: Colors.white38, fontSize: 11.5),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              const Icon(Icons.search, size: 15, color: Colors.white70),
              const SizedBox(width: 6),
              const Icon(Icons.settings, size: 13, color: Colors.white70),
              const SizedBox(width: 6),
            ],
          ),
        );

        final paginationBox = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Có 114 bài này, nằm với 12 trang',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
            const SizedBox(width: 8),
            _buildPageBtn(1, isActive: _currentPage == 1),
            _buildPageBtn(2, isActive: _currentPage == 2),
            _buildPageBtn(3, isActive: _currentPage == 3),
            _buildPageBtn(4, isActive: _currentPage == 4),
            _buildPageBtn(5, isActive: _currentPage == 5),
            _buildPageBtn(6, isActive: _currentPage == 6),
            InkWell(
              onTap: () {
                if (_currentPage < _totalPages) {
                  setState(() => _currentPage++);
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                margin: const EdgeInsets.only(left: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF131A30),
                  borderRadius: BorderRadius.circular(3),
                  border: Border.all(color: const Color(0xFF2E3B5F)),
                ),
                child: const Icon(Icons.chevron_right, size: 14, color: Colors.white70),
              ),
            ),
          ],
        );

        if (isCompact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              searchBox,
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: paginationBox,
              ),
            ],
          );
        }

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            searchBox,
            paginationBox,
          ],
        );
      },
    );
  }

  Widget _buildPageBtn(int page, {bool isActive = false}) {
    return InkWell(
      onTap: () => setState(() => _currentPage = page),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 1.5),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF8B0000) : const Color(0xFF131A30),
          borderRadius: BorderRadius.circular(3),
          border: Border.all(
            color: isActive ? const Color(0xFFE53935) : const Color(0xFF2E3B5F),
          ),
        ),
        child: Text(
          '$page',
          style: TextStyle(
            color: isActive ? Colors.white : Colors.white70,
            fontSize: 11.5,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  // --- 4. Bảng Chủ Đề ---
  Widget _buildPostsTable() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF161F36),
        border: Border.all(color: const Color(0xFF2E3B5F), width: 1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double tableWidth = constraints.maxWidth > 760 ? constraints.maxWidth : 760.0;

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: tableWidth,
              child: Column(
                children: [
                  // Hàng Header Cột
                  Container(
                    decoration: const BoxDecoration(
                      color: Color(0xFF131A30),
                      borderRadius: BorderRadius.vertical(top: Radius.circular(5)),
                      border: Border(bottom: BorderSide(color: Color(0xFF2E3B5F), width: 1.5)),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 12),
                    child: const Row(
                      children: [
                        Expanded(
                          flex: 5,
                          child: Text(
                            'CHỦ ĐỀ',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Text(
                            'TRẢ LỜI',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Text(
                            'XEM',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            'BÀI CUỐI',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Các hàng bài viết
                  for (int i = 0; i < _posts.length; i++)
                    _buildPostRow(_posts[i], i),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPostRow(Map<String, dynamic> item, int index) {
    final isEven = index % 2 == 0;
    final rowBg = isEven ? const Color(0xFF1A233E) : const Color(0xFF151C33);
    final pages = item['pages'] as List<dynamic>?;

    return Container(
      decoration: BoxDecoration(
        color: rowBg,
        border: const Border(
          bottom: BorderSide(color: Color(0xFF242F50), width: 0.8),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 1. Cột Chủ đề
          Expanded(
            flex: 5,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 2, right: 8),
                  child: Icon(Icons.description_outlined, color: Color(0xFFEF5350), size: 16),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['title'] as String,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'gửi bởi ${item['author']} » ${item['time']} » trong ${item['category']}',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 11.5,
                        ),
                      ),
                      if (pages != null && pages.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.copy, color: Colors.white38, size: 10),
                            const SizedBox(width: 4),
                            for (final p in pages)
                              Container(
                                margin: const EdgeInsets.only(right: 3),
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF101628),
                                  borderRadius: BorderRadius.circular(2),
                                  border: Border.all(color: const Color(0xFF2E3B5F)),
                                ),
                                child: Text(
                                  '$p',
                                  style: const TextStyle(color: Colors.white70, fontSize: 10),
                                ),
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

          // 2. Cột Trả lời
          Expanded(
            flex: 1,
            child: Text(
              '${item['replies']}',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[300],
                fontSize: 12.5,
              ),
            ),
          ),

          // 3. Cột Xem
          Expanded(
            flex: 1,
            child: Text(
              '${item['views']}',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[300],
                fontSize: 12.5,
              ),
            ),
          ),

          // 4. Cột Bài cuối
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'gửi bởi ',
                      style: TextStyle(color: Colors.grey[400], fontSize: 11.5),
                    ),
                    Flexible(
                      child: Text(
                        item['lastAuthor'] as String,
                        style: const TextStyle(
                          color: Color(0xFFEF5350),
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 2),
                    const Icon(Icons.play_arrow, size: 10, color: Color(0xFFEF5350)),
                  ],
                ),
                Text(
                  item['lastTime'] as String,
                  style: TextStyle(color: Colors.grey[400], fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- 6. Jump Dropdown ---
  Widget _buildJumpDropdown() {
    return Container(
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF131A30),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFF2E3B5F)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedJumpCategory,
          dropdownColor: const Color(0xFF131A30),
          style: const TextStyle(color: Colors.white70, fontSize: 12),
          icon: const Icon(Icons.arrow_drop_down, color: Colors.white70, size: 18),
          items: _jumpCategories.map((category) {
            return DropdownMenuItem<String>(
              value: category,
              child: Text(category),
            );
          }).toList(),
          onChanged: (val) {
            if (val != null) {
              setState(() => _selectedJumpCategory = val);
            }
          },
        ),
      ),
    );
  }

  // --- 7. Khám Phá Thêm (3 mục chuẩn xác: Nâng Cấp Gói, Thuật Thư kim, Thẻ Công Cụ) ---
  Widget _buildExploreMoreSection() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF161F36),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF2E3B5F)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Tiêu đề khối
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xFF131A30),
              borderRadius: BorderRadius.vertical(top: Radius.circular(5)),
              border: Border(bottom: BorderSide(color: Color(0xFF2E3B5F))),
            ),
            child: const Text(
              'Khám phá thêm',
              style: TextStyle(
                color: Color(0xFFFFD700),
                fontWeight: FontWeight.bold,
                fontSize: 13.5,
              ),
            ),
          ),

          // 3 mục
          _buildExploreItem('Nâng Cấp Gói', () => context.go('/apps')),
          const Divider(height: 1, color: Color(0xFF242F50)),
          _buildExploreItem('Thuật Thư kim', () => context.go('/forum')),
          const Divider(height: 1, color: Color(0xFF242F50)),
          _buildExploreItem('Thẻ Công Cụ', () => context.go('/apps')),
        ],
      ),
    );
  }

  Widget _buildExploreItem(String title, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white54, size: 18),
          ],
        ),
      ),
    );
  }

  // --- 8. Footer Diễn Đàn ---
  Widget _buildForumFooter() {
    return Column(
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
                  const Text('<', style: TextStyle(color: Colors.white38, fontSize: 12)),
                  const SizedBox(width: 6),
                  InkWell(
                    onTap: () => context.go('/forum'),
                    child: const Text('Diễn đàn', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFEF5350))),
                  ),
                  const SizedBox(width: 6),
                  const Text('<', style: TextStyle(color: Colors.white38, fontSize: 12)),
                  const SizedBox(width: 6),
                  const Text('Bài gần đây', style: TextStyle(color: Colors.white70)),
                ],
              ),
              Wrap(
                spacing: 12,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _buildFooterLink(Icons.email, 'Liên hệ', () => context.go('/contact')),
                  _buildFooterLink(Icons.share, 'Chia sẻ', () {}),
                  _buildFooterLink(Icons.security, 'Chúng tôi', () => context.go('/forum/team')),
                  _buildFooterLink(Icons.group, 'Thành viên', () => context.go('/forum/members')),
                  _buildFooterLink(Icons.delete, 'Xóa hết cookie', () {}),
                  const Text('Múi giờ UTC+07:00', style: TextStyle(fontSize: 12, color: Colors.white54)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
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

  Widget _buildFooterLink(IconData icon, String text, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
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
}
