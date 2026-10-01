// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Hiển thị popup Tìm một thành viên (Member Search Dialog)
Future<String?> showMemberSearchDialog(
  BuildContext context, {
  void Function(String username)? onSelectMember,
}) {
  return showDialog<String>(
    context: context,
    builder: (context) => Dialog(
      
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1024, maxHeight: 900),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Scaffold(
            backgroundColor: const Color(0xFF1E2640),
            MemberSearchContent(
              isDialog: true,
              onSelectMember: (username) {
                if (onSelectMember != null) {
                  onSelectMember(username);
                }
                Navigator.of(context).pop(username);
              },
            ),
          ),
        ),
      ),
    ),
  );
}

/// Màn hình độc lập Tìm một thành viên (Member Search Screen)
class MemberSearchScreen extends StatelessWidget {
  const MemberSearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Material(color: Colors.transparent, child: 
      
      SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: MemberSearchContent(isDialog: false),
      ),
    );
  }
}

/// Widget nội dung tìm kiếm thành viên dùng chung cho cả Dialog và Screen
class MemberSearchContent extends StatefulWidget {
  final bool isDialog;
  final void Function(String username)? onSelectMember;

  const MemberSearchContent({
    super.key,
    this.isDialog = false,
    this.onSelectMember,
  });

  @override
  State<MemberSearchContent> createState() => _MemberSearchContentState();
}

