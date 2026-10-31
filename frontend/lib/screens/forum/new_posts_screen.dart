import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../utils/boxed_snack_bar.dart';
import '../../widgets/responsive_layout.dart';
import '../../widgets/mobile_bottom_nav.dart';

class NewPostsScreen extends StatefulWidget {
  const NewPostsScreen({super.key});

  @override
  State<NewPostsScreen> createState() => _NewPostsScreenState();
}

class _NewPostsScreenState extends State<NewPostsScreen> {
  int _currentMobileIndex = 2; // Tab Diễn đàn
  int _currentPage = 1;
  final int _totalPages = 6;
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

  // Dữ liệu chuẩn xác 20 bài viết mới nhất từ Hình 3
  final List<Map<String, dynamic>> _posts = [
    {
      'id': 1,
      'title': 'Mạng hữu duyên cùng việc tâm linh',
      'author': 'tientai',
      'time': '18:41, 05/01/21',
      'category': 'Câu lạc bộ - Giao lưu - Kết bạn',
      'replies': 9,
      'views': 1087,
      'lastPostAuthor': 'TUVI 12',
      'lastPostTime': '09:01, 07/09/26',
      'pages': null,
    },
    {
      'id': 2,
      'title': 'Nghiệm lý với hình dáng, tướng mạo qua Tử vi',
      'author': 'hạt gạo nhỏ',
      'time': '09:03, 01/01/12',
      'category': 'Xem Tử vi',
      'replies': 37458,
      'views': 3505778,
      'lastPostAuthor': 'thikthii',
      'lastPostTime': '08:58, 07/09/26',
      'pages': [1, 2, 3, 4, 5, 3748],
    },
    {
      'id': 3,
      'title': 'Nhờ các nhân luận giải giúp em/cháu đợt này 38-48',
      'author': 'goldenstar',
      'time': '22:55, 05/09/26',
      'category': 'Xem Tử vi',
      'replies': 11,
      'views': 288,
      'lastPostAuthor': 'vtsaucy',
      'lastPostTime': '08:34, 07/09/26',
      'pages': null,
    },
    {
      'id': 4,
      'title': 'Lá số phật Thích ca mâu ni',
      'author': 'nguyenkienbk',
      'time': '20:00, 16/09/23',
      'category': 'Xem Tử vi',
      'replies': 38,
      'views': 15578,
      'lastPostAuthor': 'sunrise',
      'lastPostTime': '08:21, 07/09/26',
      'pages': null,
    },
    {
      'id': 5,
      'title': 'Phúc đức là rễ hay mệnh mới là rễ',
      'author': 'sang16bn',
      'time': '18:24, 05/09/26',
      'category': 'Xem Tử vi',
      'replies': 71,
      'views': 1253,
      'lastPostAuthor': 'thikthii',
      'lastPostTime': '08:20, 07/09/26',
      'pages': [1, 2, 3, 4, 8],
    },
    {
      'id': 6,
      'title': 'Lá số nhờ mọi người xem giúp mệnh lại quan là tới liêm phá này với ạ',
      'author': 'hailuanhviet',
      'time': '08:03, 10/08/26',
      'category': 'Lớp học tử vi',
      'replies': 2,
      'views': 55,
      'lastPostAuthor': 'vtsaucy',
      'lastPostTime': '08:14, 07/09/26',
      'pages': null,
    },
    {
      'id': 7,
      'title': 'Nhờ bác Chuong@than coi giúp lá số tử vi',
      'author': 'soiconbuidoi',
      'time': '22:04, 02/09/26',
      'category': 'Xem Tử vi',
      'replies': 6,
      'views': 211,
      'lastPostAuthor': 'soiconbuidoi',
      'lastPostTime': '08:07, 07/09/26',
      'pages': null,
    },
    {
      'id': 8,
      'title': 'Năm nay không nên làm ăn ở vận này ạ',
      'author': 'nguoilamvuon88',
      'time': '23:28, 05/09/26',
      'category': 'Xem Tử vi',
      'replies': 3,
      'views': 125,
      'lastPostAuthor': 'vtsaucy',
      'lastPostTime': '08:01, 07/09/26',
      'pages': null,
    },
    {
      'id': 9,
      'title': 'Cho con xin hỏi duyên sang Pháp màu vé xin lời khuyên với ạ!',
      'author': 'Cà rốt Vui Vẻ',
      'time': '08:44, 05/09/26',
      'category': 'Xem Tử vi',
      'replies': 1,
      'views': 95,
      'lastPostAuthor': 'Cà rốt Vui Vẻ',
      'lastPostTime': '07:55, 07/09/26',
      'pages': null,
    },
    {
      'id': 10,
      'title': 'Cần tìm Mẹ ca',
      'author': 'phithienkim',
      'time': '19:43, 03/07/21',
      'category': 'Câu lạc bộ - Giao lưu - Kết bạn',
      'replies': 34,
      'views': 1053,
      'lastPostAuthor': 'scarletst',
      'lastPostTime': '08:05, 07/09/26',
      'pages': [1, 2, 3, 4],
    },
    {
      'id': 11,
      'title': 'Tìm sự cứu trinh ở đâu',
      'author': 'lavender',
      'time': '14:12, 10/06/21',
      'category': 'Cuộc sống muôn màu',
      'replies': 8,
      'views': 149,
      'lastPostAuthor': 'lavender',
      'lastPostTime': '08:02, 07/09/26',
      'pages': null,
    },
    {
      'id': 12,
      'title': 'Bị phản là lá số này sống đến giờ là kỳ tích?',
      'author': 'luanlytuvi88',
      'time': '22:15, 02/09/26',
      'category': 'Xem Tử vi',
      'replies': 25,
      'views': 504,
      'lastPostAuthor': 'scarletst',
      'lastPostTime': '07:59, 07/09/26',
      'pages': [1, 2, 3],
    },
    {
      'id': 13,
      'title': 'Vợ chồng em hiếm muộn đến nay là 5 năm rồi ạ',
      'author': 'giotnuoctrenla',
      'time': '11:32, 05/09/26',
      'category': 'Xem Tử vi',
      'replies': 6,
      'views': 192,
      'lastPostAuthor': 'vtsaucy',
      'lastPostTime': '07:49, 07/09/26',
      'pages': null,
    },
    {
      'id': 14,
      'title': 'Thời trai là đã qua rồi / Cứ nhìn mai tóc gió thổi loa dài',
      'author': 'thikthii',
      'time': '20:43, 27/08/26',
      'category': 'Cuộc sống muôn màu',
      'replies': 35,
      'views': 1272,
      'lastPostAuthor': 'thikthii',
      'lastPostTime': '07:47, 07/09/26',
      'pages': [1, 2, 3, 4, 7],
    },
    {
      'id': 15,
      'title': 'Ngu muội',
      'author': 'Hội Hậu Mạt Vương Q',
      'time': '08:26, 07/09/26',
      'category': 'Cuộc sống muôn màu',
      'replies': 1,
      'views': 18,
      'lastPostAuthor': 'Hội Hậu Mạt Vương Q',
      'lastPostTime': '07:35, 07/09/26',
      'pages': null,
    },
    {
      'id': 16,
      'title': 'Còn nhiều Bản lĩnh',
      'author': 'Hội Hậu Mạt Vương Q',
      'time': '08:30, 07/09/26',
      'category': 'Cuộc sống muôn màu',
      'replies': 2,
      'views': 22,
      'lastPostAuthor': 'Hội Hậu Mạt Vương Q',
      'lastPostTime': '07:33, 07/09/26',
      'pages': null,
    },
    {
      'id': 17,
      'title': 'Ly nhục lạc',
      'author': 'lavender',
      'time': '16:54, 29/08/26',
      'category': 'Cuộc sống muôn màu',
      'replies': 20,
      'views': 725,
      'lastPostAuthor': 'lavender',
      'lastPostTime': '07:18, 07/09/26',
      'pages': [1, 2, 3],
    },
    {
      'id': 18,
      'title': 'Ý vay nghĩ',
      'author': 'phithienkim',
      'time': '14:04, 05/09/26',
      'category': 'Cổ học - Văn hóa - Tín ngưỡng',
      'replies': 28,
      'views': 1078,
      'lastPostAuthor': 'ams',
      'lastPostTime': '07:10, 07/09/26',
      'pages': [1, 2, 3, 4],
    },
    {
      'id': 19,
      'title': 'Mùa Thượng Thích Minh Châu',
      'author': 'phithienkim',
      'time': '15:43, 05/09/26',
      'category': 'Cổ học - Văn hóa - Tín ngưỡng',
      'replies': 139,
      'views': 13543,
      'lastPostAuthor': 'ams',
      'lastPostTime': '07:06, 07/09/26',
      'pages': [1, 2, 3, 4, 14],
    },
    {
      'id': 20,
      'title': 'Protein giúp duy trì sức khỏe tuổi trung niên ra sao?',
      'author': 'giatnguyet',
      'time': '07:48, 17/09/26',
      'category': 'Cuộc sống - Sức khỏe - Đời sống',
      'replies': 0,
      'views': 6,
      'lastPostAuthor': 'giatnguyet',
      'lastPostTime': '06:48, 07/09/26',
      'pages': null,
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
          const SizedBox(height: 16),

          // 2. Thanh công cụ tìm kiếm và thông tin kết quả trên
          _buildSearchAndPaginationBar(isTop: true),
          const SizedBox(height: 12),

          // 3. Bảng Danh Sách Bài Viết (Tỷ lệ 5:2:3 chuẩn xác)
          _buildPostsTable(),
          const SizedBox(height: 12),

          // 4. Thanh công cụ và phân trang dưới
          _buildSearchAndPaginationBar(isTop: false),
          const SizedBox(height: 28),

          // 5. Khám phá thêm
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
          Row(
            children: const [
              Icon(Icons.mark_chat_unread_outlined, color: Color(0xFFFFD700), size: 24),
              SizedBox(width: 10),
              Text(
                'Bài viết mới',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFFD700), // Vàng hoàng gia sang trọng
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          InkWell(
            onTap: () => context.go('/forum'),
            child: Row(
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

  // --- 2 & 4. Thanh Công Cụ Tìm Kiếm & Phân Trang ---
  Widget _buildSearchAndPaginationBar({required bool isTop}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isCompact = constraints.maxWidth < 650;

        if (isCompact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Link quay về
              InkWell(
                onTap: () {},
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.chevron_left, color: Color(0xFFEF5350), size: 16),
                    Text(
                      'Quay về tìm kiếm nâng cao',
                      style: TextStyle(color: Color(0xFFEF5350), fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              // Ô search nếu ở trên
              if (isTop) ...[
                _buildSearchInput(),
                const SizedBox(height: 8),
              ],
              // Dòng kết quả & Phân trang
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Có thể thấy ${_posts.length} kết quả (trang $_currentPage / $_totalPages)',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  _buildPaginationControls(),
                ],
              ),
              if (!isTop) ...[
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: _buildJumpDropdown(),
                ),
              ],
            ],
          );
        }

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Cụm bên trái: Link quay về & Ô tìm kiếm (nếu isTop)
            Row(
              children: [
                InkWell(
                  onTap: () {},
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.chevron_left, color: Color(0xFFEF5350), size: 16),
                      Text(
                        'Quay về tìm kiếm nâng cao',
                        style: TextStyle(
                          color: Color(0xFFEF5350),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isTop) ...[
                  const SizedBox(width: 14),
                  _buildSearchInput(),
                ],
              ],
            ),
            // Cụm bên phải: Thống kê & Phân trang
            Row(
              children: [
                Text(
                  'Có thể thấy ${_posts.length} kết quả • trang $_currentPage trên $_totalPages',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(width: 12),
                _buildPaginationControls(),
                if (!isTop) ...[
                  const SizedBox(width: 8),
                  _buildJumpDropdown(),
                ],
              ],
            ),
          ],
        );
      },
    );
  }

  // Widget ô tìm kiếm trong bảng
  Widget _buildSearchInput() {
    return Container(
      width: 220,
      height: 32,
      decoration: BoxDecoration(
        color: const Color(0xFF131A30),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFF37446B)),
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
                hintStyle: TextStyle(color: Colors.white38, fontSize: 12),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.search, size: 16, color: Colors.white70),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            onPressed: () {},
            tooltip: 'Tìm kiếm',
          ),
          Container(width: 1, height: 16, color: Colors.white24),
          IconButton(
            icon: const Icon(Icons.settings, size: 14, color: Colors.white70),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            onPressed: () {},
            tooltip: 'Cài đặt tìm kiếm',
          ),
        ],
      ),
    );
  }

  // Widget cụm phân trang [1] [2] [3]...
  Widget _buildPaginationControls() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int p = 1; p <= 3; p++)
          _buildPageNumberButton(p, isActive: p == _currentPage),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4),
          child: Text('...', style: TextStyle(color: Colors.white54)),
        ),
        _buildPageNumberButton(6, isActive: 6 == _currentPage),
        const SizedBox(width: 4),
        InkWell(
          onTap: () {
            if (_currentPage < _totalPages) {
              setState(() => _currentPage++);
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF263252),
              borderRadius: BorderRadius.circular(3),
              border: Border.all(color: const Color(0xFF3E4E77)),
            ),
            child: const Text(
              'Tiếp',
              style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPageNumberButton(int page, {bool isActive = false}) {
    return InkWell(
      onTap: () => setState(() => _currentPage = page),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF8B0000) : const Color(0xFF263252),
          borderRadius: BorderRadius.circular(3),
          border: Border.all(
            color: isActive ? const Color(0xFFE53935) : const Color(0xFF3E4E77),
          ),
        ),
        child: Text(
          '$page',
          style: TextStyle(
            color: isActive ? Colors.white : Colors.white70,
            fontSize: 12,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildJumpDropdown() {
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF131A30),
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: const Color(0xFF37446B)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: 'chuyen_den',
          dropdownColor: const Color(0xFF1E2640),
          style: const TextStyle(color: Colors.white70, fontSize: 12),
          icon: const Icon(Icons.arrow_drop_down, color: Colors.white70, size: 18),
          items: const [
            DropdownMenuItem(value: 'chuyen_den', child: Text('Chuyển đến...')),
            DropdownMenuItem(value: 'tu_vi', child: Text('Xem Tử vi')),
            DropdownMenuItem(value: 'tu_tru', child: Text('Kiến thức Tứ trụ')),
            DropdownMenuItem(value: 'cuoc_song', child: Text('Cuộc sống muôn màu')),
          ],
          onChanged: (_) {},
        ),
      ),
    );
  }

  // --- 3. Bảng Danh Sách Bài Viết (Chuẩn Tỷ Lệ 5:2:3 & Cuộn Ngang Thiết Bị Nhỏ) ---
  Widget _buildPostsTable() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF161F36),
        border: Border.all(color: const Color(0xFF2E3B5F)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Khóa tối thiểu 800px để không vỡ tỷ lệ 5:2:3 trên mobile
          final double tableWidth = constraints.maxWidth > 800 ? constraints.maxWidth : 800.0;

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: tableWidth,
              child: Column(
                children: [
                  // --- Header Hàng Tiêu Đề Cột: Tỷ lệ 5 : 2 : 3 ---
                  Container(
                    decoration: const BoxDecoration(
                      color: Color(0xFF8B0000), // Đỏ đô chuẩn nhận diện
                      borderRadius: BorderRadius.vertical(top: Radius.circular(5)),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Cột 1: Chủ đề (flex: 5)
                        const Expanded(
                          flex: 5,
                          child: Text(
                            'Chủ đề',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        // Cột 2: Trả lời / Xem (flex: 2)
                        Expanded(
                          flex: 2,
                          child: Row(
                            children: const [
                              Expanded(
                                child: Text(
                                  'Trả lời',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  'Xem',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Cột 3: Bài cuối (flex: 3)
                        const Expanded(
                          flex: 3,
                          child: Padding(
                            padding: EdgeInsets.only(left: 8.0),
                            child: Text(
                              'Bài cuối',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // --- Danh Sách Từng Dòng Bài Viết ---
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _posts.length,
                    separatorBuilder: (context, index) => const Divider(
                      color: Colors.white24, // Đường viền mờ chống lóa mắt
                      height: 1,
                      thickness: 1,
                    ),
                    itemBuilder: (context, index) {
                      final post = _posts[index];
                      return _buildPostRow(post);
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // Xây dựng 1 dòng bài viết với Expanded flex: 5 : 2 : 3
  Widget _buildPostRow(Map<String, dynamic> post) {
    final List<dynamic>? pages = post['pages'];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // === CỘT 1 (flex: 5): Icon, Tiêu đề bài viết & Tác giả/Chuyên mục ===
          Expanded(
            flex: 5,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon trạng thái bài viết
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () => _navigateToTopic(context, post),
                    child: const Padding(
                      padding: EdgeInsets.only(top: 2.0, right: 10.0),
                      child: Icon(
                        Icons.description,
                        color: Color(0xFFEF5350), // Đỏ tươi nổi bật
                        size: 20,
                      ),
                    ),
                  ),
                ),
                // Nội dung text tiêu đề & metadata
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Tiêu đề bài viết (Trắng sáng, tối đa 2 dòng kèm dấu ...)
                      _HoverablePostTitle(
                        title: post['title'] ?? '',
                        onTap: () => _navigateToTopic(context, post),
                      ),
                      const SizedBox(height: 4),
                      // Dòng thông tin người gửi » thời gian » chuyên mục
                      RichText(
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        text: TextSpan(
                          style: const TextStyle(color: Colors.white54, fontSize: 12),
                          children: [
                            const TextSpan(text: 'gửi bởi '),
                            TextSpan(
                              text: post['author'],
                              style: const TextStyle(
                                color: Color(0xFFFF8A80),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextSpan(text: ' » ${post['time']} » trong '),
                            TextSpan(
                              text: post['category'],
                              style: const TextStyle(color: Color(0xFF80D8FF)),
                            ),
                          ],
                        ),
                      ),
                      // Nếu có các nút trang nhỏ [1] [2] [3]...
                      if (pages != null && pages.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 3,
                          runSpacing: 2,
                          children: [
                            const Text(
                              '[ Đi đến trang: ',
                              style: TextStyle(color: Colors.white38, fontSize: 11),
                            ),
                            ...pages.map((p) {
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF263252),
                                  borderRadius: BorderRadius.circular(2),
                                  border: Border.all(color: const Color(0xFF3E4E77)),
                                ),
                                child: Text(
                                  '$p',
                                  style: const TextStyle(color: Colors.white70, fontSize: 10),
                                ),
                              );
                            }),
                            const Text(
                              ' ]',
                              style: TextStyle(color: Colors.white38, fontSize: 11),
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

          // === CỘT 2 (flex: 2): Số Trả lời & Số lượt xem ===
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${post['replies']}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    '${post['views']}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // === CỘT 3 (flex: 3): Bài cuối (Tác giả, Thời gian, Nút xem nhanh) ===
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  RichText(
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    text: TextSpan(
                      style: const TextStyle(color: Colors.white70, fontSize: 12.5),
                      children: [
                        const TextSpan(text: 'gửi bởi '),
                        TextSpan(
                          text: post['lastPostAuthor'],
                          style: const TextStyle(
                            color: Color(0xFFFF8A80),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          post['lastPostTime'],
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.grey[400], fontSize: 12),
                        ),
                      ),
                      const SizedBox(width: 4),
                      InkWell(
                        onTap: () => _navigateToTopic(context, post),
                        child: const Icon(Icons.open_in_new, color: Color(0xFF00E5FF), size: 13),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- 5. Khối Khám Phá Thêm ---
  Widget _buildExploreMore() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF161F36),
        border: Border.all(color: const Color(0xFF2E3B5F)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFF131A30),
              borderRadius: BorderRadius.vertical(top: Radius.circular(5)),
              border: Border(bottom: BorderSide(color: Color(0xFF2E3B5F))),
            ),
            width: double.infinity,
            child: const Text(
              'Khám phá thêm',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: Color(0xFFFFD700),
              ),
            ),
          ),
          _buildExploreItem('Công cụ Tìm kiếm'),
          _buildExploreItem('Software'),
          _buildExploreItem('Dự đoán/Ngũ linh học', isLast: true),
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
          border: isLast ? null : const Border(bottom: BorderSide(color: Colors.white12)),
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
            color: const Color(0xFF161F36),
            border: Border.all(color: const Color(0xFF2E3B5F)),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            runSpacing: 10,
            children: [
              // Trái: Breadcrumb mini
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
                  const Text('Bài viết mới', style: TextStyle(color: Colors.white70)),
                ],
              ),
              // Phải: Các liên kết chức năng
              Wrap(
                spacing: 12,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _buildFooterLink(Icons.email, 'Liên hệ'),
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
        const SizedBox(height: 20),
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
        const SizedBox(height: 24),
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

class _HoverablePostTitle extends StatefulWidget {
  final String title;
  final VoidCallback onTap;

  const _HoverablePostTitle({
    required this.title,
    required this.onTap,
  });

  @override
  State<_HoverablePostTitle> createState() => _HoverablePostTitleState();
}

class _HoverablePostTitleState extends State<_HoverablePostTitle> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final displayColor = _isHovered ? const Color(0xFF1E88E5) : Colors.white;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Text(
          widget.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: displayColor,
            fontSize: 14.5,
            fontWeight: FontWeight.w600,
            height: 1.3,
            decoration: _isHovered ? TextDecoration.underline : null,
            decorationColor: displayColor,
          ),
        ),
      ),
    );
  }
}
