import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/auth_service.dart';
import '../../services/forum_user_repository.dart';
import '../../services/signalr_service.dart';
import '../../widgets/user_rank_badge_widget.dart';

typedef UserProfileScreen = MemberProfileScreen;

/// Màn hình Thông tin thành viên / User Profile chuẩn Boxed Layout 1024px & Theme Dark Navy
class MemberProfileScreen extends StatefulWidget {
  final String username;
  final ForumUserRepository? repository;

  const MemberProfileScreen({
    super.key,
    this.username = '',
    this.repository,
  });

  @override
  State<MemberProfileScreen> createState() => _MemberProfileScreenState();
}

class _MemberProfileScreenState extends State<MemberProfileScreen> {
  String _selectedGroup = 'Thành viên';
  String _selectedJumpCategory = 'Chuyển đến';
  late final ForumUserRepository _userRepository;
  UserProfileStats? _stats;
  bool _isLoading = false;
  late String _effectiveUsername;
  List<String> _jumpCategories = [
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
  void initState() {
    super.initState();
    _effectiveUsername = widget.username;
    _userRepository = widget.repository ?? HttpForumUserRepository();
    _loadUserStats();
    _loadJumpCategories();

    // Lắng nghe SignalR sự kiện thay đổi Role và Rank theo thời gian thực
    signalRService.listenToUserRoleChanged(_onUserRoleChangedSignalR);
    signalRService.listenToUserRankChanged(_onUserRankChangedSignalR);
    signalRService.listenToUserRoleRevoked(_onUserRoleRevokedSignalR);
  }

  @override
  void dispose() {
    signalRService.removeUserRoleChangedListener();
    signalRService.removeUserRankChangedListener();
    signalRService.removeUserRoleRevokedListener();
    super.dispose();
  }

  void _onUserRoleChangedSignalR(List<Object?>? args) {
    if (mounted) {
      _loadUserStats();
    }
  }

  void _onUserRankChangedSignalR(List<Object?>? args) {
    if (mounted) {
      _loadUserStats();
    }
  }

  void _onUserRoleRevokedSignalR(List<Object?>? args) {
    if (mounted) {
      _loadUserStats();
    }
  }

  Future<void> _loadJumpCategories() async {
    try {
      final cats = await _userRepository.fetchJumpCategories();
      if (mounted && cats.isNotEmpty) {
        setState(() {
          _jumpCategories = cats;
        });
      }
    } catch (_) {}
  }

  Future<void> _loadUserStats() async {
    String username = widget.username;
    if (username.isEmpty) {
      try {
        final loggedIn = await AuthService().getUsername();
        if (loggedIn != null && loggedIn.isNotEmpty) {
          username = loggedIn;
        }
      } catch (_) {}
    }
    if (mounted) {
      setState(() {
        _effectiveUsername = username;
        _isLoading = true;
      });
    }
    if (username.isNotEmpty) {
      try {
        final stats = await _userRepository.fetchUserProfileStats(username);
        if (mounted && stats != null) {
          setState(() {
            _stats = stats;
            _selectedGroup = stats.group;
          });
        }
      } catch (_) {}
    }
    if (mounted) setState(() => _isLoading = false);
  }

  List<String> get _groupOptions {
    final groups = <String>{'Thành viên'};
    if (_stats != null) {
      for (final g in _stats!.userGroups) {
        if (g.trim().isNotEmpty) groups.add(g.trim());
      }
      final rankLower = _stats!.rank.toLowerCase();
      final groupLower = _stats!.group.toLowerCase();
      if (rankLower.contains('quản lý') ||
          groupLower.contains('quản trị') ||
          groupLower.contains('admin')) {
        groups.add('Ban quản trị');
      }
    }
    return groups.toList();
  }



  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Material(
        color: Colors.transparent,
        child: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: CircularProgressIndicator(color: Color(0xFFEF5350)),
          ),
        ),
      );
    }
    // Tuân thủ Boxed Layout Rule 7: Trả về nội dung thuần, nền trong suốt để màu MainLayout hiện ra
    return Material(color: Colors.transparent, child: 
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Gộp các khối lại, bỏ SizedBox/Margin thừa
          _buildProfileHeaderCard(),
          _buildDetailsCard(),
          _buildSignatureCard(),
          const SizedBox(height: 16), // Khoảng cách nhỏ trước Dropdown
          _buildJumpDropdown(),
          const SizedBox(height: 16), // Khoảng cách nhỏ trước Footer
          _buildForumFooter(),
        ],
      ),
    );
  }

  Widget _buildProfileLogoWidget() {
    final rank = (_stats?.rank ?? '').toLowerCase();
    final group = (_stats?.group ?? '').toLowerCase();
    final role = (_stats?.role ?? '').toLowerCase();
    final badge = (_stats?.badge ?? '').toLowerCase();
    final int safeStars = (_stats?.stars != null && _stats!.stars > 0) ? _stats!.stars : 1;

    // 1. Ban Quản Trị
    if (role == 'super_admin' || role == 'superadmin' || rank.contains('superadmin') || group.contains('superadmin') || badge.contains('superadmin')) {
      return Image.asset(
        'assets/images/logo_super_admin.png',
        key: ValueKey('logo_bqt_${_effectiveUsername}_super_admin_v5'),
        width: 160,
        height: 210,
        fit: BoxFit.contain,
      );
    }
    if (rank.contains('sáng lập') || group.contains('sáng lập') || badge.contains('sáng lập')) {
      return Image.asset(
        'assets/images/logo_sang_lap.png',
        key: ValueKey('logo_bqt_${_effectiveUsername}_sang_lap_v5'),
        width: 160,
        height: 210,
        fit: BoxFit.contain,
      );
    }
    if (role == 'admin' || rank.contains('admin') || group.contains('admin') || group.contains('quản trị')) {
      return Image.asset(
        'assets/images/logo_admin.png',
        key: ValueKey('logo_bqt_${_effectiveUsername}_admin_v5'),
        width: 160,
        height: 210,
        fit: BoxFit.contain,
      );
    }
    if (rank.contains('quản lý') || group.contains('quản lý') || badge.contains('quản lý')) {
      return Image.asset(
        'assets/images/logo_quan_ly.png',
        key: ValueKey('logo_bqt_${_effectiveUsername}_quan_ly_v5'),
        width: 160,
        height: 210,
        fit: BoxFit.contain,
      );
    }
    if (rank.contains('hội viên') || group.contains('hội viên') || badge.contains('hội viên')) {
      return Image.asset(
        'assets/images/logo_hoi_vien.png',
        key: ValueKey('logo_bqt_${_effectiveUsername}_hoi_vien_v5'),
        width: 160,
        height: 210,
        fit: BoxFit.contain,
      );
    }
    if (role == 'moderator' || rank.contains('điều hành') || group.contains('điều hành') || badge.contains('điều hành')) {
      return Image.asset(
        'assets/images/logo_dieu_hanh.png',
        key: ValueKey('logo_bqt_${_effectiveUsername}_dieu_hanh_v5'),
        width: 160,
        height: 210,
        fit: BoxFit.contain,
      );
    }
    if (rank.contains('tư vấn') || group.contains('tư vấn') || badge.contains('tư vấn')) {
      return Image.asset(
        'assets/images/logo_tu_van.png',
        key: ValueKey('logo_bqt_${_effectiveUsername}_tu_van_v5'),
        width: 160,
        height: 210,
        fit: BoxFit.contain,
      );
    }

    // 2. Đại Sư (Chuyên gia) - Chuẩn động Hình 9
    if (rank.contains('đẳng') || badge.contains('đại sư')) {
      return MasterTitleLogoWidget(
        userId: _effectiveUsername,
        starLevel: safeStars,
        rankTitle: _getProfileRankTitle(),
        width: 160,
        height: 210,
      );
    }

    // 3. Thành viên - Chuẩn động Hình 7
    return MemberTitleLogoWidget(
      userId: _effectiveUsername,
      starLevel: safeStars,
      rankTitle: 'Thành viên',
      width: 160,
      height: 210,
    );
  }

  String _getProfileRankTitle() {
    final rank = _stats?.rank ?? 'Thành viên';
    final role = (_stats?.role ?? '').toLowerCase();
    final badge = (_stats?.badge ?? '').toLowerCase();

    if (role == 'super_admin' || badge.contains('sáng lập') || rank.toLowerCase().contains('sáng lập')) {
      return 'Quản lý'; // Theo đúng yêu cầu Hình 8
    }
    return rank;
  }

  // --- 1. Khung hộp thông tin cá nhân (Hình 5 / Hình 8) ---
  Widget _buildProfileHeaderCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        border: const Border(bottom: BorderSide(color: Color(0xFF2E3B5F))),
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
              'Đang xem thông tin cá nhân về $_effectiveUsername',
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
                // Logo thành viên (Hình 7) hoặc Đại Sư (Hình 9) hoặc BQT
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Center(
                    child: _buildProfileLogoWidget(),
                  ),
                ),

                // Tên đăng nhập
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Tên đăng nhập: ',
                      style: TextStyle(fontSize: 13.5, color: Colors.grey[400]),
                    ),
                    Text(
                      _effectiveUsername,
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
                const SizedBox(height: 10),

                // Xếp hạng (Chuẩn động Hình 6 cho Thành viên, Hình 8 cho Đại Sư)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Xếp hạng: ',
                      style: TextStyle(fontSize: 13.5, color: Colors.grey[400]),
                    ),
                    const SizedBox(width: 8),
                    UserRankBadgeWidget(
                      userId: _effectiveUsername,
                      rankTitle: _getProfileRankTitle(),
                      starLevel: (_stats?.stars != null && _stats!.stars > 0) ? _stats!.stars : 1,
                      badgeType: _stats?.badge,
                      width: 120,
                      height: 42,
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Tuổi
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Tuổi: ',
                      style: TextStyle(fontSize: 13.5, color: Colors.grey[400]),
                    ),
                    Text(
                      _stats != null ? '${_stats!.age}' : '45',
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Nhóm [Dropdown] [Nút Chuyển]
                Builder(
                  builder: (context) {
                    final currentOptions = _groupOptions;
                    final currentVal = currentOptions.contains(_selectedGroup)
                        ? _selectedGroup
                        : currentOptions.first;
                    return Row(
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
                              border: const Border(bottom: BorderSide(color: Color(0xFF2E3B5F))),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: currentVal,
                                dropdownColor: const Color(0xFF131A30),
                                menuMaxHeight: 350,
                                isDense: true,
                                style: const TextStyle(color: Colors.white, fontSize: 13),
                                icon: const Icon(Icons.arrow_drop_down, color: Colors.white70, size: 18),
                                items: currentOptions.map((group) {
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
                    );
                  },
                ),

                // Đến từ (chỉ hiển thị khi có ký tự trong hồ sơ)
                if (_stats?.fromLocation != null && _stats!.fromLocation.trim().isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Đến từ: ',
                        style: TextStyle(fontSize: 13.5, color: Colors.grey[400]),
                      ),
                      Flexible(
                        child: Text(
                          _stats!.fromLocation.trim(),
                          style: const TextStyle(
                            fontSize: 13.5,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
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
    );
  }

  // --- 2. Hai cột LIÊN HỆ và THỐNG KÊ THÀNH VIÊN (Hình 5) ---
  Widget _buildDetailsCard() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        border: const Border(bottom: BorderSide(color: Color(0xFF2E3B5F))),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 650;

          final contactCol = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'LIÊN HỆ ${_effectiveUsername.toUpperCase()}',
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
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    'Địa chỉ email: ',
                    style: TextStyle(fontSize: 13, color: Colors.grey[400]),
                  ),
                  InkWell(
                    onTap: () => context.go('/forum/member/$_effectiveUsername/email'),
                    child: RichText(
                      text: const TextSpan(
                        text: 'Gửi email cho',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFFEF5350),
                          decoration: TextDecoration.underline,
                          decorationColor: Color(0xFFEF5350),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    'Tin nhắn: ',
                    style: TextStyle(fontSize: 13, color: Colors.grey[400]),
                  ),
                  InkWell(
                    onTap: () => context.go('/forum/messages'),
                    child: RichText(
                      text: const TextSpan(
                        text: 'Gửi tin nhắn',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFFEF5350),
                          decoration: TextDecoration.underline,
                          decorationColor: Color(0xFFEF5350),
                        ),
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
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    'Tham gia: ',
                    style: TextStyle(fontSize: 13, color: Colors.grey[400]),
                  ),
                  Text(
                    _stats?.joinDate ?? '12:03, 04/07/12',
                    style: const TextStyle(fontSize: 13, color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    'Lần hoạt động trước: ',
                    style: TextStyle(fontSize: 13, color: Colors.grey[400]),
                  ),
                  Text(
                    _stats?.lastActive ?? '-',
                    style: const TextStyle(fontSize: 13, color: Colors.white),
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
                  Text(
                    _stats != null ? '${_stats!.postCount}' : '0',
                    style: const TextStyle(
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
                    onTap: () {
                      final targetUser = _effectiveUsername;
                      context.push('/forum/user-posts?username=$targetUser');
                    },
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
                '(${(_stats?.postPercentage ?? 0.00).toStringAsFixed(2)}% trong tổng số bài viết / ${(_stats?.postsPerDay ?? 0.01).toStringAsFixed(2)} bài viết/ngày)',
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
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(4),
              border: const Border(bottom: BorderSide(color: Color(0xFF2E3B5F))),
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
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        border: const Border(bottom: BorderSide(color: Color(0xFF2E3B5F))),
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
            color: Colors.transparent,
            border: const Border(bottom: BorderSide(color: Color(0xFF2E3B5F))),
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
                    _effectiveUsername,
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
