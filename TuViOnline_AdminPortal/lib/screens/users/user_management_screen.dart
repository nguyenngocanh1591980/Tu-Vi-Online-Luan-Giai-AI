import 'package:flutter/material.dart';
import '../../services/admin_repository.dart';
import '../../services/signalr_service.dart';
import '../../theme/admin_colors.dart';
import '../../widgets/rbac_matrix_modal.dart';
import '../../widgets/user_rank_badge_widget.dart';
import '../../widgets/admin_data_grid_layout.dart';

class UserManagementScreen extends StatefulWidget {
  final String? initialRole;

  const UserManagementScreen({super.key, this.initialRole});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final AdminRepository _repo = AdminRepository();
  List<dynamic> _users = [];
  int _totalCount = 0;
  int _totalPages = 1;
  int _currentPage = 1;
  final int _pageSize = 25;
  String _selectedLetter = 'Tất cả';
  String? _selectedRole;
  bool _isLoading = true;
  int? _highlightedUserId;

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final ScrollController _horizontalScrollController = ScrollController();
  final ScrollController _verticalScrollController = ScrollController();

  final List<String> _allowedRoles = const [
    'Admin',
    'Sáng Lập',
    'Điều hành',
    'Tư Vấn',
    'Quản Lý',
    'Moderator',
    'User'
  ];

  final List<String> _alphabet = const [
    'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M',
    'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z'
  ];

