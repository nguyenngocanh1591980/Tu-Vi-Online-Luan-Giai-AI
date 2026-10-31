import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/admin_repository.dart';
import '../../services/signalr_service.dart';
import '../../widgets/user_rank_badge_widget.dart';

/// Cho phép kéo cuộn trực tiếp bằng chuột, trackpad và cảm ứng trên Web Desktop
class _AlwaysDragScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.trackpad,
    PointerDeviceKind.stylus,
  };
}

class MasterManagementScreen extends StatefulWidget {
  const MasterManagementScreen({super.key});

  @override
  State<MasterManagementScreen> createState() => _MasterManagementScreenState();
}

class _MasterManagementScreenState extends State<MasterManagementScreen> {
  final AdminRepository _repo = AdminRepository();
  List<dynamic> _masters = [];
  bool _isLoading = true;
  int? _selectedIndex;
  int? _highlightedUserId;
  String? _highlightedUsername;

  // State Phân Trang Server-Side (25 dòng/trang)
  int _currentPage = 1;
  final int _pageSize = 25;
  int _totalCount = 0;
  int _totalPages = 1;

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

  final List<String> _rankOptions = const [
    'Nhất Đẳng',
    'Nhị Đẳng',
    'Tam Đẳng',
    'Tứ Đẳng',
    'Ngũ Đẳng',
    'Lục Đẳng',
  ];

  @override
  void initState() {
    super.initState();
    _loadMasters(page: 1);
    signalRService.listenToMasterProfileUpdated(_onMasterProfileUpdatedSignalR);
    signalRService.listenToUserRankChanged(_onUserRankChangedSignalR);
    signalRService.listenToUserRoleChanged(_onUserRoleChangedSignalR);
    signalRService.listenToUserStatusChanged(_onUserStatusChangedSignalR);
  }

  @override
  void dispose() {
    _horizontalScrollController.dispose();
    _verticalScrollController.dispose();
    signalRService.removeMasterProfileUpdatedListener();
    signalRService.removeUserRankChangedListener();
    signalRService.removeUserRoleChangedListener();
    signalRService.removeUserStatusChangedListener();
    super.dispose();
  }

  void _onMasterProfileUpdatedSignalR(List<Object?>? args) {
    if (mounted) {
      if (args != null && args.isNotEmpty && args[0] is Map) {
        final map = args[0] as Map;
        final userId = map['userId'] as int?;
        final username = (map['username'] ?? map['masterName'])?.toString() ?? '';
        _handleAfterMasterRankUpdated(userId, username);
        return;
      }
      _loadMasters(page: _currentPage);
    }
  }

  void _onUserRankChangedSignalR(List<Object?>? args) {
    if (mounted) {
      if (args != null && args.isNotEmpty && args[0] is Map) {
        final map = args[0] as Map;
        final rankTitle = map['rankTitle']?.toString() ?? '';
        if (rankTitle.toLowerCase().contains('đẳng')) {
          final userId = map['userId'] as int?;
          final username = (map['username'] ?? map['masterName'])?.toString() ?? '';
          _handleAfterMasterRankUpdated(userId, username);
          return;
        }
      }
      _loadMasters(page: _currentPage);
    }
  }

  void _onUserRoleChangedSignalR(List<Object?>? args) {
    if (mounted) {
      _loadMasters(page: _currentPage);
    }
  }

  void _onUserStatusChangedSignalR(List<Object?>? args) {
    if (mounted) {
      _loadMasters(page: _currentPage);
    }
  }

