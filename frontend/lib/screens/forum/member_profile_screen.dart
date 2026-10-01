import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

typedef UserProfileScreen = MemberProfileScreen;

/// Màn hình Thông tin thành viên / User Profile chuẩn Boxed Layout 1024px & Theme Dark Navy
class MemberProfileScreen extends StatefulWidget {
  final String username;

  const MemberProfileScreen({
    super.key,
    this.username = 'Gacon1980',
  });

  @override
  State<MemberProfileScreen> createState() => _MemberProfileScreenState();
}

class _MemberProfileScreenState extends State<MemberProfileScreen> {
  String _selectedGroup = 'Thành viên';
  String _selectedJumpCategory = 'Chuyển đến';

  final List<String> _groupOptions = [
    'Thành viên',
    'Ban quản trị',
    'BQL Trung Châu',
    'CLB Lý số Hà Nội',
    'LSHQ: Quẻ dịch',
    'LSHQ: Tứ trụ',
    'LSHQ: Tử vi',
    'Quản trị viên',
    'Trao đổi học thuật',
    'Trung Châu Lý Số',
    'Tư vấn Phong Thủy',
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

  @override
  Widget build(BuildContext context) {
    return Material(color: Colors.transparent, child: 
      
      SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Khung hộp thông tin cá nhân
            _buildProfileHeaderCard(),
            const SizedBox(height: 16),

            // 2. Hai cột: LIÊN HỆ & THỐNG KÊ THÀNH VIÊN
            _buildDetailsCard(),
            const SizedBox(height: 16),

            // 3. Khối Chữ ký cá nhân (Hình 5)
            _buildSignatureCard(),
            const SizedBox(height: 16),

            // 4. Dropdown Chuyển đến
            _buildJumpDropdown(),
            const SizedBox(height: 28),

            // 5. Footer Diễn đàn
            _buildForumFooter(),
          ],
        ),
      ),
    );
  }

  // --- 1. Khung hộp thông tin cá nhân (Hình 5) ---
  Widget _buildProfileHeaderCard() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF161F36),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF2E3B5F)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header tiêu đề khung
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFF131A30),
              borderRadius: BorderRadius.vertical(top: Radius.circular(5)),
              border: Border(bottom: BorderSide(color: Color(0xFF2E3B5F))),
            ),
            child: Text(
              'Đang xem thông tin cá nhân về ${widget.username}',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 0.3,
              ),
            ),
          ),

          // Nội dung chi tiết thông tin
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Tên đăng nhập
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Tên đăng nhập: ',
                      style: TextStyle(fontSize: 13.5, color: Colors.grey[400]),
                    ),
                    Text(
                      widget.username,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFEF5350),
                      ),
                    ),
                    InkWell(
                      onTap: () => context.go('/forum/ucp'),
                      child: const Text(
                        ' [ Sửa hồ sơ ]',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFEF5350),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // Xếp hạng
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Xếp hạng: ',
                      style: TextStyle(fontSize: 13.5, color: Colors.grey[400]),
                    ),
                    const Text(
                      'Chính thức',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // 2 Icon sao vàng
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(
                      Icons.star,
                      size: 16,
                      color: Color(0xFFFFD700),
                    ),
                    SizedBox(width: 4),
                    Icon(
                      Icons.star,
                      size: 16,
                      color: Color(0xFFFFD700),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // Tuổi
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Tuổi: ',
                      style: TextStyle(fontSize: 13.5, color: Colors.grey[400]),
                    ),
                    const Text(
                      '45',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Nhóm [Dropdown] [Nút Chuyển]
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Nhóm: ',
                      style: TextStyle(fontSize: 13.5, color: Colors.grey[400]),
                    ),
                    Theme(
                      data: Theme.of(context).copyWith(
                        hoverColor: const Color(0xFF2A324D),
                        focusColor: const Color(0xFF2A324D),
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF131A30),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: const Color(0xFF2E3B5F)),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedGroup,
                            dropdownColor: const Color(0xFF131A30),
                            menuMaxHeight: 350,
                            isDense: true,
                            style: const TextStyle(color: Colors.white, fontSize: 13),
                            icon: const Icon(Icons.arrow_drop_down, color: Colors.white70, size: 18),
                            items: _groupOptions.map((group) {
                              return DropdownMenuItem<String>(
                                value: group,
                                child: Text(
                                  group,
                                  style: const TextStyle(color: Colors.white, fontSize: 13),
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  _selectedGroup = val;
                                });
                              }
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF131A30),
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Color(0xFF2E3B5F)),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      child: const Text(
                        'Chuyển',
                        style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Đến từ
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Đến từ: ',
                      style: TextStyle(fontSize: 13.5, color: Colors.grey[400]),
                    ),
                    const Flexible(
                      child: Text(
                        'Linh quy thiên tuế thần khí vượng.Báo ngọc vạn niên quý minh trường.',
                        style: TextStyle(
                          fontSize: 13.5,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- 2. Hai cột LIÊN HỆ và THỐNG KÊ THÀNH VIÊN (Hình 5) ---
  Widget _buildDetailsCard() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: const Color(0xFF161F36),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF2E3B5F)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 650;

          final contactCol = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'LIÊN HỆ ${widget.username.toUpperCase()}',
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFFD700),
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              const Divider(color: Color(0xFF2E3B5F), height: 1),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    'Địa chỉ email: ',
                    style: TextStyle(fontSize: 13, color: Colors.grey[400]),
                  ),
                  InkWell(
                    onTap: () {},
                    child: const Text(
                      'Gửi email cho',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFFEF5350),
                        decoration: TextDecoration.underline,
                        decorationColor: Color(0xFFEF5350),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    'Tin nhắn: ',
                    style: TextStyle(fontSize: 13, color: Colors.grey[400]),
                  ),
                  InkWell(
                    onTap: () => context.go('/forum/inbox'),
                    child: const Text(
                      'Gửi tin nhắn',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFFEF5350),
                        decoration: TextDecoration.underline,
                        decorationColor: Color(0xFFEF5350),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );

          final statsCol = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'THỐNG KÊ THÀNH VIÊN',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFFD700),
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              const Divider(color: Color(0xFF2E3B5F), height: 1),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    'Tham gia: ',
                    style: TextStyle(fontSize: 13, color: Colors.grey[400]),
                  ),
                  const Text(
                    '12:03, 04/07/12',
                    style: TextStyle(fontSize: 13, color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    'Lần hoạt động trước: ',
                    style: TextStyle(fontSize: 13, color: Colors.grey[400]),
                  ),
                  const Text(
                    '-',
                    style: TextStyle(fontSize: 13, color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    'Số bài viết: ',
                    style: TextStyle(fontSize: 13, color: Colors.grey[400]),
                  ),
                  const Text(
                    '35',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    ' | ',
                    style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                  ),
                  InkWell(
                    onTap: () {},
                    child: const Text(
                      'Tìm tất cả bài viết của thành viên này',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFFEF5350),
                        decoration: TextDecoration.underline,
                        decorationColor: Color(0xFFEF5350),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '(0.00% trong tổng số bài viết / 0.01 bài viết/ngày)',
                style: TextStyle(fontSize: 12, color: Colors.grey[400]),
              ),
              const SizedBox(height: 8),
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    'Danh sách cảm ơn: ',
                    style: TextStyle(fontSize: 13, color: Colors.grey[400]),
                  ),
                  InkWell(
                    onTap: () {},
                    child: const Text(
                      'Hiển thị danh sách với tất cả các cảm ơn',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFFEF5350),
                        decoration: TextDecoration.underline,
                        decorationColor: Color(0xFFEF5350),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );

          if (isMobile) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                contactCol,
                const SizedBox(height: 20),
                statsCol,
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: contactCol),
              const SizedBox(width: 24),
              const VerticalDivider(color: Color(0xFF2E3B5F), width: 1, thickness: 1),
              const SizedBox(width: 24),
              Expanded(child: statsCol),
            ],
          );
        },
      ),
    );
  }

  // --- 3. Dropdown Chuyển đến (Hình 1, 2, 3 -> áp dụng vào Hình 5) ---
  Widget _buildJumpDropdown() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Theme(
          data: Theme.of(context).copyWith(
            hoverColor: const Color(0xFF2A324D),
            focusColor: const Color(0xFF2A324D),
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF161F36),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: const Color(0xFF2E3B5F)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedJumpCategory,
                dropdownColor: const Color(0xFF131A30),
                menuMaxHeight: 400,
                isDense: true,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                icon: const Icon(Icons.arrow_drop_down, color: Colors.white70, size: 18),
                items: _jumpCategories.map((cat) {
                  final isChild = cat.startsWith('↳');
                  final isRoot = cat == 'Chuyển đến';
                  return DropdownMenuItem<String>(
                    value: cat,
                    child: Padding(
                      padding: EdgeInsets.only(left: isChild ? 14.0 : 0.0),
                      child: Text(
                        cat,
                        style: TextStyle(
                          color: isRoot
                              ? Colors.grey[300]
                              : (isChild ? const Color(0xFFEF5350) : Colors.white),
                          fontWeight: (isChild || isRoot) ? FontWeight.normal : FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _selectedJumpCategory = val;
                    });
                    if (val != 'Chuyển đến') {
                      context.go('/forum');
                    }
                  }
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  // --- 3. Khối Chữ ký cá nhân (Hình 5) ---
  Widget _buildSignatureCard() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF161F36),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF2E3B5F)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFF131A30),
              borderRadius: BorderRadius.vertical(top: Radius.circular(5)),
              border: Border(bottom: BorderSide(color: Color(0xFF2E3B5F))),
            ),
            child: const Text(
              'CHỮ KÝ CÁ NHÂN',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.bold,
                color: Color(0xFFFFD700),
                letterSpacing: 0.5,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Ánh Dương văn võ ngàn năm tỏa',
                  style: TextStyle(fontSize: 13.5, color: Colors.white, height: 1.5),
                ),
                Text(
                  'Phẩm giá thanh cao rạng núi sông',
                  style: TextStyle(fontSize: 13.5, color: Colors.white, height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- 5. Footer Diễn đàn ---
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
                  const Text('Thành viên', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFEF5350))),
                  const SizedBox(width: 6),
                  const Text('<', style: TextStyle(color: Colors.white38, fontSize: 12)),
                  const SizedBox(width: 6),
                  Text(
                    widget.username,
                    style: const TextStyle(color: Colors.white70),
                  ),
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
          Text(text, style: const TextStyle(fontSize: 12, color: Colors.white70)),
        ],
      ),
    );
  }
}
