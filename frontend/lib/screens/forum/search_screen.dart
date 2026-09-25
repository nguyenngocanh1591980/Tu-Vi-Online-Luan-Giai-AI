import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/responsive_layout.dart';
import '../../widgets/mobile_bottom_nav.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  int _currentMobileIndex = 2; // Tab Diễn đàn
  int _selectedTabIndex = 0; // 0: Tìm kiếm, 1: Tìm kiếm nâng cao
  final TextEditingController _searchController = TextEditingController();

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
                          // 1. Tiêu đề khối & 2 Tab nội bộ (Hình 4)
                          _buildSearchHeaderAndTabs(),
                          const SizedBox(height: 16),

                          // 2. Khung Tìm Kiếm Google Cải Tiến
                          _buildGoogleSearchSection(),
                          const SizedBox(height: 28),

                          // 3. Khối Khám phá thêm (Hình 4: "Tạo Thiết Kế", "Phối Màu Nhuộm", "Nâng Cấp OS")
                          _buildExploreMore(),
                          const SizedBox(height: 28),

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
        ],
      ),
    );
  }

  // --- 1. Tiêu Đề & 2 Tabs Nội Bộ (Hình 4) ---
  Widget _buildSearchHeaderAndTabs() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tìm kiếm',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            // Tab 1: "Tìm kiếm" (đang active)
            InkWell(
              onTap: () => setState(() => _selectedTabIndex = 0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: _selectedTabIndex == 0 ? const Color(0xFF131A30) : const Color(0xFF1E2640),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                  border: Border.all(
                    color: _selectedTabIndex == 0 ? const Color(0xFF2E3B5F) : Colors.transparent,
                  ),
                ),
                child: Text(
                  'Tìm kiếm',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: _selectedTabIndex == 0 ? FontWeight.bold : FontWeight.normal,
                    color: _selectedTabIndex == 0 ? Colors.white : Colors.white60,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 4),
            // Tab 2: "Tìm kiếm nâng cao" (inactive)
            InkWell(
              onTap: () => setState(() => _selectedTabIndex = 1),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: _selectedTabIndex == 1 ? const Color(0xFF131A30) : const Color(0xFF1E2640),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                  border: Border.all(
                    color: _selectedTabIndex == 1 ? const Color(0xFF2E3B5F) : Colors.transparent,
                  ),
                ),
                child: Text(
                  'Tìm kiếm nâng cao',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: _selectedTabIndex == 1 ? FontWeight.bold : FontWeight.normal,
                    color: _selectedTabIndex == 1 ? Colors.white : Colors.white60,
                  ),
                ),
              ),
            ),
          ],
        ),
        const Divider(height: 1, thickness: 1.5, color: Color(0xFF2E3B5F)),
      ],
    );
  }

  // --- 2. Khung Tìm Kiếm Google Cải Tiến (Hình 4) ---
  Widget _buildGoogleSearchSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF131A30),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF2E3B5F)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF1E2640),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: const Color(0xFF2E3B5F)),
            ),
            child: Row(
              children: [
                // Icon kính lúp bên trái
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Icon(Icons.search, size: 20, color: Colors.white70),
                ),
                // Logo Google kèm chữ "CẢI TIẾN" ở góc
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    RichText(
                      text: const TextSpan(
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: -0.5),
                        children: [
                          TextSpan(text: 'G', style: TextStyle(color: Color(0xFF4285F4))),
                          TextSpan(text: 'o', style: TextStyle(color: Color(0xFFEA4335))),
                          TextSpan(text: 'o', style: TextStyle(color: Color(0xFFFBBC05))),
                          TextSpan(text: 'g', style: TextStyle(color: Color(0xFF4285F4))),
                          TextSpan(text: 'l', style: TextStyle(color: Color(0xFF34A853))),
                          TextSpan(text: 'e', style: TextStyle(color: Color(0xFFEA4335))),
                        ],
                      ),
                    ),
                    const SizedBox(width: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2E3B5F),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: const Text(
                        'CẢI TIẾN',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF90CAF9),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(width: 1, height: 22, color: const Color(0xFF2E3B5F)),
                    const SizedBox(width: 8),
                  ],
                ),
                // Ô TextField nhập liệu
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(fontSize: 14, color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: 'Nhập từ khóa tìm kiếm trong diễn đàn...',
                      hintStyle: TextStyle(fontSize: 13, color: Colors.white38),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                      isDense: true,
                    ),
                    onSubmitted: (val) {},
                  ),
                ),
                // Nút tìm kiếm
                InkWell(
                  onTap: () {},
                  child: Container(
                    height: 48,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: const BoxDecoration(
                      color: Color(0xFFEF5350),
                      borderRadius: BorderRadius.horizontal(right: Radius.circular(3)),
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      'Tìm kiếm',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Tìm kiếm nhanh toàn bộ nội dung, câu hỏi, luận giải và thảo luận trên diễn đàn.',
            style: TextStyle(fontSize: 12, color: Colors.white54),
          ),
        ],
      ),
    );
  }

  // --- 3. Khối Khám Phá Thêm (Hình 4: "Tạo Thiết Kế", "Phối Màu Nhuộm", "Nâng Cấp OS") ---
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
          _buildExploreItem('Tạo Thiết Kế'),
          _buildExploreItem('Phối Màu Nhuộm'),
          _buildExploreItem('Nâng Cấp OS', isLast: true),
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

  // --- 4. Footer Diễn Đàn ---
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
