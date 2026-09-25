import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/responsive_layout.dart';
import '../../widgets/mobile_bottom_nav.dart';

class UserPostsScreen extends StatefulWidget {
  const UserPostsScreen({super.key});

  @override
  State<UserPostsScreen> createState() => _UserPostsScreenState();
}

class _UserPostsScreenState extends State<UserPostsScreen> {
  int _currentMobileIndex = 2; // Tab Diễn đàn
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

  // Dữ liệu chính xác 100% 10 chủ đề từ Hình 2
  final List<Map<String, dynamic>> _posts = [
    {
      'id': 1,
      'title': 'Mong mọi người giúp đỡ, em đang khá phân vân chuyện học hành',
      'author': 'lebkue',
      'time': '20:26, 12/07/12',
      'category': 'Xem Tử vi',
      'replies': 9,
      'views': 1245,
      'lastPostAuthor': 'lebkue',
      'lastPostTime': '19:56, 12/02/24',
      'isHot': false,
      'isFavorite': false,
      'pages': null,
    },
    {
      'id': 2,
      'title': 'LÁ SỐ HÓA KHOA LỘC MÃ TẠI PHU....CHỒNG ẮT HẲN GIÀU CÓ ĐỊA VỊ HƠN NGƯỜI',
      'author': 'vuulan',
      'time': '20:03, 23/11/14',
      'category': 'Xem Tử vi',
      'replies': 147,
      'views': 31248,
      'lastPostAuthor': 'hysshu',
      'lastPostTime': '12:14, 30/04/22',
      'isHot': true,
      'isFavorite': true,
      'pages': [1, '...', 11, 12, 13, 14, 15],
    },
    {
      'id': 3,
      'title': 'Khi nào bé mới có chồng? Sao bạn bè cưới hết rồi, còn mình bé thui. :(',
      'author': 'mai.tran',
      'time': '09:07, 25/11/14',
      'category': 'Xem Tử vi',
      'replies': 32,
      'views': 5155,
      'lastPostAuthor': 'mai.tran',
      'lastPostTime': '19:30, 27/11/14',
      'isHot': true,
      'isFavorite': false,
      'pages': [1, 2, 3, 4],
    },
    {
      'id': 4,
      'title': 'Mệnh vô chính diệu - Lận đận mãi sao ạ?',
      'author': 'pandacool261291',
      'time': '18:04, 27/10/14',
      'category': 'Xem Tử vi',
      'replies': 8,
      'views': 1171,
      'lastPostAuthor': 'Gacon1980',
      'lastPostTime': '11:43, 27/11/14',
      'isHot': false,
      'isFavorite': false,
      'pages': null,
    },
    {
      'id': 5,
      'title': 'TỬ VI NGHIỆM LÝ - DÀNH CHO NGƯỜI TRÊN 30 TUỔI.',
      'author': 'nhatminh8',
      'time': '15:52, 10/07/12',
      'category': 'Xem Tử vi',
      'replies': 46,
      'views': 7679,
      'lastPostAuthor': 'anhlinhmotminh',
      'lastPostTime': '11:01, 13/09/12',
      'isHot': true,
      'isFavorite': false,
      'pages': [1, 2, 3, 4, 5],
    },
    {
      'id': 6,
      'title': 'anh em vào giải dùm ! nhìn tử vi buồn quá !',
      'author': 'vvv',
      'time': '10:16, 07/07/12',
      'category': 'Xem Tử vi',
      'replies': 14,
      'views': 2001,
      'lastPostAuthor': 'vvv',
      'lastPostTime': '09:30, 14/08/12',
      'isHot': false,
      'isFavorite': false,
      'pages': null,
    },
    {
      'id': 7,
      'title': 'Hà xinh tươi đẹp rạng ngời :D',
      'author': '8883',
      'time': '15:58, 13/07/12',
      'category': 'Xem Tử vi',
      'replies': 35,
      'views': 4189,
      'lastPostAuthor': '8883',
      'lastPostTime': '10:59, 16/07/12',
      'isHot': true,
      'isFavorite': false,
      'pages': [1, 2, 3, 4],
    },
    {
      'id': 8,
      'title': 'Số này làm đại gia',
      'author': 'khoavpso1991',
      'time': '02:09, 13/07/12',
      'category': 'Xem Tử vi',
      'replies': 14,
      'views': 1752,
      'lastPostAuthor': 'khoavpso1991',
      'lastPostTime': '10:20, 14/07/12',
      'isHot': false,
      'isFavorite': false,
      'pages': [1, 2],
    },
    {
      'id': 9,
      'title': 'Mong các bác cao nhân xem giúp ah',
      'author': 'tranteohd',
      'time': '12:52, 06/07/12',
      'category': 'Xem Tử vi',
      'replies': 3,
      'views': 582,
      'lastPostAuthor': 'Gacon1980',
      'lastPostTime': '09:21, 14/07/12',
      'isHot': false,
      'isFavorite': false,
      'pages': null,
    },
    {
      'id': 10,
      'title': 'Xem giúp xem bao giờ em lấy chồng với! Và chồng em là người?',
      'author': 'Phuong Dung',
      'time': '21:38, 10/07/12',
      'category': 'Xem Tử vi',
      'replies': 11,
      'views': 1912,
      'lastPostAuthor': 'Gacon1980',
      'lastPostTime': '21:00, 13/07/12',
      'isHot': false,
      'isFavorite': false,
      'pages': [1, 2],
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

  // --- Layout Tổng Thể Boxed Layout 1024px ---
  Widget _buildBody(BuildContext context) {
    return Container(
      color: const Color(0xFFF0F2F5),
      width: double.infinity,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1024),
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(top: 0, bottom: 24.0),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E2640), // Nền Dark Navy đồng bộ
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
                          // 1. Tiêu đề khối
                          _buildPageHeader(),
                          const SizedBox(height: 14),

                          // 2. Thanh công cụ tìm kiếm và thông tin kết quả trên
                          _buildSearchAndPaginationBar(isTop: true),
                          const SizedBox(height: 12),

                          // 3. Bảng Danh Sách 10 Bài Viết
                          _buildPostsTable(),
                          const SizedBox(height: 12),

                          // 4. Thanh công cụ và phân trang dưới
                          _buildSearchAndPaginationBar(isTop: false),
                          const SizedBox(height: 24),

                          // 5. Khối Khám phá thêm ("Nguồn Mở", "Đặt lịch tư vấn", "Sách tử vi")
                          _buildExploreMore(),
                          const SizedBox(height: 28),

                          // 6. Footer diễn đàn
                          _buildForumFooter(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
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
          'Đã tìm thấy 10 kết quả',
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

  // --- 2 & 4. Thanh Công Cụ & Phân Trang ---
  Widget _buildSearchAndPaginationBar({required bool isTop}) {
    if (isTop) {
      return Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 12,
        runSpacing: 10,
        children: [
          // Khung tìm kiếm nội bộ nền tối
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

          // Thông tin kết quả & trang
          const Text(
            'Đã tìm thấy 10 kết quả • Trang 1 trên 1',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
    } else {
      // Thanh điều hướng phía dưới
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

              // Text phân trang
              const Text(
                'Đã tìm thấy 10 kết quả • Trang 1 trên 1',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
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

  // --- 3. Bảng Danh Sách Bài Viết ---
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
              color: Color(0xFF131A30), // Nền Dark Navy sâu cho Header
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

          // Danh sách 10 dòng
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
    final bool isHot = post['isHot'] == true;
    final bool isFavorite = post['isFavorite'] == true;
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
                // Icon chủ đề (folder / flame)
                Container(
                  margin: const EdgeInsets.only(top: 2, right: 10),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: const Color(0xFF131A30),
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFF2E3B5F)),
                        ),
                        child: Icon(
                          isHot ? Icons.local_fire_department : Icons.description_outlined,
                          size: 16,
                          color: isHot ? const Color(0xFFFF7043) : Colors.white70,
                        ),
                      ),
                      if (isFavorite)
                        const Positioned(
                          bottom: -2,
                          left: -2,
                          child: Icon(
                            Icons.star,
                            size: 12,
                            color: Colors.amberAccent,
                          ),
                        ),
                    ],
                  ),
                ),

                // Nội dung Tiêu đề & tác giả & phân trang
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      InkWell(
                        onTap: () {},
                        child: Text(
                          post['title'],
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFEF5350), // Màu link đỏ nguyên bản
                            height: 1.3,
                          ),
                        ),
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
                      // Mini phân trang bên trong bài
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
                    const Icon(Icons.arrow_forward_ios, size: 9, color: Color(0xFFEF5350)),
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

  // --- 5. Khối Khám Phá Thêm (Hình 2: Nguồn Mở, Đặt lịch tư vấn, Sách tử vi) ---
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
          _buildExploreItem('Đặt lịch tư vấn'),
          _buildExploreItem('Sách tử vi', isLast: true),
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
    return ResponsiveLayout(
      mobileBody: Scaffold(
        backgroundColor: const Color(0xFFF0F2F5),
        body: _buildBody(context),
        bottomNavigationBar: MobileBottomNavBar(
          currentIndex: _currentMobileIndex,
          onTap: _onMobileNavTapped,
        ),
      ),
      desktopBody: Scaffold(
        backgroundColor: const Color(0xFFF0F2F5),
        body: _buildBody(context),
      ),
    );
  }
}