  Future<void> _handleAfterMasterRankUpdated(int? userId, String username) async {
    setState(() {
      _highlightedUserId = userId;
      _highlightedUsername = username;
      _currentPage = 1;
    });

    await _loadMasters(page: 1);

    if (!mounted) return;

    // Tìm index của Đại Sư trong trang 1
    int targetIndex = _masters.indexWhere((m) =>
        (userId != null && (m['userId'] == userId || m['id'] == userId)) ||
        (username.isNotEmpty &&
            (m['username']?.toString().toLowerCase() == username.toLowerCase() ||
             m['masterName']?.toString().toLowerCase() == username.toLowerCase())));

    // Nếu không có ở trang 1, quét các trang tiếp theo
    if (targetIndex == -1 && _totalPages > 1) {
      for (int p = 2; p <= _totalPages; p++) {
        final res = await _repo.fetchMastersPaginated(page: p, pageSize: _pageSize);
        final items = (res['items'] as List<dynamic>?) ?? [];
        final idx = items.indexWhere((m) =>
            (userId != null && (m['userId'] == userId || m['id'] == userId)) ||
            (username.isNotEmpty &&
                (m['username']?.toString().toLowerCase() == username.toLowerCase() ||
                 m['masterName']?.toString().toLowerCase() == username.toLowerCase())));
        if (idx != -1) {
          if (!mounted) return;
          setState(() {
            _currentPage = p;
            _masters = items;
            _totalCount = (res['totalCount'] as num?)?.toInt() ?? _masters.length;
            _totalPages = (res['totalPages'] as num?)?.toInt() ?? _totalPages;
          });
          targetIndex = idx;
          break;
        }
      }
    }

    if (targetIndex != -1 && mounted) {
      setState(() {
        _selectedIndex = targetIndex;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_verticalScrollController.hasClients && _verticalScrollController.position.hasContentDimensions) {
          const double rowHeight = 68.0;
          final double targetOffset = (targetIndex * rowHeight).clamp(0.0, _verticalScrollController.position.maxScrollExtent);
          _verticalScrollController.animateTo(
            targetOffset,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOutCubic,
          );
        }
      });
    }
  }

  Future<void> _loadMasters({int? page}) async {
    if (page != null) {
      _currentPage = page;
    }
    setState(() => _isLoading = true);
    final pagedData = await _repo.fetchMastersPaginated(page: _currentPage, pageSize: _pageSize);
    if (mounted) {
      setState(() {
        _masters = (pagedData['items'] as List<dynamic>?) ?? [];
        _totalCount = (pagedData['totalCount'] as num?)?.toInt() ?? _masters.length;
        _totalPages = (pagedData['totalPages'] as num?)?.toInt() ?? 1;
        _currentPage = (pagedData['currentPage'] as num?)?.toInt() ?? _currentPage;
        if (_totalPages < 1) _totalPages = 1;
        _isLoading = false;
        if (_selectedIndex != null && _selectedIndex! >= _masters.length) {
          _selectedIndex = null;
        }
      });
    }
  }

  // --- 1. MODAL FORM: THÊM ĐẠI SƯ (CHUYÊN GIA) ---
  void _openAddMasterDialog() {
    final usernameController = TextEditingController();
    final masterNameController = TextEditingController();
    String selectedRank = _rankOptions.first;
    DateTime selectedDate = DateTime.now();

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final dateStr = DateFormat('dd/MM/yyyy').format(selectedDate);

            return AlertDialog(
              backgroundColor: const Color(0xFF161F36),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: const BorderSide(color: Color(0xFF2E3B5F)),
              ),
              title: const Row(
                children: [
                  Icon(Icons.person_add_alt_1, color: Color(0xFFFFD700), size: 22),
                  SizedBox(width: 8),
                  Text(
                    'Thêm Đại Sư (Chuyên gia)',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: 480,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Tên thành viên
                      const Text('Tên Thành viên (Username):', style: TextStyle(color: Colors.white70, fontSize: 13)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: usernameController,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Nhập username liên kết (ví dụ: ngocanh1)',
                          hintStyle: const TextStyle(color: Colors.white30, fontSize: 13),
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
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                            borderSide: const BorderSide(color: Color(0xFFFFD700)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Tên Chuyên gia
                      const Text('Tên Đại Sư (Chuyên Gia):', style: TextStyle(color: Colors.white70, fontSize: 13)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: masterNameController,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Nhập danh xưng (ví dụ: Thầy Thiên Cơ)',
                          hintStyle: const TextStyle(color: Colors.white30, fontSize: 13),
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
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                            borderSide: const BorderSide(color: Color(0xFFFFD700)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Xếp hạng Dropdown (Nhất Đẳng đến Lục Đẳng)
                      const Text('Xếp hạng (Từ Nhất Đẳng đến Lục Đẳng):', style: TextStyle(color: Colors.white70, fontSize: 13)),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF131A30),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFF2E3B5F)),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: selectedRank,
                            isExpanded: true,
                            dropdownColor: const Color(0xFF131A30),
                            style: const TextStyle(color: Colors.white, fontSize: 14),
                            icon: const Icon(Icons.arrow_drop_down, color: Color(0xFFFFD700)),
                            items: _rankOptions.map((rank) {
                              return DropdownMenuItem<String>(
                                value: rank,
                                child: Text(rank),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setDialogState(() => selectedRank = val);
                              }
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Ngày tham gia DatePicker
                      const Text('Ngày tham gia:', style: TextStyle(color: Colors.white70, fontSize: 13)),
                      const SizedBox(height: 6),
                      InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: selectedDate,
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                            builder: (context, child) {
                              return Theme(
                                data: ThemeData.dark().copyWith(
                                  colorScheme: const ColorScheme.dark(
                                    primary: Color(0xFFFFD700),
                                    onPrimary: Colors.black,
                                    surface: Color(0xFF161F36),
                                    onSurface: Colors.white,
                                  ),
                                ),
                                child: child!,
                              );
                            },
                          );
                          if (picked != null) {
                            setDialogState(() => selectedDate = picked);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF131A30),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFF2E3B5F)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(dateStr, style: const TextStyle(color: Colors.white, fontSize: 14)),
                              const Icon(Icons.calendar_month, color: Color(0xFFFFD700), size: 20),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Hủy', style: TextStyle(color: Colors.white60)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  ),
                  onPressed: () {
                    final name = masterNameController.text.trim();
                    if (name.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Vui lòng nhập tên chuyên gia!'), backgroundColor: Colors.redAccent),
                      );
                      return;
                    }

                    final messenger = ScaffoldMessenger.of(context);
                    // Confirm Dialog: "Bạn có chắc chắn tạo dữ liệu này không?"
                    _showConfirmActionDialog(
                      title: 'Xác nhận tạo mới',
                      message: 'Bạn có chắc chắn tạo dữ liệu này không?',
                      onConfirm: () async {
                        Navigator.pop(ctx); // Đóng modal form
                        final res = await _repo.createMaster({
                          'username': usernameController.text.trim(),
                          'masterName': name,
                          'rankTitle': selectedRank,
                          'joinDate': selectedDate.toIso8601String(),
                        });
                        if (mounted) {
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text(res['message'] ?? 'Thực hiện thành công'),
                              backgroundColor: res['success'] == true ? Colors.green : Colors.redAccent,
                            ),
                          );
                          _loadMasters(page: _currentPage);
                        }
                      },
                    );
                  },
                  child: const Text('Xác nhận', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // --- 2. MODAL FORM: SỬA DỮ LIỆU ĐẠI SƯ (CHUYÊN GIA) ---
  void _openEditMasterDialog() {
    if (_selectedIndex == null || _selectedIndex! < 0 || _selectedIndex! >= _masters.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn 1 chuyên gia trong danh sách để chỉnh sửa.'),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      return;
    }

    final current = _masters[_selectedIndex!];
    final id = (current['id'] as num?)?.toInt() ?? 0;
    final usernameController = TextEditingController(text: current['username']?.toString() ?? '');
    final masterNameController = TextEditingController(text: current['masterName']?.toString() ?? '');
    
    String currentRank = current['rankTitle']?.toString() ?? 'Nhất Đẳng';
    if (!_rankOptions.contains(currentRank)) {
      currentRank = _rankOptions.first;
    }
    String selectedRank = currentRank;

    DateTime selectedDate = DateTime.now();
    if (current['joinDate'] != null) {
      try {
        selectedDate = DateTime.parse(current['joinDate'].toString());
      } catch (_) {}
    }

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final dateStr = DateFormat('dd/MM/yyyy').format(selectedDate);

            return AlertDialog(
              backgroundColor: const Color(0xFF161F36),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: const BorderSide(color: Color(0xFF2E3B5F)),
              ),
              title: const Row(
                children: [
                  Icon(Icons.edit_note, color: Color(0xFFFFD700), size: 24),
                  SizedBox(width: 8),
                  Text(
                    'Sửa Dữ liệu Đại Sư (Chuyên Gia)',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: 480,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Tên thành viên
                      const Text('Tên Thành viên (Username):', style: TextStyle(color: Colors.white70, fontSize: 13)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: usernameController,
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
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                            borderSide: const BorderSide(color: Color(0xFFFFD700)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Tên Chuyên gia
                      const Text('Tên Đại Sư (Chuyên Gia):', style: TextStyle(color: Colors.white70, fontSize: 13)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: masterNameController,
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
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                            borderSide: const BorderSide(color: Color(0xFFFFD700)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Xếp hạng Dropdown
                      const Text('Xếp hạng (Từ Nhất Đẳng đến Lục Đẳng):', style: TextStyle(color: Colors.white70, fontSize: 13)),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF131A30),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFF2E3B5F)),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: selectedRank,
                            isExpanded: true,
                            dropdownColor: const Color(0xFF131A30),
                            style: const TextStyle(color: Colors.white, fontSize: 14),
                            icon: const Icon(Icons.arrow_drop_down, color: Color(0xFFFFD700)),
                            items: _rankOptions.map((rank) {
                              return DropdownMenuItem<String>(
                                value: rank,
                                child: Text(rank),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setDialogState(() => selectedRank = val);
                              }
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Ngày tham gia DatePicker
                      const Text('Ngày tham gia:', style: TextStyle(color: Colors.white70, fontSize: 13)),
                      const SizedBox(height: 6),
                      InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: selectedDate,
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                            builder: (context, child) {
                              return Theme(
                                data: ThemeData.dark().copyWith(
                                  colorScheme: const ColorScheme.dark(
                                    primary: Color(0xFFFFD700),
                                    onPrimary: Colors.black,
                                    surface: Color(0xFF161F36),
                                    onSurface: Colors.white,
                                  ),
                                ),
                                child: child!,
                              );
                            },
                          );
                          if (picked != null) {
                            setDialogState(() => selectedDate = picked);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF131A30),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFF2E3B5F)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(dateStr, style: const TextStyle(color: Colors.white, fontSize: 14)),
                              const Icon(Icons.calendar_month, color: Color(0xFFFFD700), size: 20),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Hủy', style: TextStyle(color: Colors.white60)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1565C0),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  ),
                  onPressed: () {
                    final name = masterNameController.text.trim();
                    if (name.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Tên chuyên gia không được rỗng!'), backgroundColor: Colors.redAccent),
                      );
                      return;
                    }

                    final messenger = ScaffoldMessenger.of(context);
                    // Confirm Dialog: "Bạn có chắc chắn sửa dữ liệu không?"
                    _showConfirmActionDialog(
                      title: 'Xác nhận chỉnh sửa',
                      message: 'Bạn có chắc chắn sửa dữ liệu không?',
                      onConfirm: () async {
                        Navigator.pop(ctx); // Đóng modal form
                        final res = await _repo.updateMaster(id, {
                          'username': usernameController.text.trim(),
                          'masterName': name,
                          'rankTitle': selectedRank,
                          'joinDate': selectedDate.toIso8601String(),
                        });
                        if (mounted) {
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text(res['message'] ?? 'Thực hiện thành công'),
                              backgroundColor: res['success'] == true ? Colors.green : Colors.redAccent,
                            ),
                          );
                          _loadMasters(page: _currentPage);
                        }
                      },
                    );
                  },
                  child: const Text('Xác nhận', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // --- 3. XÓA DỮ LIỆU ĐẠI SƯ (CHUYÊN GIA) - DIALOG Y/N ---
  void _openDeleteMasterDialog() {
    if (_selectedIndex == null || _selectedIndex! < 0 || _selectedIndex! >= _masters.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn 1 chuyên gia trong danh sách để xóa.'),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      return;
    }

    final current = _masters[_selectedIndex!];
    final id = (current['id'] as num?)?.toInt() ?? 0;
    final name = current['masterName']?.toString() ?? 'Chuyên gia này';

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1A2E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(color: Color(0xFFEF5350), width: 1.5),
          ),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Color(0xFFEF5350), size: 26),
              SizedBox(width: 8),
              Text('Xác nhận xóa dữ liệu', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bạn có chắc chắn xóa dữ liệu không (Y/N)',
                style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(
                'Đại Sư: $name (ID: $id)\nThao tác này sẽ xóa vĩnh viễn khỏi Database PostgreSQL.',
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
          actions: [
            // Nút N: Hủy bỏ, giữ nguyên giao diện
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white70,
                side: const BorderSide(color: Color(0xFF2E3B5F)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              onPressed: () {
                Navigator.pop(ctx);
              },
              child: const Text('N (Hủy)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ),

            // Nút Y: Xác nhận xóa vĩnh viễn khỏi DB
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD32F2F),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                Navigator.pop(ctx);
                final res = await _repo.deleteMaster(id);
                if (mounted) {
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(res['message'] ?? 'Đã xóa vĩnh viễn.'),
                      backgroundColor: res['success'] == true ? Colors.green : Colors.redAccent,
                    ),
                  );
                  setState(() {
                    _selectedIndex = null;
                  });
                  _loadMasters(page: _currentPage);
                }
              },
              child: const Text('Y (Xóa)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ),
          ],
        );
      },
    );
  }

  // Helper Confirm Action Dialog
  void _showConfirmActionDialog({
    required String title,
    required String message,
    required VoidCallback onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF161F36),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: Color(0xFF2E3B5F)),
        ),
        title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        content: Text(message, style: const TextStyle(color: Colors.white70, fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy', style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFD700),
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              onConfirm();
            },
            child: const Text('Đồng ý', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
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
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
            child: const Text('Đã hiểu', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  bool _isSupremeMaster(dynamic m) {
    if (m == null) return false;
    if (m['isSupreme'] == true) return true;
    final role = (m['role']?.toString() ?? '').toLowerCase();
    final username = (m['username']?.toString() ?? '').toLowerCase();
    final masterName = (m['masterName']?.toString() ?? '').toLowerCase();
    final rankTitle = (m['rankTitle']?.toString() ?? '').toLowerCase();
    final badge = (m['badge']?.toString() ?? '').toLowerCase();

    if (role == 'super_admin' || role == 'admin' ||
        username == 'ngocanh1' ||
        rankTitle.contains('sáng lập') || rankTitle.contains('admin') ||
        badge.contains('sáng lập') || badge.contains('admin') ||
        masterName.contains('sáng lập')) {
      return true;
    }
    return false;
  }

  Future<void> _handleLockMaster(dynamic m) async {
    if (_isSupremeMaster(m)) {
      _showWarningDialog(
        title: 'Không thể khóa tài khoản',
        message: 'Không thể khóa tài khoản đang giữ chức vụ Tối cao (Admin hoặc Sáng Lập)! Vui lòng gỡ chức vụ tại bảng Quản lý Ban Quản Trị trước.',
      );
      return;
    }

    final masterName = m['masterName']?.toString() ?? 'Chuyên gia này';
    final username = m['username']?.toString() ?? '';

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
          'Bạn có chắc chắn muốn KHÓA tài khoản của Đại Sư "$masterName" ($username)? Người dùng này sẽ không thể đăng nhập hoặc thao tác trên hệ thống.',
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
      final id = (m['id'] as num?)?.toInt() ?? 0;
      final res = await _repo.updateMasterStatus(id, false);
      if (!mounted) return;

      if (res['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã khóa tài khoản của Đại Sư "$masterName".'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
        _loadMasters(page: _currentPage);
      } else {
        _showWarningDialog(
          title: 'Khóa tài khoản thất bại',
          message: res['message'] ?? 'Không thể cập nhật trạng thái tài khoản.',
        );
      }
    }
  }

  Future<void> _handleUnlockMaster(dynamic m) async {
    final masterName = m['masterName']?.toString() ?? 'Chuyên gia này';
    final username = m['username']?.toString() ?? '';

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
          'Bạn có chắc chắn muốn MỞ KHÓA tài khoản của Đại Sư "$masterName" ($username)? Người dùng sẽ được phép đăng nhập và sử dụng hệ thống bình thường.',
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
      final id = (m['id'] as num?)?.toInt() ?? 0;
      final res = await _repo.updateMasterStatus(id, true);
      if (!mounted) return;

      if (res['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã mở khóa tài khoản của Đại Sư "$masterName".'),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
        _loadMasters(page: _currentPage);
      } else {
        _showWarningDialog(
          title: 'Mở khóa thất bại',
          message: res['message'] ?? 'Không thể cập nhật trạng thái tài khoản.',
        );
      }
    }
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
            // --- HEADER + THANH CÔNG CỤ 3 NÚT CRUD (THAY THẾ BANNER CHỮ ĐỎ) ---
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 16,
              runSpacing: 12,
              children: [
                // Tiêu đề màn hình
                const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.military_tech_outlined, color: Color(0xFFFFD700), size: 28),
                    SizedBox(width: 10),
                    Text(
                      'Hồ sơ Chuyên gia',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),

                // Thanh 3 nút CRUD (Thêm, Sửa, Xóa) có hiệu ứng Hover gạch chân
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    _HoverActionButton(
                      label: 'Thêm Đại Sư (Chuyên gia)',
                      icon: Icons.person_add_alt_1,
                      accentColor: const Color(0xFF4CAF50),
                      onTap: _openAddMasterDialog,
                    ),
                    _HoverActionButton(
                      label: 'Sửa Dữ liệu Đại Sư (Chuyên Gia)',
                      icon: Icons.edit_note,
                      accentColor: const Color(0xFF29B6F6),
                      onTap: _openEditMasterDialog,
                    ),
                    _HoverActionButton(
                      label: 'Xóa Dữ liệu Đại Sư (Chuyên Gia)',
                      icon: Icons.delete_outline,
                      accentColor: const Color(0xFFEF5350),
                      onTap: _openDeleteMasterDialog,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 18),

            // --- BẢNG DỮ LIỆU DATA GRID 12 CỘT CHUẨN DARK THEME ---
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF161F36),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF2E3B5F), width: 1.2),
                  boxShadow: const [
                    BoxShadow(color: Colors.black38, blurRadius: 10, offset: Offset(0, 4)),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: Color(0xFFFFD700)))
                    : _masters.isEmpty
                        ? const Center(
                            child: Text(
                              'Chưa có chuyên gia nào trong hệ thống.',
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
                                      child: _build12ColumnTable(),
                                    ),
                                    SizedBox(
                                      width: 14,
                                      child: _CustomVerticalScrollbar(controller: _verticalScrollController),
                                    ),
                                  ],
                                ),
                              ),
                              _buildPaginationBar(),
                            ],
                          ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- BUILD BẢNG 14 CỘT CHI TIẾT VỚI THANH CUỘN 2 CHIỀU CÓ SCROLLBAR HIỂN THỊ ---
  Widget _build12ColumnTable() {
    const double tableWidth = 1740.0;

    return ScrollConfiguration(
      behavior: _AlwaysDragScrollBehavior(),
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
                // 1. Header 14 Cột (Tổng ~1690px, đặt trong tableWidth 1740px ôm trọn không overflow)
                Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFF101628),
                    border: Border(bottom: BorderSide(color: Color(0xFF2E3B5F), width: 1.5)),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                  child: Row(
                    children: const [
                      // 1. STT (50px)
                      SizedBox(width: 50, child: Text('STT', textAlign: TextAlign.center, style: _headerStyle)),
                      // 2. Tên Thành viên (130px)
                      SizedBox(width: 130, child: Text('Tên Thành viên', style: _headerStyle)),
                      // 3. Tên Đại Sư (Chuyên Gia) (160px)
                      SizedBox(width: 160, child: Text('Tên Đại Sư (Chuyên Gia)', style: _headerStyle)),
                      // 4. Xếp hạng (130px)
                      SizedBox(width: 130, child: Text('Xếp hạng', textAlign: TextAlign.center, style: _headerStyle)),
                      // 5. Logo Danh hiệu (110px)
                      SizedBox(width: 110, child: Text('Logo Danh hiệu', textAlign: TextAlign.center, style: _headerStyle)),
                      // 6. Ngày tham gia (110px)
                      SizedBox(width: 110, child: Text('Ngày tham gia', textAlign: TextAlign.center, style: _headerStyle)),
                      // 7. Số Ngày đặt lịch xem (Online) (110px)
                      SizedBox(width: 110, child: Text('Lịch Online\n(Số Ngày)', textAlign: TextAlign.center, style: _headerStyle)),
                      // 8. Số Ngày đặt lịch xem (Offline) (110px)
                      SizedBox(width: 110, child: Text('Lịch Offline\n(Số Ngày)', textAlign: TextAlign.center, style: _headerStyle)),
                      // 9. Số Ngày Hủy lịch (100px)
                      SizedBox(width: 100, child: Text('Hủy lịch\n(Số Ngày)', textAlign: TextAlign.center, style: _headerStyle)),
                      // 10. Số Người đặt lịch xem (110px)
                      SizedBox(width: 110, child: Text('Người đặt\n(Tổng số)', textAlign: TextAlign.center, style: _headerStyle)),
                      // 11. Số tiền nhận được trong tuần (160px)
                      SizedBox(width: 160, child: Text('Tiền nhận trong tuần\n(VNĐ)', textAlign: TextAlign.right, style: _headerStyle)),
                      // 12. Cảm ơn (90px)
                      SizedBox(width: 90, child: Text('Cảm ơn\n(Lượt)', textAlign: TextAlign.center, style: _headerStyle)),
                      // 13. Mở Tài khoản (165px)
                      SizedBox(width: 165, child: Text('Mở Tài khoản', textAlign: TextAlign.center, style: _headerStyle)),
                      // 14. Khóa Tài khoản (155px)
                      SizedBox(width: 155, child: Text('Khóa Tài khoản', textAlign: TextAlign.center, style: _headerStyle)),
                    ],
                  ),
                ),

                // 2. Danh sách các hàng dữ liệu (Cuộn dọc)
                Expanded(
                  child: SingleChildScrollView(
                    controller: _verticalScrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      children: [
                        for (int i = 0; i < _masters.length; i++) _buildMasterRow(_masters[i], i),
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

  // --- THANH ĐIỀU HƯỚNG PHÂN TRANG (PAGINATION CONTROLS) CHUẨN DARK THEME ---
  Widget _buildPaginationBar() {
    final startItem = _totalCount == 0 ? 0 : (_currentPage - 1) * _pageSize + 1;
    final endItem = (_currentPage * _pageSize) > _totalCount ? _totalCount : (_currentPage * _pageSize);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: Color(0xFF101628),
        border: Border(top: BorderSide(color: Color(0xFF2E3B5F), width: 1.2)),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 12,
        runSpacing: 8,
        children: [
          // 1. Thống kê số lượng
          Text(
            'Hiển thị $startItem - $endItem trên tổng số $_totalCount Đại Sư (25 dòng/trang)',
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),

          // 2. Nút Cuộn nhanh 2 chiều Bảng 14 cột
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              OutlinedButton.icon(
                onPressed: _scrollToStart,
                icon: const Icon(Icons.arrow_back, size: 14),
                label: const Text('Đầu bảng (Cột 1-7)', style: TextStyle(fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFFFD700),
                  side: const BorderSide(color: Color(0xFF2E3B5F)),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: _scrollToEnd,
                icon: const Icon(Icons.arrow_forward, size: 14),
                label: const Text('Cuối bảng (Cột 8-14)', style: TextStyle(fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFFFD700),
                  side: const BorderSide(color: Color(0xFF2E3B5F)),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                ),
              ),
            ],
          ),

          // 3. Cụm nút điều hướng: < Trang trước | 1 2 3 ... | Trang sau >
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Nút Trang trước
              OutlinedButton.icon(
                onPressed: _currentPage > 1
                    ? () => _loadMasters(page: _currentPage - 1)
                    : null,
                icon: const Icon(Icons.chevron_left, size: 18),
                label: const Text('Trang trước'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFFFD700),
                  disabledForegroundColor: Colors.white30,
                  side: BorderSide(color: _currentPage > 1 ? const Color(0xFF2E3B5F) : Colors.white12),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
              const SizedBox(width: 8),

              // Các nút số trang
              for (int p = 1; p <= _totalPages; p++) ...[
                if (p == 1 || p == _totalPages || (p >= _currentPage - 2 && p <= _currentPage + 2)) ...[
                  InkWell(
                    onTap: p == _currentPage ? null : () => _loadMasters(page: p),
                    borderRadius: BorderRadius.circular(4),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: p == _currentPage ? const Color(0xFFFFD700) : const Color(0xFF161F36),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: p == _currentPage ? const Color(0xFFFFD700) : const Color(0xFF2E3B5F),
                        ),
                      ),
                      child: Text(
                        '$p',
                        style: TextStyle(
                          color: p == _currentPage ? Colors.black : Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ] else if (p == _currentPage - 3 || p == _currentPage + 3) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 2),
                    child: Text('...', style: TextStyle(color: Colors.white54)),
                  ),
                ],
              ],

              const SizedBox(width: 8),
              // Nút Trang sau
              OutlinedButton.icon(
                onPressed: _currentPage < _totalPages
                    ? () => _loadMasters(page: _currentPage + 1)
                    : null,
                icon: const Icon(Icons.chevron_right, size: 18),
                label: const Text('Trang sau'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFFFD700),
                  disabledForegroundColor: Colors.white30,
                  side: BorderSide(color: _currentPage < _totalPages ? const Color(0xFF2E3B5F) : Colors.white12),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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

  Widget _buildMasterRow(dynamic m, int index) {
    final isSelected = _selectedIndex == index;
    final isEven = index % 2 == 0;

    final stt = m['stt'] ?? ((_currentPage - 1) * _pageSize + index + 1);
    final username = m['username']?.toString() ?? '-';
    final masterName = m['masterName']?.toString() ?? '-';
    final rankTitle = m['rankTitle']?.toString() ?? 'Nhất Đẳng';
    final starLevel = (m['starLevel'] as num?)?.toInt() ?? 1;

    final isHighlighted = (m['userId'] != null && _highlightedUserId == m['userId']) ||
        (_highlightedUsername != null && _highlightedUsername!.isNotEmpty &&
            (username.toLowerCase() == _highlightedUsername!.toLowerCase() ||
             masterName.toLowerCase() == _highlightedUsername!.toLowerCase()));

    Color rowBg = isEven ? const Color(0xFF161F36) : const Color(0xFF131A30);
    if (isSelected || isHighlighted) {
      rowBg = const Color(0xFF1E2F5A); // Highlight khi chọn dòng hoặc vừa cập nhật
    }

    String joinDateFormatted = '-';
    if (m['joinDateFormatted'] != null && m['joinDateFormatted'].toString().isNotEmpty) {
      joinDateFormatted = m['joinDateFormatted'].toString();
    } else if (m['joinDate'] != null) {
      try {
        joinDateFormatted = DateFormat('dd/MM/yyyy').format(DateTime.parse(m['joinDate'].toString()).toLocal());
      } catch (_) {
        joinDateFormatted = '-';
      }
    }
    final onlineDays = m['onlineBookingDays'] ?? 0;
    final offlineDays = m['offlineBookingDays'] ?? 0;
    final cancelledDays = m['cancelledBookingDays'] ?? 0;
    final bookedClients = m['totalBookedClients'] ?? 0;
    final thanksCount = m['thanksCount'] ?? 0;
    final bool isActive = (m['isActive'] as bool?) ?? true;

    String earningsStr = '0 đ';
    if (m['weeklyEarningsFormatted'] != null && m['weeklyEarningsFormatted'].toString().isNotEmpty) {
      earningsStr = m['weeklyEarningsFormatted'].toString();
    } else if (m['weeklyEarnings'] != null) {
      final double val = double.tryParse(m['weeklyEarnings'].toString()) ?? 0;
      earningsStr = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(val);
    }

    return InkWell(
      onTap: () {
        setState(() {
          if (_selectedIndex == index) {
            _selectedIndex = null; // Bỏ chọn
          } else {
            _selectedIndex = index; // Chọn dòng
          }
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color: rowBg,
          border: Border(
            bottom: const BorderSide(color: Color(0xFF242F50), width: 0.8),
            left: (isSelected || isHighlighted) ? const BorderSide(color: Color(0xFFFFD700), width: 4) : BorderSide.none,
            top: isHighlighted ? const BorderSide(color: Color(0xFFFFD700), width: 1.5) : BorderSide.none,
            right: isHighlighted ? const BorderSide(color: Color(0xFFFFD700), width: 1.5) : BorderSide.none,
          ),
        ),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 1. STT (50px)
            SizedBox(
              width: 50,
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

            // 2. Tên Thành viên (130px)
            SizedBox(
              width: 130,
              child: Text(
                username,
                style: const TextStyle(
                  color: Color(0xFFFFD700),
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // 3. Tên Đại Sư (Chuyên Gia) (160px)
            SizedBox(
              width: 160,
              child: Text(
                masterName,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13.5,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // 4. Xếp hạng (130px) - Chuẩn động Hình 8
            SizedBox(
              width: 130,
              child: Center(
                child: UserRankBadgeWidget(
                  userId: m['userId'] ?? m['id'],
                  rankTitle: rankTitle,
                  starLevel: starLevel,
                  width: 118,
                  height: 42,
                ),
              ),
            ),

            // 5. Logo Danh hiệu (110px) - Chuẩn động Hình 9 (hoặc Hình 7 nếu là Thành viên)
            SizedBox(
              width: 110,
              child: Center(
                child: rankTitle.toLowerCase().contains('thành viên')
                    ? MemberTitleLogoWidget(
                        userId: m['userId'] ?? m['id'],
                        starLevel: starLevel,
                        rankTitle: rankTitle,
                        width: 44,
                        height: 52,
                      )
                    : MasterTitleLogoWidget(
                        userId: m['userId'] ?? m['id'],
                        starLevel: starLevel,
                        rankTitle: rankTitle,
                        width: 44,
                        height: 52,
                      ),
              ),
            ),

            // 6. Ngày tham gia (110px)
            SizedBox(
              width: 110,
              child: Text(
                joinDateFormatted,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[300], fontSize: 12.5),
              ),
            ),

            // 7. Số Ngày đặt lịch xem (Online) (110px)
            SizedBox(
              width: 110,
              child: Text(
                '$onlineDays',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF64B5F6), fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),

            // 8. Số Ngày đặt lịch xem (Offline) (110px)
            SizedBox(
              width: 110,
              child: Text(
                '$offlineDays',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF81C784), fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),

            // 9. Số Ngày Hủy lịch (100px)
            SizedBox(
              width: 100,
              child: Text(
                '$cancelledDays',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFFE57373), fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),

            // 10. Số Người đặt lịch xem (110px)
            SizedBox(
              width: 110,
              child: Text(
                '$bookedClients',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),

            // 11. Số tiền nhận được trong tuần (160px)
            SizedBox(
              width: 160,
              child: Text(
                earningsStr,
                textAlign: TextAlign.right,
                style: const TextStyle(color: Color(0xFFFFD54F), fontWeight: FontWeight.bold, fontSize: 13.5),
              ),
            ),

            // 12. Cảm ơn (90px)
            SizedBox(
              width: 90,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.favorite, color: Color(0xFFE91E63), size: 14),
                  const SizedBox(width: 4),
                  Text(
                    '$thanksCount',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12.5),
                  ),
                ],
              ),
            ),

            // 13. Mở Tài khoản (165px)
            SizedBox(
              width: 165,
              child: Center(
                child: SizedBox(
                  height: 28,
                  width: 100,
                  child: ElevatedButton(
                    onPressed: !isActive ? () => _handleUnlockMaster(m) : null,
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

            // 14. Khóa Tài khoản (155px)
            SizedBox(
              width: 155,
              child: Center(
                child: SizedBox(
                  height: 28,
                  width: 90,
                  child: ElevatedButton(
                    onPressed: isActive ? () => _handleLockMaster(m) : null,
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
          ],
        ),
      ),
    );
  }
}

/// Widget Nút Chức Năng với Hiệu ứng Hover Gạch Chân (Underline UX)
class _HoverActionButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color accentColor;
  final VoidCallback onTap;

  const _HoverActionButton({
    required this.label,
    required this.icon,
    required this.accentColor,
    required this.onTap,
  });

  @override
  State<_HoverActionButton> createState() => _HoverActionButtonState();
}

class _HoverActionButtonState extends State<_HoverActionButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final bgCol = _isHovered
        ? widget.accentColor.withValues(alpha: 0.18)
        : const Color(0xFF131A30);
    final borderCol = _isHovered
        ? widget.accentColor
        : const Color(0xFF2E3B5F);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: bgCol,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: borderCol, width: 1.2),
            boxShadow: _isHovered
                ? [
                    BoxShadow(
                      color: widget.accentColor.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, color: widget.accentColor, size: 18),
              const SizedBox(width: 8),
              Text(
                widget.label,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  letterSpacing: 0.2,
                  decoration: _isHovered ? TextDecoration.underline : TextDecoration.none,
                  decorationColor: widget.accentColor,
                  decorationThickness: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Thanh cuộn dọc chuyên biệt cho Bảng Hồ sơ Chuyên gia (Luôn hiển thị cố định ở mép phải của bảng)
class _CustomVerticalScrollbar extends StatelessWidget {
  final ScrollController controller;

  const _CustomVerticalScrollbar({required this.controller});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final bool hasValidDimensions = controller.hasClients &&
            controller.positions.isNotEmpty &&
            controller.position.hasContentDimensions;
        final bool canScroll = hasValidDimensions && controller.position.maxScrollExtent > 0;

        return LayoutBuilder(
          builder: (context, constraints) {
            double trackHeight = constraints.maxHeight;
            if (!trackHeight.isFinite || trackHeight <= 0) {
              if (constraints.minHeight.isFinite && constraints.minHeight > 0) {
                trackHeight = constraints.minHeight;
              } else {
                trackHeight = 520.0;
              }
            }

            final double staticThumbHeight = (trackHeight - 8).clamp(20.0, trackHeight);

            if (!canScroll || !hasValidDimensions) {
              return Container(
                width: 14,
                height: trackHeight,
                decoration: const BoxDecoration(
                  color: Color(0xFF0D1424),
                  border: Border(left: BorderSide(color: Color(0xFF2E3B5F), width: 1)),
                ),
                child: Stack(
                  children: [
                    SizedBox(width: 14, height: trackHeight),
                    Positioned(
                      top: 4,
                      left: 1.5,
                      right: 1.5,
                      height: staticThumbHeight,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFD700),
                          borderRadius: BorderRadius.circular(6),
                          boxShadow: const [
                            BoxShadow(color: Colors.black45, blurRadius: 3),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }

            final pos = controller.position;
            final maxExtent = pos.maxScrollExtent;
            if (maxExtent <= 0) {
              return Container(
                width: 14,
                height: trackHeight,
                decoration: const BoxDecoration(
                  color: Color(0xFF0D1424),
                  border: Border(left: BorderSide(color: Color(0xFF2E3B5F), width: 1)),
                ),
                child: Stack(
                  children: [
                    SizedBox(width: 14, height: trackHeight),
                    Positioned(
                      top: 4,
                      left: 1.5,
                      right: 1.5,
                      height: staticThumbHeight,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFD700),
                          borderRadius: BorderRadius.circular(6),
                          boxShadow: const [
                            BoxShadow(color: Colors.black45, blurRadius: 3),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }

            final currentPixels = pos.pixels.clamp(0.0, maxExtent);
            final viewportDim = pos.viewportDimension;
            final totalScrollable = maxExtent + viewportDim;

            final thumbHeightRatio = totalScrollable > 0
                ? (viewportDim / totalScrollable).clamp(0.12, 0.85)
                : 0.2;
            final thumbHeight = (trackHeight * thumbHeightRatio).clamp(32.0, trackHeight);
            final availableTravel = (trackHeight - thumbHeight).clamp(0.0, trackHeight);
            final thumbOffset = (availableTravel > 0 && maxExtent > 0)
                ? ((currentPixels / maxExtent) * availableTravel).clamp(0.0, availableTravel)
                : 0.0;

            return MouseRegion(
              cursor: SystemMouseCursors.grab,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onVerticalDragUpdate: (details) {
                  if (availableTravel > 0 && maxExtent > 0) {
                    final deltaFraction = details.delta.dy / availableTravel;
                    final newPixels = (controller.offset + deltaFraction * maxExtent).clamp(0.0, maxExtent);
                    controller.jumpTo(newPixels);
                  }
                },
                onTapDown: (details) {
                  if (availableTravel > 0 && maxExtent > 0) {
                    final tapRatio = (details.localPosition.dy / trackHeight).clamp(0.0, 1.0);
                    controller.jumpTo((tapRatio * maxExtent).clamp(0.0, maxExtent));
                  }
                },
                child: Container(
                  width: 14,
                  height: trackHeight,
                  decoration: const BoxDecoration(
                    color: Color(0xFF0D1424),
                    border: Border(left: BorderSide(color: Color(0xFF2E3B5F), width: 1)),
                  ),
                  child: Stack(
                    children: [
                      SizedBox(width: 14, height: trackHeight),
                      Positioned(
                        top: thumbOffset,
                        left: 1.5,
                        right: 1.5,
                        height: thumbHeight,
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFD700),
                            borderRadius: BorderRadius.circular(6),
                            boxShadow: const [
                              BoxShadow(color: Colors.black45, blurRadius: 3),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
