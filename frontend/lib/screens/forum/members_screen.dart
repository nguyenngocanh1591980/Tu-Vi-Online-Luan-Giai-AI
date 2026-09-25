import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'member_search_dialog.dart';

class MembersScreen extends StatefulWidget {
  const MembersScreen({super.key});

  @override
  State<MembersScreen> createState() => _MembersScreenState();
}

class _MembersScreenState extends State<MembersScreen> {
  int _currentPage = 1;
  final int _totalPages = 8241;
  String _selectedLetter = 'Tất cả';
  String _selectedJumpCategory = 'Chuyển đến';

  final List<String> _alphabet = [
    'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M',
    'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z'
  ];

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

  // Danh sách 25 thành viên bảo toàn 100% nguyên gốc từ Hình 2
  final List<Map<String, dynamic>> _members = [
    {
      'username': 'Admin',
      'nameColor': const Color(0xFFEF5350),
      'isBold': true,
      'badgeText': 'QUẢN LÝ',
      'badgeType': 'badge_blue',
      'posts': 83,
      'website': '',
      'joinDate': '11:22, 03/09/08',
    },
    {
      'username': 'nncuong',
      'nameColor': const Color(0xFFEF5350),
      'isBold': true,
      'badgeText': 'SÁNG LẬP',
      'badgeType': 'badge_red',
      'posts': 2713,
      'website': '',
      'joinDate': '12:44, 03/09/08',
    },
    {
      'username': 'phudongsoft',
      'nameColor': const Color(0xFF42A5F5),
      'isBold': true,
      'badgeText': 'QUẢN LÝ',
      'badgeType': 'badge_blue',
      'posts': 185,
      'website': '',
      'joinDate': '12:45, 03/09/08',
    },
    {
      'username': 'phamthaihoa',
      'nameColor': const Color(0xFFBA68C8),
      'isBold': true,
      'badgeText': 'HỘI VIÊN',
      'badgeType': 'badge_purple',
      'posts': 243,
      'website': '',
      'joinDate': '13:42, 03/09/08',
    },
    {
      'username': 'AnhTu',
      'nameColor': Colors.white,
      'isBold': false,
      'badgeText': '☆',
      'badgeType': 'star_1',
      'posts': 14,
      'website': '',
      'joinDate': '13:42, 03/09/08',
    },
    {
      'username': 'madhia1',
      'nameColor': Colors.white,
      'isBold': false,
      'badgeText': '☆',
      'badgeType': 'star_1',
      'posts': 21,
      'website': '',
      'joinDate': '15:06, 03/09/08',
    },
    {
      'username': 'nailaduong',
      'nameColor': Colors.white,
      'isBold': false,
      'badgeText': '☆',
      'badgeType': 'star_1',
      'posts': 0,
      'website': '',
      'joinDate': '15:13, 03/09/08',
    },
    {
      'username': 'dp14ic',
      'nameColor': Colors.white,
      'isBold': false,
      'badgeText': '☆',
      'badgeType': 'star_1',
      'posts': 0,
      'website': '',
      'joinDate': '15:34, 03/09/08',
    },
    {
      'username': 'hanhfpm',
      'nameColor': Colors.white,
      'isBold': false,
      'badgeText': '☆',
      'badgeType': 'star_1',
      'posts': 9,
      'website': '',
      'joinDate': '15:43, 03/09/08',
    },
    {
      'username': 'locvtn',
      'nameColor': Colors.white,
      'isBold': false,
      'badgeText': '☆',
      'badgeType': 'star_1',
      'posts': 0,
      'website': 'http://www.hungloc.net',
      'joinDate': '16:30, 03/09/08',
    },
    {
      'username': 'ngoiluuqu',
      'nameColor': Colors.white,
      'isBold': false,
      'badgeText': '☆',
      'badgeType': 'star_1',
      'posts': 0,
      'website': '',
      'joinDate': '10:07, 04/09/08',
    },
    {
      'username': 'w_clock',
      'nameColor': Colors.white,
      'isBold': false,
      'badgeText': '☆',
      'badgeType': 'star_1',
      'posts': 1,
      'website': '',
      'joinDate': '10:38, 04/09/08',
    },
    {
      'username': 'tranminh1111',
      'nameColor': Colors.white,
      'isBold': true,
      'badgeText': '☆',
      'badgeType': 'star_1',
      'posts': 0,
      'website': '',
      'joinDate': '13:42, 04/09/08',
    },
    {
      'username': 'minhtu',
      'nameColor': Colors.white,
      'isBold': false,
      'badgeText': '☆',
      'badgeType': 'star_1',
      'posts': 0,
      'website': '',
      'joinDate': '20:34, 04/09/08',
    },
    {
      'username': 'Tubby',
      'nameColor': Colors.white,
      'isBold': false,
      'badgeText': '☆',
      'badgeType': 'star_1',
      'posts': 6,
      'website': '',
      'joinDate': '10:24, 05/09/08',
    },
    {
      'username': 'kimcuong',
      'nameColor': Colors.white,
      'isBold': false,
      'badgeText': '☆☆',
      'badgeType': 'star_2',
      'posts': 25,
      'website': '',
      'joinDate': '18:50, 05/09/08',
    },
    {
      'username': 'thanhhoa',
      'nameColor': Colors.white,
      'isBold': false,
      'badgeText': '☆',
      'badgeType': 'star_1',
      'posts': 0,
      'website': '',
      'joinDate': '22:43, 05/09/08',
    },
    {
      'username': 'thinhhu',
      'nameColor': Colors.white,
      'isBold': false,
      'badgeText': '☆',
      'badgeType': 'star_1',
      'posts': 0,
      'website': '',
      'joinDate': '09:29, 06/09/08',
    },
    {
      'username': 'iockkkk',
      'nameColor': Colors.white,
      'isBold': false,
      'badgeText': '☆',
      'badgeType': 'star_1',
      'posts': 0,
      'website': '',
      'joinDate': '13:04, 06/09/08',
    },
    {
      'username': 'bada',
      'nameColor': Colors.white,
      'isBold': false,
      'badgeText': '☆',
      'badgeType': 'star_1',
      'posts': 0,
      'website': '',
      'joinDate': '10:54, 09/09/08',
    },
    {
      'username': 'support',
      'nameColor': Colors.white,
      'isBold': false,
      'badgeText': '☆',
      'badgeType': 'star_1',
      'posts': 0,
      'website': '',
      'joinDate': '23:20, 10/09/08',
    },
    {
      'username': 'jonapih',
      'nameColor': Colors.white,
      'isBold': false,
      'badgeText': '☆',
      'badgeType': 'star_1',
      'posts': 0,
      'website': '',
      'joinDate': '00:31, 13/09/08',
    },
    {
      'username': 'jonapih01',
      'nameColor': Colors.white,
      'isBold': false,
      'badgeText': '☆',
      'badgeType': 'star_1',
      'posts': 0,
      'website': '',
      'joinDate': '09:33, 13/09/08',
    },
    {
      'username': 'am_duongH',
      'nameColor': const Color(0xFF66BB6A),
      'isBold': true,
      'badgeText': '☆☆',
      'badgeType': 'star_2',
      'posts': 416,
      'website': '',
      'joinDate': '10:17, 15/09/08',
    },
    {
      'username': 'ngocphuong',
      'nameColor': Colors.white,
      'isBold': false,
      'badgeText': '☆',
      'badgeType': 'star_1',
      'posts': 0,
      'website': '',
      'joinDate': '19:09, 17/09/08',
    },
  ];

