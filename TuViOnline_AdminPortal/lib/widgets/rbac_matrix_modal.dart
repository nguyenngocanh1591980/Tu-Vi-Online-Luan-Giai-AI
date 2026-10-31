import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import '../services/admin_repository.dart';
import '../theme/admin_colors.dart';
import '../utils/boxed_snack_bar.dart';
import 'admin_data_grid_layout.dart';
import 'user_rank_badge_widget.dart';

/// Banner hiển thị trạng thái thực thi RBAC Enforced (Hình 1)
class RbacEnforcedBanner extends StatefulWidget {
  final VoidCallback onOpenMatrix;

  const RbacEnforcedBanner({
    super.key,
    required this.onOpenMatrix,
  });

  @override
  State<RbacEnforcedBanner> createState() => _RbacEnforcedBannerState();
}

class _RbacEnforcedBannerState extends State<RbacEnforcedBanner> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: InkWell(
        onTap: widget.onOpenMatrix,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFF131A30),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _isHovered ? AdminColors.primary : const Color(0xFF2E3B5F),
              width: 1.2,
            ),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Icon khiên màu xanh ngọc (Hình 1)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF003B38),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AdminColors.primary.withAlpha(120), width: 1),
                ),
                child: const Icon(
                  Icons.shield,
                  color: AdminColors.primary,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),

              // Tiêu đề banner (Hình 1)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Chính sách Phân quyền RBAC',
                      style: TextStyle(
                        color: Color(0xFFB0BEC5),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Enforced ( Admin, Sáng Lập, Điều hành, Tư Vấn, Quản Lý, Moderator, User)',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14.5,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.3,
                        decoration: _isHovered ? TextDecoration.underline : TextDecoration.none,
                        decorationColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

              // Icon mở modal (Hình 1)
              IconButton(
                onPressed: widget.onOpenMatrix,
                icon: const Icon(
                  Icons.open_in_new,
                  color: Color(0xFFB0BEC5),
                  size: 20,
                ),
                tooltip: 'Xem Ma Trận Phân Quyền [LIVE]',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Modal Ma Trận Phân Quyền RBAC Thời Gian Thực (Hình 2)
/// Thiết kế 3 Bảng DataGrid độc lập:
/// Bảng 1 (25 dòng): Cập nhật Phân Quyền (8 Radio buttons, Unique Admin & Sáng Lập)
/// Bảng 2 (10 dòng): Nâng/Giảm Cấp Thành Viên (8 sao tím theo Hình 3)
/// Bảng 3 (12 dòng): Nâng/Giảm Cấp Đại Sư (10 sao đỏ theo Hình 4)
class RbacMatrixModal extends StatefulWidget {
  final Function(String roleKey) onSelectRole;

  const RbacMatrixModal({
    super.key,
    required this.onSelectRole,
  });

  static Future<dynamic> show(BuildContext context, {required Function(String roleKey) onSelectRole}) {
    return showDialog<dynamic>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withAlpha(180),
      builder: (ctx) => RbacMatrixModal(onSelectRole: onSelectRole),
    );
  }

  @override
  State<RbacMatrixModal> createState() => _RbacMatrixModalState();
}

class _RbacMatrixModalState extends State<RbacMatrixModal> with SingleTickerProviderStateMixin {
  final AdminRepository _repo = AdminRepository();
  late TabController _tabController;
  bool _isLoading = true;

  // Dữ liệu cho 3 bảng
  List<Map<String, dynamic>> _usersTable1 = [];
  List<Map<String, dynamic>> _membersTable2 = [];
  List<Map<String, dynamic>> _mastersTable3 = [];

  // State phục vụ Bảng 1: Tìm kiếm & Gán chức vụ Bảng 1
  final TextEditingController _t1SearchController = TextEditingController();
  Map<String, dynamic>? _t1SearchedUser;
  bool _t1IsSearching = false;
  String _t1SelectedRole = 'User';

  // State phục vụ Bảng 2 (Nhiệm Vụ 1): Tìm kiếm & Nâng/giảm cấp Thành viên 1 - 9 sao
  final TextEditingController _t2SearchController = TextEditingController();
  Map<String, dynamic>? _t2SearchedUser;
  bool _t2IsSearching = false;
  int _t2SelectedStar = 1;

  // State phục vụ Bảng 3 (Nhiệm Vụ 2): Tìm kiếm & Nâng/giảm cấp Đại Sư 1 - 10 sao đỏ
  final TextEditingController _t3SearchController = TextEditingController();
  Map<String, dynamic>? _t3SearchedUser;
  bool _t3IsSearching = false;
  int _t3SelectedStar = 1;

  // State lựa chọn cho từng dòng
  // Bảng 1: userId -> Set<String> roles (nếu > 1 là invalid trigger viền đỏ)
  final Map<int, Set<String>> _selectedRoles = {};
  // Bảng 2: userId -> starLevel (2 đến 9)
  final Map<int, int> _selectedMemberStars = {};
  // Bảng 3: masterId -> starLevel (1 đến 10)
  final Map<int, int> _selectedMasterStars = {};

  final List<String> _availableRoles = const [
    'Admin',
    'Sáng Lập',
    'Điều hành',
    'Tư Vấn',
    'Quản Lý',
    'Moderator',
    'Đại sư',
    'User',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAllData();
  }

  @override
  void dispose() {
    _t1SearchController.dispose();
    _t2SearchController.dispose();
    _t3SearchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAllData() async {
    setState(() => _isLoading = true);
    final res = await _repo.fetchMatrixData();
    if (mounted) {
      if (res != null && res['success'] == true) {
        final rawUsers = (res['users'] as List<dynamic>?) ?? [];
        final rawMembers = (res['members'] as List<dynamic>?) ?? [];
        final rawMasters = (res['masters'] as List<dynamic>?) ?? [];

        _usersTable1 = rawUsers.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        _membersTable2 = rawMembers.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        _mastersTable3 = rawMasters.map((e) => Map<String, dynamic>.from(e as Map)).toList();

        // Khởi tạo state lựa chọn
        for (var u in _usersTable1) {
          final uid = u['id'] as int;
          final role = _mapDbRoleToDisplay(u['role']?.toString() ?? 'User', u['badge']?.toString());
          _selectedRoles[uid] = {role};
        }

        for (var m in _membersTable2) {
          final uid = m['id'] as int;
          final stars = (m['starLevel'] as num?)?.toInt() ?? 2;
          _selectedMemberStars[uid] = stars.clamp(2, 9);
        }

        for (var mast in _mastersTable3) {
          final mid = mast['id'] as int;
          final stars = (mast['starLevel'] as num?)?.toInt() ?? 1;
          _selectedMasterStars[mid] = stars.clamp(1, 10);
        }
      }
      setState(() => _isLoading = false);
    }
  }

  String _mapDbRoleToDisplay(String role, String? badge) {
    final b = (badge ?? '').toLowerCase();
    if (b.contains('sáng lập')) return 'Sáng Lập';
    if (b.contains('quản lý')) return 'Quản Lý';
    if (b.contains('quản trị')) return 'Admin';
    if (b.contains('tư vấn')) return 'Tư Vấn';
    if (b.contains('điều hành')) return 'Điều hành';
    if (b.contains('đại sư')) return 'Đại sư';

    final r = role.toLowerCase();
    if (r == 'super_admin') return 'Sáng Lập';
    if (r == 'admin') return 'Admin';
    if (r == 'moderator') return 'Điều hành';
    return 'User';
  }

  // Xử lý Tìm kiếm User Bảng 1 (Nhiệm Vụ 1)
  Future<void> _handleT1Search() async {
    final username = _t1SearchController.text.trim();
    if (username.isEmpty) return;

    setState(() => _t1IsSearching = true);
    final res = await _repo.checkUsername(username);
    if (!mounted) return;
    setState(() => _t1IsSearching = false);

    if (res['success'] == true && res['user'] != null) {
      setState(() {
        _t1SearchedUser = Map<String, dynamic>.from(res['user'] as Map);
        final role = _mapDbRoleToDisplay(_t1SearchedUser!['role']?.toString() ?? 'User', _t1SearchedUser!['badge']?.toString());
        _t1SelectedRole = role;
      });
    } else {
      setState(() {
        _t1SearchedUser = null;
      });
      showErrorSnackBar(context, 'Không có tên thành viên trên trong dữ liệu. Xin vui lòng nhập lại !');
    }
  }

  // Xác nhận phân quyền Bảng 1 với ràng buộc Unique (Nhiệm Vụ 1)
  Future<void> _confirmT1RoleUpdate() async {
    if (_t1SearchedUser == null) {
      final inputVal = _t1SearchController.text.trim();
      if (inputVal.isNotEmpty) {
        await _handleT1Search();
      }
      if (!mounted) return;
      if (_t1SearchedUser == null) {
        showErrorSnackBar(context, 'Không có tên thành viên trên trong dữ liệu. Xin vui lòng nhập lại !');
        return;
      }
    }

    if (!mounted) return;
    // 1. Bật Dialog xác nhận: "Bạn có chắc chắn không (Y/N)?"
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF161F36),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: Color(0xFF2E3B5F)),
        ),
        title: const Text(
          'Xác nhận phân quyền',
          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Bạn có chắc chắn không (Y/N)?',
          style: TextStyle(color: Colors.white70, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('N', style: TextStyle(color: Colors.white54, fontSize: 14, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AdminColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Y', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final targetUserId = _t1SearchedUser!['id'] as int;

    // 2. Nếu chọn "Y" VÀ vị trí chọn mới là Admin hoặc Sáng Lập (Vị trí Unique):
    if (_t1SelectedRole == 'Admin' || _t1SelectedRole == 'Sáng Lập') {
      final checkRes = await _repo.checkUniqueHolder(_t1SelectedRole, targetUserId);
      if (checkRes['isOccupied'] == true && checkRes['currentHolder'] != null) {
        final currentHolder = checkRes['currentHolder'];
        if (!mounted) return;

        // Bật Dialog cảnh báo:
        await showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            backgroundColor: const Color(0xFF161F36),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: const BorderSide(color: Colors.redAccent, width: 1.5),
            ),
            title: const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 24),
                SizedBox(width: 8),
                Text(
                  'Cảnh báo Vị trí Unique',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            content: Text(
              'Hiện có user $currentHolder đang đảm nhiệm vị trí này. Bạn cần phải hủy nhiệm vụ người đó trước rồi mới \'Xác nhận\' ở mục này?',
              style: const TextStyle(color: Colors.white, fontSize: 13.5, height: 1.4),
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFC62828),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Đồng ý & Đi tới Quản lý BQT', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );

        if (!mounted) return;
        // Ngay lập tức điều hướng màn hình sang Hình 3 (board_management_screen.dart)
        Navigator.of(context).pop(); // Đóng Modal Ma Trận RBAC
        context.go('/dashboard/board'); // Điều hướng tới Quản lý Ban Quản Trị
        return;
      }
    }

    // 3. Nếu vị trí CHƯA CÓ người đảm nhiệm (hoặc vị trí thường):
    final res = await _repo.updateUserRoleRbac(
      userId: targetUserId,
      role: _t1SelectedRole,
    );

    if (!mounted) return;
    if (res['success'] == true) {
      showSuccessSnackBar(context, res['message'] ?? 'Đã cập nhật phân quyền thành công!');
      widget.onSelectRole(_t1SelectedRole);
    } else {
      showErrorSnackBar(context, res['message'] ?? 'Có lỗi xảy ra khi cập nhật phân quyền.');
    }

    if (res['success'] == true) {
      final refreshed = await _repo.checkUsername(_t1SearchedUser!['username'].toString());
      if (mounted && refreshed['success'] == true && refreshed['user'] != null) {
        setState(() {
          _t1SearchedUser = Map<String, dynamic>.from(refreshed['user'] as Map);
        });
      }
      _loadAllData();
    }
  }

  // Xử lý Tìm kiếm User Bảng 2 (Nhiệm Vụ 1)
  Future<void> _handleT2Search() async {
    final username = _t2SearchController.text.trim();
    if (username.isEmpty) return;

    setState(() => _t2IsSearching = true);
    final res = await _repo.checkUsername(username);
    if (!mounted) return;
    setState(() => _t2IsSearching = false);

    if (res['success'] == true && res['user'] != null) {
      setState(() {
        _t2SearchedUser = Map<String, dynamic>.from(res['user'] as Map);
        final currentStar = (_t2SearchedUser!['starLevel'] as num?)?.toInt() ?? 1;
        _t2SelectedStar = currentStar.clamp(1, 9);
      });
    } else {
      setState(() {
        _t2SearchedUser = null;
      });
      showErrorSnackBar(context, 'Không có tên thành viên trên trong dữ liệu. Xin vui lòng nhập lại !');
    }
  }

  // Xác nhận Nâng/Giảm Cấp Thành Viên Bảng 2 (Nhiệm Vụ 1)
  Future<void> _confirmT2RankUpdate() async {
    if (_t2SearchedUser == null) {
      final inputVal = _t2SearchController.text.trim();
      if (inputVal.isNotEmpty) {
        await _handleT2Search();
      }
      if (!mounted) return;
      if (_t2SearchedUser == null) {
        showErrorSnackBar(context, 'Không có tên thành viên trên trong dữ liệu. Xin vui lòng nhập lại !');
        return;
      }
    }

    if (!mounted) return;
    // Kiểm tra ràng buộc: Nếu User đang giữ vị trí Unique tối cao (Admin hoặc Sáng Lập)
    final currentRole = _mapDbRoleToDisplay(_t2SearchedUser!['role']?.toString() ?? 'User', _t2SearchedUser!['badge']?.toString());
    if (currentRole == 'Admin' || currentRole == 'Sáng Lập') {
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF161F36),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(color: Colors.redAccent, width: 1.5),
          ),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 24),
              SizedBox(width: 8),
              Text(
                'Cảnh báo Vị trí Unique',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Text(
            'User ${_t2SearchedUser!['username']} hiện đang giữ vị trí $currentRole (vị trí Unique tối cao). Bạn cần phải hủy nhiệm vụ tại bảng Quản lý Ban Quản Trị trước khi chuyển xuống cấp Thành viên!',
            style: const TextStyle(color: Colors.white, fontSize: 13.5, height: 1.4),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                Navigator.of(context).pop();
                context.go('/dashboard/board');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFC62828),
                foregroundColor: Colors.white,
              ),
              child: const Text('Đồng ý & Đi tới Quản lý BQT', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
      return;
    }

    // 1. Bật Dialog xác nhận đúng từng chữ yêu cầu:
    // Tiêu đề trên: "Xác nhận nâng cấp giảm cấp thành viên"
    // Câu hỏi dưới: "Bạn có chắc chắn không(Y/N)"
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF161F36),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: Color(0xFF2E3B5F)),
        ),
        title: const Text(
          'Xác nhận nâng cấp giảm cấp thành viên',
          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Bạn có chắc chắn không(Y/N)',
          style: TextStyle(color: Colors.white70, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('N', style: TextStyle(color: Colors.white54, fontSize: 14, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AdminColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Y', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    // Trường hợp ấn N: đóng hộp thoại, màn hình vẫn giữ nguyên ở Hình 2
    if (confirmed != true || !mounted) return;

    final targetUserId = _t2SearchedUser!['id'] as int;
    final targetUsername = _t2SearchedUser!['username']?.toString() ?? '';

    // Trường hợp ấn Y:
    final res = await _repo.updateUserRankRbac(
      userId: targetUserId,
      starLevel: _t2SelectedStar,
      rankTitle: 'Thành viên',
    );

    if (!mounted) return;

    if (res['success'] == true) {
      // Hiển thị thông báo: "Bạn đã thay đổi thành công"
      showSuccessSnackBar(context, 'Bạn đã thay đổi thành công');

      // Tự động đóng Modal Bảng 2 và đưa màn hình quay về Hình 3 kèm dữ liệu user
      Navigator.of(context).pop({
        'action': 'member_rank_updated',
        'userId': targetUserId,
        'username': targetUsername,
        'starLevel': _t2SelectedStar,
      });

      // Nếu đang ở màn hình khác ngoài /dashboard/users, tự động chuyển về Quản lý User (Hình 3)
      try {
        final loc = GoRouterState.of(context).matchedLocation;
        if (!loc.startsWith('/dashboard/users')) {
          context.go('/dashboard/users');
        }
      } catch (_) {}
    } else {
      showErrorSnackBar(context, res['message'] ?? 'Có lỗi xảy ra khi cập nhật cấp bậc thành viên.');
    }
  }

  // Xử lý Tìm kiếm User / Đại Sư Bảng 3 (Nhiệm Vụ 2)
  Future<void> _handleT3Search() async {
    final query = _t3SearchController.text.trim();
    if (query.isEmpty) return;

    setState(() => _t3IsSearching = true);
    final res = await _repo.checkUsername(query);
    if (!mounted) return;
    setState(() => _t3IsSearching = false);

    if (res['success'] == true && res['user'] != null) {
      setState(() {
        _t3SearchedUser = Map<String, dynamic>.from(res['user'] as Map);
        final currentStar = (_t3SearchedUser!['starLevel'] as num?)?.toInt() ?? 1;
        _t3SelectedStar = currentStar.clamp(1, 10);
      });
    } else {
      setState(() {
        _t3SearchedUser = null;
      });
      showErrorSnackBar(context, 'Không có tên thành viên trên trong dữ liệu. Xin vui lòng nhập lại !');
    }
  }

  // Xác nhận Nâng/Giảm Cấp Đại Sư Bảng 3 (Nhiệm Vụ 2)
  Future<void> _confirmT3RankUpdate() async {
    if (_t3SearchedUser == null) {
      final inputVal = _t3SearchController.text.trim();
      if (inputVal.isNotEmpty) {
        await _handleT3Search();
      }
      if (!mounted) return;
      if (_t3SearchedUser == null) {
        showErrorSnackBar(context, 'Không có tên thành viên trên trong dữ liệu. Xin vui lòng nhập lại !');
        return;
      }
    }

    if (!mounted) return;

    // 1. Hộp thoại xác nhận đúng yêu cầu:
    // Tiêu đề trên: "Xác nhận nâng cấp giảm cấp Đại Sư"
    // Câu hỏi dưới: "Bạn có chắc chắn không(Y/N)"
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF161F36),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: Color(0xFF2E3B5F)),
        ),
        title: const Text(
          'Xác nhận nâng cấp giảm cấp Đại Sư',
          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Bạn có chắc chắn không(Y/N)',
          style: TextStyle(color: Colors.white70, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('N', style: TextStyle(color: Colors.white54, fontSize: 14, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AdminColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Y', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    // Trường hợp ấn N: đóng hộp thoại, màn hình vẫn giữ nguyên ở Hình 4
    if (confirmed != true || !mounted) return;

    final targetUserId = _t3SearchedUser!['id'] as int;
    final targetUsername = _t3SearchedUser!['username']?.toString() ?? '';

    final dangViMap = [
      'Nhất Đẳng', 'Nhị Đẳng', 'Tam Đẳng', 'Tứ Đẳng', 'Ngũ Đẳng',
      'Lục Đẳng', 'Thất Đẳng', 'Bát Đẳng', 'Cửu Đẳng'
    ];
    final rankTitle = dangViMap[(_t3SelectedStar - 1).clamp(0, 8)];

    // Trường hợp ấn Y:
    final res = await _repo.updateUserRankRbac(
      userId: targetUserId,
      starLevel: _t3SelectedStar,
      rankTitle: rankTitle,
    );

    if (!mounted) return;

    if (res['success'] == true) {
      // Hiển thị thông báo: "Bạn đã thay đổi thành công"
      showSuccessSnackBar(context, 'Bạn đã thay đổi thành công');

      // Tự động đóng Modal Bảng 3 và trả về thông tin cập nhật
      Navigator.of(context).pop({
        'action': 'master_rank_updated',
        'userId': targetUserId,
        'username': targetUsername,
        'starLevel': _t3SelectedStar,
        'rankTitle': rankTitle,
      });

      // Chuyển màn hình quay về Hình 5 (Hồ sơ Chuyên gia)
      try {
        final loc = GoRouterState.of(context).matchedLocation;
        if (!loc.startsWith('/dashboard/masters')) {
          context.go('/dashboard/masters');
        }
      } catch (_) {}
    } else {
      showErrorSnackBar(context, res['message'] ?? 'Có lỗi xảy ra khi cập nhật cấp bậc Đại Sư.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF131A30),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: Color(0xFF2E3B5F), width: 1.2),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1080, maxHeight: 820),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Modal (Hình 2)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF003B38),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AdminColors.primary.withAlpha(150), width: 1),
                    ),
                    child: const Icon(Icons.shield, color: AdminColors.primary, size: 26),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ma Trận Phân Quyền RBAC Thời Gian Thực',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Hệ thống Single Source of Truth: Đồng bộ trực tiếp PostgreSQL và broadcast SignalR tới toàn hệ thống',
                          style: TextStyle(
                            color: Color(0xFFB0BEC5),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Badge [LIVE] (Hình 2)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF132A1C),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFF2E7D32), width: 1),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.fiber_manual_record, color: Color(0xFF4CAF50), size: 10),
                        SizedBox(width: 5),
                        Text(
                          'LIVE',
                          style: TextStyle(
                            color: Color(0xFF4CAF50),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Nút X đóng
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.white70, size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // TabBar chuyển 3 Bảng
              Container(
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Color(0xFF2E3B5F), width: 1.2)),
                ),
                child: TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  indicatorColor: AdminColors.primary,
                  indicatorWeight: 3,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white60,
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                  tabs: [
                    Tab(text: 'BẢNG 1: CẬP NHẬT PHÂN QUYỀN'),
                    Tab(text: 'BẢNG 2: NÂNG/GIẢM CẤP THÀNH VIÊN'),
                    Tab(text: 'BẢNG 3: NÂNG/GIẢM CẤP ĐẠI SƯ'),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Nội dung 3 Bảng DataGrid
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: AdminColors.primary))
                    : TabBarView(
                        controller: _tabController,
                        children: [
                          _buildTable1(),
                          _buildTable2(),
                          _buildTable3(),
                        ],
                      ),
              ),

              const SizedBox(height: 12),
              const Divider(color: Color(0xFF2E3B5F), height: 1),
              const SizedBox(height: 10),

              // Footer với nút Đóng
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '* Lưu ý: Vị trí "Admin" và "Sáng lập" là Unique (Chỉ 1 user trên toàn hệ thống).',
                    style: TextStyle(color: Color(0xFFFFD54F), fontSize: 12, fontStyle: FontStyle.italic),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E2640),
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Color(0xFF2E3B5F)),
                      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                    child: const Text('Đóng', style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- BẢNG 1: CẬP NHẬT PHÂN QUYỀN (HÌNH 1 & HÌNH 2 - NHIỆM VỤ 1) ---
  Widget _buildTable1() {
    return AdminDataGridBox(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Bảng 1: Cột 1 (Tên Thành viên), Cột 2 (Xếp hạng Hiện tại), Cột 3 (Vị trí Đảm nhiệm mới), Cột 4 (Xác nhận)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFF101628),
              border: Border(bottom: BorderSide(color: Color(0xFF2E3B5F), width: 1.2)),
            ),
            child: const Row(
              children: [
                SizedBox(
                  width: 320,
                  child: Text('TÊN THÀNH VIÊN', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12.5)),
                ),
                SizedBox(
                  width: 180,
                  child: Text('XẾP HẠNG HIỆN TẠI', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12.5)),
                ),
                Expanded(
                  child: Text('VỊ TRÍ ĐẢM NHIỆM MỚI', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12.5)),
                ),
                SizedBox(
                  width: 120,
                  child: Text('XÁC NHẬN', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12.5)),
                ),
              ],
            ),
          ),

          // Dòng nhập liệu tìm kiếm, hiển thị badge và thanh Dropdown bar (Hình 2)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: const BoxDecoration(
              color: Color(0xFF161F36),
              border: Border(bottom: BorderSide(color: Color(0xFF242F50), width: 1)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // CỘT 1: Ô NHẬP LIỆU TÌM KIẾM (TextField)
                SizedBox(
                  width: 320,
                  child: Container(
                    height: 42,
                    decoration: BoxDecoration(
                      color: const Color(0xFF101628),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFF2E3B5F), width: 1.2),
                    ),
                    child: TextField(
                      controller: _t1SearchController,
                      style: const TextStyle(color: Colors.white, fontSize: 13.5),
                      decoration: InputDecoration(
                        hintText: 'Nhập hoặc dán username...',
                        hintStyle: const TextStyle(color: Colors.white38, fontSize: 12.5),
                        prefixIcon: const Icon(Icons.search, color: AdminColors.primary, size: 20),
                        suffixIcon: _t1IsSearching
                            ? const Padding(
                                padding: EdgeInsets.all(10),
                                child: SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: AdminColors.primary),
                                ),
                              )
                            : IconButton(
                                icon: const Icon(Icons.arrow_forward, color: Color(0xFFFFD700), size: 18),
                                tooltip: 'Tìm kiếm thành viên',
                                onPressed: _handleT1Search,
                              ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      onSubmitted: (_) => _handleT1Search(),
                    ),
                  ),
                ),

                // CỘT 2: XẾP HẠNG HIỆN TẠI (Nạp Badge từ PostgreSQL Docker)
                SizedBox(
                  width: 180,
                  child: Center(
                    child: _t1SearchedUser != null
                        ? UserRankBadgeWidget(
                            userId: _t1SearchedUser!['id'],
                            rankTitle: _t1SearchedUser!['rankTitle']?.toString() ??
                                _t1SearchedUser!['badge']?.toString() ??
                                'Thành viên',
                            starLevel: (_t1SearchedUser!['starLevel'] as num?)?.toInt() ?? 1,
                            width: 118,
                            height: 42,
                          )
                        : Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF101628),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.white12),
                            ),
                            child: const Text(
                              'Chưa có dữ liệu',
                              style: TextStyle(color: Colors.white38, fontSize: 11.5, fontStyle: FontStyle.italic),
                            ),
                          ),
                  ),
                ),

                // CỘT 3: VỊ TRÍ ĐẢM NHIỆM MỚI (Thanh Dropdown Bar nhỏ gọn chuẩn Hình 2)
                Expanded(
                  child: Center(
                    child: _buildT1DropdownBar(),
                  ),
                ),

                // CỘT 4: NÚT XÁC NHẬN
                SizedBox(
                  width: 120,
                  child: Center(
                    child: ElevatedButton(
                      onPressed: _confirmT1RoleUpdate,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AdminColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                        elevation: 2,
                      ),
                      child: const Text(
                        'Xác nhận',
                        style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Vùng hiển thị thông tin chi tiết của Thành viên được tìm thấy
          Expanded(
            child: _t1SearchedUser != null
                ? Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: const Color(0xFF101628),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF2E3B5F), width: 1.2),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.verified_user, color: AdminColors.primary, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Thông tin chi tiết: ${_t1SearchedUser!['username']}',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF132A1C),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: const Color(0xFF2E7D32)),
                                ),
                                child: const Text('Đã xác thực trong PostgreSQL Docker', style: TextStyle(color: Color(0xFF4CAF50), fontSize: 11)),
                              ),
                            ],
                          ),
                          const Divider(color: Color(0xFF2E3B5F), height: 20),
                          Wrap(
                            spacing: 24,
                            runSpacing: 12,
                            children: [
                              _buildT1InfoItem('User ID', '#${_t1SearchedUser!['id']}'),
                              _buildT1InfoItem('Tên đăng nhập', '${_t1SearchedUser!['username']}'),
                              _buildT1InfoItem('Vai trò hệ thống', '${_t1SearchedUser!['role']} (RoleId: ${_t1SearchedUser!['roleId']})'),
                              _buildT1InfoItem('Huy hiệu', '${_t1SearchedUser!['badge']}'),
                              _buildT1InfoItem('Cấp sao hiện tại', '${_t1SearchedUser!['starLevel']} sao'),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF161F36),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.info_outline, color: Color(0xFFFFD54F), size: 18),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Để cập nhật vị trí mới cho ${_t1SearchedUser!['username']}: Hãy chọn chức vụ tại cột "Vị trí Đảm nhiệm mới" ở trên và nhấn "Xác nhận". Hệ thống sẽ tự động kiểm tra tính duy nhất (Unique) trước khi đồng bộ SignalR tới toàn hệ thống.',
                                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.person_search_outlined, size: 54, color: Colors.white24),
                        const SizedBox(height: 12),
                        const Text(
                          'Nhập tên tài khoản (username) tại ô tìm kiếm phía trên để bắt đầu phân quyền',
                          style: TextStyle(color: Colors.white54, fontSize: 13.5),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Hệ thống sẽ tra cứu trực tiếp dữ liệu từ PostgreSQL Docker theo thời gian thực',
                          style: TextStyle(color: Colors.white30, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildT1InfoItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11.5)),
        const SizedBox(height: 3),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
      ],
    );
  }

  // Thanh Dropdown Bar nhỏ gọn chuẩn phong cách Hình 2
  Widget _buildT1DropdownBar() {
    return Container(
      height: 40,
      constraints: const BoxConstraints(maxWidth: 220),
      decoration: BoxDecoration(
        color: const Color(0xFF101628),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFF2E3B5F), width: 1.2),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 1)),
        ],
      ),
      child: PopupMenuButton<String>(
        initialValue: _t1SelectedRole,
        tooltip: 'Chọn Vị trí Đảm nhiệm mới',
        offset: const Offset(0, 44),
        color: const Color(0xFF131A30),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
          side: const BorderSide(color: Color(0xFF2E3B5F), width: 1.2),
        ),
        onSelected: (val) {
          setState(() {
            _t1SelectedRole = val;
          });
        },
        itemBuilder: (context) {
          return _availableRoles.map((role) {
            final isSelected = role == _t1SelectedRole;
            return PopupMenuItem<String>(
              value: role,
              height: 38,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF004D40) : Colors.transparent,
                  borderRadius: BorderRadius.circular(4),
                  border: isSelected ? Border.all(color: AdminColors.primary, width: 1) : null,
                ),
                child: Row(
                  children: [
                    Icon(
                      isSelected ? Icons.check_circle : Icons.circle_outlined,
                      color: isSelected ? AdminColors.primary : Colors.white38,
                      size: 14,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      role,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.white70,
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  _t1SelectedRole,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                height: 18,
                width: 1,
                color: const Color(0xFF2E3B5F),
                margin: const EdgeInsets.symmetric(horizontal: 8),
              ),
              const Icon(Icons.arrow_drop_down, color: Color(0xFFFFD700), size: 20),
            ],
          ),
        ),
      ),
    );
  }

  // --- BẢNG 2: NÂNG/GIẢM CẤP THÀNH VIÊN (CHUẨN 4 CỘT HÌNH 1 & HÌNH 2) ---
  Widget _buildTable2() {
    return AdminDataGridBox(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Bảng 2: Cột 1 (Tên Thành viên), Cột 2 (Xếp hạng Hiện tại), Cột 3 (Vị trí Đảm nhiệm mới), Cột 4 (Xác nhận)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFF101628),
              border: Border(bottom: BorderSide(color: Color(0xFF2E3B5F), width: 1.2)),
            ),
            child: const Row(
              children: [
                SizedBox(
                  width: 320,
                  child: Text('TÊN THÀNH VIÊN', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12.5)),
                ),
                SizedBox(
                  width: 180,
                  child: Text('XẾP HẠNG HIỆN TẠI', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12.5)),
                ),
                Expanded(
                  child: Text('VỊ TRÍ ĐẢM NHIỆM MỚI', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12.5)),
                ),
                SizedBox(
                  width: 120,
                  child: Text('XÁC NHẬN', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12.5)),
                ),
              ],
            ),
          ),

          // Dòng nhập liệu tìm kiếm, hiển thị badge và thanh Dropdown bar (Hình 2)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: const BoxDecoration(
              color: Color(0xFF161F36),
              border: Border(bottom: BorderSide(color: Color(0xFF242F50), width: 1)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // CỘT 1: Ô NHẬP LIỆU TÌM KIẾM (TextField)
                SizedBox(
                  width: 320,
                  child: Container(
                    height: 42,
                    decoration: BoxDecoration(
                      color: const Color(0xFF101628),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFF2E3B5F), width: 1.2),
                    ),
                    child: TextField(
                      controller: _t2SearchController,
                      style: const TextStyle(color: Colors.white, fontSize: 13.5),
                      decoration: InputDecoration(
                        hintText: 'Nhập hoặc dán username...',
                        hintStyle: const TextStyle(color: Colors.white38, fontSize: 12.5),
                        prefixIcon: const Icon(Icons.search, color: AdminColors.primary, size: 20),
                        suffixIcon: _t2IsSearching
                            ? const Padding(
                                padding: EdgeInsets.all(10),
                                child: SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: AdminColors.primary),
                                ),
                              )
                            : IconButton(
                                icon: const Icon(Icons.arrow_forward, color: Color(0xFFFFD700), size: 18),
                                tooltip: 'Tìm kiếm thành viên',
                                onPressed: _handleT2Search,
                              ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      onSubmitted: (_) => _handleT2Search(),
                    ),
                  ),
                ),

                // CỘT 2: XẾP HẠNG HIỆN TẠI (Nạp Badge từ PostgreSQL Docker chuẩn sao tím Hình 3, 6)
                SizedBox(
                  width: 180,
                  child: Center(
                    child: _t2SearchedUser != null
                        ? UserRankBadgeWidget(
                            userId: _t2SearchedUser!['id'],
                            rankTitle: _t2SearchedUser!['rankTitle']?.toString() ??
                                _t2SearchedUser!['badge']?.toString() ??
                                'Thành viên',
                            starLevel: (_t2SearchedUser!['starLevel'] as num?)?.toInt() ?? 1,
                            badgeType: 'badge_purple',
                            width: 118,
                            height: 42,
                          )
                        : Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF101628),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.white12),
                            ),
                            child: const Text(
                              'Chưa có dữ liệu',
                              style: TextStyle(color: Colors.white38, fontSize: 11.5, fontStyle: FontStyle.italic),
                            ),
                          ),
                  ),
                ),

                // CỘT 3: VỊ TRÍ ĐẢM NHIỆM MỚI (Thanh Dropdown Bar sổ dọc 9 vị trí chuẩn Hình 2)
                Expanded(
                  child: Center(
                    child: _buildT2DropdownBar(),
                  ),
                ),

                // CỘT 4: NÚT XÁC NHẬN
                SizedBox(
                  width: 120,
                  child: Center(
                    child: ElevatedButton(
                      onPressed: _confirmT2RankUpdate,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AdminColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                        elevation: 2,
                      ),
                      child: const Text(
                        'Xác nhận',
                        style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Vùng hiển thị thông tin chi tiết của Thành viên được tìm thấy
          Expanded(
            child: _t2SearchedUser != null
                ? Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: const Color(0xFF101628),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF2E3B5F), width: 1.2),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.verified_user, color: AdminColors.primary, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Thông tin chi tiết: ${_t2SearchedUser!['username']}',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF132A1C),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: const Color(0xFF2E7D32)),
                                ),
                                child: const Text('Đã xác thực trong PostgreSQL Docker', style: TextStyle(color: Color(0xFF4CAF50), fontSize: 11)),
                              ),
                            ],
                          ),
                          const Divider(color: Color(0xFF2E3B5F), height: 20),
                          Wrap(
                            spacing: 24,
                            runSpacing: 12,
                            children: [
                              _buildT1InfoItem('User ID', '#${_t2SearchedUser!['id']}'),
                              _buildT1InfoItem('Tên đăng nhập', '${_t2SearchedUser!['username']}'),
                              _buildT1InfoItem('Vai trò hệ thống', '${_t2SearchedUser!['role']} (RoleId: ${_t2SearchedUser!['roleId']})'),
                              _buildT1InfoItem('Xếp hạng hiện tại', '${_t2SearchedUser!['rankTitle'] ?? _t2SearchedUser!['badge'] ?? 'Thành viên'}'),
                              _buildT1InfoItem('Cấp sao hiện tại', '${_t2SearchedUser!['starLevel'] ?? 1} sao tím'),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF161F36),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.info_outline, color: Color(0xFFFFD54F), size: 18),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Để cập nhật cấp bậc thành viên cho ${_t2SearchedUser!['username']}: Hãy chọn cấp sao (từ "Thành viên 1 sao" đến "Thành viên 9 sao") tại cột "Vị trí Đảm nhiệm mới" ở trên và nhấn "Xác nhận". Hệ thống sẽ lưu dữ liệu xuống PostgreSQL Docker và broadcast SignalR tới toàn hệ thống.',
                                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.person_search_outlined, size: 54, color: Colors.white24),
                        const SizedBox(height: 12),
                        const Text(
                          'Nhập tên tài khoản (username) tại ô tìm kiếm phía trên để bắt đầu nâng/giảm cấp thành viên',
                          style: TextStyle(color: Colors.white54, fontSize: 13.5),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Hệ thống sẽ tra cứu trực tiếp dữ liệu từ PostgreSQL Docker theo thời gian thực',
                          style: TextStyle(color: Colors.white30, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // Thanh Dropdown Bar sổ dọc 9 vị trí (Thành viên 1 sao -> Thành viên 9 sao)
  Widget _buildT2DropdownBar() {
    final currentTitle = 'Thành viên $_t2SelectedStar sao';

    return Container(
      height: 40,
      constraints: const BoxConstraints(maxWidth: 220),
      decoration: BoxDecoration(
        color: const Color(0xFF101628),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFF2E3B5F), width: 1.2),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 1)),
        ],
      ),
      child: PopupMenuButton<int>(
        initialValue: _t2SelectedStar,
        tooltip: 'Chọn Cấp sao Thành viên mới',
        offset: const Offset(0, 44),
        color: const Color(0xFF131A30),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
          side: const BorderSide(color: Color(0xFF2E3B5F), width: 1.2),
        ),
        onSelected: (val) {
          setState(() {
            _t2SelectedStar = val;
          });
        },
        itemBuilder: (context) {
          return List.generate(9, (idx) {
            final starVal = idx + 1; // 1 đến 9 sao
            final title = 'Thành viên $starVal sao';
            final isSelected = starVal == _t2SelectedStar;

            return PopupMenuItem<int>(
              value: starVal,
              height: 38,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF004D40) : Colors.transparent,
                  borderRadius: BorderRadius.circular(4),
                  border: isSelected ? Border.all(color: AdminColors.primary, width: 1) : null,
                ),
                child: Row(
                  children: [
                    Icon(
                      isSelected ? Icons.check_circle : Icons.circle_outlined,
                      color: isSelected ? AdminColors.primary : Colors.white38,
                      size: 14,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      title,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.white70,
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            );
          });
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  currentTitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                height: 18,
                width: 1,
                color: const Color(0xFF2E3B5F),
                margin: const EdgeInsets.symmetric(horizontal: 8),
              ),
              const Icon(Icons.arrow_drop_down, color: Color(0xFFFFD700), size: 20),
            ],
          ),
        ),
      ),
    );
  }

  // Thanh Dropdown Bar sổ dọc 9 vị trí Đẳng vị Đại Sư (Nhất Đẳng -> Cửu Đẳng, sao đỏ #EF4444)
  Widget _buildT3DropdownBar() {
    final dangViMap = [
      'Nhất Đẳng', 'Nhị Đẳng', 'Tam Đẳng', 'Tứ Đẳng', 'Ngũ Đẳng',
      'Lục Đẳng', 'Thất Đẳng', 'Bát Đẳng', 'Cửu Đẳng'
    ];
    final currentTitle = dangViMap[(_t3SelectedStar - 1).clamp(0, 8)];

    return Container(
      height: 40,
      constraints: const BoxConstraints(maxWidth: 240),
      decoration: BoxDecoration(
        color: const Color(0xFF101628),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFF2E3B5F), width: 1.2),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 1)),
        ],
      ),
      child: PopupMenuButton<int>(
        initialValue: _t3SelectedStar,
        tooltip: 'Chọn Đẳng vị Đại Sư mới',
        offset: const Offset(0, 44),
        color: const Color(0xFF131A30),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
          side: const BorderSide(color: Color(0xFF2E3B5F), width: 1.2),
        ),
        onSelected: (val) {
          setState(() {
            _t3SelectedStar = val;
          });
        },
        itemBuilder: (context) {
          return List.generate(9, (idx) {
            final starVal = idx + 1; // 1 đến 9 sao đỏ
            final title = dangViMap[idx];
            final isSelected = starVal == _t3SelectedStar;

            return PopupMenuItem<int>(
              value: starVal,
              height: 38,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF3B1010) : Colors.transparent,
                  borderRadius: BorderRadius.circular(4),
                  border: isSelected ? Border.all(color: const Color(0xFFEF4444), width: 1) : null,
                ),
                child: Row(
                  children: [
                    Icon(
                      isSelected ? Icons.check_circle : Icons.circle_outlined,
                      color: isSelected ? const Color(0xFFEF4444) : Colors.white38,
                      size: 14,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      title,
                      style: TextStyle(
                        color: isSelected ? const Color(0xFFFFD54F) : Colors.white,
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Dải sao đỏ bắt buộc #EF4444
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(
                          starVal,
                          (s) => const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 0.5),
                            child: Icon(Icons.star, size: 10, color: Color(0xFFEF4444)),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          });
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Text(
                      currentTitle,
                      style: const TextStyle(
                        color: Color(0xFFFFD54F),
                        fontWeight: FontWeight.bold,
                        fontStyle: FontStyle.italic,
                        fontSize: 13,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(width: 6),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(
                        _t3SelectedStar,
                        (s) => const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 0.5),
                          child: Icon(Icons.star, size: 9, color: Color(0xFFEF4444)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                height: 18,
                width: 1,
                color: const Color(0xFF2E3B5F),
                margin: const EdgeInsets.symmetric(horizontal: 8),
              ),
              const Icon(Icons.arrow_drop_down, color: Color(0xFFFFD700), size: 20),
            ],
          ),
        ),
      ),
    );
  }

  // --- BẢNG 3: NÂNG/GIẢM CẤP ĐẠI SƯ (Hình 4 thiết kế lại 4 cột giống Hình 1) ---
  Widget _buildTable3() {
    final dangViMap = [
      'Nhất Đẳng', 'Nhị Đẳng', 'Tam Đẳng', 'Tứ Đẳng', 'Ngũ Đẳng',
      'Lục Đẳng', 'Thất Đẳng', 'Bát Đẳng', 'Cửu Đẳng'
    ];

    return AdminDataGridBox(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header 4 Cột cố định chuẩn Hình 1
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFF101628),
              border: Border(bottom: BorderSide(color: Color(0xFF2E3B5F), width: 1.2)),
            ),
            child: const Row(
              children: [
                // CỘT 1: TÊN THÀNH VIÊN
                SizedBox(
                  width: 320,
                  child: Text(
                    'TÊN THÀNH VIÊN',
                    style: TextStyle(
                      color: Color(0xFFFFD700),
                      fontWeight: FontWeight.bold,
                      fontSize: 12.5,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),

                // CỘT 2: XẾP HẠNG HIỆN TẠI
                SizedBox(
                  width: 180,
                  child: Text(
                    'XẾP HẠNG HIỆN TẠI',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFFFFD700),
                      fontWeight: FontWeight.bold,
                      fontSize: 12.5,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),

                // CỘT 3: VỊ TRÍ ĐẢM NHIỆM MỚI
                Expanded(
                  child: Text(
                    'VỊ TRÍ ĐẢM NHIỆM MỚI',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFFFFD700),
                      fontWeight: FontWeight.bold,
                      fontSize: 12.5,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),

                // CỘT 4: XÁC NHẬN
                SizedBox(
                  width: 120,
                  child: Text(
                    'XÁC NHẬN',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFFFFD700),
                      fontWeight: FontWeight.bold,
                      fontSize: 12.5,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Dòng nhập liệu tìm kiếm, hiển thị badge và thanh Dropdown bar (Hình 4)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: const BoxDecoration(
              color: Color(0xFF161F36),
              border: Border(bottom: BorderSide(color: Color(0xFF242F50), width: 1)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // CỘT 1: Ô NHẬP LIỆU TÌM KIẾM (TextField)
                SizedBox(
                  width: 320,
                  child: Container(
                    height: 42,
                    decoration: BoxDecoration(
                      color: const Color(0xFF101628),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFF2E3B5F), width: 1.2),
                    ),
                    child: TextField(
                      controller: _t3SearchController,
                      style: const TextStyle(color: Colors.white, fontSize: 13.5),
                      decoration: InputDecoration(
                        hintText: 'Nhập hoặc dán username...',
                        hintStyle: const TextStyle(color: Colors.white38, fontSize: 12.5),
                        prefixIcon: const Icon(Icons.search, color: AdminColors.primary, size: 20),
                        suffixIcon: _t3IsSearching
                            ? const Padding(
                                padding: EdgeInsets.all(10),
                                child: SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: AdminColors.primary),
                                ),
                              )
                            : IconButton(
                                icon: const Icon(Icons.arrow_forward, color: Color(0xFFFFD700), size: 18),
                                tooltip: 'Tìm kiếm Đại Sư / thành viên',
                                onPressed: _handleT3Search,
                              ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      onSubmitted: (_) => _handleT3Search(),
                    ),
                  ),
                ),

                // CỘT 2: XẾP HẠNG HIỆN TẠI (Nạp Badge từ PostgreSQL Docker chuẩn sao đỏ Hình 4, 8)
                SizedBox(
                  width: 180,
                  child: Center(
                    child: _t3SearchedUser != null
                        ? UserRankBadgeWidget(
                            userId: _t3SearchedUser!['id'],
                            rankTitle: _t3SearchedUser!['rankTitle']?.toString() ??
                                _t3SearchedUser!['badge']?.toString() ??
                                'Nhất Đẳng',
                            starLevel: (_t3SearchedUser!['starLevel'] as num?)?.toInt() ?? 1,
                            badgeType: 'badge_red',
                            width: 118,
                            height: 42,
                          )
                        : Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF101628),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.white12),
                            ),
                            child: const Text(
                              'Chưa có dữ liệu',
                              style: TextStyle(color: Colors.white38, fontSize: 11.5, fontStyle: FontStyle.italic),
                            ),
                          ),
                  ),
                ),

                // CỘT 3: VỊ TRÍ ĐẢM NHIỆM MỚI (Thanh Dropdown Bar sổ dọc 10 Đẳng vị sao đỏ Hình 4)
                Expanded(
                  child: Center(
                    child: _buildT3DropdownBar(),
                  ),
                ),

                // CỘT 4: NÚT XÁC NHẬN
                SizedBox(
                  width: 120,
                  child: Center(
                    child: ElevatedButton(
                      onPressed: _confirmT3RankUpdate,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AdminColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                        elevation: 2,
                      ),
                      child: const Text(
                        'Xác nhận',
                        style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Vùng hiển thị thông tin chi tiết của Đại Sư được tìm thấy
          Expanded(
            child: _t3SearchedUser != null
                ? Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: const Color(0xFF101628),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF2E3B5F), width: 1.2),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.verified_user, color: AdminColors.primary, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Thông tin chi tiết: ${_t3SearchedUser!['username']}${_t3SearchedUser!['masterName'] != null ? ' (${_t3SearchedUser!['masterName']})' : ''}',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF132A1C),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: const Color(0xFF2E7D32)),
                                ),
                                child: const Text('Đã xác thực trong PostgreSQL Docker', style: TextStyle(color: Color(0xFF4CAF50), fontSize: 11)),
                              ),
                            ],
                          ),
                          const Divider(color: Color(0xFF2E3B5F), height: 20),
                          Wrap(
                            spacing: 24,
                            runSpacing: 12,
                            children: [
                              _buildT1InfoItem('User ID', '#${_t3SearchedUser!['id']}'),
                              _buildT1InfoItem('Tên đăng nhập', '${_t3SearchedUser!['username']}'),
                              if (_t3SearchedUser!['masterName'] != null)
                                _buildT1InfoItem('Tên Đại Sư', '${_t3SearchedUser!['masterName']}'),
                              _buildT1InfoItem('Vai trò hệ thống', '${_t3SearchedUser!['role'] ?? 'User'}'),
                              _buildT1InfoItem('Huy hiệu', '${_t3SearchedUser!['badge'] ?? 'ĐẠI SƯ'}'),
                              _buildT1InfoItem('Cấp sao hiện tại', '${_t3SearchedUser!['starLevel'] ?? 1} sao đỏ'),
                              _buildT1InfoItem('Đẳng vị hiện tại', '${_t3SearchedUser!['rankTitle'] ?? 'Nhất Đẳng'}'),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF161F36),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0xFF2E3B5F)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.info_outline, color: Color(0xFFFFD700), size: 18),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Bạn đang chuẩn bị cập nhật Đại Sư "${_t3SearchedUser!['username']}" lên vị trí "${dangViMap[(_t3SelectedStar - 1).clamp(0, 9)]}" ($_t3SelectedStar sao đỏ). Nhấn "Xác nhận" để lưu vào PostgreSQL Docker.',
                                    style: const TextStyle(color: Colors.white70, fontSize: 12.5),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.person_search_outlined, color: Colors.white.withAlpha(50), size: 56),
                        const SizedBox(height: 12),
                        const Text(
                          'Nhập tên tài khoản (username) hoặc tên Đại Sư tại ô tìm kiếm phía trên để bắt đầu nâng/giảm cấp Đại Sư',
                          style: TextStyle(color: Colors.white54, fontSize: 13.5),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Hệ thống sẽ tra cứu trực tiếp dữ liệu từ PostgreSQL Docker theo thời gian thực',
                          style: TextStyle(color: Colors.white30, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