class _MemberSearchContentState extends State<MemberSearchContent> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _joinDateController = TextEditingController();
  final TextEditingController _postsCountController = TextEditingController();

  String _joinCondition = 'before';
  String _selectedGroup = 'all';
  String _postsCondition = 'equal';
  String _sortBy = 'join_date';
  String _sortOrder = 'asc';
  String _selectedLetter = 'Tất cả';
  final int _currentPage = 1;
  final int _totalPages = 260;

  final List<String> _alphabet = [
    'Tất cả',
    'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M',
    'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z',
    'Thông tin khác'
  ];

  // Danh sách chuẩn xác 25 thành viên mẫu từ Hình 4
  final List<Map<String, dynamic>> _allMembers = [
    {
      'username': 'Admin',
      'rank': 'QUẢN LÝ',
      'rankType': 'badge_admin',
      'posts': 81,
      'website': '',
      'joinDate': '11:22, 05/09/08',
      'isSelected': false,
    },
    {
      'username': 'nncuong',
      'rank': 'SÁNG LẬP',
      'rankType': 'badge_founder',
      'posts': 2713,
      'website': '',
      'joinDate': '12:44, 05/09/08',
      'isSelected': false,
    },
    {
      'username': 'phuclongusdt',
      'rank': 'QUẢN LÝ',
      'rankType': 'badge_admin',
      'posts': 199,
      'website': '',
      'joinDate': '12:48, 05/09/08',
      'isSelected': false,
    },
    {
      'username': 'phanthithao',
      'rank': 'HỘI VIÊN',
      'rankType': 'badge_member',
      'posts': 243,
      'website': '',
      'joinDate': '13:42, 05/09/08',
      'isSelected': false,
    },
    {
      'username': 'AnVTu',
      'rank': '',
      'rankType': 'star',
      'posts': 14,
      'website': '',
      'joinDate': '13:42, 05/09/08',
      'isSelected': false,
    },
    {
      'username': 'mocha13',
      'rank': '',
      'rankType': 'star',
      'posts': 21,
      'website': '',
      'joinDate': '19:08, 05/09/08',
      'isSelected': false,
    },
    {
      'username': 'nalsaluong',
      'rank': '',
      'rankType': '',
      'posts': 3,
      'website': '',
      'joinDate': '19:15, 05/09/08',
      'isSelected': false,
    },
    {
      'username': 'dyt4w',
      'rank': '',
      'rankType': '',
      'posts': 0,
      'website': '',
      'joinDate': '19:34, 05/09/08',
      'isSelected': false,
    },
    {
      'username': 'hanhye',
      'rank': '',
      'rankType': '',
      'posts': 9,
      'website': '',
      'joinDate': '19:43, 05/09/08',
      'isSelected': false,
    },
    {
      'username': 'tarvin',
      'rank': '',
      'rankType': '',
      'posts': 3,
      'website': 'http://www.hungloc.net',
      'joinDate': '19:39, 05/09/08',
      'isSelected': false,
    },
    {
      'username': 'ngocluina',
      'rank': '',
      'rankType': '',
      'posts': 0,
      'website': '',
      'joinDate': '19:57, 05/09/08',
      'isSelected': false,
    },
    {
      'username': 'w_slioak',
      'rank': '',
      'rankType': '',
      'posts': 1,
      'website': '',
      'joinDate': '15:38, 04/09/08',
      'isSelected': false,
    },
    {
      'username': 'loanmanhh1111',
      'rank': '',
      'rankType': '',
      'posts': 3,
      'website': '',
      'joinDate': '15:42, 04/09/08',
      'isSelected': false,
    },
    {
      'username': 'minhbe',
      'rank': '',
      'rankType': '',
      'posts': 0,
      'website': '',
      'joinDate': '20:34, 04/09/08',
      'isSelected': false,
    },
    {
      'username': 'fukloy',
      'rank': '',
      'rankType': '',
      'posts': 0,
      'website': '',
      'joinDate': '13:24, 06/09/08',
      'isSelected': false,
    },
    {
      'username': 'kimxuong',
      'rank': '',
      'rankType': 'two_stars',
      'posts': 26,
      'website': '',
      'joinDate': '18:39, 06/09/08',
      'isSelected': false,
    },
    {
      'username': 'thanhhoa',
      'rank': '',
      'rankType': '',
      'posts': 5,
      'website': '',
      'joinDate': '22:41, 06/09/08',
      'isSelected': false,
    },
    {
      'username': 'thekieu',
      'rank': '',
      'rankType': '',
      'posts': 3,
      'website': '',
      'joinDate': '09:29, 06/09/08',
      'isSelected': false,
    },
    {
      'username': 'red464',
      'rank': '',
      'rankType': '',
      'posts': 3,
      'website': '',
      'joinDate': '11:04, 06/09/08',
      'isSelected': false,
    },
    {
      'username': 'bida',
      'rank': '',
      'rankType': '',
      'posts': 3,
      'website': '',
      'joinDate': '13:44, 06/09/08',
      'isSelected': false,
    },
    {
      'username': 'nappori',
      'rank': '',
      'rankType': '',
      'posts': 3,
      'website': '',
      'joinDate': '21:28, 13/09/08',
      'isSelected': false,
    },
    {
      'username': 'juraych',
      'rank': '',
      'rankType': '',
      'posts': 0,
      'website': '',
      'joinDate': '09:31, 13/09/08',
      'isSelected': false,
    },
    {
      'username': 'juraych01',
      'rank': '',
      'rankType': '',
      'posts': 0,
      'website': '',
      'joinDate': '09:35, 13/09/08',
      'isSelected': false,
    },
    {
      'username': 'em_duong34',
      'rank': '',
      'rankType': 'star_circle',
      'posts': 416,
      'website': '',
      'joinDate': '18:17, 16/09/08',
      'isSelected': false,
    },
    {
      'username': 'ngayphuong',
      'rank': '',
      'rankType': '',
      'posts': 0,
      'website': '',
      'joinDate': '19:28, 17/09/08',
      'isSelected': false,
    },
  ];

  late List<Map<String, dynamic>> _filteredMembers;

  @override
  void initState() {
    super.initState();
    _filteredMembers = List.from(_allMembers);
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _joinDateController.dispose();
    _postsCountController.dispose();
    super.dispose();
  }

  void _filterMembers() {
    final query = _usernameController.text.trim().toLowerCase();
    setState(() {
      _filteredMembers = _allMembers.where((m) {
        final username = (m['username'] as String).toLowerCase();
        if (query.isNotEmpty) {
          final cleanQuery = query.replaceAll('*', '');
          if (!username.contains(cleanQuery)) return false;
        }
        if (_selectedLetter != 'Tất cả') {
          if (_selectedLetter == 'Thông tin khác') {
            final firstChar = username.isNotEmpty ? username[0].toUpperCase() : '';
            if (RegExp(r'[A-Z]').hasMatch(firstChar)) return false;
          } else {
            if (!username.startsWith(_selectedLetter.toLowerCase())) return false;
          }
        }
        return true;
      }).toList();
    });
  }

  void _toggleSelectAll(bool select) {
    setState(() {
      for (var m in _filteredMembers) {
        m['isSelected'] = select;
      }
    });
  }

  void _submitSelected() {
    final selected = _filteredMembers
        .where((m) => m['isSelected'] == true)
        .map((m) => m['username'] as String)
        .toList();

    if (selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng đánh dấu chọn ít nhất một thành viên.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final joined = selected.join('\n');
    if (widget.onSelectMember != null) {
      widget.onSelectMember!(joined);
    } else {
      Navigator.of(context).pop(joined);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Bar của Popup/Trang
          _buildHeaderBar(),
          const SizedBox(height: 16),

          // 1. Khối Form Tìm Kiếm
          _buildSearchForm(),
          const SizedBox(height: 20),

          // 2. Bộ Lọc Chữ Cái & Phân Trang
          _buildAlphabetFilter(),
          const SizedBox(height: 12),
          _buildCountAndPagination(),
          const SizedBox(height: 10),

          // 3. Bảng Kết Quả Tìm Kiếm (25 Thành Viên Mẫu)
          _buildMembersTable(),
          const SizedBox(height: 12),

          // 4. Cụm Thao Tác Đáy (Chọn đánh dấu, Chọn tất cả, Bỏ chọn tất cả)
          _buildBottomActions(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildHeaderBar() {
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
            children: const [
              Icon(Icons.search, color: Color(0xFFFFD700), size: 20),
              SizedBox(width: 10),
              Text(
                'Tìm một thành viên',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFFD700),
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          if (widget.isDialog)
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white70, size: 20),
              onPressed: () => Navigator.of(context).pop(),
              tooltip: 'Đóng',
            )
          else
            InkWell(
              onTap: () => context.go('/forum/ucp'),
              child: Row(
                children: const [
                  Icon(Icons.arrow_back_ios, color: Color(0xFF90CAF9), size: 14),
                  SizedBox(width: 4),
                  Text(
                    'Về Thiết lập cá nhân',
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

  // --- Khối 1: Form Tìm Kiếm (Hình 4) ---
  Widget _buildSearchForm() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF161F36),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF2E3B5F)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Lời hướng dẫn nguyên văn từ Hình 4
          Text(
            'Công cụ này sẽ giúp bạn tìm kiếm những thành viên xác định trong hệ thống. Bạn không cần phải điền đầy đủ thông tin trong tất cả các mục bên dưới. Sử dụng dấu * để tìm kiếm những thành viên có tên giống nhau một phần nào đó. Khi nhập thông tin về ngày tháng bạn cần sử dụng định dạng YYYY-MM-DD. Ví dụ: 2004-02-29. Đánh dấu chọn trong phần đánh dấu để chọn một hay nhiều tên thành viên. Những tên thành viên khác nhau có thể được chọn tùy thuộc vào bảng được liệt kê. Bấm vào nút Chọn đánh dấu nếu có để quay về bảng điều khiển trước.',
            style: TextStyle(
              fontSize: 12.5,
              color: Colors.grey[300],
              height: 1.45,
            ),
          ),
          const SizedBox(height: 16),
          const Divider(color: Color(0xFF2E3B5F), height: 1),
          const SizedBox(height: 16),

          // Các hàng nhập thông tin tìm kiếm
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 650;
              return Column(
                children: [
                  // Hàng 1: Tên đăng nhập & Tham gia
                  if (isNarrow) ...[
                    _buildFieldRow('Tên đăng nhập:', _buildUsernameInput()),
                    const SizedBox(height: 10),
                    _buildFieldRow('Tham gia:', _buildJoinDateInput()),
                  ] else
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _buildFieldRow('Tên đăng nhập:', _buildUsernameInput())),
                        const SizedBox(width: 24),
                        Expanded(child: _buildFieldRow('Tham gia:', _buildJoinDateInput())),
                      ],
                    ),
                  const SizedBox(height: 12),

                  // Hàng 2: Nhóm & Bài viết
                  if (isNarrow) ...[
                    _buildFieldRow('Nhóm:', _buildGroupDropdown()),
                    const SizedBox(height: 10),
                    _buildFieldRow('Bài viết:', _buildPostsInput()),
                  ] else
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _buildFieldRow('Nhóm:', _buildGroupDropdown())),
                        const SizedBox(width: 24),
                        Expanded(child: _buildFieldRow('Bài viết:', _buildPostsInput())),
                      ],
                    ),
                  const SizedBox(height: 12),

                  // Hàng 3: Sắp xếp theo
                  _buildFieldRow('Sắp xếp theo:', _buildSortInputs()),
                ],
              );
            },
          ),
          const SizedBox(height: 18),

          // Nút Tìm kiếm
          Center(
            child: ElevatedButton.icon(
              onPressed: _filterMembers,
              icon: const Icon(Icons.search, size: 16, color: Colors.white),
              label: const Text(
                'Tìm kiếm',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E3B5F),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldRow(String label, Widget input) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(child: input),
      ],
    );
  }

  Widget _buildUsernameInput() {
    return TextField(
      controller: _usernameController,
      style: const TextStyle(color: Colors.white, fontSize: 13),
      decoration: InputDecoration(
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        filled: true,
        fillColor: const Color(0xFF131A30),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: Color(0xFF2E3B5F)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: Color(0xFF2E3B5F)),
        ),
      ),
      onSubmitted: (_) => _filterMembers(),
    );
  }

  Widget _buildJoinDateInput() {
    return Row(
      children: [
        SizedBox(
          width: 105,
          child: DropdownButtonFormField<String>(
            isExpanded: true,
            value: _joinCondition,
            dropdownColor: const Color(0xFF131A30),
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              filled: true,
              fillColor: const Color(0xFF131A30),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
            ),
            items: const [
              DropdownMenuItem(value: 'before', child: Text('Trước')),
              DropdownMenuItem(value: 'after', child: Text('Sau')),
              DropdownMenuItem(value: 'equal', child: Text('Bằng')),
            ],
            onChanged: (val) => setState(() => _joinCondition = val ?? 'before'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: TextField(
            controller: _joinDateController,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: InputDecoration(
              isDense: true,
              hintText: 'YYYY-MM-DD',
              hintStyle: const TextStyle(color: Colors.white38, fontSize: 12),
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              filled: true,
              fillColor: const Color(0xFF131A30),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGroupDropdown() {
    return DropdownButtonFormField<String>(
      isExpanded: true,
      value: _selectedGroup,
      dropdownColor: const Color(0xFF131A30),
      style: const TextStyle(color: Colors.white, fontSize: 13),
      decoration: InputDecoration(
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        filled: true,
        fillColor: const Color(0xFF131A30),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
      ),
      items: const [
        DropdownMenuItem(value: 'all', child: Text('Tất cả các nhóm')),
        DropdownMenuItem(value: 'admin', child: Text('Ban Quản Trị')),
        DropdownMenuItem(value: 'member', child: Text('Thành viên')),
        DropdownMenuItem(value: 'advisor', child: Text('Ban tư vấn')),
      ],
      onChanged: (val) => setState(() => _selectedGroup = val ?? 'all'),
    );
  }

  Widget _buildPostsInput() {
    return Row(
      children: [
        SizedBox(
          width: 110,
          child: DropdownButtonFormField<String>(
            isExpanded: true,
            value: _postsCondition,
            dropdownColor: const Color(0xFF131A30),
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              filled: true,
              fillColor: const Color(0xFF131A30),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
            ),
            items: const [
              DropdownMenuItem(value: 'equal', child: Text('Bằng')),
              DropdownMenuItem(value: 'greater', child: Text('Nhiều hơn')),
              DropdownMenuItem(value: 'less', child: Text('Ít hơn')),
            ],
            onChanged: (val) => setState(() => _postsCondition = val ?? 'equal'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: TextField(
            controller: _postsCountController,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              filled: true,
              fillColor: const Color(0xFF131A30),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSortInputs() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        SizedBox(
          width: 155,
          child: DropdownButtonFormField<String>(
            isExpanded: true,
            value: _sortBy,
            dropdownColor: const Color(0xFF131A30),
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              filled: true,
              fillColor: const Color(0xFF131A30),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
            ),
            items: const [
              DropdownMenuItem(value: 'join_date', child: Text('Ngày tham gia')),
              DropdownMenuItem(value: 'username', child: Text('Tên đăng nhập')),
              DropdownMenuItem(value: 'posts', child: Text('Số bài viết')),
            ],
            onChanged: (val) => setState(() => _sortBy = val ?? 'join_date'),
          ),
        ),
        SizedBox(
          width: 120,
          child: DropdownButtonFormField<String>(
            isExpanded: true,
            value: _sortOrder,
            dropdownColor: const Color(0xFF131A30),
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              filled: true,
              fillColor: const Color(0xFF131A30),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
            ),
            items: const [
              DropdownMenuItem(value: 'asc', child: Text('Tăng dần')),
              DropdownMenuItem(value: 'desc', child: Text('Giảm dần')),
            ],
            onChanged: (val) => setState(() => _sortOrder = val ?? 'asc'),
          ),
        ),
      ],
    );
  }

  // --- Khối 2: Bộ Lọc Chữ Cái A-Z (Hình 4) ---
  Widget _buildAlphabetFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Thành viên',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: _alphabet.map((letter) {
            final isSelected = _selectedLetter == letter;
            return InkWell(
              onTap: () {
                setState(() => _selectedLetter = letter);
                _filterMembers();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF8B0000) : const Color(0xFF161F36),
                  borderRadius: BorderRadius.circular(3),
                  border: Border.all(
                    color: isSelected ? const Color(0xFFFFD700) : const Color(0xFF2E3B5F),
                  ),
                ),
                child: Text(
                  letter,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? Colors.white : const Color(0xFF90CAF9),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildCountAndPagination() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          '25999 thành viên',
          style: TextStyle(fontSize: 12.5, color: Colors.white70),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF8B0000),
                borderRadius: BorderRadius.circular(3),
              ),
              child: Text(
                '$_currentPage',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
            const SizedBox(width: 4),
            ...[2, 3, 4, 5].map((page) => Container(
                  margin: const EdgeInsets.only(right: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF161F36),
                    borderRadius: BorderRadius.circular(3),
                    border: Border.all(color: const Color(0xFF2E3B5F)),
                  ),
                  child: Text(
                    '$page',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF90CAF9)),
                  ),
                )),
            const Text(' ... ', style: TextStyle(color: Colors.white70, fontSize: 12)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF161F36),
                borderRadius: BorderRadius.circular(3),
                border: Border.all(color: const Color(0xFF2E3B5F)),
              ),
              child: Text(
                '$_totalPages',
                style: const TextStyle(fontSize: 12, color: Color(0xFF90CAF9)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // --- Khối 3: Bảng Danh Sách 25 Thành Viên Mẫu (Hình 4) ---
  Widget _buildMembersTable() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF161F36),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF2E3B5F)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Cột (Hình 4: Nền đỏ sẫm #131A30 / #5A1010)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: const BoxDecoration(
              color: Color(0xFF131A30),
              borderRadius: BorderRadius.vertical(top: Radius.circular(5)),
              border: Border(bottom: BorderSide(color: Color(0xFF2E3B5F))),
            ),
            child: Row(
              children: const [
                SizedBox(
                  width: 150,
                  child: Text(
                    'Tên đăng nhập',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12.5,
                      color: Color(0xFFFFD700),
                    ),
                  ),
                ),
                SizedBox(
                  width: 130,
                  child: Text(
                    'Xếp hạng',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12.5,
                      color: Color(0xFFFFD700),
                    ),
                  ),
                ),
                SizedBox(
                  width: 70,
                  child: Text(
                    'Bài viết',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12.5,
                      color: Color(0xFFFFD700),
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'Website',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12.5,
                      color: Color(0xFFFFD700),
                    ),
                  ),
                ),
                SizedBox(
                  width: 120,
                  child: Text(
                    'Tham gia',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12.5,
                      color: Color(0xFFFFD700),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Danh sách các hàng thành viên
          ...List.generate(_filteredMembers.length, (index) {
            final m = _filteredMembers[index];
            final isEven = index % 2 == 0;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: isEven ? const Color(0xFF1A233D) : const Color(0xFF161F36),
                border: Border(
                  bottom: BorderSide(color: const Color(0xFF2E3B5F).withValues(alpha: 0.5)),
                ),
              ),
              child: Row(
                children: [
                  // Cột Tên đăng nhập & Checkbox & Nút [ Chọn ]
                  SizedBox(
                    width: 150,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: Checkbox(
                            value: m['isSelected'] ?? false,
                            onChanged: (val) {
                              setState(() => m['isSelected'] = val ?? false);
                            },
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                m['username'],
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFEF5350),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              InkWell(
                                onTap: () {
                                  if (widget.onSelectMember != null) {
                                    widget.onSelectMember!(m['username']);
                                  } else {
                                    Navigator.of(context).pop(m['username']);
                                  }
                                },
                                child: const Text(
                                  '[ Chọn ]',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF90CAF9),
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Cột Xếp hạng (Badge)
                  SizedBox(
                    width: 130,
                    child: _buildRankBadge(m['rank'], m['rankType']),
                  ),

                  // Cột Số bài viết
                  SizedBox(
                    width: 70,
                    child: Text(
                      '${m['posts']}',
                      style: const TextStyle(fontSize: 12.5, color: Colors.white70),
                    ),
                  ),

                  // Cột Website
                  Expanded(
                    child: Text(
                      m['website'],
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64B5F6),
                        decoration: TextDecoration.underline,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                  // Cột Tham gia
                  SizedBox(
                    width: 120,
                    child: Text(
                      m['joinDate'],
                      style: const TextStyle(fontSize: 12, color: Colors.white70),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildRankBadge(String rankText, String rankType) {
    if (rankType == 'badge_admin') {
      return Align(
        alignment: Alignment.centerLeft,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1565C0), Color(0xFF0D47A1)],
              ),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.white38),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.star, color: Color(0xFFFFD700), size: 11),
                SizedBox(width: 3),
                Text(
                  'QUẢN LÝ',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                SizedBox(width: 3),
                Icon(Icons.star, color: Color(0xFFFFD700), size: 11),
              ],
            ),
          ),
        ),
      );
    } else if (rankType == 'badge_founder') {
      return Align(
        alignment: Alignment.centerLeft,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFD84315), Color(0xFFBF360C)],
              ),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.white38),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.star, color: Color(0xFFFFD700), size: 11),
                SizedBox(width: 3),
                Text(
                  'SÁNG LẬP',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                SizedBox(width: 3),
                Icon(Icons.star, color: Color(0xFFFFD700), size: 11),
              ],
            ),
          ),
        ),
      );
    } else if (rankType == 'badge_member') {
      return Align(
        alignment: Alignment.centerLeft,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF880E4F), Color(0xFF4A148C)],
              ),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.white38),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.star, color: Color(0xFFFFD700), size: 11),
                SizedBox(width: 3),
                Text(
                  'HỘI VIÊN',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                SizedBox(width: 3),
                Icon(Icons.star, color: Color(0xFFFFD700), size: 11),
              ],
            ),
          ),
        ),
      );
    } else if (rankType == 'star') {
      return const Align(
        alignment: Alignment.centerLeft,
        child: Icon(Icons.star_border, color: Colors.white54, size: 14),
      );
    } else if (rankType == 'two_stars') {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.star_border, color: Colors.white54, size: 14),
          Icon(Icons.star_border, color: Colors.white54, size: 14),
        ],
      );
    } else if (rankType == 'star_circle') {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.circle, color: Color(0xFFFFD700), size: 8),
          SizedBox(width: 2),
          Icon(Icons.circle, color: Color(0xFFFFD700), size: 8),
        ],
      );
    }
    return const SizedBox.shrink();
  }

  // --- Khối 4: Cụm Thao Tác Đáy (Hình 4) ---
  Widget _buildBottomActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        ElevatedButton(
          onPressed: _submitSelected,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2E3B5F),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          ),
          child: const Text('Chọn đánh dấu', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        Row(
          children: [
            InkWell(
              onTap: () => _toggleSelectAll(true),
              child: const Text(
                'Chọn tất cả',
                style: TextStyle(
                  fontSize: 12.5,
                  color: Color(0xFF90CAF9),
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
            const Text(' • ', style: TextStyle(color: Colors.white54)),
            InkWell(
              onTap: () => _toggleSelectAll(false),
              child: const Text(
                'Bỏ chọn tất cả',
                style: TextStyle(
                  fontSize: 12.5,
                  color: Color(0xFF90CAF9),
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
