import 'package:flutter/material.dart';
import '../../services/admin_repository.dart';
import '../../services/signalr_service.dart';
import '../../widgets/admin_data_grid_layout.dart';
import '../../widgets/create_role_modal.dart';
import '../../utils/boxed_snack_bar.dart';

class BoardManagementScreen extends StatefulWidget {
  const BoardManagementScreen({super.key});

  @override
  State<BoardManagementScreen> createState() => _BoardManagementScreenState();
}

class _BoardManagementScreenState extends State<BoardManagementScreen> {
  final AdminRepository _repo = AdminRepository();
  bool _isLoading = true;
  List<dynamic> _members = [];
  int? _selectedIndex;

  // State Phân Trang Server-Side (25 dòng/trang)
  int _currentPage = 1;
  final int _pageSize = 25;
  int _totalCount = 0;
  int _totalPages = 1;

  // Trạng thái hủy vị trí: tập hợp index đang được highlight (gạch chân)
  final Set<int> _underlinedIndices = {};
  bool _isRevoking = false;

  // Trạng thái gạch chân nút Tạo Chức Vụ Mới
  bool _isCreateRoleUnderlined = false;

  // Bộ điều khiển Cuộn 2 Chiều có hiển thị thanh Scrollbar
  final ScrollController _horizontalScrollController = ScrollController();
  final ScrollController _verticalScrollController = ScrollController();

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
    _loadBoardMembers(page: 1);
    signalRService.listenToBoardMembersChanged(_onBoardChangedSignalR);
    signalRService.listenToUserRoleChanged(_onUserRoleChangedSignalR);
  }

  @override
  void dispose() {
    _horizontalScrollController.dispose();
    _verticalScrollController.dispose();
    signalRService.removeBoardMembersChangedListener();
    signalRService.removeUserRoleChangedListener();
    super.dispose();
  }

  void _onBoardChangedSignalR(List<Object?>? args) {
    if (mounted) {
      _loadBoardMembers(page: _currentPage);
    }
  }

  void _onUserRoleChangedSignalR(List<Object?>? args) {
    if (mounted) {
      _loadBoardMembers(page: _currentPage);
    }
  }

  Future<void> _loadBoardMembers({int? page}) async {
    if (page != null) {
      _currentPage = page;
    }
    setState(() => _isLoading = true);
    final data = await _repo.fetchBoardMembersPaginated(page: _currentPage, pageSize: _pageSize);
    if (mounted) {
      setState(() {
        _members = (data['items'] as List<dynamic>?) ?? [];
        _totalCount = (data['totalCount'] as num?)?.toInt() ?? _members.length;
        _totalPages = (data['totalPages'] as num?)?.toInt() ?? 1;
        _currentPage = (data['currentPage'] as num?)?.toInt() ?? _currentPage;
        if (_totalPages < 1) _totalPages = 1;
        _isLoading = false;
        if (_selectedIndex != null && _selectedIndex! >= _members.length) {
          _selectedIndex = null;
        }
      });
    }
  }

  // ================================================================
  // Xử lý Hủy vị trí quản trị viên (Nhiệm Vụ 2)
  // ================================================================
  Future<void> _handleRevokeRole(dynamic member, int index) async {
    if (_isRevoking) return;
    // Bật hiệu ứng gạch chân ngay lập tức khi click
    setState(() {
      _underlinedIndices.add(index);
    });
    final username = member['username']?.toString() ?? (member['name']?.toString() ?? '-');
    if (!mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF161F36),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: Color(0xFFC62828), width: 1.5),
        ),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Color(0xFFF44336), size: 26),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Xác nhận Hủy vị trí',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
        content: RichText(
          text: TextSpan(
            style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.6),
            children: [
              const TextSpan(text: 'Nếu xác nhận, user '),
              TextSpan(
                text: username,
                style: const TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.bold),
              ),
              const TextSpan(text: ' sẽ ngay lập tức trở về vị trí "Thành viên 1 sao tím".\n\nBạn chắc chắn không?'),
            ],
          ),
        ),
        actionsAlignment: MainAxisAlignment.end,
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFF546E7A)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            child: const Text('N - Hủy bỏ',
              style: TextStyle(color: Colors.white60, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFC62828),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            child: const Text('Y - Xác nhận',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      if (mounted) setState(() => _underlinedIndices.remove(index));
      return;
    }
    // Thực thi hủy vị trí
    final memberId = (member['id'] as num?)?.toInt() ?? (member['userId'] as num?)?.toInt() ?? 0;
    if (username.isEmpty || username == '_' || username == '-') {
      if (mounted) {
        setState(() => _underlinedIndices.remove(index));
        showErrorSnackBar(context, 'Vị trí này hiện đang trống.');
      }
      return;
    }
    setState(() => _isRevoking = true);
    final result = await _repo.revokeUserRole(userId: memberId, username: username);
    if (!mounted) return;
    setState(() {
      _isRevoking = false;
      if (result['success'] == true) {
        final updated = Map<String, dynamic>.from(member as Map);
        updated['username'] = '_';
        _members[index] = updated;
      } else {
        _underlinedIndices.remove(index);
      }
    });
    if (result['success'] == true) {
      showSuccessSnackBar(context, result['message'] ?? 'Đã hủy vị trí thành công. User đã trở thành Thành viên 1 sao tím.');
    } else {
      showErrorSnackBar(context, result['message'] ?? 'Có lỗi xảy ra khi hủy vị trí.');
    }
  }

  // Widget nút Sửa dòng (Nhiệm Vụ 2)
  Widget _buildEditButton(dynamic member, int index) {
    return ElevatedButton.icon(
      onPressed: () async {
        final updated = await CreateRoleModal.showEdit(
          context,
          Map<String, dynamic>.from(member as Map),
        );
        if (updated == true && mounted) {
          _loadBoardMembers(page: _currentPage);
        }
      },
      icon: const Icon(Icons.edit_note, color: Colors.white, size: 16),
      label: const Text(
        'Sửa dòng',
        style: TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF0288D1),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        minimumSize: const Size(88, 32),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
        elevation: 2,
      ),
    );
  }

  // Widget nút Xóa dòng — ràng buộc bảo vệ chặt chẽ (Nhiệm Vụ 3)
  Widget _buildDeleteButton(dynamic member, int index) {
    final username = member['username']?.toString() ?? '-';
    final stt = member['stt'] ?? ((_currentPage - 1) * _pageSize + index + 1);

    // Trường hợp 1: Dòng ĐANG CÓ User (Cột Thành viên chứa tên User)
    if (username != '_' && username.isNotEmpty && username != '-') {
      return ElevatedButton(
        onPressed: () {
          // Bật Alert Dialog cảnh báo ngăn xóa
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => AlertDialog(
              backgroundColor: const Color(0xFF161F36),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: const BorderSide(color: Color(0xFFC62828), width: 1.5),
              ),
              title: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Color(0xFFF44336), size: 26),
                  SizedBox(width: 10),
                  Text(
                    'Cảnh báo xóa dòng',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              content: const Text(
                'Bạn phải Xác nhận ở Cột Xóa tên User bên cạnh xong thì mới xóa được dòng này',
                style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
              ),
              actions: [
                ElevatedButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFC62828),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  ),
                  child: const Text('Đã hiểu', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFC62828),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          minimumSize: const Size(80, 32),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
        ),
        child: const Text('Xóa', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
      );
    }

    // Trường hợp 2: Dòng TRỐNG User (Cột Thành viên hiển thị - hoặc _)
    return ElevatedButton(
      onPressed: () async {
        final confirmed = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            backgroundColor: const Color(0xFF161F36),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: const BorderSide(color: Color(0xFFC62828), width: 1.5),
            ),
            title: const Row(
              children: [
                Icon(Icons.delete_forever, color: Color(0xFFF44336), size: 24),
                SizedBox(width: 8),
                Text('Xác nhận Xóa Dòng', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            content: Text(
              'Bạn có chắc chắn xóa dòng $stt này không?',
              style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
            ),
            actions: [
              OutlinedButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF546E7A)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                ),
                child: const Text('Hủy', style: TextStyle(color: Colors.white60, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFC62828),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                ),
                child: const Text('Xóa', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
        if (confirmed != true) return;
        final roleId = (member['id'] as num?)?.toInt() ?? (member['userId'] as num?)?.toInt() ?? 0;
        setState(() => _isLoading = true);
        final result = await _repo.deleteBoardRole(roleId);
        if (!mounted) return;
        setState(() => _isLoading = false);
        if (result['success'] == true) {
          // Xóa ngay lập tức trên UI và đồng bộ lại danh sách
          setState(() {
            _members.removeAt(index);
            if (_selectedIndex != null && _selectedIndex! >= _members.length) {
              _selectedIndex = null;
            }
          });
          showSuccessSnackBar(context, result['message'] ?? 'Đã xóa chức vụ thành công.');
          await _loadBoardMembers(page: _currentPage);
        } else {
          showErrorSnackBar(context, result['message'] ?? 'Lỗi khi xóa chức vụ.');
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF5D4037),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        minimumSize: const Size(80, 32),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
      ),
      child: const Text('Xóa', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }

  // Widget nút Hủy vị trí — ẩn nếu dòng trống, hiển thị nút xác nhận nếu có user
  Widget _buildRevokeButton(dynamic member, int index) {
    final username = member['username']?.toString() ?? '-';
    final isUnderlined = _underlinedIndices.contains(index);
    if (username == '_' || username.isEmpty || username == '-') {
      return const Text('—', style: TextStyle(color: Colors.white38, fontSize: 18), textAlign: TextAlign.center);
    }
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: ElevatedButton(
        onPressed: _isRevoking ? null : () => _handleRevokeRole(member, index),
        style: ElevatedButton.styleFrom(
          backgroundColor: isUnderlined ? const Color(0xFF7B1111) : const Color(0xFFC62828),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          minimumSize: const Size(110, 32),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
          elevation: isUnderlined ? 0 : 2,
        ),
        child: Text(
          isUnderlined ? 'Đang xử lý...' : 'Xác nhận',
          style: TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            decoration: isUnderlined ? TextDecoration.underline : TextDecoration.none,
            decorationColor: Colors.white,
          ),
        ),
      ),
    );
  }

  // ================================================================
  // Modal Form "Tạo Chức Vụ Mới" (Nhiệm Vụ 2 - Chuẩn 6 Dải Nhập Liệu)
  // ================================================================
  Future<void> _showCreateRoleModal() async {
    final created = await CreateRoleModal.show(context);
    if (created == true) {
      _loadBoardMembers(page: _currentPage);
    }
  }

  // Helper mapping hình ảnh Ruy Băng Ngang (Hình 3)
  String _getRibbonAsset(String? rank, String? rawAsset) {
    if (rawAsset != null && rawAsset.isNotEmpty) {
      final fileName = rawAsset.split('/').last;
      return 'assets/images/$fileName';
    }
    final r = (rank ?? '').toLowerCase();
    if (r.contains('admin')) return 'assets/images/ribbon_admin.png';
    if (r.contains('sáng lập')) return 'assets/images/ribbon_sang_lap.png';
    if (r.contains('quản lý')) return 'assets/images/ribbon_quan_ly.png';
    if (r.contains('hội viên')) return 'assets/images/ribbon_hoi_vien.png';
    if (r.contains('điều hành')) return 'assets/images/ribbon_dieu_hanh.png';
    if (r.contains('tư vấn')) return 'assets/images/ribbon_tu_van.png';
    return 'assets/images/ribbon_quan_ly.png';
  }

  // Helper mapping hình ảnh Logo Dọc (Hình 4)
  String _getLogoAsset(String? rank, String? rawAsset) {
    if (rawAsset != null && rawAsset.isNotEmpty) {
      final fileName = rawAsset.split('/').last;
      return 'assets/images/$fileName';
    }
    final r = (rank ?? '').toLowerCase();
    if (r.contains('superadmin') || r.contains('super admin')) return 'assets/images/logo_super_admin.png';
    if (r.contains('admin')) return 'assets/images/logo_admin.png';
    if (r.contains('sáng lập')) return 'assets/images/logo_sang_lap.png';
    if (r.contains('quản lý')) return 'assets/images/logo_quan_ly.png';
    if (r.contains('hội viên')) return 'assets/images/logo_hoi_vien.png';
    if (r.contains('điều hành')) return 'assets/images/logo_dieu_hanh.png';
    if (r.contains('tư vấn')) return 'assets/images/logo_tu_van.png';
    return 'assets/images/logo_quan_ly.png';
  }

  Color _parseColor(dynamic raw, Color fallback) {
    if (raw is String && raw.startsWith('#')) {
      final hex = raw.replaceFirst('#', '0xFF');
      final val = int.tryParse(hex);
      if (val != null) return Color(val);
    }
    return fallback;
  }

  Widget _buildRibbonImage(String assetPath) {
    final fileName = assetPath.split('/').last;
    return Image.asset(
      assetPath,
      height: 34,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return Image.network(
          'http://localhost:5000/images/$fileName',
          height: 34,
          fit: BoxFit.contain,
          errorBuilder: (c, e, s) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF1E88E5),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text('XẾP HẠNG', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
          ),
        );
      },
    );
  }

  Widget _buildLogoImage(String assetPath) {
    final fileName = assetPath.split('/').last;
    return Image.asset(
      assetPath,
      height: 50,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return Image.network(
          'http://localhost:5000/images/$fileName',
          height: 50,
          fit: BoxFit.contain,
          errorBuilder: (c, e, s) => const Icon(Icons.shield, color: Color(0xFFFFD700), size: 28),
        );
      },
    );
  }

  // Helper phân tách chuỗi quyền / chuyên mục thành danh sách hiển thị
  List<String> _parseListItems(String? raw, String fallback) {
    if (raw == null || raw.trim().isEmpty || raw.trim() == '-') return [fallback];
    final parts = raw.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    return parts.isEmpty ? [fallback] : parts;
  }

  // Widget Dropdown Multi-select Bar nhỏ gọn ở mỗi dòng (Nhiệm Vụ 1)
  Widget _buildDropdownBar({
    required String rawValue,
    required String fallback,
    required double width,
    Color textColor = Colors.white70,
    Color borderColor = const Color(0xFF283A63),
    Color bgColor = const Color(0xFF0F1829),
  }) {
    final items = _parseListItems(rawValue, fallback);
    final displayText = rawValue.isNotEmpty ? rawValue : fallback;

    return SizedBox(
      width: width,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Theme(
          data: Theme.of(context).copyWith(
            popupMenuTheme: PopupMenuThemeData(
              color: const Color(0xFF131A30),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: const BorderSide(color: Color(0xFF2E3B5F), width: 1.2),
              ),
              elevation: 8,
            ),
          ),
          child: PopupMenuButton<String>(
            tooltip: 'Xem danh sách chi tiết',
            offset: const Offset(0, 34),
            position: PopupMenuPosition.under,
            itemBuilder: (ctx) {
              return items.map((item) {
                return PopupMenuItem<String>(
                  enabled: false,
                  height: 36,
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, color: Color(0xFF00BFA5), size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(5),
                border: Border.all(color: borderColor, width: 1.0),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      displayText,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.arrow_drop_down,
                    color: Color(0xFFFFD700),
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Tiêu đề trang + Nút Làm mới
            _buildHeaderBar(),
            const SizedBox(height: 18),

            // Khối Data Grid 8 Cột theo Chuẩn Hình 7
            Expanded(
              child: AdminDataGridBox(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: Color(0xFFFFD700)))
                    : _members.isEmpty
                        ? const Center(
                            child: Text(
                              'Chưa có dữ liệu Ban Quản Trị.',
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
                                      child: _build8ColumnTable(),
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
                                itemName: 'Thành viên Ban Quản Trị',
                                startButtonLabel: 'Đầu bảng (Cột 1-4)',
                                endButtonLabel: 'Cuối bảng (Cột 5-11)',
                                onScrollToStart: _scrollToStart,
                                onScrollToEnd: _scrollToEnd,
                                onPreviousPage: _currentPage > 1 ? () => _loadBoardMembers(page: _currentPage - 1) : null,
                                onNextPage: _currentPage < _totalPages ? () => _loadBoardMembers(page: _currentPage + 1) : null,
                                onPageSelected: (p) => _loadBoardMembers(page: p),
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

  Widget _buildHeaderBar() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF131A30),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF2E3B5F), width: 1.2),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Row(
            children: [
              Icon(Icons.security, color: Color(0xFFFFD700), size: 24),
              SizedBox(width: 10),
              Text(
                'Quản lý Ban Quản Trị',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              // Nút [+ Tạo Chức Vụ Mới] (Nền xanh ngọc #00BFA5, chữ trắng, in đậm)
              ElevatedButton.icon(
                onPressed: () async {
                  setState(() => _isCreateRoleUnderlined = true);
                  await _showCreateRoleModal();
                  if (mounted) setState(() => _isCreateRoleUnderlined = false);
                },
                icon: const Icon(Icons.add, color: Colors.white, size: 16),
                label: Text(
                  '+ Tạo Chức Vụ Mới',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    decoration: _isCreateRoleUnderlined ? TextDecoration.underline : TextDecoration.none,
                    decorationColor: Colors.white,
                    decorationThickness: 2,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00BFA5),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
              ),

              // Nút [C Làm mới]
              ElevatedButton.icon(
                onPressed: () => _loadBoardMembers(page: _currentPage),
                icon: const Icon(Icons.refresh, color: Colors.white, size: 16),
                label: const Text('Làm mới', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1976D2),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static const TextStyle _headerStyle = TextStyle(
    color: Color(0xFFFFD700),
    fontWeight: FontWeight.bold,
    fontSize: 12.5,
    letterSpacing: 0.3,
  );

  Widget _build8ColumnTable() {
    const double tableWidth = 1880.0;

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
                // Header chuẩn khít
                Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFF101628),
                    border: Border(
                      bottom: BorderSide(color: Color(0xFF2E3B5F), width: 1.5),
                      left: BorderSide(color: Colors.transparent, width: 4),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                  child: Row(
                    children: [
                      // 1. STT (60px)
                      SizedBox(width: 60, child: Text('STT', textAlign: TextAlign.center, style: _headerStyle)),
                      // 2. Tên thành viên (180px)
                      SizedBox(width: 180, child: Text('Tên thành viên', style: _headerStyle)),
                      // 3. Nhóm chính (180px)
                      SizedBox(width: 180, child: Text('Nhóm chính', style: _headerStyle)),
                      // 4. Xếp hạng (160px)
                      SizedBox(width: 160, child: Text('Xếp hạng', textAlign: TextAlign.center, style: _headerStyle)),
                      // 5. Chuyên mục Quản Lý (240px)
                      SizedBox(width: 240, child: Text('Chuyên mục Quản Lý', style: _headerStyle)),
                      // 6. Chủ đề Quản Lý (200px)
                      SizedBox(width: 200, child: Text('Chủ đề Quản Lý', style: _headerStyle)),
                      // 7. Cấp quyền quản lý (220px)
                      SizedBox(width: 220, child: Text('Cấp quyền quản lý', style: _headerStyle)),
                      // 8. Logo hiển thị (120px)
                      SizedBox(width: 120, child: Text('Logo hiển thị', textAlign: TextAlign.center, style: _headerStyle)),
                      // 9. Xóa Tên User (160px)
                      SizedBox(
                        width: 160,
                        child: Text(
                          'XÓA TÊN USER',
                          textAlign: TextAlign.center,
                          style: _headerStyle.copyWith(color: const Color(0xFFF44336)),
                        ),
                      ),
                      // 10. Sửa Dữ Liệu Dòng (160px) - Mới (Nhiệm Vụ 2)
                      SizedBox(
                        width: 160,
                        child: Text(
                          'SỬA DỮ LIỆU DÒNG',
                          textAlign: TextAlign.center,
                          style: _headerStyle.copyWith(color: const Color(0xFF4FC3F7)),
                        ),
                      ),
                      // 11. Xóa Dòng (160px)
                      SizedBox(
                        width: 160,
                        child: Text(
                          'XÓA DÒNG',
                          textAlign: TextAlign.center,
                          style: _headerStyle,
                        ),
                      ),
                    ],
                  ),
                ),

                // Danh sách dòng dữ liệu (Cuộn dọc)
                Expanded(
                  child: SingleChildScrollView(
                    controller: _verticalScrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      children: [
                        for (int i = 0; i < _members.length; i++) _buildBoardRow(_members[i], i),
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

  Widget _buildBoardRow(dynamic m, int index) {
    final isSelected = _selectedIndex == index;
    final isEven = index % 2 == 0;
    Color rowBg = isEven ? const Color(0xFF161F36) : const Color(0xFF131A30);
    if (isSelected) {
      rowBg = const Color(0xFF1E2F5A);
    }

    final stt = m['stt'] ?? ((_currentPage - 1) * _pageSize + index + 1);
    final username = m['username']?.toString() ?? (m['name']?.toString() ?? '-');
    final nameColor = _parseColor(m['nameColor'], const Color(0xFFEF5350));
    final primaryGroup = m['primaryGroup']?.toString() ?? (m['groupLevel']?.toString() ?? 'Ban Quản Trị');
    final primaryColor = _parseColor(m['primaryGroupColor'], const Color(0xFF29B6F6));
    final rank = m['rank']?.toString() ?? (m['badgeText']?.toString() ?? 'Quản lý');
    final isFirstRow = (index == 0 && _currentPage == 1) || (stt == 1);
    final ribbonAsset = isFirstRow ? 'assets/images/ribbon_admin.png' : _getRibbonAsset(rank, m['ribbonAsset']?.toString());
    final managedCategories = m['managedCategories']?.toString() ?? 'Tất cả chuyên mục';
    final managedTopics = m['managedTopics']?.toString() ?? 'Tất cả chủ đề';
    final permission = m['managementPermission']?.toString() ?? 'Toàn quyền quản lý';
    final logoAsset = isFirstRow ? 'assets/images/logo_admin.png' : _getLogoAsset(rank, m['logoAsset']?.toString());

    return InkWell(
      onTap: () {
        setState(() {
          if (_selectedIndex == index) {
            _selectedIndex = null;
          } else {
            _selectedIndex = index;
          }
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color: rowBg,
          border: Border(
            bottom: const BorderSide(color: Color(0xFF242F50), width: 0.8),
            left: BorderSide(
              color: isSelected ? const Color(0xFFFFD700) : Colors.transparent,
              width: 4,
            ),
          ),
        ),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 1. STT (60px)
            SizedBox(
              width: 60,
              child: Text(
                '$stt',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isSelected ? const Color(0xFFFFD700) : Colors.white70,
                  fontWeight: FontWeight.bold,
                  fontSize: 12.5,
                ),
              ),
            ),

            // 2. Tên thành viên (180px)
            SizedBox(
              width: 180,
              child: Text(
                username,
                style: TextStyle(
                  color: nameColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 13.5,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // 3. Nhóm chính (180px)
            SizedBox(
              width: 180,
              child: Text(
                primaryGroup,
                style: TextStyle(
                  color: primaryColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // 4. Xếp hạng (160px)
            SizedBox(
              width: 160,
              child: Center(
                child: _buildRibbonImage(ribbonAsset),
              ),
            ),

            // 5. Chuyên mục Quản Lý (240px) — Dropdown Bar (Nhiệm Vụ 1)
            _buildDropdownBar(
              rawValue: managedCategories,
              fallback: 'Tất cả chuyên mục',
              width: 240,
              textColor: Colors.white70,
            ),

            // 6. Chủ đề Quản Lý (200px) — Dropdown Bar (Nhiệm Vụ 1)
            _buildDropdownBar(
              rawValue: managedTopics,
              fallback: 'Tất cả chủ đề',
              width: 200,
              textColor: Colors.white70,
            ),

            // 7. Cấp quyền quản lý (220px) — Dropdown Bar (Nhiệm Vụ 1)
            _buildDropdownBar(
              rawValue: permission,
              fallback: 'Toàn quyền quản lý',
              width: 220,
              textColor: const Color(0xFFFFD54F),
            ),

            // 8. Logo hiển thị (120px)
            SizedBox(
              width: 120,
              child: Center(
                child: _buildLogoImage(logoAsset),
              ),
            ),

                // 9. Xóa Tên User (160px)
                SizedBox(
                  width: 160,
                  child: Center(
                    child: _buildRevokeButton(m, index),
                  ),
                ),
                // 10. Sửa Dữ Liệu Dòng (160px) - Mới (Nhiệm Vụ 2)
                SizedBox(
                  width: 160,
                  child: Center(
                    child: _buildEditButton(m, index),
                  ),
                ),
                // 11. Xóa Dòng (160px)
                SizedBox(
                  width: 160,
                  child: Center(
                    child: _buildDeleteButton(m, index),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}