  Future<void> _launchWebsite(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
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
                      // 1. Tiêu đề khối Thành viên
                      _buildHeaderTitle(),
                      const SizedBox(height: 12),

                      // 2. Thanh Tìm kiếm & Lọc chữ cái (Khóa chặt Hình 2)
                      _buildFilterAndAlphabetBar(),
                      const SizedBox(height: 12),

                      // 3. Thanh thông tin kết quả & Phân trang trên
                      _buildPaginationRow(),
                      const SizedBox(height: 8),

                      // 4. Bảng Dữ Liệu Thành Viên 5 cột (Khóa chặt Hình 2)
                      _buildMembersTable(),
                      const SizedBox(height: 12),

                      // 5. Thanh thông tin kết quả & Phân trang dưới
                      _buildPaginationRow(),
                      const SizedBox(height: 16),

                      // 6. Jump Dropdown "Chuyển đến"
                      Align(
                        alignment: Alignment.centerRight,
                        child: _buildJumpDropdown(),
                      ),
                      const SizedBox(height: 24),

                      // 7. Footer diễn đàn
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
          Icon(Icons.people_alt_outlined, color: Color(0xFFFFD700), size: 20),
          SizedBox(width: 8),
          Text(
            'Thành viên',
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

  // --- 2. Thanh lọc và dải ký tự A - Z ---
  Widget _buildFilterAndAlphabetBar() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF131A30),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFF2E3B5F)),
      ),
      child: Wrap(
        alignment: WrapAlignment.start,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 6,
        runSpacing: 6,
        children: [
          InkWell(
            onTap: () => showMemberSearchDialog(context),
            child: const Text(
              'Tìm một thành viên',
              style: TextStyle(
                color: Color(0xFFEF5350),
                fontSize: 13,
                fontWeight: FontWeight.bold,
                decoration: TextDecoration.underline,
                decorationColor: Color(0xFFEF5350),
              ),
            ),
          ),
          const Text('•', style: TextStyle(color: Colors.white54, fontSize: 13)),
          InkWell(
            onTap: () => setState(() => _selectedLetter = 'Tất cả'),
            child: Text(
              'Tất cả',
              style: TextStyle(
                color: _selectedLetter == 'Tất cả' ? const Color(0xFFFFD700) : Colors.white70,
                fontSize: 13,
                fontWeight: _selectedLetter == 'Tất cả' ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          for (final letter in _alphabet) ...[
            InkWell(
              onTap: () => setState(() => _selectedLetter = letter),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Text(
                  letter,
                  style: TextStyle(
                    color: _selectedLetter == letter ? const Color(0xFFFFD700) : Colors.white70,
                    fontSize: 12.5,
                    fontWeight: _selectedLetter == letter ? FontWeight.bold : FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
          const Text('•', style: TextStyle(color: Colors.white54, fontSize: 13)),
          InkWell(
            onTap: () => showMemberSearchDialog(context),
            child: const Text(
              'Thông tin khác',
              style: TextStyle(
                color: Color(0xFF90CAF9),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- 3 & 5. Thanh phân trang ---
  Widget _buildPaginationRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          '206024 thành viên',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            InkWell(
              onTap: () {},
              child: Container(
                padding: const EdgeInsets.all(4),
                margin: const EdgeInsets.only(right: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF131A30),
                  borderRadius: BorderRadius.circular(3),
                  border: Border.all(color: const Color(0xFF2E3B5F)),
                ),
                child: const Icon(Icons.subdirectory_arrow_right, size: 14, color: Colors.white70),
              ),
            ),
            _buildPageBtn(1, isActive: _currentPage == 1),
            _buildPageBtn(2, isActive: _currentPage == 2),
            _buildPageBtn(3, isActive: _currentPage == 3),
            _buildPageBtn(4, isActive: _currentPage == 4),
            _buildPageBtn(5, isActive: _currentPage == 5),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 2),
              child: Text('...', style: TextStyle(color: Colors.white54, fontSize: 11)),
            ),
            _buildPageBtn(8241, isActive: _currentPage == 8241),
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
        ),
      ],
    );
  }

  Widget _buildPageBtn(int page, {bool isActive = false}) {
    return InkWell(
      onTap: () => setState(() => _currentPage = page),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 1.5),
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
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
            fontSize: 12,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  // --- 4. Bảng Danh Sách Thành Viên ---
  Widget _buildMembersTable() {
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
                          flex: 3,
                          child: Text(
                            'TÊN ĐĂNG NHẬP',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            'XẾP HẠNG',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Text(
                            'BÀI VIẾT',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            'WEBSITE',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            'THAM GIA',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Các hàng thành viên
                  for (int i = 0; i < _members.length; i++) _buildMemberRow(_members[i], i),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMemberRow(Map<String, dynamic> item, int index) {
    final isEven = index % 2 == 0;
    final rowBg = isEven ? const Color(0xFF1A233E) : const Color(0xFF151C33);

    return Container(
      decoration: BoxDecoration(
        color: rowBg,
        border: const Border(
          bottom: BorderSide(color: Color(0xFF242F50), width: 0.8),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 1. Tên đăng nhập
          Expanded(
            flex: 3,
            child: InkWell(
              onTap: () => context.go('/forum/member/${item['username']}'),
              child: Text(
                item['username'] as String,
                style: TextStyle(
                  color: item['nameColor'] as Color,
                  fontWeight: (item['isBold'] as bool) ? FontWeight.bold : FontWeight.normal,
                  fontSize: 13,
                ),
              ),
            ),
          ),

          // 2. Xếp hạng
          Expanded(
            flex: 2,
            child: Center(
              child: _buildRankWidget(item['badgeText'] as String, item['badgeType'] as String),
            ),
          ),

          // 3. Bài viết
          Expanded(
            flex: 1,
            child: Text(
              '${item['posts']}',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[300],
                fontSize: 12.5,
              ),
            ),
          ),

          // 4. Website
          Expanded(
            flex: 2,
            child: (item['website'] as String).isNotEmpty
                ? InkWell(
                    onTap: () => _launchWebsite(item['website'] as String),
                    child: Text(
                      item['website'] as String,
                      style: const TextStyle(
                        color: Color(0xFFEF5350),
                        fontSize: 11.5,
                        decoration: TextDecoration.underline,
                        decorationColor: Color(0xFFEF5350),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  )
                : const SizedBox.shrink(),
          ),

          // 5. Tham gia
          Expanded(
            flex: 2,
            child: Text(
              item['joinDate'] as String,
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRankWidget(String text, String type) {
    if (type.startsWith('badge_')) {
      Color bg1 = const Color(0xFF1565C0);
      Color bg2 = const Color(0xFF0D47A1);

      if (type == 'badge_red') {
        bg1 = const Color(0xFFD32F2F);
        bg2 = const Color(0xFFB71C1C);
      } else if (type == 'badge_purple') {
        bg1 = const Color(0xFF8E24AA);
        bg2 = const Color(0xFF6A1B9A);
      }

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [bg1, bg2]),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.white30, width: 0.8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.star, color: Color(0xFFFFD700), size: 10),
            const SizedBox(width: 4),
            Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 10.5,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.star, color: Color(0xFFFFD700), size: 10),
          ],
        ),
      );
    } else {
      return Text(
        text,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 13,
          letterSpacing: 2,
        ),
      );
    }
  }

  // --- 6. Jump Dropdown ---
  Widget _buildJumpDropdown() {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 10),
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

  // --- 7. Footer Diễn Đàn ---
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
                  const Text('Thành viên', style: TextStyle(color: Colors.white70)),
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
