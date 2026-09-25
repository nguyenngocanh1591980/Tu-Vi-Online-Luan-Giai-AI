import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/ucp_state_service.dart';
import 'ucp_screen.dart';
import 'member_search_dialog.dart';

/// Màn hình Bạn bè (UCP Friends Screen) độc lập
class UcpFriendsScreen extends StatelessWidget {
  const UcpFriendsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const UcpScreen(initialTabIndex: 5);
  }
}

/// Widget nội dung tab Bạn bè với Theme Dark Navy (#1E2640), Boxed Layout 1024px liền khối
class UcpFriendsContent extends StatefulWidget {
  final int initialSidebarIndex;

  const UcpFriendsContent({
    super.key,
    this.initialSidebarIndex = 0,
  });

  @override
  State<UcpFriendsContent> createState() => _UcpFriendsContentState();
}

class _UcpFriendsContentState extends State<UcpFriendsContent> {
  late int _selectedSidebarIndex;

  // Controllers cho form thêm mới
  final TextEditingController _addFriendsController = TextEditingController();
  final TextEditingController _addEnemiesController = TextEditingController();

  // Danh sách bạn thân gốc (Hình 2)
  final List<String> _friendsList = [
    'hoangnguyenhuu',
    'phamquynh',
  ];
  final Set<String> _selectedFriendsToRemove = {};

  // Danh sách kẻ thù gốc (Hình 5: Ban đầu trống)
  final List<String> _enemiesList = [];
  final Set<String> _selectedEnemiesToRemove = {};

  final List<String> _sidebarMenus = [
    'Quản lí bạn thân',
    'Quản lí kẻ thù',
  ];

  // Khối Khám phá thêm của Tab Bạn bè
  final List<String> _exploreCategories = [
    'Tra Bách Khoa',
    'Xem Phong Thủy',
    'Lịch Vạn Sự',
  ];

  @override
  void initState() {
    super.initState();
    _selectedSidebarIndex = widget.initialSidebarIndex;
  }

  @override
  void dispose() {
    _addFriendsController.dispose();
    _addEnemiesController.dispose();
    super.dispose();
  }

