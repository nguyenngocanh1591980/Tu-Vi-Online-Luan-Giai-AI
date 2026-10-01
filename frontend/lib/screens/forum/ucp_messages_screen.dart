// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/ucp_state_service.dart';
import '../../utils/boxed_snack_bar.dart';

/// Màn hình Tin nhắn (UCP Messages Screen) độc lập
class UcpMessagesScreen extends StatefulWidget {
  final int initialSidebarIndex;
  const UcpMessagesScreen({super.key, this.initialSidebarIndex = 0});

  @override
  State<UcpMessagesScreen> createState() => _UcpMessagesScreenState();
}

class _UcpMessagesScreenState extends State<UcpMessagesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.initialSidebarIndex == 2) {
        UcpStateService.setSubItem('Tin nhắn', 'Hộp thư nhận');
      } else {
        UcpStateService.setSubItem('Tin nhắn', 'Soạn tin nhắn');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Material(color: Colors.transparent, child: 
      
      SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildTitleBar(context),
            UcpMessagesContent(initialSidebarIndex: widget.initialSidebarIndex),
            const SizedBox(height: 28),
            _buildForumFooter(context),
          ],
        ),
      ),
    );
  }

  Widget _buildTitleBar(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF131A30),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF2A3450), width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.email, color: Color(0xFFFFD700), size: 20),
              const SizedBox(width: 10),
              ValueListenableBuilder<UcpNavigationState>(
                valueListenable: UcpStateService.navigationState,
                builder: (context, navState, _) {
                  final title = navState.subItem ?? 'Soạn tin nhắn';
                  return Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFFD700),
                      letterSpacing: 0.5,
                    ),
                  );
                },
              ),
            ],
          ),
          InkWell(
            onTap: () => context.go('/forum'),
            child: Row(
              children: const [
                Icon(Icons.arrow_back_ios, color: Color(0xFF90CAF9), size: 14),
                SizedBox(width: 4),
                Text(
                  'Về Diễn đàn',
                  style: TextStyle(
                    color: Color(0xFF90CAF9),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForumFooter(BuildContext context) {
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
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
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
                  InkWell(
                    onTap: () => context.go('/forum/ucp'),
                    child: const Text('Thiết lập cá nhân', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFEF5350))),
                  ),
                  const SizedBox(width: 6),
                  const Text('<', style: TextStyle(color: Colors.white38, fontSize: 12)),
                  const SizedBox(width: 6),
                  InkWell(
                    onTap: () => context.go('/forum/ucp/messages'),
                    child: const Text('Tin nhắn', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFEF5350))),
                  ),
                  const SizedBox(width: 6),
                  const Text('<', style: TextStyle(color: Colors.white38, fontSize: 12)),
                  const SizedBox(width: 6),
                  ValueListenableBuilder<UcpNavigationState>(
                    valueListenable: UcpStateService.navigationState,
                    builder: (context, navState, _) {
                      final title = navState.subItem ?? 'Soạn tin nhắn';
                      return Text(title, style: const TextStyle(color: Colors.white70));
                    },
                  ),
                ],
              ),
              Wrap(
                spacing: 12,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _buildFooterLink(Icons.email, 'Liên hệ'),
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

/// Widget nội dung tab Tin nhắn với Theme Dark Navy (#1E2640), Boxed Layout 1024px và xử lý Overflow
class UcpMessagesContent extends StatefulWidget {
  final int initialSidebarIndex;

  const UcpMessagesContent({
    super.key,
    this.initialSidebarIndex = 0,
  });

  @override
  State<UcpMessagesContent> createState() => _UcpMessagesContentState();
}

class _UcpMessagesContentState extends State<UcpMessagesContent> {
  static const List<String> _folderKeys = ['compose', 'drafts', 'inbox', 'outbox', 'sent', 'rules'];
  String _currentFolder = 'compose';
  String _exportFormat = 'csv';
  String _markAction = 'mark_important';
  int _currentPage = 1;
  final int _totalPages = 2;

  // State phân mục Bộ lọc và thư mục tin (Hình 2)
  String _ruleField = 'Tiêu đề';
  final TextEditingController _folderNameController = TextEditingController();
  String _overCapacityAction = 'delete_old';
  String _moveTargetFolder = 'Hộp tin nhận (27 trong số 500 tin nhắn được lưu)';

  final List<String> _friendsList = [
    'hoangnguyenhuu',
    'phamquynh',
  ];

  // Khối Khám phá thêm đặc trưng của Tab Tin nhắn (Hình 5)
  final List<String> _exploreCategories = [
    'Trang trí nhà và nội thất',
    'Lịch sử',
    'Đạo Phật',
  ];

  // Danh sách 27 tin nhắn chuẩn xác bảo toàn 100% dữ liệu gốc (Hình 5)
  final List<Map<String, dynamic>> _messages = [
    {
      'id': 1,
      'title': 'TL: trả lời tổng kết',
      'author': 'hoangnguyenhuu',
      'time': '19:26, 07/12/14',
      'isUnread': false,
      'isImportant': false,
      'isSelected': false,
    },
    {
      'id': 2,
      'title': 'TL: trả lời tổng kết',
      'author': 'hoangnguyenhuu',
      'time': '19:22, 07/12/14',
      'isUnread': false,
      'isImportant': false,
      'isSelected': false,
    },
    {
      'id': 3,
      'title': 'TL: Trả lời',
      'author': 'hoangnguyenhuu',
      'time': '19:17, 07/12/14',
      'isUnread': false,
      'isImportant': false,
      'isSelected': false,
    },
    {
      'id': 4,
      'title': 'TL: Trả lời',
      'author': 'hoangnguyenhuu',
      'time': '18:27, 07/12/14',
      'isUnread': false,
      'isImportant': false,
      'isSelected': false,
    },
    {
      'id': 5,
      'title': 'TL: Xem lá số cho em',
      'author': 'hoangnguyenhuu',
      'time': '16:35, 07/12/14',
      'isUnread': false,
      'isImportant': false,
      'isSelected': false,
    },
    {
      'id': 6,
      'title': 'TL: Xem lá số cho em',
      'author': 'hoangnguyenhuu',
      'time': '15:59, 07/12/14',
      'isUnread': false,
      'isImportant': false,
      'isSelected': false,
    },
    {
      'id': 7,
      'title': 'TL: Xem lá số cho em',
      'author': 'hoangnguyenhuu',
      'time': '15:56, 07/12/14',
      'isUnread': false,
      'isImportant': false,
      'isSelected': false,
    },
    {
      'id': 8,
      'title': 'chào a',
      'author': 'hoangnguyenhuu',
      'time': '15:51, 07/12/14',
      'isUnread': false,
      'isImportant': false,
      'isSelected': false,
    },
    {
      'id': 9,
      'title': 'TL: Anh gửi cho em rồi mà',
      'author': 'hoangnguyenhuu',
      'time': '15:38, 07/12/14',
      'isUnread': false,
      'isImportant': false,
      'isSelected': false,
      'highlightType': 'yellow',
    },
    {
      'id': 10,
      'title': 'TL: Anh gửi cho em rồi mà',
      'author': 'hoangnguyenhuu',
      'time': '15:27, 07/12/14',
      'isUnread': false,
      'isImportant': false,
      'isSelected': false,
    },
    {
      'id': 11,
      'title': 'TL: Anh gửi cho em rồi mà',
      'author': 'hoangnguyenhuu',
      'time': '15:18, 07/12/14',
      'isUnread': false,
      'isImportant': false,
      'isSelected': false,
    },
    {
      'id': 12,
      'title': 'TL: Anh gửi cho em rồi mà',
      'author': 'hoangnguyenhuu',
      'time': '15:13, 07/12/14',
      'isUnread': false,
      'isImportant': false,
      'isSelected': false,
    },
    {
      'id': 13,
      'title': 'TL: Anh gửi cho em rồi mà',
      'author': 'hoangnguyenhuu',
      'time': '13:06, 07/12/14',
      'isUnread': false,
      'isImportant': false,
      'isSelected': false,
    },
    {
      'id': 14,
      'title': 'TL: Anh gửi cho em rồi mà',
      'author': 'hoangnguyenhuu',
      'time': '13:05, 07/12/14',
      'isUnread': false,
      'isImportant': false,
      'isSelected': false,
    },
    {
      'id': 15,
      'title': 'chào a',
      'author': 'hoangnguyenhuu',
      'time': '13:01, 07/12/14',
      'isUnread': false,
      'isImportant': false,
      'isSelected': false,
    },
    {
      'id': 16,
      'title': 'chào a',
      'author': 'hoangnguyenhuu',
      'time': '12:23, 07/12/14',
      'isUnread': false,
      'isImportant': false,
      'isSelected': false,
    },
    {
      'id': 17,
      'title': 'e mong a giúp',
      'author': 'hoangnguyenhuu',
      'time': '11:49, 07/12/14',
      'isUnread': false,
      'isImportant': false,
      'isSelected': false,
    },
    {
      'id': 18,
      'title': 'mong a giúp a',
      'author': 'hoangnguyenhuu',
      'time': '11:45, 07/12/14',
      'isUnread': false,
      'isImportant': false,
      'isSelected': false,
    },
    {
      'id': 19,
      'title': 'TL: em cần hỏi chuyện gì ?',
      'author': 'hoangnguyenhuu',
      'time': '11:06, 06/12/14',
      'isUnread': false,
      'isImportant': false,
      'isSelected': false,
    },
    {
      'id': 20,
      'title': 'SDG',
      'author': 'hoangnguyenhuu',
      'time': '21:43, 03/12/14',
      'isUnread': false,
      'isImportant': false,
      'isSelected': false,
    },
    {
      'id': 21,
      'title': 'TL: Toàn bộ gửi qua email của bạn',
      'author': 'hoangnguyenhuu',
      'time': '15:35, 03/12/14',
      'isUnread': false,
      'isImportant': false,
      'isSelected': false,
      'highlightType': 'blue',
    },
    {
      'id': 22,
      'title': 'TL: A vẫn mãi là cánh chim độc cô hành mà thôi!',
      'author': 'phamquynh',
      'time': '18:32, 09/11/14',
      'isUnread': false,
      'isImportant': false,
      'isSelected': false,
      'highlightType': 'blue',
    },
    {
      'id': 23,
      'title': 'TL: nhìn nick không nhận ra anh hả',
      'author': 'phamquynh',
      'time': '22:30, 09/11/14',
      'isUnread': false,
      'isImportant': false,
      'isSelected': false,
      'highlightType': 'blue',
    },
    {
      'id': 24,
      'title': 'TL: nhìn nick không nhận ra anh hả',
      'author': 'phamquynh',
      'time': '22:17, 09/11/14',
      'isUnread': false,
      'isImportant': false,
      'isSelected': false,
      'highlightType': 'orange',
    },
    {
      'id': 25,
      'title': 'TL: sao không trả lời vậy',
      'author': 'phamquynh',
      'time': '19:35, 09/11/14',
      'isUnread': false,
      'isImportant': false,
      'isSelected': false,
    },
    {
      'id': 26,
      'title': 'TL: sao không trả lời vậy',
      'author': 'phamquynh',
      'time': '19:30, 09/11/14',
      'isUnread': false,
      'isImportant': false,
      'isSelected': false,
    },
    {
      'id': 27,
      'title': 'chào anh',
      'author': 'phamquynh',
      'time': '19:15, 09/11/14',
      'isUnread': false,
      'isImportant': false,
      'isSelected': false,
    },
  ];

  // Danh sách 12 tin nhắn đã gửi chuẩn xác bảo toàn 100% dữ liệu gốc (Hình 5)
  final List<Map<String, dynamic>> _sentMessages = [
    {
      'id': 1,
      'title': 'trả lời tổng kết',
      'recipient': 'binh131091',
      'time': '14:17, 07/12/14',
      'isSelected': false,
    },
    {
      'id': 2,
      'title': 'Trả lời',
      'recipient': 'binh131091',
      'time': '14:02, 07/12/14',
      'isSelected': false,
    },
    {
      'id': 3,
      'title': 'Xem lá số cho em',
      'recipient': 'binh131091',
      'time': '13:49, 07/12/14',
      'isSelected': false,
    },
    {
      'id': 4,
      'title': 'Anh gửi cho em rùi mà',
      'recipient': 'binh131091',
      'time': '12:56, 07/12/14',
      'isSelected': false,
    },
    {
      'id': 5,
      'title': 'em cần hỏi chuyện gì ?',
      'recipient': 'binh131091',
      'time': '10:50, 07/12/14',
      'isSelected': false,
    },
    {
      'id': 6,
      'title': 'Thế không sợ chồng ghen hả?',
      'titleColor': const Color(0xFFEF5350),
      'recipient': 'phamquynh',
      'recipientColor': const Color(0xFF81C784),
      'time': '21:07, 30/11/14',
      'isSelected': false,
    },
    {
      'id': 7,
      'title': 'A vẫn mãi là cánh chim độc cô hành mà thôi!?',
      'recipient': 'phamquynh',
      'recipientColor': const Color(0xFF81C784),
      'time': '09:20, 30/11/14',
      'isSelected': false,
    },
    {
      'id': 8,
      'title': 'nhìn nick không nhận ra anh hả',
      'recipient': 'phamquynh',
      'recipientColor': const Color(0xFF81C784),
      'time': '17:52, 29/11/14',
      'isSelected': false,
    },
    {
      'id': 9,
      'title': 'Toàn bộ gửi qua email của bạn',
      'recipient': 'hoangnguyenhuu',
      'recipientColor': const Color(0xFFFFB74D),
      'time': '11:41, 29/11/14',
      'isSelected': false,
    },
    {
      'id': 10,
      'title': 'Bạn có đủ bộ bản phủ đó không',
      'recipient': 'hoangnguyenhuu',
      'recipientColor': const Color(0xFFFFB74D),
      'time': '22:44, 28/11/14',
      'isSelected': false,
    },
    {
      'id': 11,
      'title': 'xin chao cao nhan',
      'recipient': 'hoangnguyenhuu',
      'recipientColor': const Color(0xFFFFB74D),
      'time': '20:10, 27/11/14',
      'isSelected': false,
    },
    {
      'id': 12,
      'title': 'sao khong tra loi vay',
      'titleColor': const Color(0xFFEF5350),
      'recipient': 'phamquynh',
      'recipientColor': const Color(0xFF81C784),
      'time': '11:29, 27/11/14',
      'isSelected': false,
    },
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialSidebarIndex >= 0 && widget.initialSidebarIndex < _folderKeys.length) {
      _currentFolder = _folderKeys[widget.initialSidebarIndex];
    }
  }

  @override
  void didUpdateWidget(covariant UcpMessagesContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialSidebarIndex != oldWidget.initialSidebarIndex &&
        widget.initialSidebarIndex >= 0 &&
        widget.initialSidebarIndex < _folderKeys.length) {
      setState(() {
        _currentFolder = _folderKeys[widget.initialSidebarIndex];
      });
    }
  }

  @override
  void dispose() {
    _folderNameController.dispose();
    super.dispose();
  }

  bool get _isAllSelected =>
      _messages.isNotEmpty && _messages.every((m) => m['isSelected'] == true);

  void _toggleSelectAll(bool? val) {
    setState(() {
      final selected = val ?? false;
      for (var m in _messages) {
        m['isSelected'] = selected;
      }
    });
  }

  bool get _isAllSentSelected =>
      _sentMessages.isNotEmpty && _sentMessages.every((m) => m['isSelected'] == true);

  void _toggleSelectAllSent(bool? val) {
    setState(() {
      final selected = val ?? false;
      for (var m in _sentMessages) {
        m['isSelected'] = selected;
      }
    });
  }

  void _executeSentAction() {
    final selectedCount = _sentMessages.where((m) => m['isSelected'] == true).length;
    if (selectedCount == 0) {
      _showBoxedSnackBar('Vui lòng chọn ít nhất một tin nhắn để thao tác.', isError: true);
      return;
    }

    setState(() {
      if (_markAction == 'delete') {
        _sentMessages.removeWhere((m) => m['isSelected'] == true);
      }
    });

    _showBoxedSnackBar('Đã thực hiện thao tác thành công trên $selectedCount tin nhắn.');
  }

  void _executeAction() {
    final selectedCount = _messages.where((m) => m['isSelected'] == true).length;
    if (selectedCount == 0) {
      _showBoxedSnackBar('Vui lòng chọn ít nhất một tin nhắn để thao tác.', isError: true);
      return;
    }

    setState(() {
      if (_markAction == 'mark_important') {
        for (var m in _messages) {
          if (m['isSelected'] == true) {
            m['isImportant'] = !(m['isImportant'] ?? false);
          }
        }
      } else if (_markAction == 'mark_read') {
        for (var m in _messages) {
          if (m['isSelected'] == true) {
            m['isUnread'] = false;
          }
        }
      } else if (_markAction == 'mark_unread') {
        for (var m in _messages) {
          if (m['isSelected'] == true) {
            m['isUnread'] = true;
          }
        }
      } else if (_markAction == 'delete') {
        _messages.removeWhere((m) => m['isSelected'] == true);
      }
    });

    _showBoxedSnackBar('Đã thực hiện thao tác thành công trên $selectedCount tin nhắn.');
  }

  void _exportFolder() {
    _showBoxedSnackBar('Đang xuất thư mục định dạng ${_exportFormat.toUpperCase()}...');
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Khối Card chính gồm Sidebar + Nội dung tương ứng (HỢP NHẤT LIỀN MẠCH 1 KHỐI)
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF161F36),
            border: Border.all(color: const Color(0xFF2E3B5F)),
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(6),
              bottomLeft: Radius.circular(6),
              bottomRight: Radius.circular(6),
            ),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = constraints.maxWidth < 750;

              if (isMobile) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildSidebar(),
                    const Divider(color: Color(0xFF2E3B5F), height: 1),
                    _buildCurrentContent(),
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Sidebar bên trái: width 220, nền #161F36
                  SizedBox(
                    width: 220,
                    child: _buildSidebar(),
                  ),
                  // Đường phân cách giữa Sidebar và Nội dung: #2E3B5F
                  Container(
                    width: 1,
                    color: const Color(0xFF2E3B5F),
                  ),
                  // Cột nội dung bên phải: nền #1E2640
                  Expanded(
                    child: _buildCurrentContent(),
                  ),
                ],
              );
            },
          ),
        ),

        const SizedBox(height: 16),

        // Khối Khám phá thêm đặc trưng của Tab Tin nhắn (Hình 5)
        _buildExploreMoreSection(),
      ],
    );
  }

  // Sidebar Menu bên trái
  Widget _buildSidebar() {
    return Container(
      color: const Color(0xFF161F36),
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSidebarItem(
            id: 'compose',
            title: 'Soạn tin nhắn',
            icon: Icons.edit_square,
            isActive: _currentFolder == 'compose',
          ),
          _buildSidebarItem(
            id: 'drafts',
            title: 'Tin nhắn nháp',
            icon: Icons.drafts,
            isActive: _currentFolder == 'drafts',
          ),
          _buildSidebarItem(
            id: 'inbox',
            title: 'Hộp thư nhận',
            count: 37,
            icon: Icons.inbox,
            isActive: _currentFolder == 'inbox',
          ),
          _buildSidebarItem(
            id: 'outbox',
            title: 'Hộp thư chuyển đi',
            count: 0,
            icon: Icons.outbox,
            isActive: _currentFolder == 'outbox',
          ),
          _buildSidebarItem(
            id: 'sent',
            title: 'Hộp thư đã gửi',
            count: 12,
            icon: Icons.send,
            isActive: _currentFolder == 'sent',
          ),

          const Divider(height: 1, thickness: 1, color: Color(0xFF2E3B5F)),

          _buildSidebarItem(
            id: 'rules',
            title: 'Bộ lọc và thư mục tin',
            icon: Icons.rule,
            isActive: _currentFolder == 'rules',
          ),

          const Divider(height: 1, thickness: 1, color: Color(0xFF2E3B5F)),

          // Mục Bạn thân
          Padding(
            padding: const EdgeInsets.all(14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Bạn thân',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFEF5350),
                  ),
                ),
                const SizedBox(height: 8),
                ..._friendsList.map((friend) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () => context.go('/forum/member/$friend'),
                              child: Text(
                                friend,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFFEF5350),
                                  decoration: TextDecoration.underline,
                                  decorationColor: Color(0xFFEF5350),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          InkWell(
                            onTap: () {},
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                border: Border.all(color: const Color(0xFF3F4E75)),
                                borderRadius: BorderRadius.circular(4),
                                color: const Color(0xFF2A3450),
                              ),
                              child: const Text('Thêm vào', style: TextStyle(color: Colors.white, fontSize: 11)),
                            ),
                          ),
                        ],
                      ),
                    )),
              ],
            ),
          ),

          const Divider(height: 1, thickness: 1, color: Color(0xFF2E3B5F)),

          // Bảng mã màu loại tin nhắn (Hình 5)
          _buildMessageLegend(),
        ],
      ),
    );
  }

  Widget _buildMessageLegend() {
    return Padding(
      padding: const EdgeInsets.all(14.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Phân loại tin nhắn',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Color(0xFFEF5350),
            ),
          ),
          const SizedBox(height: 8),
          _buildLegendItem(const Color(0xFF00E5FF), 'Tin nhắn đã được đánh dấu'),
          _buildLegendItem(const Color(0xFFFF9800), 'Tin nhắn quan trọng'),
          _buildLegendItem(const Color(0xFFEF5350), 'Tin nhắn chưa đọc'),
          _buildLegendItem(const Color(0xFF2196F3), 'Tin nhắn từ bạn bè'),
          _buildLegendItem(const Color(0xFF9E9E9E), 'Tin nhắn đã đọc'),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 11.5, color: Colors.white70),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarItem({
    required String id,
    required String title,
    int? count,
    required IconData icon,
    required bool isActive,
  }) {
    return InkWell(
      onTap: () {
        setState(() {
          _currentFolder = id;
        });
        UcpStateService.setSubItem('Tin nhắn', title);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF263252) : Colors.transparent,
          border: isActive
              ? const Border(left: BorderSide(color: Color(0xFFEF5350), width: 4))
              : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: isActive ? Colors.white : Colors.grey[400],
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: isActive ? Colors.white : Colors.grey[300],
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  fontSize: 13,
                ),
              ),
            ),
            if (count != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: (id == 'inbox' || isActive) ? const Color(0xFFEF5350) : Colors.white12,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentContent() {
    switch (_currentFolder) {
      case 'compose':
        return _buildComposeArea();
      case 'drafts':
        return _buildDraftsArea();
      case 'outbox':
        return _buildOutboxArea();
      case 'sent':
        return _buildSentArea();
      case 'rules':
        return _buildRulesArea();
      case 'inbox':
      default:
        return _buildMessagesArea();
    }
  }

  // --- Phân Mục Bộ Lọc và Thư Mục Tin (Hình 2) ---
  Widget _buildRulesArea() {
    return Container(
      color: const Color(0xFF1E2640),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Bộ lọc và thư mục tin',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          const Divider(color: Color(0xFF2E3B5F), height: 1),
          const SizedBox(height: 16),

          // Khung cấu hình Dark Navy #161F36
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF161F36),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFF2E3B5F)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Những bộ lọc tin nhắn tự động đã có
                const Text(
                  'NHỮNG BỘ LỌC TIN NHẮN TỰ ĐỘNG ĐÃ CÓ',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: Colors.white70,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 10),
                const Divider(color: Color(0xFF2E3B5F), height: 1),
                const SizedBox(height: 12),
                const Text(
                  '1. Không có quy tắc nào được xác định.',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                const Divider(color: Color(0xFF2E3B5F), height: 1),
                const SizedBox(height: 14),

                // 2. Thêm quy tắc mới
                const Text(
                  'THÊM QUY TẮC MỚI',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: Colors.white70,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 10),
                const Divider(color: Color(0xFF2E3B5F), height: 1),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    const Text('Nếu:', style: TextStyle(fontSize: 13, color: Colors.white70)),
                    _buildDarkDropdown<String>(
                      value: _ruleField,
                      items: const [
                        DropdownMenuItem(value: 'Tiêu đề', child: Text('Tiêu đề')),
                        DropdownMenuItem(value: 'Người gửi', child: Text('Người gửi')),
                        DropdownMenuItem(value: 'Nội dung', child: Text('Nội dung')),
                        DropdownMenuItem(value: 'Thời gian', child: Text('Thời gian')),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _ruleField = val);
                      },
                    ),
                    _buildDarkButton('Bước kế tiếp', onTap: () {
                      _showBoxedSnackBar('Đang chuyển sang bước thiết lập điều kiện quy tắc...');
                    }),
                  ],
                ),
                const SizedBox(height: 20),
                const Divider(color: Color(0xFF2E3B5F), height: 1),
                const SizedBox(height: 14),

                // 3. Tùy chọn thư mục
                const Text(
                  'TÙY CHỌN THƯ MỤC',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: Colors.white70,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 10),
                const Divider(color: Color(0xFF2E3B5F), height: 1),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    const Text('Thêm thư mục:', style: TextStyle(fontSize: 13, color: Colors.white70)),
                    SizedBox(
                      width: 260,
                      height: 32,
                      child: TextField(
                        controller: _folderNameController,
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: const Color(0xFF131A30),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          border: OutlineInputBorder(
                            borderSide: const BorderSide(color: Color(0xFF2E3B5F)),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: const BorderSide(color: Color(0xFF2E3B5F)),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                    _buildDarkButton('Thêm vào', onTap: () {
                      final text = _folderNameController.text.trim();
                      if (text.isNotEmpty) {
                        _showBoxedSnackBar('Đã thêm thư mục mới: $text');
                        _folderNameController.clear();
                      } else {
                        _showBoxedSnackBar('Vui lòng nhập tên thư mục cần thêm.', isError: true);
                      }
                    }),
                  ],
                ),
                const SizedBox(height: 24),
                const Divider(color: Color(0xFF2E3B5F), height: 1),
                const SizedBox(height: 18),

                // 4. Nếu thư mục này vượt quá dung lượng cho phép
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isMobile = constraints.maxWidth < 650;

                    final leftLabel = SizedBox(
                      width: isMobile ? double.infinity : 220,
                      child: const Text(
                        'Nếu thư mục này vượt quá dung lượng cho phép:',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white70,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );

                    final rightOptions = Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Radio 1: Xóa những tin nhắn cũ
                        InkWell(
                          onTap: () => setState(() => _overCapacityAction = 'delete_old'),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Radio<String>(
                                value: 'delete_old',
                                groupValue: _overCapacityAction,
                                activeColor: const Color(0xFFEF5350),
                                onChanged: (v) => setState(() => _overCapacityAction = v!),
                              ),
                              const Text('Xóa những tin nhắn cũ', style: TextStyle(color: Colors.white, fontSize: 13)),
                            ],
                          ),
                        ),
                        // Radio 2: Di chuyển đến thư mục
                        InkWell(
                          onTap: () => setState(() => _overCapacityAction = 'move_to'),
                          child: Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Radio<String>(
                                value: 'move_to',
                                groupValue: _overCapacityAction,
                                activeColor: const Color(0xFFEF5350),
                                onChanged: (v) => setState(() => _overCapacityAction = v!),
                              ),
                              const Text('Di chuyển đến thư mục:', style: TextStyle(color: Colors.white, fontSize: 13)),
                              const SizedBox(width: 8),
                              ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 420),
                                child: _buildDarkDropdown<String>(
                                  value: _moveTargetFolder,
                                  isExpanded: true,
                                  items: const [
                                    DropdownMenuItem(
                                      value: 'Hộp tin nhận (27 trong số 500 tin nhắn được lưu)',
                                      child: Text(
                                        'Hộp tin nhận (27 trong số 500 tin nhắn được lưu)',
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    DropdownMenuItem(
                                      value: 'Hộp tin chuyển đi (0 trong số 500 tin nhắn được lưu)',
                                      child: Text(
                                        'Hộp tin chuyển đi (0 trong số 500 tin nhắn được lưu)',
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    DropdownMenuItem(
                                      value: 'Hộp tin đã gửi (12 trong số 500 tin nhắn được lưu)',
                                      child: Text(
                                        'Hộp tin đã gửi (12 trong số 500 tin nhắn được lưu)',
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                  onChanged: (v) {
                                    if (v != null) setState(() => _moveTargetFolder = v);
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Radio 3: Không nhận thêm những tin nhắn mới
                        InkWell(
                          onTap: () => setState(() => _overCapacityAction = 'reject_new'),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Radio<String>(
                                value: 'reject_new',
                                groupValue: _overCapacityAction,
                                activeColor: const Color(0xFFEF5350),
                                onChanged: (v) => setState(() => _overCapacityAction = v!),
                              ),
                              const Expanded(
                                child: Padding(
                                  padding: EdgeInsets.only(top: 12.0),
                                  child: Text(
                                    'Không nhận thêm những tin nhắn mới (Những tin nhắn mới sẽ quay lại khi nào dung lượng đủ cho phép)',
                                    style: TextStyle(color: Colors.white, fontSize: 13),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );

                    if (isMobile) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          leftLabel,
                          const SizedBox(height: 8),
                          rightOptions,
                        ],
                      );
                    }

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        leftLabel,
                        const SizedBox(width: 16),
                        Expanded(child: rightOptions),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 20),

                // 5. Thiết lập mặc định
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isMobile = constraints.maxWidth < 650;

                    final defaultLabel = SizedBox(
                      width: isMobile ? double.infinity : 220,
                      child: const Text(
                        'Thiết lập mặc định:',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white70,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );

                    final defaultContent = Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Xóa những tin nhắn cũ',
                          style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        _buildDarkButton('Thay đổi', onTap: () {
                          _showBoxedSnackBar('Đã cập nhật thiết lập mặc định thành công.');
                        }),
                      ],
                    );

                    if (isMobile) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          defaultLabel,
                          const SizedBox(height: 8),
                          defaultContent,
                        ],
                      );
                    }

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        defaultLabel,
                        const SizedBox(width: 16),
                        Expanded(child: defaultContent),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 20),

                // 6. Dòng chú thích cuối
                const Text(
                  'Những thiết lập này sẽ được tạo nhanh nếu như không có mục nào ở trên có thể dùng được.',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 12.5,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Phân Mục Hộp Thư Chuyển Đi (Hình 2) ---
  Widget _buildOutboxArea() {
    return Container(
      color: const Color(0xFF1E2640),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Thư mục Header & Dung lượng lưu trữ
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF161F36),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFF2E3B5F)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Xem tin nhắn: Hộp tin chuyển đi',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Thư mục 0% đã đầy (0 trong số 500 tin nhắn được lưu trữ)',
                  style: TextStyle(fontSize: 13, color: Colors.white70),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: const LinearProgressIndicator(
                    value: 0.0,
                    minHeight: 6,
                    backgroundColor: Colors.white12,
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00E5FF)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // 2. Thanh Công Cụ Trên (Nút Tin nhắn mới)
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _currentFolder = 'compose';
                  });
                  UcpStateService.setSubItem('Tin nhắn', 'Soạn tin nhắn');
                },
                icon: const Icon(Icons.edit, size: 16, color: Colors.white),
                label: const Text(
                  'Tin nhắn mới',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF131A30),
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Color(0xFF2E3B5F)),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 3. Khung Thông Báo Rỗng
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF161F36),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFF2E3B5F)),
            ),
            child: const Text(
              'Không có tin nhắn nào',
              style: TextStyle(
                color: Colors.white,
                fontSize: 13.5,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Phân Mục Hộp Thư Đã Gửi (Hình 5) ---
  Widget _buildSentArea() {
    return Container(
      color: const Color(0xFF1E2640),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Thư mục Header & Dung lượng lưu trữ
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF161F36),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFF2E3B5F)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Xem tin nhắn: Hộp tin đã gửi',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Thư mục 2% đã đầy (12 trong số 500 tin nhắn được lưu trữ)',
                  style: TextStyle(fontSize: 13, color: Colors.white70),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: const LinearProgressIndicator(
                    value: 12 / 500,
                    minHeight: 6,
                    backgroundColor: Colors.white12,
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00E5FF)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // 2. Thanh Công Cụ Trên (Nút Tin nhắn mới + Điều hướng)
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _currentFolder = 'compose';
                  });
                  UcpStateService.setSubItem('Tin nhắn', 'Soạn tin nhắn');
                },
                icon: const Icon(Icons.edit, size: 16, color: Colors.white),
                label: const Text(
                  'Tin nhắn mới',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF131A30),
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Color(0xFF2E3B5F)),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                ),
              ),
              const Text(
                'Đánh dấu đã đọc tất cả • Có 12 tin nhắn • Trang 1 trên 1',
                style: TextStyle(fontSize: 12, color: Colors.white54),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 3. Bảng 12 Tin Nhắn Đã Gửi
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF161F36),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFF2E3B5F)),
            ),
            child: Column(
              children: [
                // Header Cột
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: const BoxDecoration(
                    color: Color(0xFF131A30),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(5)),
                    border: Border(bottom: BorderSide(color: Color(0xFF2E3B5F))),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.mark_email_read, size: 16, color: Color(0xFFFFD700)),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Tin nhắn',
                          style: TextStyle(
                            color: Color(0xFFFFD700),
                            fontWeight: FontWeight.bold,
                            fontSize: 13.5,
                          ),
                        ),
                      ),
                      const Text(
                        'Chọn',
                        style: TextStyle(
                          color: Color(0xFFFFD700),
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Checkbox(
                        value: _isAllSentSelected,
                        onChanged: _toggleSelectAllSent,
                        activeColor: const Color(0xFFEF5350),
                        checkColor: Colors.white,
                        side: const BorderSide(color: Colors.white, width: 1.5),
                      ),
                    ],
                  ),
                ),

                // Danh sách từng dòng tin nhắn
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _sentMessages.length,
                  separatorBuilder: (context, index) => const Divider(
                    color: Color(0xFF2E3B5F),
                    height: 1,
                    thickness: 1,
                  ),
                  itemBuilder: (context, index) {
                    final msg = _sentMessages[index];
                    final bool isSelected = msg['isSelected'] ?? false;
                    final Color recipientColor = msg['recipientColor'] ?? const Color(0xFF64B5F6);
                    final Color titleColor = msg['titleColor'] ?? Colors.white;

                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: LayoutBuilder(
                        builder: (context, rowConstraints) {
                          final isNarrow = rowConstraints.maxWidth < 450;
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.article_outlined,
                                color: Colors.white38,
                                size: 18,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      msg['title'],
                                      style: TextStyle(
                                        color: titleColor,
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        const Text(
                                          'Người nhận ',
                                          style: TextStyle(fontSize: 11.5, color: Colors.white54),
                                        ),
                                        Text(
                                          msg['recipient'],
                                          style: TextStyle(
                                            color: recipientColor,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 11.5,
                                          ),
                                        ),
                                        if (isNarrow) ...[
                                          const SizedBox(width: 6),
                                          Text(
                                            '• ${msg['time']}',
                                            style: const TextStyle(fontSize: 11, color: Colors.white38),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              if (!isNarrow) ...[
                                const SizedBox(width: 8),
                                Text(
                                  'Ngày gửi: ${msg['time']}',
                                  style: const TextStyle(fontSize: 11.5, color: Colors.white54),
                                ),
                              ],
                              const SizedBox(width: 12),
                              Checkbox(
                                value: isSelected,
                                onChanged: (val) {
                                  setState(() {
                                    msg['isSelected'] = val ?? false;
                                  });
                                },
                                activeColor: const Color(0xFFEF5350),
                                checkColor: Colors.white,
                                side: const BorderSide(color: Colors.white38, width: 1.5),
                              ),
                            ],
                          );
                        },
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // 4. Thanh Công Cụ Tác Vụ Đáy (Bọc Wrap chống tràn viền)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF131A30),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFF2E3B5F)),
            ),
            child: Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Text(
                  'Xuất thư mục đang xem:',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                _buildDarkDropdown(
                  value: _exportFormat,
                  items: const [
                    DropdownMenuItem(value: 'csv', child: Text('Định dạng CSV')),
                    DropdownMenuItem(value: 'xml', child: Text('Định dạng XML')),
                    DropdownMenuItem(value: 'txt', child: Text('Định dạng Văn bản')),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _exportFormat = val);
                  },
                ),
                _buildDarkButton('Chuyển', onTap: _exportFolder),

                const SizedBox(width: 8),

                _buildDarkDropdown(
                  value: _markAction,
                  items: const [
                    DropdownMenuItem(
                      value: 'mark_important',
                      child: Text('Đánh dấu/Bỏ đánh dấu quan trọng'),
                    ),
                    DropdownMenuItem(
                      value: 'mark_read',
                      child: Text('Đánh dấu đã đọc'),
                    ),
                    DropdownMenuItem(
                      value: 'mark_unread',
                      child: Text('Đánh dấu chưa đọc'),
                    ),
                    DropdownMenuItem(
                      value: 'delete',
                      child: Text('Xóa các mục đã chọn'),
                    ),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _markAction = val);
                  },
                ),
                _buildDarkButton('Chuyển', onTap: _executeSentAction),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // 5. Thanh Điều Hướng Chân Bảng
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Wrap(
                spacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  InkWell(
                    onTap: () => _toggleSelectAllSent(true),
                    child: const Text(
                      'Chọn tất cả',
                      style: TextStyle(
                        color: Color(0xFFEF5350),
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Text('•', style: TextStyle(color: Colors.white38)),
                  InkWell(
                    onTap: () => _toggleSelectAllSent(false),
                    child: const Text(
                      'Bỏ chọn tất cả',
                      style: TextStyle(
                        color: Color(0xFFEF5350),
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const Text(
                'Có 12 tin nhắn • Trang 1 trên 1',
                style: TextStyle(fontSize: 12, color: Colors.white54),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- Phân Mục Tin Nhắn Nháp (Hình 2) ---
  Widget _buildDraftsArea() {
    return Container(
      color: const Color(0xFF1E2640),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Bản nháp đã lưu',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          const Divider(color: Color(0xFF2E3B5F), height: 1),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF161F36),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFF2E3B5F)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Với bảng điều khiển này, bạn có thể xem, sửa và xóa những bản nháp đã lưu của mình.',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                SizedBox(height: 12),
                Text(
                  'Không có bản nháp nào được lưu.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Vùng Danh Sách Tin Nhắn Chính (Nền #1E2640) ---
  Widget _buildMessagesArea() {
    return Container(
      color: const Color(0xFF1E2640),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Thư mục Header & Dung lượng lưu trữ
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF161F36),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFF2E3B5F)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Xem tin nhắn: Hộp tin nhận',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Thư mục 5% đã đầy (27 trong số 500 tin nhắn được lưu trữ)',
                  style: TextStyle(fontSize: 13, color: Colors.white70),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: const LinearProgressIndicator(
                    value: 27 / 500,
                    minHeight: 6,
                    backgroundColor: Colors.white12,
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00E5FF)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // 2. Thanh Công Cụ Trên (Phân trang mini bọc Wrap chống overflow)
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _currentFolder = 'compose';
                  });
                  UcpStateService.setSubItem('Tin nhắn', 'Soạn tin nhắn');
                },
                icon: const Icon(Icons.edit, size: 16, color: Colors.white),
                label: const Text(
                  'Tin nhắn mới',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF131A30),
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Color(0xFF2E3B5F)),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                ),
              ),
              Wrap(
                spacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const Text(
                    'Đánh dấu đã đọc tất cả • Có 27 tin nhắn',
                    style: TextStyle(fontSize: 12, color: Colors.white54),
                  ),
                  _buildPaginationControls(),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 3. Bảng Tin Nhắn (Đầy đủ 27 tin nhắn)
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF161F36),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFF2E3B5F)),
            ),
            child: Column(
              children: [
                // Header Cột
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: const BoxDecoration(
                    color: Color(0xFF131A30),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(5)),
                    border: Border(bottom: BorderSide(color: Color(0xFF2E3B5F))),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.mark_email_read, size: 16, color: Color(0xFFFFD700)),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Tin nhắn',
                          style: TextStyle(
                            color: Color(0xFFFFD700),
                            fontWeight: FontWeight.bold,
                            fontSize: 13.5,
                          ),
                        ),
                      ),
                      const Text(
                        'Chọn',
                        style: TextStyle(
                          color: Color(0xFFFFD700),
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Checkbox(
                        value: _isAllSelected,
                        onChanged: _toggleSelectAll,
                        activeColor: const Color(0xFFEF5350),
                        checkColor: Colors.white,
                        side: const BorderSide(color: Colors.white, width: 1.5),
                      ),
                    ],
                  ),
                ),

                // Danh sách từng dòng tin nhắn
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _messages.length,
                  separatorBuilder: (context, index) => const Divider(
                    color: Color(0xFF2E3B5F),
                    height: 1,
                    thickness: 1,
                  ),
                  itemBuilder: (context, index) {
                    final msg = _messages[index];
                    final bool isUnread = msg['isUnread'] ?? false;
                    final bool isImportant = msg['isImportant'] ?? false;
                    final bool isSelected = msg['isSelected'] ?? false;
                    final String? highlightType = msg['highlightType'];

                    Color? rowBgColor;
                    Border? rowBorder;

                    if (highlightType == 'yellow') {
                      rowBgColor = const Color(0xFF38351D);
                    } else if (isUnread) {
                      rowBgColor = const Color(0xFF2A324D);
                    }

                    if (highlightType == 'blue') {
                      rowBorder = Border.all(color: const Color(0xFF2196F3), width: 1);
                    } else if (highlightType == 'orange') {
                      rowBorder = Border.all(color: const Color(0xFFFF9800), width: 1);
                    }

                    return Container(
                      decoration: BoxDecoration(
                        color: rowBgColor ?? Colors.transparent,
                        border: rowBorder,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Icon(
                            isImportant
                                ? Icons.label_important
                                : isUnread
                                    ? Icons.mark_email_unread
                                    : Icons.drafts,
                            color: isImportant
                                ? const Color(0xFFFFD700)
                                : isUnread
                                    ? const Color(0xFFEF5350)
                                    : (highlightType == 'yellow' ? const Color(0xFFFFD700) : Colors.white38),
                            size: 18,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                InkWell(
                                  onTap: () {
                                    setState(() {
                                      msg['isUnread'] = false;
                                    });
                                  },
                                  child: Text(
                                    msg['title'],
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 13.5,
                                      fontWeight: isUnread ? FontWeight.bold : FontWeight.w500,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                RichText(
                                  text: TextSpan(
                                    style: const TextStyle(fontSize: 11.5, color: Colors.white54),
                                    children: [
                                      const TextSpan(text: 'bởi '),
                                      TextSpan(
                                        text: msg['author'],
                                        style: const TextStyle(
                                          color: Color(0xFF64B5F6),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      TextSpan(text: ' » ${msg['time']}'),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Checkbox(
                            value: isSelected,
                            onChanged: (val) {
                              setState(() {
                                msg['isSelected'] = val ?? false;
                              });
                            },
                            activeColor: const Color(0xFFEF5350),
                            checkColor: Colors.white,
                            side: const BorderSide(color: Colors.white38, width: 1.5),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // 4. Thanh Công Cụ Tác Vụ Đáy (CHỐNG TRÀN VIỀN BẰNG WRAP VÀ PADDING 16)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF131A30),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFF2E3B5F)),
            ),
            child: Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Text(
                  'Xuất thư mục đang xem:',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                _buildDarkDropdown(
                  value: _exportFormat,
                  items: const [
                    DropdownMenuItem(value: 'csv', child: Text('Định dạng CSV')),
                    DropdownMenuItem(value: 'xml', child: Text('Định dạng XML')),
                    DropdownMenuItem(value: 'txt', child: Text('Định dạng Văn bản')),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _exportFormat = val);
                  },
                ),
                _buildDarkButton('Chuyển', onTap: _exportFolder),

                const SizedBox(width: 8),

                _buildDarkDropdown(
                  value: _markAction,
                  items: const [
                    DropdownMenuItem(
                      value: 'mark_important',
                      child: Text('Đánh dấu/Bỏ đánh dấu quan trọng'),
                    ),
                    DropdownMenuItem(
                      value: 'mark_read',
                      child: Text('Đánh dấu đã đọc'),
                    ),
                    DropdownMenuItem(
                      value: 'mark_unread',
                      child: Text('Đánh dấu chưa đọc'),
                    ),
                    DropdownMenuItem(
                      value: 'delete',
                      child: Text('Xóa các mục đã chọn'),
                    ),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _markAction = val);
                  },
                ),
                _buildDarkButton('Chuyển', onTap: _executeAction),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // 5. Thanh Điều Hướng Dưới (Đánh dấu tất cả & Phân trang)
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Wrap(
                spacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  InkWell(
                    onTap: () => _toggleSelectAll(true),
                    child: const Text(
                      'Chọn tất cả',
                      style: TextStyle(
                        color: Color(0xFFEF5350),
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Text('•', style: TextStyle(color: Colors.white38)),
                  InkWell(
                    onTap: () => _toggleSelectAll(false),
                    child: const Text(
                      'Bỏ chọn tất cả',
                      style: TextStyle(
                        color: Color(0xFFEF5350),
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              Wrap(
                spacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const Text(
                    'Có 27 tin nhắn',
                    style: TextStyle(fontSize: 12, color: Colors.white54),
                  ),
                  _buildPaginationControls(),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildComposeArea() {
    return Container(
      color: const Color(0xFF1E2640),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Soạn tin nhắn',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 12),
          const Divider(color: Color(0xFF2E3B5F), height: 1),
          const SizedBox(height: 16),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Thêm những người nhận:', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    TextField(
                      maxLines: 3,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFF131A30),
                        isDense: true,
                        contentPadding: const EdgeInsets.all(10),
                        border: OutlineInputBorder(borderSide: const BorderSide(color: Color(0xFF2E3B5F)), borderRadius: BorderRadius.circular(4)),
                        enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Color(0xFF2E3B5F)), borderRadius: BorderRadius.circular(4)),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        _buildDarkButton('Thêm vào', onTap: () {}),
                        _buildDarkButton('Thêm vào [Đồng gửi]', onTap: () {}),
                        InkWell(
                          onTap: () {},
                          child: const Text('Tìm một thành viên', style: TextStyle(color: Color(0xFFEF5350), fontSize: 12, decoration: TextDecoration.underline, decorationColor: Color(0xFFEF5350))),
                        )
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Thêm nhóm:', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Container(
                      height: 70,
                      decoration: BoxDecoration(
                        color: const Color(0xFF131A30),
                        border: Border.all(color: const Color(0xFF2E3B5F)),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: ListView(
                        children: const [
                          Padding(padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4), child: Text('Ban tư vấn', style: TextStyle(color: Colors.white, fontSize: 13))),
                          Padding(padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4), child: Text('Hội viên Kim cương', style: TextStyle(color: Colors.white, fontSize: 13))),
                          Padding(padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4), child: Text('Quản lý', style: TextStyle(color: Colors.white, fontSize: 13))),
                          Padding(padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4), child: Text('Điều hành', style: TextStyle(color: Colors.white, fontSize: 13))),
                          Padding(padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4), child: Text('Cặp đôi lý số', style: TextStyle(color: Colors.white, fontSize: 13))),
                          Padding(padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4), child: Text('Tư vấn phong Thủy', style: TextStyle(color: Colors.white, fontSize: 13))),
                          Padding(padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4), child: Text('Tư vấn Tử vi', style: TextStyle(color: Colors.white, fontSize: 13))),
                          Padding(padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4), child: Text('Tư vấn Tứ Trụ', style: TextStyle(color: Colors.white, fontSize: 13))),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          const Divider(color: Color(0xFF2E3B5F), height: 1),
          const SizedBox(height: 16),

          Row(
            children: [
              const Text('Biểu tượng tin nhắn:', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold)),
              const SizedBox(width: 16),
              Row(
                children: [
                  Radio(value: true, groupValue: true, onChanged: (v) {}, activeColor: const Color(0xFFEF5350)),
                  const Text('Không dùng', style: TextStyle(color: Colors.white, fontSize: 13)),
                ],
              ),
              const SizedBox(width: 8),
              const Icon(Icons.star_border, color: Colors.amber, size: 18),
              const SizedBox(width: 4),
              const Icon(Icons.local_fire_department, color: Colors.orange, size: 18),
              const SizedBox(width: 4),
              const Icon(Icons.favorite_border, color: Colors.red, size: 18),
              const SizedBox(width: 4),
              const Icon(Icons.thumb_up_alt_outlined, color: Colors.blue, size: 18),
            ],
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              const SizedBox(
                width: 140,
                child: Text('Tiêu đề:', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold)),
              ),
              Expanded(
                child: TextField(
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color(0xFF131A30),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(borderSide: const BorderSide(color: Color(0xFF2E3B5F)), borderRadius: BorderRadius.circular(4)),
                    enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Color(0xFF2E3B5F)), borderRadius: BorderRadius.circular(4)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF131A30),
              border: Border.all(color: const Color(0xFF2E3B5F)),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Color(0xFF161F36),
                    border: Border(bottom: BorderSide(color: Color(0xFF2E3B5F))),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(3)),
                  ),
                  child: Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      _buildToolbarButton('B'),
                      _buildToolbarButton('i'),
                      _buildToolbarButton('u'),
                      _buildToolbarButton('Quote'),
                      _buildToolbarButton('Code'),
                      _buildToolbarButton('List'),
                      _buildToolbarButton('List='),
                      _buildToolbarButton('[*]'),
                      _buildToolbarButton('Img'),
                      _buildToolbarButton('URL'),
                      const SizedBox(width: 8),
                      Container(
                        height: 24,
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        decoration: BoxDecoration(border: Border.all(color: const Color(0xFF3F4E75)), borderRadius: BorderRadius.circular(2)),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: 'Cỡ chữ',
                            dropdownColor: const Color(0xFF131A30),
                            icon: const Icon(Icons.arrow_drop_down, color: Colors.white54, size: 16),
                            style: const TextStyle(color: Colors.white, fontSize: 11),
                            items: const [DropdownMenuItem(value: 'Cỡ chữ', child: Text('Cỡ chữ'))],
                            onChanged: (v) {},
                          )
                        )
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.format_color_text, color: Colors.white70, size: 16),
                    ],
                  ),
                ),
                TextField(
                  maxLines: 15,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildDarkButton('Lưu bản nháp', onTap: () {}),
              const SizedBox(width: 8),
              _buildDarkButton('Xem trước', onTap: () {}),
              const SizedBox(width: 8),
              _buildDarkButton('Xác nhận', onTap: () {}),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(color: Color(0xFF2E3B5F), height: 1),
          const SizedBox(height: 16),

          _buildCheckboxRow('Tắt các thẻ BBCode'),
          _buildCheckboxRow('Tắt Biểu tượng vui'),
          _buildCheckboxRow('Dùng tự động nhận diện các địa chỉ URL'),
        ],
      ),
    );
  }

  Widget _buildToolbarButton(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFF2A3450),
        border: Border.all(color: const Color(0xFF3F4E75)),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildCheckboxRow(String label) {
    return Row(
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: Checkbox(
            value: false,
            onChanged: (v) {},
            side: const BorderSide(color: Colors.white38, width: 1.5),
            activeColor: const Color(0xFFEF5350),
          ),
        ),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13)),
      ],
    );
  }

  Widget _buildDarkDropdown<T>({
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
    bool isExpanded = false,
  }) {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF161F36),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.white24, width: 1),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isDense: true,
          isExpanded: isExpanded,
          dropdownColor: const Color(0xFF131A30),
          style: const TextStyle(color: Colors.white, fontSize: 12.5),
          icon: const Icon(Icons.arrow_drop_down, color: Colors.white, size: 18),
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildDarkButton(String text, {required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFF2A3450),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: const Color(0xFF3F4E75), width: 1),
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12.5,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildPaginationControls() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int p = 1; p <= _totalPages; p++)
          _buildPageNumberButton(p, isActive: p == _currentPage),
        const SizedBox(width: 4),
        InkWell(
          onTap: () {
            if (_currentPage < _totalPages) {
              setState(() => _currentPage++);
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF263252),
              borderRadius: BorderRadius.circular(3),
              border: Border.all(color: const Color(0xFF3E4E77)),
            ),
            child: const Text(
              '>',
              style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPageNumberButton(int page, {bool isActive = false}) {
    return InkWell(
      onTap: () => setState(() => _currentPage = page),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFEF5350) : const Color(0xFF263252),
          borderRadius: BorderRadius.circular(3),
          border: Border.all(
            color: isActive ? const Color(0xFFEF5350) : const Color(0xFF3E4E77),
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

  // Khối Khám phá thêm (Hình 2)
  Widget _buildExploreMoreSection() {
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
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xFF131A30),
              borderRadius: BorderRadius.vertical(top: Radius.circular(5)),
              border: Border(bottom: BorderSide(color: Color(0xFF2E3B5F))),
            ),
            child: const Text(
              'Khám phá thêm',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Color(0xFFFFD700),
                letterSpacing: 0.5,
              ),
            ),
          ),
          ...List.generate(_exploreCategories.length, (index) {
            final title = _exploreCategories[index];
            final isLast = index == _exploreCategories.length - 1;

            return InkWell(
              onTap: () => context.go('/forum'),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  border: isLast ? null : const Border(bottom: BorderSide(color: Color(0xFF2E3B5F))),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right,
                      size: 18,
                      color: Colors.white38,
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  void _showBoxedSnackBar(String message, {bool isError = false}) {
    if (isError) {
      showErrorSnackBar(context, message);
    } else {
      showBoxedSnackBar(context, message);
    }
  }
}