  void _scrollToStart() {
    if (_horizontalScrollController.hasClients) {
      _horizontalScrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _scrollToEnd() {
    if (_horizontalScrollController.hasClients) {
      _horizontalScrollController.animateTo(
        _horizontalScrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.initialRole;
    _loadUsers();
    signalRService.listenToUserRoleChanged(_onUserRoleChangedSignalR);
    signalRService.listenToUserRankChanged(_onUserRankChangedSignalR);
    signalRService.listenToUserRoleRevoked(_onUserRoleRevokedSignalR);
    signalRService.listenToMasterProfileUpdated(_onMasterProfileUpdatedSignalR);
    signalRService.listenToUserStatusChanged(_onUserStatusChangedSignalR);
  }

  @override
  void dispose() {
    signalRService.removeUserRoleChangedListener();
    signalRService.removeUserRankChangedListener();
    signalRService.removeUserRoleRevokedListener();
    signalRService.removeMasterProfileUpdatedListener();
    signalRService.removeUserStatusChangedListener();
    _searchController.dispose();
    _searchFocusNode.dispose();
    _horizontalScrollController.dispose();
    _verticalScrollController.dispose();
    super.dispose();
  }

  void _onMasterProfileUpdatedSignalR(List<Object?>? args) {
    if (mounted) {
      _loadUsers();
    }
  }

  void _onUserStatusChangedSignalR(List<Object?>? args) {
    if (mounted) {
      _loadUsers();
    }
  }

  void _onUserRoleChangedSignalR(List<Object?>? args) {
    if (mounted) {
      _loadUsers();
    }
  }

  void _onUserRankChangedSignalR(List<Object?>? args) {
    if (mounted) {
      if (args != null && args.isNotEmpty && args[0] is Map) {
        final map = args[0] as Map;
        final userId = map['userId'] as int?;
        final username = map['username']?.toString() ?? '';
        if (userId != null) {
          _handleAfterMemberRankUpdated(userId, username);
          return;
        }
      }
      _loadUsers();
    }
  }

  Future<void> _handleAfterMemberRankUpdated(int? userId, String username) async {
    setState(() {
      _selectedLetter = 'Tất cả';
      _selectedRole = null;
      _searchController.clear();
      _highlightedUserId = userId;
      _currentPage = 1;
    });

    await _loadUsers();

    if (!mounted || userId == null) return;

    int targetIndex = _users.indexWhere((u) => u['id'] == userId || u['username']?.toString().toLowerCase() == username.toLowerCase());

    if (targetIndex == -1 && _totalPages > 1) {
      for (int p = 2; p <= _totalPages; p++) {
        final res = await _repo.fetchUsersPaginated(
          page: p,
          pageSize: _pageSize,
        );
        final items = (res['items'] as List<dynamic>?) ?? [];
        final idx = items.indexWhere((u) => u['id'] == userId || u['username']?.toString().toLowerCase() == username.toLowerCase());
        if (idx != -1) {
          if (!mounted) return;
          setState(() {
            _currentPage = p;
            _users = items;
            _totalCount = (res['totalCount'] as int?) ?? _users.length;
            _totalPages = (res['totalPages'] as int?) ?? _totalPages;
          });
          targetIndex = idx;
          break;
        }
      }
    }

    if (targetIndex != -1 && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_verticalScrollController.hasClients && _verticalScrollController.position.hasContentDimensions) {
          const double rowHeight = 52.0;
          final double targetOffset = (targetIndex * rowHeight).clamp(0.0, _verticalScrollController.position.maxScrollExtent);
          _verticalScrollController.animateTo(
            targetOffset,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOutCubic,
          );
        }
      });
    }

    Future.delayed(const Duration(seconds: 4), () {
      if (mounted && _highlightedUserId == userId) {
        setState(() {
          _highlightedUserId = null;
        });
      }
    });
  }

  void _onUserRoleRevokedSignalR(List<Object?>? args) {
    if (mounted) {
      _loadUsers();
    }
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    final res = await _repo.fetchUsersPaginated(
      page: _currentPage,
      pageSize: _pageSize,
      search: _searchController.text.trim(),
      letter: _selectedLetter,
      role: _selectedRole,
    );
    if (mounted) {
      setState(() {
        _users = (res['items'] as List<dynamic>?) ?? [];
        _totalCount = (res['totalCount'] as int?) ?? _users.length;
        _totalPages = (res['totalPages'] as int?) ?? 1;
        _currentPage = (res['page'] as int?) ?? _currentPage;
        _isLoading = false;
      });
    }
  }

  void _onSearch() {
    setState(() {
      _currentPage = 1;
    });
    _loadUsers();
  }

  String _mapCurrentRole(dynamic u) {
    final rawRole = (u['role']?.toString() ?? 'User').toLowerCase();
    final badgeText = (u['badgeText']?.toString() ?? (u['badge']?.toString() ?? '')).toLowerCase();
    final rankTitle = (u['rankTitle']?.toString() ?? '').toLowerCase();

    if (rawRole == 'super_admin' || badgeText.contains('sáng lập') || rankTitle.contains('sáng lập')) {
      return 'Sáng Lập';
    } else if (badgeText.contains('quản trị') || rankTitle.contains('quản trị') || (rawRole == 'admin' && badgeText.contains('admin'))) {
      return 'Admin';
    } else if (badgeText.contains('quản lý') || rankTitle.contains('quản lý') || rawRole == 'admin') {
      return 'Quản Lý';
    } else if (badgeText.contains('tư vấn') || rankTitle.contains('tư vấn')) {
      return 'Tư Vấn';
    } else if (badgeText.contains('điều hành') || rankTitle.contains('điều hành')) {
      return 'Điều hành';
    } else if (rawRole == 'moderator') {
      return 'Moderator';
    } else {
      return 'User';
    }
  }

  bool _isUniqueRoleHolder(dynamic u) {
    final role = _mapCurrentRole(u);
    return role == 'Admin' || role == 'Sáng Lập';
  }

  void _showWarningDialog({required String title, required String message}) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF161F36),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: Color(0xFFEF4444), width: 1.2),
        ),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444), size: 24),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(color: Colors.white70, fontSize: 13.5, height: 1.5),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AdminColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
            child: const Text('Đã hiểu'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleRoleChangeRequest(dynamic u, String currentRole, String newRole) async {
    final userId = int.tryParse(u['id'].toString()) ?? 0;

    // Ràng buộc bảo vệ Admin/Sáng Lập cũ
    if (_isUniqueRoleHolder(u) && newRole != currentRole) {
      _showWarningDialog(
        title: 'Cảnh báo vi phạm vị trí',
        message: 'Không thể hạ quyền trực tiếp của User đang giữ chức vụ $currentRole! Vui lòng gỡ chức vụ tại bảng Quản lý Ban Quản Trị trước.',
      );
      return;
    }

    // Ràng buộc vị trí duy nhất khi chọn Admin/Sáng Lập mới
    if (newRole == 'Admin' || newRole == 'Sáng Lập') {
      final checkRes = await _repo.checkRoleHolder(newRole, excludeUserId: userId);
      if (!mounted) return;
      if (checkRes['exists'] == true) {
        _showWarningDialog(
          title: 'Vị trí duy nhất đã có người giữ',
          message: checkRes['message'] ?? 'Vị trí $newRole là duy nhất và hiện đã có người nắm giữ! Vui lòng chuyển sang màn hình Quản lý Ban Quản Trị để hủy vị trí cũ trước.',
        );
        return;
      }
    }

    if (!mounted) return;
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF161F36),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: Color(0xFF2E3B5F), width: 1.2),
        ),
        title: const Text('Xác nhận đổi quyền', style: TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.bold)),
        content: Text(
          'Bạn có chắc chắn muốn đổi quyền của user "${u['username']}" từ "$currentRole" sang "$newRole"?',
          style: const TextStyle(color: Colors.white70, fontSize: 13.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AdminColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
            child: const Text('Xác nhận', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (!mounted) return;
    if (confirm == true) {
      _updateRole(u['id'].toString(), newRole);
    }
  }

  Future<void> _updateRole(String id, String newRole) async {
    final userId = int.tryParse(id) ?? 0;
    final res = await _repo.updateUser(userId, {'role': newRole});
    if (!mounted) return;

    if (res['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message'] ?? 'Cập nhật vai trò thành công'),
          backgroundColor: AdminColors.success,
        ),
      );
      _loadUsers();
    } else {
      _showWarningDialog(
        title: 'Cập nhật thất bại',
        message: res['message'] ?? 'Không thể cập nhật vai trò người dùng.',
      );
    }
  }

  Future<void> _handleLockAccount(dynamic u, String currentRole) async {
    if (_isUniqueRoleHolder(u)) {
      _showWarningDialog(
        title: 'Không thể khóa tài khoản',
        message: 'Không thể khóa tài khoản đang giữ chức vụ $currentRole! Vui lòng gỡ chức vụ tại bảng Quản lý Ban Quản Trị trước.',
      );
      return;
    }

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF161F36),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: Color(0xFFEF4444), width: 1.2),
        ),
        title: const Text('Xác nhận khóa tài khoản', style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.bold)),
        content: Text(
          'Bạn có chắc chắn muốn KHÓA tài khoản của thành viên "${u['username']}"? Người dùng này sẽ không thể đăng nhập hoặc thao tác trên hệ thống.',
          style: const TextStyle(color: Colors.white70, fontSize: 13.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
            child: const Text('Khóa Tài Khoản', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final userId = int.tryParse(u['id'].toString()) ?? 0;
      final res = await _repo.updateUserStatusDirect(userId, false);
      if (!mounted) return;

      if (res['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã khóa tài khoản thành viên "${u['username']}".'),
            backgroundColor: AdminColors.error,
          ),
        );
        _loadUsers();
      } else {
        _showWarningDialog(
          title: 'Khóa tài khoản thất bại',
          message: res['message'] ?? 'Không thể cập nhật trạng thái tài khoản.',
        );
      }
    }
  }

  Future<void> _handleUnlockAccount(dynamic u) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF161F36),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: Color(0xFF10B981), width: 1.2),
        ),
        title: const Text('Xác nhận mở khóa tài khoản', style: TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold)),
        content: Text(
          'Bạn có chắc chắn muốn MỞ KHÓA tài khoản của thành viên "${u['username']}"? Người dùng sẽ được phép đăng nhập và sử dụng hệ thống bình thường.',
          style: const TextStyle(color: Colors.white70, fontSize: 13.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
            child: const Text('Mở Khóa', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final userId = int.tryParse(u['id'].toString()) ?? 0;
      final res = await _repo.updateUserStatusDirect(userId, true);
      if (!mounted) return;

      if (res['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã mở khóa tài khoản thành viên "${u['username']}".'),
            backgroundColor: AdminColors.success,
          ),
        );
        _loadUsers();
      } else {
        _showWarningDialog(
          title: 'Mở khóa thất bại',
          message: res['message'] ?? 'Không thể cập nhật trạng thái tài khoản.',
        );
      }
    }
  }

  Future<void> _handleDeleteUser(dynamic u, String currentRole) async {
    if (_isUniqueRoleHolder(u)) {
      _showWarningDialog(
        title: 'Không thể xóa user này',
        message: 'Không thể xóa trực tiếp tài khoản đang giữ chức vụ $currentRole! Vui lòng gỡ chức vụ tại bảng Quản lý Ban Quản Trị trước.',
      );
      return;
    }

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF161F36),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
        ),
        title: const Row(
          children: [
            Icon(Icons.delete_forever, color: Color(0xFFEF4444), size: 26),
            SizedBox(width: 10),
            Text('Xác nhận xóa người dùng', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'CẢNH BÁO NGUY HIỂM: Bạn có chắc chắn muốn xóa vĩnh viễn user "${u['username']}" khỏi hệ thống?',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13.5),
            ),
            const SizedBox(height: 8),
            const Text(
              'Toàn bộ dữ liệu của thành viên này sẽ bị xóa khỏi cơ sở dữ liệu PostgreSQL Docker và KHÔNG THỂ KHÔI PHỤC.',
              style: TextStyle(color: Colors.white60, fontSize: 13, height: 1.4),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF991B1B),
              side: const BorderSide(color: Color(0xFFEF4444), width: 1),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
            child: const Text('Xác nhận Xóa Vĩnh Viễn', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final userId = int.tryParse(u['id'].toString()) ?? 0;
      final res = await _repo.deleteUser(userId);
      if (!mounted) return;

      if (res['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['message'] ?? 'Đã xóa người dùng thành công'),
            backgroundColor: AdminColors.error,
          ),
        );
        _loadUsers();
      } else {
        _showWarningDialog(
          title: 'Xóa user thất bại',
          message: res['message'] ?? 'Có lỗi xảy ra khi xóa người dùng.',
        );
      }
    }
  }

  String _formatNowVnTime() {
    final now = DateTime.now().toUtc().add(const Duration(hours: 7));
    final hh = now.hour.toString().padLeft(2, '0');
    final mm = now.minute.toString().padLeft(2, '0');
    final dd = now.day.toString().padLeft(2, '0');
    final mo = now.month.toString().padLeft(2, '0');
    final yy = (now.year % 100).toString().padLeft(2, '0');
    return '$hh:$mm, $dd/$mo/$yy';
  }

  void _openAddUserModal() {
    final usernameCtrl = TextEditingController();
    final postsCtrl = TextEditingController(text: '0');
    final websiteCtrl = TextEditingController();
    final joinDateCtrl = TextEditingController(text: _formatNowVnTime());
    String selectedRole = 'User';
    bool isActive = true;
    int starLevel = 1;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          Widget previewBadge;
          if (selectedRole == 'Sáng Lập') {
            previewBadge = const UserRankBadgeWidget(
              rankTitle: 'Sáng Lập',
              starLevel: 1,
              ribbonAsset: 'assets/images/ribbon_sang_lap.png',
              width: 110,
              height: 38,
            );
          } else if (selectedRole == 'Admin') {
            previewBadge = const UserRankBadgeWidget(
              rankTitle: 'Quản trị viên',
              starLevel: 2,
              ribbonAsset: 'assets/images/ribbon_quan_ly.png',
              width: 110,
              height: 38,
            );
          } else if (selectedRole == 'Quản Lý') {
            previewBadge = const UserRankBadgeWidget(
              rankTitle: 'Quản Lý',
              starLevel: 2,
              ribbonAsset: 'assets/images/ribbon_quan_ly.png',
              width: 110,
              height: 38,
            );
          } else if (selectedRole == 'Điều hành' || selectedRole == 'Moderator') {
            previewBadge = const UserRankBadgeWidget(
              rankTitle: 'Điều Hành',
              starLevel: 2,
              ribbonAsset: 'assets/images/ribbon_dieu_hanh.png',
              width: 110,
              height: 38,
            );
          } else if (selectedRole == 'Tư Vấn') {
            previewBadge = const UserRankBadgeWidget(
              rankTitle: 'Tư Vấn',
              starLevel: 2,
              ribbonAsset: 'assets/images/ribbon_tu_van.png',
              width: 110,
              height: 38,
            );
          } else {
            previewBadge = UserRankBadgeWidget(
              rankTitle: 'Thành viên',
              starLevel: starLevel,
              badgeType: 'badge_yellow',
              width: 110,
              height: 38,
            );
          }

          return AlertDialog(
            backgroundColor: const Color(0xFF161F36),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: const BorderSide(color: Color(0xFF2E3B5F), width: 1.5),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.person_add_alt_1_rounded, color: Color(0xFF60A5FA), size: 22),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Thêm 1 Dòng Dữ Liệu User Mới',
                  style: TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            content: SizedBox(
              width: 580,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('1. Tên đăng nhập (*)', style: TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: usernameCtrl,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Nhập tên đăng nhập...',
                        hintStyle: const TextStyle(color: Colors.white38),
                        filled: true,
                        fillColor: const Color(0xFF0F1524),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Color(0xFF2E3B5F))),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                    const SizedBox(height: 14),

                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('2. Nhóm Chính (*)', style: TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0F1524),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: const Color(0xFF2E3B5F)),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: selectedRole,
                                    isExpanded: true,
                                    dropdownColor: const Color(0xFF131A30),
                                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                                    items: _allowedRoles.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                                    onChanged: (val) {
                                      if (val != null) {
                                        setModalState(() {
                                          selectedRole = val;
                                        });
                                      }
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('3. Xếp hạng (Badge)', style: TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 6),
                              Container(
                                height: 42,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0F1524),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: const Color(0xFF2E3B5F)),
                                ),
                                child: previewBadge,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('4. Bài viết', style: TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 6),
                              TextField(
                                controller: postsCtrl,
                                keyboardType: TextInputType.number,
                                style: const TextStyle(color: Colors.white, fontSize: 13),
                                decoration: InputDecoration(
                                  hintText: '0',
                                  filled: true,
                                  fillColor: const Color(0xFF0F1524),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Color(0xFF2E3B5F))),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('5. Website', style: TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 6),
                              TextField(
                                controller: websiteCtrl,
                                style: const TextStyle(color: Colors.white, fontSize: 13),
                                decoration: InputDecoration(
                                  hintText: 'https://...',
                                  filled: true,
                                  fillColor: const Color(0xFF0F1524),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Color(0xFF2E3B5F))),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('6. Thời gian tham gia', style: TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 6),
                              TextField(
                                controller: joinDateCtrl,
                                style: const TextStyle(color: Colors.white, fontSize: 13),
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: const Color(0xFF0F1524),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Color(0xFF2E3B5F))),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('7. Trạng thái hoạt động', style: TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0F1524),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: const Color(0xFF2E3B5F)),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<bool>(
                                    value: isActive,
                                    isExpanded: true,
                                    dropdownColor: const Color(0xFF131A30),
                                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                                    items: const [
                                      DropdownMenuItem(value: true, child: Text('Hoạt động (Mở Khóa)', style: TextStyle(color: Color(0xFF10B981)))),
                                      DropdownMenuItem(value: false, child: Text('Bị Khóa', style: TextStyle(color: Color(0xFFEF4444)))),
                                    ],
                                    onChanged: (val) {
                                      if (val != null) {
                                        setModalState(() {
                                          isActive = val;
                                        });
                                      }
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton.icon(
                onPressed: () async {
                  final username = usernameCtrl.text.trim();
                  if (username.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Vui lòng nhập tên đăng nhập!'), backgroundColor: AdminColors.error),
                    );
                    return;
                  }

                  // Kiểm tra vị trí duy nhất Admin / Sáng Lập
                  if (selectedRole == 'Admin' || selectedRole == 'Sáng Lập') {
                    final checkRes = await _repo.checkRoleHolder(selectedRole);
                    if (checkRes['exists'] == true) {
                      _showWarningDialog(
                        title: 'Vị trí duy nhất đã có người giữ',
                        message: checkRes['message'] ?? 'Vị trí $selectedRole là duy nhất và hiện đã có người nắm giữ! Vui lòng chuyển sang màn hình Quản lý Ban Quản Trị để hủy vị trí cũ trước.',
                      );
                      return;
                    }
                  }

                  final payload = {
                    'username': username,
                    'role': selectedRole,
                    'starLevel': starLevel,
                    'rankTitle': selectedRole == 'Sáng Lập' ? 'Sáng Lập' : (selectedRole == 'Admin' ? 'Quản trị viên' : (selectedRole == 'Quản Lý' ? 'Quản lý' : 'Thành viên')),
                    'postCount': int.tryParse(postsCtrl.text.trim()) ?? 0,
                    'website': websiteCtrl.text.trim(),
                    'joinDate': joinDateCtrl.text.trim(),
                    'isActive': isActive,
                  };

                  final res = await _repo.createUser(payload);
                  if (!ctx.mounted) return;

                  if (res['success'] == true) {
                    Navigator.of(ctx).pop();
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(res['message'] ?? 'Thêm 1 dòng dữ liệu user mới thành công!'),
                        backgroundColor: AdminColors.success,
                      ),
                    );
                    _loadUsers();
                  } else {
                    if (!mounted) return;
                    _showWarningDialog(
                      title: 'Thêm user thất bại',
                      message: res['message'] ?? 'Không thể lưu dữ liệu xuống cơ sở dữ liệu.',
                    );
                  }
                },
                icon: const Icon(Icons.check, size: 16),
                label: const Text('Lưu Dữ Liệu User'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _openEditUserModal(dynamic u, String currentRole) {
    final userId = int.tryParse(u['id'].toString()) ?? 0;
    final usernameCtrl = TextEditingController(text: u['username']?.toString() ?? '');
    final postsCtrl = TextEditingController(text: (u['posts'] ?? u['postCount'] ?? 0).toString());
    final websiteCtrl = TextEditingController(text: u['website']?.toString() ?? '');
    final joinDateCtrl = TextEditingController(text: u['joinDate']?.toString() ?? (u['createdAt']?.toString() ?? ''));
    String selectedRole = currentRole;
    bool isActive = (u['isActive'] as bool?) ?? true;
    int starLevel = (u['starLevel'] as num?)?.toInt() ?? 1;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          Widget previewBadge;
          if (selectedRole == 'Sáng Lập') {
            previewBadge = UserRankBadgeWidget(
              userId: u['id'],
              rankTitle: 'Sáng Lập',
              starLevel: 1,
              ribbonAsset: 'assets/images/ribbon_sang_lap.png',
              width: 118,
              height: 42,
            );
          } else if (selectedRole == 'Admin') {
            previewBadge = UserRankBadgeWidget(
              userId: u['id'],
              rankTitle: 'Quản trị viên',
              starLevel: 2,
              ribbonAsset: 'assets/images/ribbon_quan_ly.png',
              width: 118,
              height: 42,
            );
          } else if (selectedRole == 'Quản Lý') {
            previewBadge = UserRankBadgeWidget(
              userId: u['id'],
              rankTitle: 'Quản Lý',
              starLevel: 2,
              ribbonAsset: 'assets/images/ribbon_quan_ly.png',
              width: 118,
              height: 42,
            );
          } else if (selectedRole == 'Điều hành' || selectedRole == 'Moderator') {
            previewBadge = UserRankBadgeWidget(
              userId: u['id'],
              rankTitle: 'Điều Hành',
              starLevel: 2,
              ribbonAsset: 'assets/images/ribbon_dieu_hanh.png',
              width: 118,
              height: 42,
            );
          } else if (selectedRole == 'Tư Vấn') {
            previewBadge = UserRankBadgeWidget(
              userId: u['id'],
              rankTitle: 'Tư Vấn',
              starLevel: 2,
              ribbonAsset: 'assets/images/ribbon_tu_van.png',
              width: 118,
              height: 42,
            );
          } else {
            previewBadge = UserRankBadgeWidget(
              userId: u['id'],
              rankTitle: 'Thành viên',
              starLevel: starLevel,
              badgeType: u['badgeType']?.toString() ?? 'badge_purple',
              width: 118,
              height: 42,
            );
          }

          return AlertDialog(
            backgroundColor: const Color(0xFF161F36),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: const BorderSide(color: Color(0xFF2E3B5F), width: 1.5),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.edit_note_rounded, color: Color(0xFF60A5FA), size: 22),
                ),
                const SizedBox(width: 10),
                Text(
                  'Sửa Dữ Liệu User: ${u['username']}',
                  style: const TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            content: SizedBox(
              width: 580,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('1. Tên đăng nhập', style: TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: usernameCtrl,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFF0F1524),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Color(0xFF2E3B5F))),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                    const SizedBox(height: 14),

                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('2. Nhóm Chính', style: TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0F1524),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: const Color(0xFF2E3B5F)),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: selectedRole,
                                    isExpanded: true,
                                    dropdownColor: const Color(0xFF131A30),
                                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                                    items: _allowedRoles.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                                    onChanged: (val) {
                                      if (val != null) {
                                        setModalState(() {
                                          selectedRole = val;
                                        });
                                      }
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('3. Xếp hạng (Badge)', style: TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 6),
                              Container(
                                height: 42,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0F1524),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: const Color(0xFF2E3B5F)),
                                ),
                                child: previewBadge,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('4. Bài viết', style: TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 6),
                              TextField(
                                controller: postsCtrl,
                                keyboardType: TextInputType.number,
                                style: const TextStyle(color: Colors.white, fontSize: 13),
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: const Color(0xFF0F1524),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Color(0xFF2E3B5F))),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('5. Website', style: TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 6),
                              TextField(
                                controller: websiteCtrl,
                                style: const TextStyle(color: Colors.white, fontSize: 13),
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: const Color(0xFF0F1524),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Color(0xFF2E3B5F))),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('6. Thời gian tham gia', style: TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 6),
                              TextField(
                                controller: joinDateCtrl,
                                style: const TextStyle(color: Colors.white, fontSize: 13),
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: const Color(0xFF0F1524),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Color(0xFF2E3B5F))),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('7. Trạng thái hoạt động', style: TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0F1524),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: const Color(0xFF2E3B5F)),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<bool>(
                                    value: isActive,
                                    isExpanded: true,
                                    dropdownColor: const Color(0xFF131A30),
                                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                                    items: const [
                                      DropdownMenuItem(value: true, child: Text('Hoạt động (Mở Khóa)', style: TextStyle(color: Color(0xFF10B981)))),
                                      DropdownMenuItem(value: false, child: Text('Bị Khóa', style: TextStyle(color: Color(0xFFEF4444)))),
                                    ],
                                    onChanged: (val) {
                                      if (val != null) {
                                        setModalState(() {
                                          isActive = val;
                                        });
                                      }
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton.icon(
                onPressed: () async {
                  final username = usernameCtrl.text.trim();
                  if (username.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Vui lòng nhập tên đăng nhập!'), backgroundColor: AdminColors.error),
                    );
                    return;
                  }

                  if (_isUniqueRoleHolder(u) && selectedRole != currentRole) {
                    _showWarningDialog(
                      title: 'Cảnh báo vi phạm vị trí',
                      message: 'Không thể hạ quyền trực tiếp của User đang giữ chức vụ $currentRole! Vui lòng gỡ chức vụ tại bảng Quản lý Ban Quản Trị trước.',
                    );
                    return;
                  }

                  if ((selectedRole == 'Admin' || selectedRole == 'Sáng Lập') && selectedRole != currentRole) {
                    final checkRes = await _repo.checkRoleHolder(selectedRole, excludeUserId: userId);
                    if (checkRes['exists'] == true) {
                      _showWarningDialog(
                        title: 'Vị trí duy nhất đã có người giữ',
                        message: checkRes['message'] ?? 'Vị trí $selectedRole là duy nhất và hiện đã có người nắm giữ! Vui lòng chuyển sang màn hình Quản lý Ban Quản Trị để hủy vị trí cũ trước.',
                      );
                      return;
                    }
                  }

                  final payload = {
                    'username': username,
                    'role': selectedRole,
                    'starLevel': starLevel,
                    'postCount': int.tryParse(postsCtrl.text.trim()) ?? 0,
                    'website': websiteCtrl.text.trim(),
                    'joinDate': joinDateCtrl.text.trim(),
                    'isActive': isActive,
                  };

                  final res = await _repo.updateUser(userId, payload);
                  if (!ctx.mounted) return;

                  if (res['success'] == true) {
                    Navigator.of(ctx).pop();
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(res['message'] ?? 'Cập nhật dữ liệu User thành công!'),
                        backgroundColor: AdminColors.success,
                      ),
                    );
                    _loadUsers();
                  } else {
                    if (!mounted) return;
                    _showWarningDialog(
                      title: 'Cập nhật thất bại',
                      message: res['message'] ?? 'Không thể lưu thay đổi vào cơ sở dữ liệu.',
                    );
                  }
                },
                icon: const Icon(Icons.save, size: 16),
                label: const Text('Lưu Thay Đổi'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B82F6),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

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
            onTap: () => _searchFocusNode.requestFocus(),
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
                _selectedRole = null;
                _currentPage = 1;
              });
              _loadUsers();
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
          for (final letter in _alphabet)
            InkWell(
              onTap: () {
                setState(() {
                  _selectedLetter = letter;
                  _currentPage = 1;
                });
                _loadUsers();
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
          const Text('•', style: TextStyle(color: Colors.white54, fontSize: 13)),
          InkWell(
            onTap: () => _searchFocusNode.requestFocus(),
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

  Widget _buildUserRow(dynamic u, int index) {
    final isHighlighted = _highlightedUserId != null && (u['id'] == _highlightedUserId);
    final isEven = index % 2 == 0;
    final rowBg = isHighlighted
        ? const Color(0xFF1E3A5F)
        : (isEven ? const Color(0xFF1A233E) : const Color(0xFF151C33));

    final username = u['username']?.toString() ?? 'N/A';
    final badgeText = u['badgeText']?.toString() ?? (u['badge']?.toString() ?? 'THÀNH VIÊN');
    final badgeType = u['badgeType']?.toString() ?? 'badge_yellow';
    final posts = u['posts'] ?? u['postCount'] ?? 0;
    final website = u['website']?.toString() ?? '';
    final joinDate = u['joinDate']?.toString() ?? (u['createdAt']?.toString() ?? '');
    final isActive = (u['isActive'] as bool?) ?? true;
    final nameColor = AdminColors.realDataText;

    final currentRole = _mapCurrentRole(u);

    Widget rankWidget;
    if (currentRole == 'Sáng Lập') {
      rankWidget = UserRankBadgeWidget(
        userId: u['id'],
        rankTitle: 'Sáng Lập',
        starLevel: 1,
        ribbonAsset: 'assets/images/ribbon_sang_lap.png',
        width: 118,
        height: 42,
      );
    } else if (currentRole == 'Admin') {
      rankWidget = UserRankBadgeWidget(
        userId: u['id'],
        rankTitle: 'Quản trị viên',
        starLevel: 2,
        ribbonAsset: 'assets/images/ribbon_quan_ly.png',
        width: 118,
        height: 42,
      );
    } else if (currentRole == 'Quản Lý') {
      rankWidget = UserRankBadgeWidget(
        userId: u['id'],
        rankTitle: 'Quản Lý',
        starLevel: 2,
        ribbonAsset: 'assets/images/ribbon_quan_ly.png',
        width: 118,
        height: 42,
      );
    } else if (currentRole == 'Điều hành' || currentRole == 'Moderator') {
      rankWidget = UserRankBadgeWidget(
        userId: u['id'],
        rankTitle: 'Điều Hành',
        starLevel: 2,
        ribbonAsset: 'assets/images/ribbon_dieu_hanh.png',
        width: 118,
        height: 42,
      );
    } else if (currentRole == 'Tư Vấn') {
      rankWidget = UserRankBadgeWidget(
        userId: u['id'],
        rankTitle: 'Tư Vấn',
        starLevel: 2,
        ribbonAsset: 'assets/images/ribbon_tu_van.png',
        width: 118,
        height: 42,
      );
    } else if (badgeText.toLowerCase().contains('đại sư') || (u['rankTitle']?.toString().toLowerCase().contains('đẳng') == true)) {
      rankWidget = UserRankBadgeWidget(
        userId: u['id'],
        rankTitle: u['rankTitle']?.toString() ?? 'Nhất Đẳng',
        starLevel: (u['starLevel'] as num?)?.toInt() ?? 1,
        width: 118,
        height: 42,
      );
    } else {
      rankWidget = UserRankBadgeWidget(
        userId: u['id'],
        rankTitle: 'Thành viên',
        starLevel: (u['starLevel'] as num?)?.toInt() ?? 1,
        badgeType: badgeType,
        width: 118,
        height: 42,
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: rowBg,
        border: isHighlighted
            ? Border.all(color: const Color(0xFFFFD700), width: 1.8)
            : const Border(
                bottom: BorderSide(color: Color(0xFF242F50), width: 0.8),
              ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 1. TÊN ĐĂNG NHẬP (260px)
          SizedBox(
            width: 260,
            child: Text(
              username,
              style: TextStyle(
                color: nameColor,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // 2. XẾP HẠNG (180px)
          SizedBox(
            width: 180,
            child: Center(
              child: rankWidget,
            ),
          ),

          // 3. BÀI VIẾT (140px)
          SizedBox(
            width: 140,
            child: Text(
              '$posts',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[300],
                fontSize: 12.5,
              ),
            ),
          ),

          // 4. WEBSITE (240px)
          SizedBox(
            width: 240,
            child: website.isNotEmpty
                ? Text(
                    website,
                    style: const TextStyle(
                      color: Color(0xFFEF5350),
                      fontSize: 11.5,
                      decoration: TextDecoration.underline,
                    ),
                    overflow: TextOverflow.ellipsis,
                  )
                : const SizedBox.shrink(),
          ),

          // 5. THAM GIA (200px)
          SizedBox(
            width: 200,
            child: Text(
              joinDate,
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 12,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // 6. NHÓM CHÍNH (160px)
          SizedBox(
            width: 160,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF131A30),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: const Color(0xFF2E3B5F), width: 1),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: currentRole,
                    dropdownColor: const Color(0xFF131A30),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                    icon: const Icon(Icons.arrow_drop_down, color: Color(0xFFFFD700), size: 18),
                    isDense: true,
                    items: _allowedRoles.map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      if (newValue != null && newValue != currentRole) {
                        _handleRoleChangeRequest(u, currentRole, newValue);
                      }
                    },
                  ),
                ),
              ),
            ),
          ),

          // 7. KHÓA TÀI KHOẢN (150px)
          SizedBox(
            width: 150,
            child: Center(
              child: SizedBox(
                height: 28,
                width: 90,
                child: ElevatedButton(
                  onPressed: isActive ? () => _handleLockAccount(u, currentRole) : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEF4444),
                    disabledBackgroundColor: const Color(0xFFEF4444).withValues(alpha: 0.25),
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    elevation: isActive ? 2 : 0,
                  ),
                  child: Text(
                    'Khóa',
                    style: TextStyle(
                      color: isActive ? Colors.white : Colors.white38,
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // 8. MỞ KHÓA TÀI KHOẢN (170px)
          SizedBox(
            width: 170,
            child: Center(
              child: SizedBox(
                height: 28,
                width: 100,
                child: ElevatedButton(
                  onPressed: !isActive ? () => _handleUnlockAccount(u) : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    disabledBackgroundColor: const Color(0xFF10B981).withValues(alpha: 0.25),
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    elevation: !isActive ? 2 : 0,
                  ),
                  child: Text(
                    'Mở Khóa',
                    style: TextStyle(
                      color: !isActive ? Colors.white : Colors.white38,
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // 9. SỬA DỮ LIỆU USER (160px)
          SizedBox(
            width: 160,
            child: Center(
              child: SizedBox(
                height: 28,
                width: 100,
                child: ElevatedButton.icon(
                  onPressed: () => _openEditUserModal(u, currentRole),
                  icon: const Icon(Icons.edit, size: 13, color: Colors.white),
                  label: const Text(
                    'Sửa User',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B82F6),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  ),
                ),
              ),
            ),
          ),

          // 10. XÓA DỮ LIỆU USER (160px)
          SizedBox(
            width: 160,
            child: Center(
              child: SizedBox(
                height: 28,
                width: 100,
                child: ElevatedButton.icon(
                  onPressed: () => _handleDeleteUser(u, currentRole),
                  icon: const Icon(Icons.delete_forever, size: 13, color: Colors.white),
                  label: const Text(
                    'Xóa User',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF991B1B),
                    side: const BorderSide(color: Color(0xFFEF4444), width: 0.8),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Banner Chính sách Phân quyền RBAC Enforced (Hình 1)
            RbacEnforcedBanner(
              onOpenMatrix: () async {
                final result = await RbacMatrixModal.show(
                  context,
                  onSelectRole: (roleKey) {
                    setState(() {
                      _selectedRole = roleKey;
                      _currentPage = 1;
                    });
                    _loadUsers();
                  },
                );

                if (result != null && result is Map && result['action'] == 'member_rank_updated') {
                  final targetUserId = result['userId'] as int?;
                  final targetUsername = result['username']?.toString() ?? '';
                  await _handleAfterMemberRankUpdated(targetUserId, targetUsername);
                }
              },
            ),
            const SizedBox(height: 16),

            // Header & Search
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    style: const TextStyle(color: AdminColors.realDataText),
                    decoration: InputDecoration(
                      hintText: 'Tìm kiếm Username/Email...',
                      hintStyle: const TextStyle(color: AdminColors.textMuted),
                      filled: true,
                      fillColor: AdminColors.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AdminColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AdminColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AdminColors.primary),
                      ),
                    ),
                    onSubmitted: (_) => _onSearch(),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: _onSearch,
                  icon: const Icon(Icons.search, color: Colors.white),
                  label: const Text('Tìm kiếm', style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AdminColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Tag phân loại màu & trạng thái lọc quyền
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      Container(width: 8, height: 8, decoration: const BoxDecoration(color: AdminColors.realDataText, shape: BoxShape.circle)),
                      const SizedBox(width: 6),
                      const Text(
                        'Dữ liệu THỰC TẾ từ Database (Chữ Trắng #FFFFFF)',
                        style: TextStyle(color: AdminColors.realDataText, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                if (_selectedRole != null && _selectedRole!.isNotEmpty) ...[
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AdminColors.primary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: AdminColors.primary),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Đang lọc Role: $_selectedRole',
                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 6),
                        InkWell(
                          onTap: () {
                            setState(() {
                              _selectedRole = null;
                              _currentPage = 1;
                            });
                            _loadUsers();
                          },
                          child: const Icon(Icons.close, size: 14, color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),

            // Thanh Tìm kiếm & Lọc A-Z (Chuẩn Hình 2)
            _buildFilterAndAlphabetBar(),
            const SizedBox(height: 12),

            // Nút "Thêm 1 dòng dữ liệu user mới" (Đối chiếu Hình 1)
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _openAddUserModal,
                  icon: const Icon(Icons.person_add_alt_1_rounded, size: 18, color: Colors.white),
                  label: const Text(
                    'Thêm 1 dòng dữ liệu user mới',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    elevation: 2,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                      side: const BorderSide(color: Color(0xFF3B82F6), width: 1),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Khối Data Grid 10 Cột theo Chuẩn Hình 1
            Expanded(
              child: AdminDataGridBox(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: Color(0xFFFFD700)))
                    : _users.isEmpty
                        ? const Center(
                            child: Text(
                              'Không tìm thấy user nào.',
                              style: TextStyle(color: Colors.white54, fontSize: 14),
                            ),
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    Expanded(
                                      child: _buildUserTable(),
                                    ),
                                    SizedBox(
                                      width: 14,
                                      child: CustomVerticalScrollbar(controller: _verticalScrollController),
                                    ),
                                  ],
                                ),
                              ),
                              AdminPaginationBar(
                                currentPage: _currentPage,
                                totalPages: _totalPages,
                                totalCount: _totalCount,
                                pageSize: _pageSize,
                                itemName: 'User',
                                startButtonLabel: '← Đầu bảng (Cột 1-5)',
                                endButtonLabel: '→ Cuối bảng (Cột 6-10)',
                                onScrollToStart: _scrollToStart,
                                onScrollToEnd: _scrollToEnd,
                                onPreviousPage: _currentPage > 1
                                    ? () {
                                        setState(() => _currentPage--);
                                        _loadUsers();
                                      }
                                    : null,
                                onNextPage: _currentPage < _totalPages
                                    ? () {
                                        setState(() => _currentPage++);
                                        _loadUsers();
                                      }
                                    : null,
                                onPageSelected: (p) {
                                  setState(() => _currentPage = p);
                                  _loadUsers();
                                },
                              ),
                            ],
                          ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserTable() {
    const double tableWidth = 1950.0;

    return ScrollConfiguration(
      behavior: AlwaysDragScrollBehavior(),
      child: RawScrollbar(
        controller: _horizontalScrollController,
        thumbVisibility: true,
        trackVisibility: true,
        interactive: true,
        thickness: 14.0,
        radius: const Radius.circular(7),
        thumbColor: const Color(0xFFFFD700),
        trackColor: const Color(0xFF0D1424),
        trackBorderColor: const Color(0xFF2E3B5F),
        child: SingleChildScrollView(
          controller: _horizontalScrollController,
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: tableWidth,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header 10 cột (260 + 180 + 140 + 240 + 200 + 160 + 150 + 170 + 160 + 160 = 1820px + 32px padding = 1852px)
                Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFF101628),
                    border: Border(bottom: BorderSide(color: Color(0xFF2E3B5F), width: 1.5)),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  child: const Row(
                    children: [
                      SizedBox(
                        width: 260,
                        child: Text('TÊN ĐĂNG NHẬP', style: TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.bold, fontSize: 12.5)),
                      ),
                      SizedBox(
                        width: 180,
                        child: Text('XẾP HẠNG', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.bold, fontSize: 12.5)),
                      ),
                      SizedBox(
                        width: 140,
                        child: Text('BÀI VIẾT', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.bold, fontSize: 12.5)),
                      ),
                      SizedBox(
                        width: 240,
                        child: Text('WEBSITE', style: TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.bold, fontSize: 12.5)),
                      ),
                      SizedBox(
                        width: 200,
                        child: Text('THAM GIA', style: TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.bold, fontSize: 12.5)),
                      ),
                      SizedBox(
                        width: 160,
                        child: Text('NHÓM CHÍNH', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.bold, fontSize: 12.5)),
                      ),
                      SizedBox(
                        width: 150,
                        child: Text('KHÓA TÀI KHOẢN', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.bold, fontSize: 12.5)),
                      ),
                      SizedBox(
                        width: 170,
                        child: Text('MỞ KHÓA TÀI KHOẢN', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.bold, fontSize: 12.5)),
                      ),
                      SizedBox(
                        width: 160,
                        child: Text('SỬA DỮ LIỆU USER', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.bold, fontSize: 12.5)),
                      ),
                      SizedBox(
                        width: 160,
                        child: Text('XÓA DỮ LIỆU USER', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.bold, fontSize: 12.5)),
                      ),
                    ],
                  ),
                ),

                // Danh sách dòng cuộn dọc
                Expanded(
                  child: SingleChildScrollView(
                    controller: _verticalScrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      children: [
                        for (int index = 0; index < _users.length; index++)
                          _buildUserRow(_users[index], index),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