  void _showBoxedSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: isError ? Colors.red[700] : const Color(0xFF131A30),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
          side: BorderSide(
            color: isError ? Colors.redAccent : const Color(0xFFFFD700),
            width: 1,
          ),
        ),
      ),
    );
  }

  void _submitFriends() {
    setState(() {
      // 1. Gỡ bỏ bạn thân được chọn
      if (_selectedFriendsToRemove.isNotEmpty) {
        _friendsList.removeWhere((f) => _selectedFriendsToRemove.contains(f));
        _selectedFriendsToRemove.clear();
      }

      // 2. Thêm bạn thân mới từ text field
      final newEntries = _addFriendsController.text
          .split('\n')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty && !_friendsList.contains(e))
          .toList();

      if (newEntries.isNotEmpty) {
        _friendsList.addAll(newEntries);
        _addFriendsController.clear();
      }
    });

    _showBoxedSnackBar('Đã cập nhật danh sách bạn thân thành công.');
  }

  void _submitEnemies() {
    setState(() {
      // 1. Gỡ bỏ kẻ thù được chọn
      if (_selectedEnemiesToRemove.isNotEmpty) {
        _enemiesList.removeWhere((e) => _selectedEnemiesToRemove.contains(e));
        _selectedEnemiesToRemove.clear();
      }

      // 2. Thêm kẻ thù mới từ text field
      final newEntries = _addEnemiesController.text
          .split('\n')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty && !_enemiesList.contains(e))
          .toList();

      if (newEntries.isNotEmpty) {
        _enemiesList.addAll(newEntries);
        _addEnemiesController.clear();
      }
    });

    _showBoxedSnackBar('Đã cập nhật danh sách kẻ thù thành công.');
  }

  void _openMemberSearch({required bool isForFriends}) {
    showMemberSearchDialog(
      context,
      onSelectMember: (selectedUsernames) {
        setState(() {
          final controller = isForFriends ? _addFriendsController : _addEnemiesController;
          if (controller.text.trim().isEmpty) {
            controller.text = selectedUsernames;
          } else {
            controller.text = '${controller.text.trim()}\n$selectedUsernames';
          }
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Khối Card chính gồm Sidebar + Nội dung (HỢP NHẤT LIỀN MẠCH 1 KHỐI 1024px)
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
                  // Cột trái: Sidebar (width: 220)
                  SizedBox(
                    width: 220,
                    child: _buildSidebar(),
                  ),
                  // Đường viền dọc phân cách
                  Container(
                    width: 1,
                    color: const Color(0xFF2E3B5F),
                  ),
                  // Cột phải: Nội dung chính
                  Expanded(
                    child: _buildCurrentContent(),
                  ),
                ],
              );
            },
          ),
        ),

        const SizedBox(height: 16),

        // Khối Khám phá thêm liền mạch
        _buildExploreSection(),
      ],
    );
  }

  // --- Sidebar Trái (Dark Navy #161F36) ---
  Widget _buildSidebar() {
    return Container(
      color: const Color(0xFF161F36),
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ...List.generate(_sidebarMenus.length, (index) {
            final isSelected = _selectedSidebarIndex == index;
            return InkWell(
              onTap: () {
                setState(() {
                  _selectedSidebarIndex = index;
                });
                UcpStateService.setSubItem('Bạn bè', _sidebarMenus[index]);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF1E2640) : Colors.transparent,
                  border: isSelected
                      ? const Border(left: BorderSide(color: Color(0xFF8B0000), width: 4))
                      : null,
                ),
                child: Text(
                  _sidebarMenus[index],
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected ? const Color(0xFFEF5350) : Colors.white70,
                  ),
                ),
              ),
            );
          }),

          const SizedBox(height: 16),
          const Divider(color: Color(0xFF2E3B5F), height: 1),
          const SizedBox(height: 12),

          // Mục Bạn thân
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
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
                      child: InkWell(
                        onTap: () => context.go('/forum/member/$friend'),
                        child: Text(
                          friend,
                          style: TextStyle(
                            fontSize: 13,
                            color: friend == 'phamquynh'
                                ? const Color(0xFF4CAF50)
                                : const Color(0xFFEF5350),
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentContent() {
    if (_selectedSidebarIndex == 0) {
      return _buildFriendsManagerContent();
    } else {
      return _buildEnemiesManagerContent();
    }
  }

  // --- Vùng Nội dung: Quản lí bạn thân (Hình 2) ---
  Widget _buildFriendsManagerContent() {
    return Container(
      color: const Color(0xFF1E2640),
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tiêu đề
          const Text(
            'Quản lí bạn thân',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),

          // Đoạn mô tả nguyên văn từ Hình 2
          Text(
            'Bạn thân là những thành viên đã được bạn thiết lập mặc định để có thể nhanh chóng liên lạc với họ hoặc liên lạc thường xuyên. Nếu giao diện bạn đang sử dụng trong hệ thống có hỗ trợ, bất kì bài viết nào được gửi bạn thân của bạn đều được đánh dấu nổi bật.',
            style: TextStyle(
              fontSize: 13.5,
              color: Colors.grey[300],
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),

          // Khối 1: Bạn thân của bạn (ListBox)
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 650;
              return Column(
                children: [
                  if (isNarrow) ...[
                    _buildFriendsLabelSection(),
                    const SizedBox(height: 8),
                    _buildFriendsListBox(),
                  ] else
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 4, child: _buildFriendsLabelSection()),
                        const SizedBox(width: 20),
                        Expanded(flex: 6, child: _buildFriendsListBox()),
                      ],
                    ),
                  const SizedBox(height: 20),

                  // Khối 2: Thêm bạn thân mới (TextField + Link Tìm một thành viên)
                  if (isNarrow) ...[
                    _buildAddFriendsLabelSection(),
                    const SizedBox(height: 8),
                    _buildAddInputSection(isForFriends: true),
                  ] else
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 4, child: _buildAddFriendsLabelSection()),
                        const SizedBox(width: 20),
                        Expanded(flex: 6, child: _buildAddInputSection(isForFriends: true)),
                      ],
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),

          // Nút Xác nhận
          Center(
            child: ElevatedButton(
              onPressed: _submitFriends,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E3B5F),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                side: const BorderSide(color: Color(0xFF3F51B5)),
              ),
              child: const Text(
                'Xác nhận',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFriendsLabelSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Bạn thân của bạn:',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Để gỡ bỏ những tên thành viên khỏi danh sách bạn thân, chọn trong danh sách rồi bấm vào nút chấp nhận.',
          style: TextStyle(
            fontSize: 12.5,
            color: Colors.grey[400],
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildFriendsListBox() {
    return Container(
      height: 110,
      decoration: BoxDecoration(
        color: const Color(0xFF131A30),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFF2E3B5F)),
      ),
      child: _friendsList.isEmpty
          ? const Center(
              child: Text(
                'Không có bạn thân nào được lưu',
                style: TextStyle(color: Colors.white38, fontSize: 13),
              ),
            )
          : ListView.builder(
              itemCount: _friendsList.length,
              itemBuilder: (context, index) {
                final friend = _friendsList[index];
                final isSelected = _selectedFriendsToRemove.contains(friend);
                return InkWell(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _selectedFriendsToRemove.remove(friend);
                      } else {
                        _selectedFriendsToRemove.add(friend);
                      }
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    color: isSelected ? const Color(0xFF1E3A8A) : Colors.transparent,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          friend,
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? Colors.white : Colors.grey[300],
                          ),
                        ),
                        if (isSelected)
                          const Icon(Icons.check, size: 16, color: Color(0xFFFFD700)),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildAddFriendsLabelSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Thêm bạn thân mới:',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Bạn có thể nhập cùng lúc nhiều tên thành viên chọn làm bạn thân với mỗi tên thành viên xác định trên một dòng.',
          style: TextStyle(
            fontSize: 12.5,
            color: Colors.grey[400],
            height: 1.4,
          ),
        ),
      ],
    );
  }

  // --- Vùng Nội dung: Quản lí kẻ thù (Hình 5) ---
  Widget _buildEnemiesManagerContent() {
    return Container(
      color: const Color(0xFF1E2640),
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tiêu đề
          const Text(
            'Quản lí kẻ thù',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),

          // Đoạn mô tả nguyên văn từ Hình 5
          Text(
            'Kẻ thù là những thành viên đã được bạn thiết lập mặc định không quan hệ. Các bài viết được gửi bởi những thành viên này sẽ không được hiển thị khi bạn xem. Các tin nhắn từ kẻ thù vẫn được phép gửi đến bạn. Lưu ý rằng bạn không thể chọn kẻ thù của mình là các điều hành viên hay quản trị viên trong website.',
            style: TextStyle(
              fontSize: 13.5,
              color: Colors.grey[300],
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),

          // Khối 1: Kẻ thù của bạn (Hình 5: "Không có kẻ thù nào được xác định")
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 650;
              return Column(
                children: [
                  if (isNarrow) ...[
                    _buildEnemiesLabelSection(),
                    const SizedBox(height: 8),
                    _buildEnemiesListBox(),
                  ] else
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 4, child: _buildEnemiesLabelSection()),
                        const SizedBox(width: 20),
                        Expanded(flex: 6, child: _buildEnemiesListBox()),
                      ],
                    ),
                  const SizedBox(height: 20),

                  // Khối 2: Thêm kẻ thù mới (TextField + Link Tìm một thành viên)
                  if (isNarrow) ...[
                    _buildAddEnemiesLabelSection(),
                    const SizedBox(height: 8),
                    _buildAddInputSection(isForFriends: false),
                  ] else
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 4, child: _buildAddEnemiesLabelSection()),
                        const SizedBox(width: 20),
                        Expanded(flex: 6, child: _buildAddInputSection(isForFriends: false)),
                      ],
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),

          // Nút Xác nhận
          Center(
            child: ElevatedButton(
              onPressed: _submitEnemies,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E3B5F),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                side: const BorderSide(color: Color(0xFF3F51B5)),
              ),
              child: const Text(
                'Xác nhận',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnemiesLabelSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Kẻ thù của bạn:',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Để gỡ bỏ những tên thành viên khỏi danh sách kẻ thù, chọn trong danh sách rồi bấm vào nút chấp nhận.',
          style: TextStyle(
            fontSize: 12.5,
            color: Colors.grey[400],
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildEnemiesListBox() {
    if (_enemiesList.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        alignment: Alignment.centerLeft,
        child: const Text(
          'Không có kẻ thù nào được xác định',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
    }

    return Container(
      height: 110,
      decoration: BoxDecoration(
        color: const Color(0xFF131A30),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFF2E3B5F)),
      ),
      child: ListView.builder(
        itemCount: _enemiesList.length,
        itemBuilder: (context, index) {
          final enemy = _enemiesList[index];
          final isSelected = _selectedEnemiesToRemove.contains(enemy);
          return InkWell(
            onTap: () {
              setState(() {
                if (isSelected) {
                  _selectedEnemiesToRemove.remove(enemy);
                } else {
                  _selectedEnemiesToRemove.add(enemy);
                }
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              color: isSelected ? const Color(0xFF1E3A8A) : Colors.transparent,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    enemy,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? Colors.white : Colors.grey[300],
                    ),
                  ),
                  if (isSelected)
                    const Icon(Icons.check, size: 16, color: Color(0xFFFFD700)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAddEnemiesLabelSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Thêm kẻ thù mới:',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Bạn có thể nhập cùng lúc nhiều tên thành viên chọn làm kẻ thù với mỗi tên thành viên xác định trên một dòng.',
          style: TextStyle(
            fontSize: 12.5,
            color: Colors.grey[400],
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildAddInputSection({required bool isForFriends}) {
    final controller = isForFriends ? _addFriendsController : _addEnemiesController;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          maxLines: 4,
          style: const TextStyle(color: Colors.white, fontSize: 13.5),
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFF131A30),
            hintText: 'Nhập tên thành viên (mỗi tên một dòng)...',
            hintStyle: const TextStyle(color: Colors.white38, fontSize: 12.5),
            contentPadding: const EdgeInsets.all(12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: const BorderSide(color: Color(0xFF2E3B5F)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: const BorderSide(color: Color(0xFF2E3B5F)),
            ),
          ),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: () => _openMemberSearch(isForFriends: isForFriends),
          child: const Text(
            'Tìm một thành viên',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Color(0xFFEF5350),
              decoration: TextDecoration.underline,
              decorationColor: Color(0xFFEF5350),
            ),
          ),
        ),
      ],
    );
  }

  // --- Khối Khám Phá Thêm ---
  Widget _buildExploreSection() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF161F36),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF2E3B5F)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Khám phá thêm
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xFF131A30),
              borderRadius: BorderRadius.vertical(top: Radius.circular(5)),
              border: Border(bottom: BorderSide(color: Color(0xFF2E3B5F))),
            ),
            child: Row(
              children: const [
                Icon(Icons.explore, color: Color(0xFFFFD700), size: 16),
                SizedBox(width: 8),
                Text(
                  'Khám phá thêm',
                  style: TextStyle(
                    color: Color(0xFFFFD700),
                    fontWeight: FontWeight.bold,
                    fontSize: 13.5,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14.0),
            child: Wrap(
              spacing: 12,
              runSpacing: 8,
              children: _exploreCategories.map((item) {
                return OutlinedButton.icon(
                  onPressed: () {
                    _showBoxedSnackBar('Đang mở chuyên mục "$item"...');
                  },
                  icon: const Icon(Icons.stars, size: 14, color: Color(0xFFFFD700)),
                  label: Text(
                    item,
                    style: const TextStyle(fontSize: 12.5, color: Colors.white),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF2E3B5F)),
                    backgroundColor: const Color(0xFF1A233D),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
