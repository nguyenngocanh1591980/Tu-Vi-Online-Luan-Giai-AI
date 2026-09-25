import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

typedef TeamScreen = AboutUsScreen;

class AboutUsScreen extends StatefulWidget {
  const AboutUsScreen({super.key});

  @override
  State<AboutUsScreen> createState() => _AboutUsScreenState();
}

class _AboutUsScreenState extends State<AboutUsScreen> {
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

  // 5 nhóm phân cấp quản trị chuẩn xác từ Hình 3
  final List<Map<String, dynamic>> _groups = [
    {
      'groupTitle': 'Quản trị viên',
      'members': [
        {
          'name': 'Admin',
          'nameColor': const Color(0xFFEF5350),
          'badgeText': 'QUẢN LÝ',
          'badgeType': 'badge_blue',
          'primaryGroup': 'Quản trị viên',
          'primaryGroupColor': const Color(0xFFEF5350),
          'managedForums': 'Tất cả chuyên mục',
        },
        {
          'name': 'nncuong',
          'nameColor': const Color(0xFFEF5350),
          'badgeText': 'SÁNG LẬP',
          'badgeType': 'badge_red',
          'primaryGroup': 'Quản trị viên',
          'primaryGroupColor': const Color(0xFFEF5350),
          'managedForums': 'Tất cả chuyên mục',
        },
      ],
      'emptyMessage': null,
    },
    {
      'groupTitle': 'Siêu quản lý',
      'members': <Map<String, dynamic>>[],
      'emptyMessage': 'Không tìm thấy thành viên nào thoả điều kiện tìm kiếm này.',
    },
    {
      'groupTitle': 'Quản lý',
      'members': [
        {
          'name': 'lysoVN',
          'nameColor': const Color(0xFF42A5F5),
          'badgeText': 'QUẢN LÝ',
          'badgeType': 'badge_blue',
          'primaryGroup': 'Quản lý',
          'primaryGroupColor': const Color(0xFF42A5F5),
          'managedForums': 'Tất cả chuyên mục',
        },
        {
          'name': 'phudongsoft',
          'nameColor': const Color(0xFF42A5F5),
          'badgeText': 'QUẢN LÝ',
          'badgeType': 'badge_blue',
          'primaryGroup': 'Quản lý',
          'primaryGroupColor': const Color(0xFF42A5F5),
          'managedForums': 'Tất cả chuyên mục',
        },
        {
          'name': 'Quản lý',
          'nameColor': const Color(0xFF42A5F5),
          'badgeText': 'QUẢN LÝ',
          'badgeType': 'badge_blue',
          'primaryGroup': 'Quản lý',
          'primaryGroupColor': const Color(0xFF42A5F5),
          'managedForums': 'Tất cả chuyên mục',
        },
      ],
      'emptyMessage': null,
    },
    {
      'groupTitle': 'Điều hành',
      'members': [
        {
          'name': 'Điều hành 2',
          'nameColor': const Color(0xFF42A5F5),
          'badgeText': 'ĐIỀU HÀNH',
          'badgeType': 'badge_blue',
          'primaryGroup': 'Điều hành',
          'primaryGroupColor': const Color(0xFF42A5F5),
          'managedForums': 'Tất cả chuyên mục',
        },
        {
          'name': 'Điều hành 4',
          'nameColor': const Color(0xFF42A5F5),
          'badgeText': 'ĐIỀU HÀNH',
          'badgeType': 'badge_blue',
          'primaryGroup': 'Điều hành',
          'primaryGroupColor': const Color(0xFF42A5F5),
          'managedForums': 'Tất cả chuyên mục',
        },
        {
          'name': 'Điều hành 5',
          'nameColor': const Color(0xFF42A5F5),
          'badgeText': 'ĐIỀU HÀNH',
          'badgeType': 'badge_blue',
          'primaryGroup': 'Điều hành',
          'primaryGroupColor': const Color(0xFF42A5F5),
          'managedForums': 'Tất cả chuyên mục',
        },
        {
          'name': 'Điều hành 6',
          'nameColor': const Color(0xFF42A5F5),
          'badgeText': 'ĐIỀU HÀNH',
          'badgeType': 'badge_blue',
          'primaryGroup': 'Điều hành',
          'primaryGroupColor': const Color(0xFF42A5F5),
          'managedForums': 'Tất cả chuyên mục',
        },
        {
          'name': 'Điều hành 7',
          'nameColor': const Color(0xFF42A5F5),
          'badgeText': 'ĐIỀU HÀNH',
          'badgeType': 'badge_blue',
          'primaryGroup': 'Điều hành',
          'primaryGroupColor': const Color(0xFF42A5F5),
          'managedForums': 'Tất cả chuyên mục',
        },
        {
          'name': 'Điều hành 8',
          'nameColor': const Color(0xFF42A5F5),
          'badgeText': 'ĐIỀU HÀNH',
          'badgeType': 'badge_blue',
          'primaryGroup': 'Điều hành',
          'primaryGroupColor': const Color(0xFF42A5F5),
          'managedForums': 'Tất cả chuyên mục',
        },
        {
          'name': 'Điều hành 9',
          'nameColor': const Color(0xFF42A5F5),
          'badgeText': 'ĐIỀU HÀNH',
          'badgeType': 'badge_blue',
          'primaryGroup': 'Điều hành',
          'primaryGroupColor': const Color(0xFF42A5F5),
          'managedForums': 'Tất cả chuyên mục',
        },
      ],
      'emptyMessage': null,
    },
    {
      'groupTitle': 'Ban tư vấn',
      'members': [
        {
          'name': 'Ban tư vấn',
          'nameColor': const Color(0xFFFFA726),
          'badgeText': 'TƯ VẤN',
          'badgeType': 'badge_green',
          'primaryGroup': 'Ban tư vấn',
          'primaryGroupColor': const Color(0xFFFFA726),
          'managedForums': 'Tất cả chuyên mục',
        },
        {
          'name': 'dungtamchin',
          'nameColor': const Color(0xFFFFA726),
          'badgeText': 'TƯ VẤN',
          'badgeType': 'badge_green',
          'primaryGroup': 'Ban tư vấn',
          'primaryGroupColor': const Color(0xFFFFA726),
          'managedForums': '-',
        },
        {
          'name': 'Kim Hải Đông',
          'nameColor': const Color(0xFF66BB6A),
          'badgeText': '☆☆☆☆☆',
          'badgeType': 'stars_5',
          'primaryGroup': 'Trao đổi học thuật',
          'primaryGroupColor': const Color(0xFF66BB6A),
          'managedForums': '-',
        },
        {
          'name': 'Lão Nông',
          'nameColor': const Color(0xFFFFA726),
          'badgeText': 'TƯ VẤN',
          'badgeType': 'badge_green',
          'primaryGroup': 'Ban tư vấn',
          'primaryGroupColor': const Color(0xFFFFA726),
          'managedForums': '-',
        },
        {
          'name': 'phonglan',
          'nameColor': const Color(0xFFFFA726),
          'badgeText': 'TƯ VẤN',
          'badgeType': 'badge_green',
          'primaryGroup': 'Ban tư vấn',
          'primaryGroupColor': const Color(0xFFFFA726),
          'managedForums': '-',
        },
        {
          'name': 'Quang lan',
          'nameColor': const Color(0xFFFFA726),
          'badgeText': 'TƯ VẤN',
          'badgeType': 'badge_green',
          'primaryGroup': 'Ban tư vấn',
          'primaryGroupColor': const Color(0xFFFFA726),
          'managedForums': '-',
        },
        {
          'name': 'QuangMuongThuy',
          'nameColor': const Color(0xFFFFA726),
          'badgeText': 'TƯ VẤN',
          'badgeType': 'badge_green',
          'primaryGroup': 'Ban tư vấn',
          'primaryGroupColor': const Color(0xFFFFA726),
          'managedForums': '-',
        },
        {
          'name': 'TRƯỜNG GIANG',
          'nameColor': const Color(0xFFFFA726),
          'badgeText': 'TƯ VẤN',
          'badgeType': 'badge_green',
          'primaryGroup': 'Ban tư vấn',
          'primaryGroupColor': const Color(0xFFFFA726),
          'managedForums': '-',
        },
      ],
      'emptyMessage': null,
    },
  ];

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
                      // 1. Tiêu đề khối Chúng tôi
                      _buildHeaderTitle(),
                      const SizedBox(height: 14),

