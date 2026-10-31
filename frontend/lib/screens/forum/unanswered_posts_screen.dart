import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../utils/boxed_snack_bar.dart';
import '../../widgets/responsive_layout.dart';
import '../../widgets/mobile_bottom_nav.dart';

class UnansweredPostsScreen extends StatefulWidget {
  const UnansweredPostsScreen({super.key});

  @override
  State<UnansweredPostsScreen> createState() => _UnansweredPostsScreenState();
}

class _UnansweredPostsScreenState extends State<UnansweredPostsScreen> {
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

  // Danh sách chính xác 100% 25 chủ đề từ Hình 2
  final List<Map<String, dynamic>> _posts = [
    {
      'id': 1,
      'title': 'Nhật nguyệt tịnh minh Bát toạ lương ninh',
      'author': 'tuantq',
      'time': '12:44, 25/07/26',
      'category': 'Xem Tử vi',
      'replies': 0,
      'views': 112,
      'lastPostAuthor': 'tuantq',
      'lastPostTime': '12:44, 25/07/26',
      'isHighlighted': false,
    },
    {
      'id': 2,
      'title': 'Xin các cao nhân luận giúp lá số Liêm Trinh - Phá Quân tại Dậu [mệnh tại Dậu...]',
      'author': 'Mai Hữu Trao Vương',
      'time': '19:42, 24/07/26',
      'category': 'Xem Tử vi',
      'replies': 0,
      'views': 127,
      'lastPostAuthor': 'Mai Hữu Trao Vương',
      'lastPostTime': '19:42, 24/07/26',
      'isHighlighted': false,
    },
    {
      'id': 3,
      'title': 'Phụ nữ mang thai có nên Cắm phòng cúng?',
      'author': 'thangcon1',
      'time': '08:04, 11/08/25',
      'category': 'Câu lạc bộ - Giao lưu - Kết bạn',
      'replies': 0,
      'views': 4,
      'lastPostAuthor': 'thangcon1',
      'lastPostTime': '01:04, 07/09/26',
      'isHighlighted': false,
    },
    {
      'id': 4,
      'title': 'Khi nào cần thay đổi thói quen ăn uống và vận động?',
      'author': 'thangcon1',
      'time': '21:05, 05/09/26',
      'category': 'Câu lạc bộ - Giao lưu - Kết bạn',
      'replies': 0,
      'views': 7,
      'lastPostAuthor': 'thangcon1',
      'lastPostTime': '23:35, 06/09/26',
      'isHighlighted': true, // Dòng thứ 4 được bôi highlight nền vàng hổ phách nổi bật
    },
    {
      'id': 5,
      'title': 'Mệnh nguyên thủ quốc gia',
      'author': 'ams',
      'time': '16:32, 20/07/26',
      'category': 'Xem Tử vi',
      'replies': 0,
      'views': 29,
      'lastPostAuthor': 'ams',
      'lastPostTime': '16:32, 20/07/26',
      'isHighlighted': false,
    },
    {
      'id': 6,
      'title': 'Tình rơi hình tế và hướng lai kinh tế',
      'author': 'barretter',
      'time': '14:04, 19/07/26',
      'category': 'Cuộc sống muôn màu',
      'replies': 0,
      'views': 11,
      'lastPostAuthor': 'barretter',
      'lastPostTime': '14:04, 19/07/26',
      'isHighlighted': false,
    },
    {
      'id': 7,
      'title': 'Giới phím ma',
      'author': 'Mai Hữu Trao Vương',
      'time': '10:48, 19/07/26',
      'category': 'Cuộc sống muôn màu',
      'replies': 0,
      'views': 7,
      'lastPostAuthor': 'Mai Hữu Trao Vương',
      'lastPostTime': '10:48, 19/07/26',
      'isHighlighted': false,
    },
    {
      'id': 8,
      'title': 'Nhờ giúp đỡ về kiện dương công việc',
      'author': 'hovantrinh',
      'time': '10:05, 19/07/26',
      'category': 'Xem Tử vi',
      'replies': 0,
      'views': 86,
      'lastPostAuthor': 'hovantrinh',
      'lastPostTime': '10:05, 19/07/26',
      'isHighlighted': false,
    },
    {
      'id': 9,
      'title': 'Mời anh chị em tới dự Cafe workshop - kỷ niệm 18 năm TL diễn đàn',
      'author': 'Quản lý',
      'time': '10:43, 19/07/26',
      'category': 'Thông báo - Sự kiện',
      'replies': 0,
      'views': 86,
      'lastPostAuthor': 'Quản lý',
      'lastPostTime': '10:43, 19/07/26',
      'isHighlighted': false,
    },
    {
      'id': 10,
      'title': 'Quy Bụi',
      'author': 'Mai Hữu Trao Vương',
      'time': '14:38, 18/07/26',
      'category': 'Cuộc sống muôn màu',
      'replies': 0,
      'views': 18,
      'lastPostAuthor': 'Mai Hữu Trao Vương',
      'lastPostTime': '14:38, 18/07/26',
      'isHighlighted': false,
    },
    {
      'id': 11,
      'title': 'Đi bộ hàng ngày: Người cao tuổi nên tập bao lâu?',
      'author': 'thangcon1',
      'time': '11:34, 18/07/26',
      'category': 'Câu lạc bộ - Giao lưu - Kết bạn',
      'replies': 0,
      'views': 4,
      'lastPostAuthor': 'thangcon1',
      'lastPostTime': '11:34, 18/07/26',
      'isHighlighted': false,
    },
    {
      'id': 12,
      'title': 'Ngo Trần',
      'author': 'Mai Hữu Trao Vương',
      'time': '18:48, 17/07/26',
      'category': 'Xem Tử vi',
      'replies': 0,
      'views': 68,
      'lastPostAuthor': 'Mai Hữu Trao Vương',
      'lastPostTime': '18:48, 17/07/26',
      'isHighlighted': false,
    },
    {
      'id': 13,
      'title': 'Hậu',
      'author': 'Mai Hữu Trao Vương',
      'time': '18:44, 17/07/26',
      'category': 'Cuộc sống muôn màu',
      'replies': 0,
      'views': 101,
      'lastPostAuthor': 'Mai Hữu Trao Vương',
      'lastPostTime': '18:44, 17/07/26',
      'isHighlighted': false,
    },
    {
      'id': 14,
      'title': 'Thiên cuộc',
      'author': 'Mai Hữu Trao Vương',
      'time': '18:38, 17/07/26',
      'category': 'Cuộc sống muôn màu',
      'replies': 0,
      'views': 114,
      'lastPostAuthor': 'Mai Hữu Trao Vương',
      'lastPostTime': '18:38, 17/07/26',
      'isHighlighted': false,
    },
    {
      'id': 15,
      'title': 'Không được đâu đại y',
      'author': 'Mai Hữu Trao Vương',
      'time': '18:32, 17/07/26',
      'category': 'Cuộc sống muôn màu',
      'replies': 0,
      'views': 70,
      'lastPostAuthor': 'Mai Hữu Trao Vương',
      'lastPostTime': '18:32, 17/07/26',
      'isHighlighted': false,
    },
    {
      'id': 16,
      'title': 'Những huyền thoại thoại',
      'author': 'barretter',
      'time': '17:31, 17/07/26',
      'category': 'Cuộc sống muôn màu',
      'replies': 0,
      'views': 113,
      'lastPostAuthor': 'barretter',
      'lastPostTime': '17:31, 17/07/26',
      'isHighlighted': false,
    },
    {
      'id': 17,
      'title': 'Khả',
      'author': 'Mai Hữu Trao Vương',
      'time': '18:13, 16/07/26',
      'category': 'Cuộc sống muôn màu',
      'replies': 0,
      'views': 114,
      'lastPostAuthor': 'Mai Hữu Trao Vương',
      'lastPostTime': '18:13, 16/07/26',
      'isHighlighted': false,
    },
    {
      'id': 18,
      'title': 'Cho chuyện Toán học',
      'author': 'Mai Hữu Trao Vương',
      'time': '18:07, 16/07/26',
      'category': 'Cuộc sống muôn màu',
      'replies': 0,
      'views': 118,
      'lastPostAuthor': 'Mai Hữu Trao Vương',
      'lastPostTime': '18:07, 16/07/26',
      'isHighlighted': false,
    },
    {
      'id': 19,
      'title': 'Cách kiểm soát tình trạng đầy bụng sau bữa ăn',
      'author': 'thangcon1',
      'time': '14:03, 16/07/26',
      'category': 'Câu lạc bộ - Giao lưu - Kết bạn',
      'replies': 0,
      'views': 7,
      'lastPostAuthor': 'thangcon1',
      'lastPostTime': '14:03, 16/07/26',
      'isHighlighted': false,
    },
    {
      'id': 20,
      'title': 'Nhẫn',
      'author': 'Mai Hữu Trao Vương',
      'time': '18:43, 15/07/26',
      'category': 'Câu lạc bộ - Giao lưu - Kết bạn',
      'replies': 0,
      'views': 121,
      'lastPostAuthor': 'Mai Hữu Trao Vương',
      'lastPostTime': '18:43, 15/07/26',
      'isHighlighted': false,
    },
    {
      'id': 21,
      'title': 'Nhờ bác Chuongduchoa coi giúp lá số tai vt',
      'author': 'vuonhoa',
      'time': '17:15, 15/07/26',
      'category': 'Xem Tử vi',
      'replies': 0,
      'views': 86,
      'lastPostAuthor': 'vuonhoa',
      'lastPostTime': '17:15, 15/07/26',
      'isHighlighted': false,
    },
    {
      'id': 22,
      'title': 'Protein giúp duy trì sức khỏe tuổi trung niên ra sao?',
      'author': 'thangcon1',
      'time': '10:14, 15/07/26',
      'category': 'Câu lạc bộ - Giao lưu - Kết bạn',
      'replies': 0,
      'views': 8,
      'lastPostAuthor': 'thangcon1',
      'lastPostTime': '10:14, 15/07/26',
      'isHighlighted': false,
    },
    {
      'id': 23,
      'title': 'Đêm bay Không Đêm',
      'author': 'Mai Hữu Trao Vương',
      'time': '18:55, 14/07/26',
      'category': 'Câu lạc bộ - Giao lưu - Kết bạn',
      'replies': 0,
      'views': 211,
      'lastPostAuthor': 'Mai Hữu Trao Vương',
      'lastPostTime': '18:55, 14/07/26',
      'isHighlighted': false,
    },
    {
      'id': 24,
      'title': 'Ngủ trưa quá nhiều và những tác động cần biết',
      'author': 'thangcon1',
      'time': '16:11, 14/07/26',
      'category': 'Câu lạc bộ - Giao lưu - Kết bạn',
      'replies': 0,
      'views': 15,
      'lastPostAuthor': 'thangcon1',
      'lastPostTime': '16:11, 14/07/26',
      'isHighlighted': false,
    },
    {
      'id': 25,
      'title': 'Có những ngày...',
      'author': 'Mai Hữu Trao Vương',
      'time': '17:35, 13/07/26',
      'category': 'Cuộc sống muôn màu',
      'replies': 0,
      'views': 111,
      'lastPostAuthor': 'Mai Hữu Trao Vương',
      'lastPostTime': '17:35, 13/07/26',
      'isHighlighted': false,
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
          'Bài chưa được trả lời',
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

  // --- 2 & 4. Thanh Công Cụ & Cụm Phân Trang (Hình 2) ---
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

          // Cụm phân trang trên chuẩn Hình 2:
          // "Đã tìm thấy nhiều hơn 1000 kết quả [ 1 ] [ 2 ] [ 3 ] [ 4 ] [ 5 ] ... [ 42 ] [ > ]"
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 5,
            children: [
              const Text(
                'Đã tìm thấy nhiều hơn 1000 kết quả',
                style: TextStyle(color: Colors.white70, fontSize: 12.5),
              ),
              const SizedBox(width: 4),
              _buildPageBox('1', isActive: _currentPage == 1, onTap: () => setState(() => _currentPage = 1)),
              _buildPageBox('2', isActive: _currentPage == 2, onTap: () => setState(() => _currentPage = 2)),
              _buildPageBox('3', isActive: _currentPage == 3, onTap: () => setState(() => _currentPage = 3)),
              _buildPageBox('4', isActive: _currentPage == 4, onTap: () => setState(() => _currentPage = 4)),
              _buildPageBox('5', isActive: _currentPage == 5, onTap: () => setState(() => _currentPage = 5)),
              const Text('...', style: TextStyle(color: Colors.white54, fontSize: 12)),
              _buildPageBox('42', isActive: _currentPage == 42, onTap: () => setState(() => _currentPage = 42)),
              _buildPageBox('>', isActive: false, onTap: () {
                if (_currentPage < 42) setState(() => _currentPage++);
              }),
            ],
          ),
        ],
      );
    } else {
      // Thanh phân trang phía dưới chuẩn Hình 2
      return Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Nút sort / view tuỳ chọn
              Container(
                height: 32,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF131A30),
                  border: Border.all(color: const Color(0xFF2E3B5F)),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.sort, size: 16, color: Colors.white70),
                    SizedBox(width: 4),
                    Icon(Icons.arrow_drop_down, size: 16, color: Colors.white70),
                  ],
                ),
              ),

              // Cụm phân trang dưới
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 5,
                children: [
                  const Text(
                    'Đã tìm thấy nhiều hơn 1000 kết quả',
                    style: TextStyle(color: Colors.white70, fontSize: 12.5),
                  ),
                  const SizedBox(width: 4),
                  _buildPageBox('1', isActive: _currentPage == 1, onTap: () => setState(() => _currentPage = 1)),
                  _buildPageBox('2', isActive: _currentPage == 2, onTap: () => setState(() => _currentPage = 2)),
                  _buildPageBox('3', isActive: _currentPage == 3, onTap: () => setState(() => _currentPage = 3)),
                  _buildPageBox('4', isActive: _currentPage == 4, onTap: () => setState(() => _currentPage = 4)),
                  _buildPageBox('5', isActive: _currentPage == 5, onTap: () => setState(() => _currentPage = 5)),
                  const Text('...', style: TextStyle(color: Colors.white54, fontSize: 12)),
                  _buildPageBox('42', isActive: _currentPage == 42, onTap: () => setState(() => _currentPage = 42)),
                  _buildPageBox('>', isActive: false, onTap: () {
                    if (_currentPage < 42) setState(() => _currentPage++);
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
    final bool isHighlighted = post['isHighlighted'] == true;

    // Màu nền dòng: Dòng thứ 4 được highlight nền vàng hổ phách nổi bật
    final Color rowBgColor = isHighlighted
        ? const Color(0xFF3E3418) // Nền vàng hổ phách nổi bật cho dòng highlight
        : (index % 2 == 0 ? const Color(0xFF1E2640) : const Color(0xFF1A223A));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: rowBgColor,
        border: isHighlighted
            ? const Border(
                left: BorderSide(color: Color(0xFFFBC02D), width: 4),
                top: BorderSide(color: Color(0xFFFBC02D), width: 0.5),
                bottom: BorderSide(color: Color(0xFFFBC02D), width: 0.5),
              )
            : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Cột 1: Thông tin chủ đề
          Expanded(
            flex: 5,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon chủ đề
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
                          border: Border.all(
                            color: isHighlighted ? const Color(0xFFFBC02D) : const Color(0xFF2E3B5F),
                          ),
                        ),
                        child: Icon(
                          Icons.assignment_late_outlined,
                          size: 16,
                          color: isHighlighted ? const Color(0xFFFBC02D) : const Color(0xFFEF5350),
                        ),
                      ),
                    ),
                  ),
                ),

                // Nội dung Tiêu đề & tác giả
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _HoverableUnansweredPostTitle(
                        title: post['title'] ?? '',
                        isHighlighted: isHighlighted,
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
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Cột 2: Trả lời (Tất cả hiển thị 0)
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

  // --- 5. Khối Khám Phá Thêm (Hình 2: "Nhà cung cấp dịch vụ diễn đàn và trò chuyện", "Thiết kế và nghệ thuật thị giác", "Thuốc nhuộm & Chất nhuộm") ---
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
          _buildExploreItem('Nhà cung cấp dịch vụ diễn đàn và trò chuyện'),
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
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontSize: 14, color: Colors.white),
              ),
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

class _HoverableUnansweredPostTitle extends StatefulWidget {
  final String title;
  final bool isHighlighted;
  final VoidCallback onTap;

  const _HoverableUnansweredPostTitle({
    required this.title,
    required this.isHighlighted,
    required this.onTap,
  });

  @override
  State<_HoverableUnansweredPostTitle> createState() => _HoverableUnansweredPostTitleState();
}

class _HoverableUnansweredPostTitleState extends State<_HoverableUnansweredPostTitle> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    Color defaultColor = widget.isHighlighted ? const Color(0xFFFFD54F) : const Color(0xFFEF5350);
    final displayColor = _isHovered ? const Color(0xFF1E88E5) : defaultColor;

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
