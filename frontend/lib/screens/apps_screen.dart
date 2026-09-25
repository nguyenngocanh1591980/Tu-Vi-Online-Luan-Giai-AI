import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class AppsScreen extends StatefulWidget {
  const AppsScreen({super.key});

  @override
  State<AppsScreen> createState() => _AppsScreenState();
}

class _AppsScreenState extends State<AppsScreen> {
  String _username = 'Khách';
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    final username = prefs.getString('username') ?? '';
    if (mounted) {
      setState(() {
        _isLoggedIn = token != null && token.isNotEmpty;
        _username = _isLoggedIn ? username : 'Khách';
      });
    }
  }

  Future<void> _launchUrl(String url) async {
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
                color: const Color(0xFF1E2640), // Nền Tím Đen / Dark Navy
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
                      // 1. Banner Tiêu Đề
                      _buildBanner(),
                      const SizedBox(height: 16),

                      // 2. Nội dung chính: Phân bổ 3 cột (LayoutBuilder responsive)
                      _buildMainGrid(context),
                      const SizedBox(height: 24),

                      // 3. Khối Khám phá thêm
                      _buildExploreMore(),
                      const SizedBox(height: 24),

                      // 4. Footer Diễn Đàn
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

  // --- 1. Banner Tiêu Đề ---
  Widget _buildBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF131A30), // Nền Tím Đen
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF2A3450), width: 1),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: const Row(
        children: [
          Icon(Icons.apps_rounded, color: Color(0xFFFFD700), size: 22),
          SizedBox(width: 10),
          Text(
            'Ứng Dụng Tử Vi Online - AI',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFFFFD700), // Vàng Kim #FFD700
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }

  // --- 2. Bố Cục Chính (3 Cột trên Desktop, 1 Cột trên Mobile) ---
  Widget _buildMainGrid(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isDesktop = constraints.maxWidth >= 850;

        if (isDesktop) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cột Trái: Danh Mục Ứng Dụng Lý Số (190px)
              SizedBox(
                width: 190,
                child: _buildLeftCategoryColumn(),
              ),
              const SizedBox(width: 16),

              // Cột Giữa: Danh Sách Chi Tiết Các Ứng Dụng (Expanded)
              Expanded(
                child: _buildCenterAppsColumn(),
              ),
              const SizedBox(width: 16),

              // Cột Phải: Thông Tin Thành Viên & Donate (190px)
              SizedBox(
                width: 190,
                child: _buildRightWidgetColumn(),
              ),
            ],
          );
        }

        // Mobile / Tablet: Xếp chồng dọc
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildLeftCategoryColumn(),
            const SizedBox(height: 16),
            _buildCenterAppsColumn(),
            const SizedBox(height: 16),
            _buildRightWidgetColumn(),
          ],
        );
      },
    );
  }

  // --- CỘT TRÁI: Ứng dụng lý số ---
  Widget _buildLeftCategoryColumn() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF131A30), // Nền #131A30
        border: Border.all(color: const Color(0xFF2E3B5F)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xFF161F36),
              borderRadius: BorderRadius.vertical(top: Radius.circular(5)),
              border: Border(bottom: BorderSide(color: Color(0xFF2E3B5F))),
            ),
            width: double.infinity,
            child: const Text(
              'Ứng dụng lý số',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Color(0xFFFFD700),
              ),
            ),
          ),
          _buildSidebarNavItem('Lịch vạn sự', onTap: () => context.go('/almanac')),
          _buildSidebarNavItem('Lá số Tử Vi', onTap: () => context.go('/horoscope')),
          _buildSidebarNavItem('Lá số Tứ trụ'),
          _buildSidebarNavItem('Bát trạch'),
          _buildSidebarNavItem('Luận quẻ Dịch', isLast: true),
        ],
      ),
    );
  }

  Widget _buildSidebarNavItem(String title, {VoidCallback? onTap, bool isLast = false}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          border: isLast ? null : const Border(bottom: BorderSide(color: Colors.white12)),
        ),
        child: Row(
          children: [
            const Icon(Icons.circle, size: 6, color: Color(0xFFEF5350)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- CỘT GIỮA: Nội Dung Các Ứng Dụng ---
  Widget _buildCenterAppsColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Khối Chào Mừng
        _buildAppCard(
          title: 'Chào mừng bạn đến với Tử Vi Online - AI',
          content: 'Chúng tôi cung cấp các phần mềm, dịch vụ tử vi và an sao tử vi: '
              'lá số tử vi, lá số tứ trụ, lịch vạn sự, phong thủy, địa lý, bát trạch, '
              'huyền không, xem ngày, luận tuổi, xem tướng, đặt tên, xem dịch, thái ất, '
              'lục nhâm. Bạn có thể gửi lá số của bạn lên diễn đàn để trao đổi và tư vấn miễn phí.',
        ),
        const SizedBox(height: 12),

        // 2. Khối Xem Nhanh Lịch Vạn Sự
        _buildQuickAlmanacCard(),
        const SizedBox(height: 12),

        // 3. Khối Lá Số Tử Vi
        _buildServiceCard(
          title: 'LÁ SỐ TỬ VI',
          description: 'Dịch vụ lấy lá số tử vi (an sao tử vi) nhanh, đẹp, chính xác và miễn phí. '
              'Tư vấn, bình giải lá số tử vi uy tín, luận đoán theo lá số tử vi, vận hạn từng năm. '
              'Có thể quản lý danh sách lá số của mình và chia sẻ lá số thuận tiện.',
          buttonText: 'Tra Cứu Ngay',
          onTap: () => context.go('/horoscope'),
        ),
        const SizedBox(height: 12),

        // 4. Khối Phong Thủy Bát Trạch
        _buildServiceCard(
          title: 'PHONG THỦY BÁT TRẠCH',
          description: 'Bát trạch nhà theo Bát trạch, chọn hướng tốt theo phong thủy Bát trạch. '
              'Tư vấn chọn hướng nhà, chọn hướng bếp, chọn hướng giường, chọn hướng bàn làm việc hợp theo tuổi. '
              'Có thể quản lý danh sách nhà và người thân của mình và chia sẻ thuận tiện.',
          buttonText: 'Xem Bát Trạch',
        ),
        const SizedBox(height: 12),

        // 5. Khối Phong Thủy Huyền Không
        _buildServiceCard(
          title: 'PHONG THỦY HUYỀN KHÔNG',
          description: 'An tinh bàn Huyền không phi tinh miễn phí. Tư vấn chọn hướng nhà, '
              'thiết kế nhà theo Phong thủy Huyền không, tránh sát theo thời vận. '
              'Có thể quản lý danh sách nhà và người thân của mình và chia sẻ thuận tiện.',
          buttonText: 'Xem Huyền Không',
        ),
        const SizedBox(height: 12),

        // 6. Khối Quẻ Dịch
        _buildServiceCard(
          title: 'QUẺ DỊCH - LUẬN QUẺ DỊCH',
          description: 'Dịch vụ lấy quẻ Dịch, gieo quẻ Dịch, quẻ Mai Hoa, quẻ Khổng Minh. '
              'Tư vấn luận giải quẻ Dịch theo sự kiện, theo vụ việc: Thời vận, công danh, '
              'nghề nghiệp, tình yêu, hôn nhân, xuất hành, sức khỏe, kiện tụng...',
          buttonText: 'Gieo Quẻ Dịch',
        ),
        const SizedBox(height: 12),

        // 7. Khối Lập Lá Số Tứ Trụ
        _buildServiceCard(
          title: 'LẬP LÁ SỐ TỨ TRỤ (BÁT TỰ)',
          description: 'Dịch vụ lập lá số Tứ trụ (Bát tự) chuẩn xác. Thần sát, dụng thần, '
              'vận hạn chi tiết theo năm tháng ngày giờ sinh khoa học.',
          buttonText: 'Lập Lá Số Tứ Trụ',
        ),
        const SizedBox(height: 12),

        // 8. Khối Thông Tin Liên Hệ Trụ Sở
        _buildContactSummaryCard(),
      ],
    );
  }

  Widget _buildAppCard({required String title, required String content}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF161F36), // Nền Card con tối hơn
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF2E3B5F)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFFFFD700),
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(
              color: Colors.grey[300],
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAlmanacCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF161F36),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF2E3B5F)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Xem nhanh - Lịch vạn sự hôm nay',
                style: TextStyle(
                  color: Color(0xFF64B5F6), // Xanh dương sáng
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              InkWell(
                onTap: () => context.go('/almanac'),
                child: const Text(
                  'Xem chi tiết >',
                  style: TextStyle(
                    color: Color(0xFFEF5350),
                    fontWeight: FontWeight.bold,
                    fontSize: 12.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(color: Colors.white24, height: 1, thickness: 1),
          const SizedBox(height: 10),
          Text(
            'Hôm nay: Ngày Hoàng Đạo - Giờ đẹp cho khai trương, ký kết, xuất hành',
            style: TextStyle(color: Colors.grey[300], fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 12,
            runSpacing: 6,
            children: const [
              Text('Giờ Hoàng đạo: Tý, Sửu, Mão, Ngọ, Thân, Dậu', style: TextStyle(color: Color(0xFF81C784), fontSize: 12.5)),
              Text('Tiết khí: Đang trong tiết Thu phân', style: TextStyle(color: Colors.white70, fontSize: 12.5)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildServiceCard({
    required String title,
    required String description,
    required String buttonText,
    VoidCallback? onTap,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF161F36),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF2E3B5F)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFFFFD700), // Vàng Kim
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: TextStyle(
              color: Colors.grey[300],
              fontSize: 13,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: ElevatedButton(
              onPressed: onTap ?? () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF263252),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                  side: const BorderSide(color: Color(0xFF3E4E77)),
                ),
              ),
              child: Text(
                buttonText,
                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF161F36),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF2E3B5F)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'THÔNG TIN LIÊN HỆ - TỬ VI ONLINE - AI',
            style: TextStyle(
              color: Color(0xFFFFD700),
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 10),
          _buildMiniContactRow(Icons.language, 'Trụ sở: Tử vi Online - AI', const Color(0xFF64B5F6)),
          const SizedBox(height: 6),
          _buildMiniContactRow(Icons.location_on, '2417 Hemisco - Hà Đông - Hà Nội', const Color(0xFFEF5350)),
          const SizedBox(height: 6),
          _buildMiniContactRow(Icons.smartphone, 'Hotline: 0867.186.288 hoặc 0988.927.838', const Color(0xFFFFB300), onTap: () => _launchUrl('tel:0867186288')),
          const SizedBox(height: 6),
          _buildMiniContactRow(Icons.email_outlined, 'Email: bantuvan.tuvionlineai@gmail.com', const Color(0xFF80D8FF), onTap: () => _launchUrl('mailto:bantuvan.tuvionlineai@gmail.com')),
          const SizedBox(height: 6),
          _buildMiniContactRow(Icons.chat_bubble_outline, 'Zalo: zalo.me/tuvionlineai', const Color(0xFF29B6F6), onTap: () => _launchUrl('https://zalo.me/tuvionlineai')),
        ],
      ),
    );
  }

  Widget _buildMiniContactRow(IconData icon, String text, Color color, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.grey[300],
                fontSize: 12.5,
                decoration: onTap != null ? TextDecoration.underline : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- CỘT PHẢI: Thành Viên & Donate ---
  Widget _buildRightWidgetColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Box Thành Viên
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF131A30),
            border: Border.all(color: const Color(0xFF2E3B5F)),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const CircleAvatar(
                radius: 28,
                backgroundColor: Color(0xFF263252),
                child: Icon(Icons.person, size: 36, color: Colors.white70),
              ),
              const SizedBox(height: 10),
              Text(
                _username,
                style: const TextStyle(
                  color: Color(0xFFFFD700),
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _isLoggedIn ? 'Thành viên diễn đàn' : 'Khách vãng lai',
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 2. Box Ủng Hộ Chúng Tôi (Donate)
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF131A30),
            border: Border.all(color: const Color(0xFF2E3B5F)),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Ủng hộ chúng tôi',
                style: TextStyle(
                  color: Color(0xFFFFD700),
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Nếu bạn thấy dịch vụ của chúng tôi có hữu ích, xin vui lòng ủng hộ để chúng tôi hoàn thiện dịch vụ hơn.',
                style: TextStyle(color: Colors.grey[300], fontSize: 12, height: 1.4),
              ),
              const SizedBox(height: 12),
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD4AF37),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.volunteer_activism, size: 16, color: Colors.black),
                      SizedBox(width: 6),
                      Text(
                        'Donate',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- 3. Khối Khám Phá Thêm ---
  Widget _buildExploreMore() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF131A30),
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
          _buildExploreItem('Văn Thơ Hay'),
          _buildExploreItem('Xem Tử Vi', onTap: () => context.go('/horoscope')),
          _buildExploreItem('Dịch Học', isLast: true),
        ],
      ),
    );
  }

  Widget _buildExploreItem(String title, {VoidCallback? onTap, bool isLast = false}) {
    return InkWell(
      onTap: onTap,
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

  // --- 4. Footer Diễn Đàn ---
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
                    child: const Text(
                      'Trang chủ',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFEF5350)),
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text('<', style: TextStyle(color: Colors.white38, fontSize: 12)),
                  const SizedBox(width: 6),
                  const Text('Ứng dụng', style: TextStyle(color: Colors.white70)),
                ],
              ),
              // Phải: Các liên kết chức năng
              Wrap(
                spacing: 12,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _buildFooterLink(Icons.email, 'Liên hệ', onTap: () => context.go('/contact')),
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

  Widget _buildFooterLink(IconData icon, String text, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap ?? () {},
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