                      // 2. Danh sách 5 Bảng Cấu Trúc Nhóm
                      for (int i = 0; i < _groups.length; i++) ...[
                        _buildGroupTable(_groups[i]),
                        const SizedBox(height: 14),
                      ],

                      // 3. Jump Dropdown "Chuyển đến"
                      Align(
                        alignment: Alignment.centerRight,
                        child: _buildJumpDropdown(),
                      ),
                      const SizedBox(height: 24),

                      // 4. Footer diễn đàn
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
          Icon(Icons.security, color: Color(0xFFFFD700), size: 20),
          SizedBox(width: 8),
          Text(
            'Chúng tôi',
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

  // --- 2. Bảng Cấu Trúc Nhóm ---
  Widget _buildGroupTable(Map<String, dynamic> group) {
    final groupTitle = group['groupTitle'] as String;
    final members = group['members'] as List<Map<String, dynamic>>;
    final emptyMessage = group['emptyMessage'] as String?;

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
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Thanh Tiêu Đề Nhóm (Nhóm Quản trị viên, Siêu quản lý...)
                  Container(
                    decoration: const BoxDecoration(
                      color: Color(0xFF131A30),
                      borderRadius: BorderRadius.vertical(top: Radius.circular(5)),
                      border: Border(bottom: BorderSide(color: Color(0xFF2E3B5F), width: 1.2)),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    child: Row(
                      children: [
                        const Icon(Icons.folder_shared_outlined, color: Color(0xFFFFD700), size: 16),
                        const SizedBox(width: 8),
                        Text(
                          groupTitle,
                          style: const TextStyle(
                            color: Color(0xFFFFD700),
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Hàng Tiêu Đề 4 Cột: Tên thành viên | Xếp hạng | Nhóm chính | Diễn đàn quản lý
                  Container(
                    decoration: const BoxDecoration(
                      color: Color(0xFF101628),
                      border: Border(bottom: BorderSide(color: Color(0xFF2E3B5F), width: 1)),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    child: const Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Text(
                            'Tên thành viên',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            'Xếp hạng',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text(
                            'Nhóm chính',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text(
                            'Diễn đàn quản lý',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Dữ liệu hoặc thông báo trống
                  if (emptyMessage != null)
                    Container(
                      color: const Color(0xFF1A233E),
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                      child: Text(
                        emptyMessage,
                        style: TextStyle(color: Colors.grey[300], fontSize: 12.5, fontStyle: FontStyle.italic),
                      ),
                    )
                  else
                    for (int i = 0; i < members.length; i++)
                      _buildMemberRow(members[i], i),
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
      padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 1. Tên thành viên
          Expanded(
            flex: 3,
            child: InkWell(
              onTap: () => context.go('/forum/member/${item['name']}'),
              child: Text(
                item['name'] as String,
                style: TextStyle(
                  color: item['nameColor'] as Color,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ),

          // 2. Xếp hạng (Badge hoặc Sao)
          Expanded(
            flex: 2,
            child: Center(
              child: _buildRankBadge(item['badgeText'] as String, item['badgeType'] as String),
            ),
          ),

          // 3. Nhóm chính
          Expanded(
            flex: 3,
            child: InkWell(
              onTap: () => context.go('/forum/ucp/groups'),
              child: Text(
                item['primaryGroup'] as String,
                style: TextStyle(
                  color: item['primaryGroupColor'] as Color,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  decoration: TextDecoration.underline,
                  decorationColor: item['primaryGroupColor'] as Color,
                ),
              ),
            ),
          ),

          // 4. Diễn đàn quản lý
          Expanded(
            flex: 3,
            child: Text(
              item['managedForums'] as String,
              style: TextStyle(
                color: (item['managedForums'] as String) == '-' ? Colors.white38 : Colors.grey[300],
                fontSize: 12.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRankBadge(String text, String type) {
    if (type.startsWith('badge_')) {
      Color bg1 = const Color(0xFF1565C0);
      Color bg2 = const Color(0xFF0D47A1);

      if (type == 'badge_red') {
        bg1 = const Color(0xFFD32F2F);
        bg2 = const Color(0xFFB71C1C);
      } else if (type == 'badge_green') {
        bg1 = const Color(0xFF689F38);
        bg2 = const Color(0xFF33691E);
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
          color: Color(0xFFFFD700),
          fontSize: 14,
          letterSpacing: 1.5,
        ),
      );
    }
  }

  // --- 3. Jump Dropdown ---
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

  // --- 4. Footer Diễn Đàn ---
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
                  const Text('Chúng tôi', style: TextStyle(color: Colors.white70)),
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
