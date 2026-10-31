import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/forum_user_repository.dart';
import '../../services/signalr_service.dart';
import '../../widgets/share_dialog.dart';
import '../../widgets/user_rank_badge_widget.dart';
import 'member_search_dialog.dart';

class MembersScreen extends StatefulWidget {
  const MembersScreen({super.key});

  @override
  State<MembersScreen> createState() => _MembersScreenState();
}

class _MembersScreenState extends State<MembersScreen> {
  final ForumUserRepository _userRepository = HttpForumUserRepository();
  List<ForumUserModel> _memberList = [];
  int _totalUsers = 4;
  int _totalPages = 1;
  int _currentPage = 1;
  String _selectedLetter = 'Tất cả';
  String? _searchQuery;
  bool _isLoading = false;
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

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchMembers();

    // Lắng nghe SignalR đồng bộ RBAC thời gian thực
    signalRService.listenToUserRoleChanged(_onUserRoleChangedSignalR);
    signalRService.listenToUserRankChanged(_onUserRankChangedSignalR);
    signalRService.listenToUserRoleRevoked(_onUserRoleRevokedSignalR);
  }

  @override
  void dispose() {
    signalRService.removeUserRoleChangedListener();
    signalRService.removeUserRankChangedListener();
    signalRService.removeUserRoleRevokedListener();
    _scrollController.dispose();
    super.dispose();
  }

  void _onUserRoleChangedSignalR(List<Object?>? args) {
    if (mounted) {
      _fetchMembers();
    }
  }

  void _onUserRankChangedSignalR(List<Object?>? args) {
    if (mounted) {
      _fetchMembers();
    }
  }

  void _onUserRoleRevokedSignalR(List<Object?>? args) {
    if (mounted) {
      _fetchMembers();
    }
  }

  Future<void> _showJumpToPageDialog() async {
    final controller = TextEditingController(text: '$_currentPage');
    final targetPage = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF161F36),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: Color(0xFF2E3B5F)),
        ),
        title: const Text(
          'Nhảy tới trang',
          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Nhập số trang (1 - $_totalPages):',
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              autofocus: true,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFF131A30),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: const BorderSide(color: Color(0xFF2E3B5F)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: const BorderSide(color: Color(0xFF2E3B5F)),
                ),
              ),
              onSubmitted: (val) {
                final parsed = int.tryParse(val.trim());
                Navigator.of(ctx).pop(parsed);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Hủy', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8B0000)),
            onPressed: () {
              final parsed = int.tryParse(controller.text.trim());
              Navigator.of(ctx).pop(parsed);
            },
            child: const Text('Đi tới', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    controller.dispose();
    if (targetPage != null) {
      final clamped = targetPage.clamp(1, _totalPages);
      if (clamped != _currentPage) {
        setState(() => _currentPage = clamped);
        _fetchMembers();
      }
    }
  }

  Future<void> _fetchMembers() async {
    setState(() => _isLoading = true);
    try {
      final res = await _userRepository.fetchUsers(
        page: _currentPage,
        pageSize: 25,
        letter: _selectedLetter,
        query: _searchQuery,
      );
      if (mounted) {
        setState(() {
          _memberList = res['users'] as List<ForumUserModel>;
          _totalUsers = res['totalUsers'] as int;
          _totalPages = res['totalPages'] as int;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _launchWebsite(String url) async {
    if (url.isEmpty) return;
    try {
      final uri = Uri.parse(url);
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Khung Tiêu Đề "Thành viên"
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
            onTap: () async {
              final result = await showMemberSearchDialog(context);
              if (result != null && result.isNotEmpty) {
                setState(() {
                  _searchQuery = result;
                  _currentPage = 1;
                });
                _fetchMembers();
              }
            },
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
            onTap: () {
              setState(() {
                _selectedLetter = 'Tất cả';
                _searchQuery = null;
                _currentPage = 1;
              });
              _fetchMembers();
            },
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
              onTap: () {
                setState(() {
                  _selectedLetter = letter;
                  _searchQuery = null;
                  _currentPage = 1;
                });
                _fetchMembers();
              },
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
            onTap: () async {
              final result = await showMemberSearchDialog(context);
              if (result != null && result.isNotEmpty) {
                setState(() {
                  _searchQuery = result;
                  _currentPage = 1;
                });
                _fetchMembers();
              }
            },
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
        Text(
          '$_totalUsers thành viên',
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            InkWell(
              onTap: _showJumpToPageDialog,
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
            for (int p = 1; p <= (_totalPages > 5 ? 5 : _totalPages); p++)
              _buildPageBtn(p, isActive: _currentPage == p),
            if (_totalPages > 5) ...[
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 2),
                child: Text('...', style: TextStyle(color: Colors.white54, fontSize: 11)),
              ),
              _buildPageBtn(_totalPages, isActive: _currentPage == _totalPages),
            ],
            InkWell(
              onTap: () {
                if (_currentPage < _totalPages) {
                  setState(() => _currentPage++);
                  _fetchMembers();
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
      onTap: () {
        if (_currentPage != page) {
          setState(() => _currentPage = page);
          _fetchMembers();
        }
      },
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

                  // Các hàng thành viên động (bọc trong Scrollbar + SingleChildScrollView)
                  if (_isLoading)
                    const Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Center(
                        child: CircularProgressIndicator(color: Color(0xFFEF5350)),
                      ),
                    )
                  else if (_memberList.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Center(
                        child: Text(
                          'Không có thành viên nào phù hợp',
                          style: TextStyle(color: Colors.white54, fontSize: 13),
                        ),
                      ),
                    )
                  else
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 620),
                      child: Scrollbar(
                        thumbVisibility: true,
                        controller: _scrollController,
                        child: SingleChildScrollView(
                          controller: _scrollController,
                          child: Column(
                            children: [
                              for (int i = 0; i < _memberList.length; i++) _buildMemberRow(_memberList[i], i),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMemberRow(ForumUserModel item, int index) {
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
              onTap: () => context.go('/forum/member/${item.username}'),
              child: Text(
                item.username,
                style: TextStyle(
                  color: item.nameColor,
                  fontWeight: item.isBold ? FontWeight.bold : FontWeight.normal,
                  fontSize: 13,
                ),
              ),
            ),
          ),

          // 2. Xếp hạng (Huy hiệu Thành viên Hình 3 hoặc Đẳng vị Hình 4)
          Expanded(
            flex: 2,
            child: Center(
              child: UserRankBadgeWidget(
                userId: item.id,
                rankTitle: item.rankTitle,
                starLevel: item.starLevel,
                badgeType: item.badgeType,
                ribbonAsset: item.ribbonAsset,
                width: 118,
                height: 42,
              ),
            ),
          ),

          // 3. Bài viết (Dynamic)
          Expanded(
            flex: 1,
            child: Text(
              '${item.posts}',
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
            child: item.website.isNotEmpty
                ? InkWell(
                    onTap: () => _launchWebsite(item.website),
                    child: Text(
                      item.website,
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

          // 5. Tham gia (Dynamic)
          Expanded(
            flex: 2,
            child: Text(
              item.joinDate,
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
                  _buildFooterLink(Icons.share, 'Chia sẻ', () => ShareHelper.share(context)),
                  _buildFooterLink(Icons.security, 'Chúng tôi', () => context.go('/forum/team')),
                  _buildFooterLink(Icons.group, 'Thành viên', () => context.go('/members')),
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
