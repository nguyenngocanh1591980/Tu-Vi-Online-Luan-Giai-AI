// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/ucp_state_service.dart';
import 'ucp_screen.dart';

/// Màn hình Nhóm (UCP Groups Screen) độc lập
class UcpGroupsScreen extends StatelessWidget {
  final int initialSidebarIndex;
  const UcpGroupsScreen({super.key, this.initialSidebarIndex = 0});

  @override
  Widget build(BuildContext context) {
    return UcpScreen(initialTabIndex: 4, initialSidebarIndex: initialSidebarIndex);
  }
}

/// Widget nội dung tab Nhóm với Theme Dark Navy (#1E2640), Boxed Layout 1024px liền khối
class UcpGroupsContent extends StatefulWidget {
  final int initialSidebarIndex;

  const UcpGroupsContent({
    super.key,
    this.initialSidebarIndex = 0,
  });

  @override
  State<UcpGroupsContent> createState() => _UcpGroupsContentState();
}

class _UcpGroupsContentState extends State<UcpGroupsContent> {
  late int _selectedSidebarIndex;
  String _selectedGroupId = 'thanh_vien';
  String _selectedGroupAction = 'info';

  final List<String> _sidebarMenus = [
    'Sửa tư cách thành viên',
    'Quản lí nhóm',
  ];

  final List<String> _friendsList = [
    'hoangnguyenhuu',
    'phamquynh',
  ];

  // Khối Khám phá thêm đặc trưng của Tab Nhóm (Hình 5)
  final List<String> _exploreCategories = [
    'Lá số Tứ trụ',
    'Xem Phong Thủy',
    'Hướng dẫn và thông tin du lịch',
  ];

  // Danh sách 24 nhóm ngoài nhóm mặc định (Bảo toàn 100% từ Hình 5)
  final List<Map<String, dynamic>> _otherGroups = [
    {
      'id': 'bql_trung_chau',
      'name': 'BQL Trung Châu',
      'color': Color(0xFF4CAF50),
      'desc': 'BQL Diễn đàn Tử Vi Trung Châu\nĐây là một nhóm đóng, những thành viên mới chỉ có thể tham gia vào nhóm khi có sự đồng ý của nhóm trưởng.',
    },
    {
      'id': 'ban_tu_van',
      'name': 'Ban tư vấn',
      'color': Color(0xFFFF9800),
      'desc': 'Ban tư vấn các vấn đề...\nĐây là một nhóm đóng, những thành viên mới chỉ có thể tham gia vào nhóm khi có sự đồng ý của nhóm trưởng.',
    },
    {
      'id': 'hoi_vien_kim_cuong',
      'name': 'Hội viên Kim cương',
      'color': Color(0xFFE91E63),
      'desc': 'Hội viên có đóng góp duy trì, phát triển chi phí cho diễn đàn...\nĐây là một nhóm đóng, những thành viên mới chỉ có thể tham gia vào nhóm khi có sự đồng ý của nhóm trưởng.',
    },
    {
      'id': 'hoi_vien_online',
      'name': 'Hội viên online',
      'color': Color(0xFF9C27B0),
      'desc': 'Hội viên tham gia thường xuyên trên diễn đàn, sinh hoạt online.\nĐây là một nhóm đóng, những thành viên mới chỉ có thể tham gia vào nhóm khi có sự đồng ý của nhóm trưởng.',
    },
    {
      'id': 'lsnq_tu_vi',
      'name': 'LSNQ: Tử vi',
      'color': Color(0xFFD32F2F),
      'desc': 'Đây là một nhóm đóng, những thành viên mới chỉ có thể tham gia vào nhóm khi có sự đồng ý của nhóm trưởng.',
    },
    {
      'id': 'quan_tri',
      'name': 'Quản trị',
      'color': Color(0xFF1976D2),
      'desc': 'Nhóm điều hành chung trong diễn đàn.\nĐây là một nhóm đóng, những thành viên mới chỉ có thể tham gia vào nhóm khi có sự đồng ý của nhóm trưởng.',
    },
    {
      'id': 'tro_ly_dieu_hanh',
      'name': 'Trợ lý điều hành',
      'color': Color(0xFF00BCD4),
      'desc': 'Hỗ trợ các công việc điều hành, phân quyền xem bài viết cho thành viên...\nĐây là một nhóm đóng, những thành viên mới chỉ có thể tham gia vào nhóm khi có sự đồng ý của nhóm trưởng.',
    },
    {
      'id': 'dieu_hanh',
      'name': 'Điều hành',
      'color': Color(0xFF2196F3),
      'desc': 'Thực hiện việc kiểm duyệt, kiểm soát bài viết của thành viên...\nĐây là một nhóm đóng, những thành viên mới chỉ có thể tham gia vào nhóm khi có sự đồng ý của nhóm trưởng.',
    },
    {
      'id': 'clb_ly_so_hn',
      'name': 'CLB Lý số Hà Nội',
      'color': Color(0xFFF44336),
      'desc': 'Hội viên CLB Lý số tại Hà Nội.\nĐây là một nhóm mở...',
    },
    {
      'id': 'clb_ly_so_hcm',
      'name': 'CLB Lý số TP. HCM',
      'color': Color(0xFFFF5722),
      'desc': 'Hội viên CLB Lý số tại TP. Hồ Chí Minh...\nĐây là một nhóm mở...',
    },
    {
      'id': 'clb_phong_thuy_tl',
      'name': 'CLB Phong Thủy TL',
      'color': Color(0xFFFFB300),
      'desc': 'Hội viên CLB Phong Thủy Thăng Long...\nĐây là một nhóm mở...',
    },
    {
      'id': 'cap_doi_cuu_si',
      'name': 'Cấp Đội cựu sĩ',
      'color': Color(0xFF607D8B),
      'desc': 'Đây là một nhóm đóng, những thành viên mới chỉ có thể tham gia vào nhóm khi có sự đồng ý của nhóm trưởng.',
    },
    {
      'id': 'hoc_phong_thuy_online',
      'name': 'Học Phong Thủy online',
      'color': Color(0xFF43A047),
      'desc': 'Học viên khóa phong thủy cơ bản Online. Học phí: 2.000.000 đ / khóa.\nĐây là một nhóm mở...',
    },
    {
      'id': 'hoc_tu_vi_online',
      'name': 'Học Tử vi online',
      'color': Color(0xFF43A047),
      'desc': 'Học viên khóa nghiên cứu Tử vi căn bản qua mạng. Học phí 500k/người...\nĐây là một nhóm mở...',
    },
    {
      'id': 'lsnq_am_duong',
      'name': 'LSNQ: Âm dương Lý số',
      'color': Color(0xFF795548),
      'desc': 'Nghiên cứu các vấn đề Âm dương lý số...\nĐây là một nhóm đóng...',
    },
    {
      'id': 'lsnq_phong_thuy',
      'name': 'LSNQ: Phong Thủy',
      'color': Color(0xFF03A9F4),
      'desc': 'Nghiên cứu Phong Thủy học...\nĐây là một nhóm đóng...',
    },
    {
      'id': 'lsnq_que_dich',
      'name': 'LSNQ: Quẻ Dịch',
      'color': Color(0xFFFB8C00),
      'desc': 'Nghiên cứu Quẻ dịch...\nĐây là một nhóm đóng...',
    },
    {
      'id': 'lsnq_tu_tru',
      'name': 'LSNQ: Tứ Trụ',
      'color': Color(0xFF689F38),
      'desc': 'Nghiên cứu Tứ trụ...\nĐây là một nhóm đóng...',
    },
    {
      'id': 'lsnq_tu_vi_nang_cao',
      'name': 'LSNQ: Tử vi Nâng cao',
      'color': Color(0xFFC62828),
      'desc': 'Nghiên cứu Tử vi nâng cao...\nĐây là một nhóm đóng...',
    },
    {
      'id': 'tac_gia',
      'name': 'Tác giả',
      'color': Color(0xFF7B1FA2),
      'desc': 'Tác giả bài viết trên diễn đàn...\nĐây là một nhóm đóng...',
    },
    {
      'id': 'trao_doi_hoc_thuat',
      'name': 'Trao đổi Học thuật',
      'color': Color(0xFF00897B),
      'desc': 'Nhóm trao đổi học thuật...\nĐây là một nhóm mở...',
    },
    {
      'id': 'trung_chau_ly_so',
      'name': 'Trung Châu Lý Số',
      'color': Color(0xFF558B2F),
      'desc': 'Nghiên cứu Tử vi theo phái Trung Châu...\nĐây là một nhóm đóng...',
    },
    {
      'id': 'tu_van_phong_thuy',
      'name': 'Tư vấn Phong Thủy',
      'color': Color(0xFFFBC02D),
      'desc': 'Hỗ trợ tư vấn Phong thủy...\nĐây là một nhóm đóng...',
    },
    {
      'id': 'tu_van_tu_tru',
      'name': 'Tư vấn Tứ Trụ',
      'color': Color(0xFF0D47A1),
      'desc': 'Hỗ trợ tư vấn Tứ trụ...\nĐây là một nhóm đóng...',
    },
  ];

  @override
  void initState() {
    super.initState();
    _selectedSidebarIndex = widget.initialSidebarIndex;
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
                    _buildCurrentSidebarContent(),
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
                    child: _buildCurrentSidebarContent(),
                  ),
                ],
              );
            },
          ),
        ),

        // Khối Khám phá thêm đặc trưng của Tab Nhóm (Hình 5)
        if (_selectedSidebarIndex == 0) ...[
          const SizedBox(height: 16),
          _buildExploreMoreSection(),
        ],
      ],
    );
  }

  Widget _buildCurrentSidebarContent() {
    if (_selectedSidebarIndex <= 0) {
      return _buildMembershipContent();
    }
    return _buildManageGroupsContent();
  }

  // --- Vùng Nội dung chính: Quản lý nhóm (Hình 2) ---
  Widget _buildManageGroupsContent() {
    return Container(
      color: const Color(0xFF1E2640),
      padding: const EdgeInsets.all(18.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tiêu đề
          const Text(
            'Nhóm',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),

          // Lời giới thiệu (Bảo toàn 100% nguyên văn từ Hình 2)
          Text(
            'Những nhóm làm nhiệm vụ của quản trị viên sẽ làm việc tốt hơn các thành viên quản trị riêng lẻ rất nhiều. Mặc định, bạn sẽ được đặt tham gia vào một nhóm xác định, đây là nhóm mặc định của bạn. Nhóm này sẽ phân biệt bạn là thành viên của nhóm với các thành viên của những nhóm khác thông qua màu sắc trên tên thành viên, hình đại diện, xếp hạng... Tùy thuộc vào quyết định của người quản trị có cho phép hay không mà bạn có thể thay đổi nhóm mặc định của mình. Bạn cũng có thể được tự thêm vào hoặc tự mình tham gia vào các nhóm thành viên khác. Một vài nhóm có thể đòi hỏi bạn thiết lập cấp phép bổ sung để xem một vài thông tin của nhóm hay năng lực để tham gia vào trong một số lĩnh vực riêng của họ.',
            style: TextStyle(
              fontSize: 13.5,
              color: Colors.grey[300],
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),

          // Dòng thông báo in đậm (Bold text theo Hình 2)
          const Text(
            'Bạn không phải là người điều hành của bất kì nhóm nào.',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // Sidebar Menu bên trái
  Widget _buildSidebar() {
    return Container(
      color: const Color(0xFF161F36),
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Các mục menu của tab Nhóm
          ...List.generate(_sidebarMenus.length, (index) {
            final isSelected = _selectedSidebarIndex == index;
            return InkWell(
              onTap: () {
                setState(() {
                  _selectedSidebarIndex = index;
                });
                UcpStateService.setSubItem('Nhóm', _sidebarMenus[index]);
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white.withValues(alpha: 0.05) : Colors.transparent,
                  border: Border(
                    left: BorderSide(
                      color: isSelected ? const Color(0xFFEF5350) : Colors.transparent,
                      width: 3,
                    ),
                  ),
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
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFFEF5350),
                            decoration: TextDecoration.underline,
                            decorationColor: Color(0xFFEF5350),
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

  // --- Vùng Nội dung chính: Mục tư cách thành viên (Hình 5) ---
  Widget _buildMembershipContent() {
    return Container(
      color: const Color(0xFF1E2640),
      padding: const EdgeInsets.all(18.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tiêu đề
          const Text(
            'Nhóm',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),

          // Lời giới thiệu (Bảo toàn 100% nguyên văn từ Hình 5)
          Text(
            'Những nhóm được thêm do ban quản trị diễn đàn liên lạc với các thành viên quản trị; đây là đặc điểm đặc biệt, bạn sẽ được đặt tham gia vào một nhóm xác định, đây là nhóm mặc định của bạn. Nhóm này sẽ phân biệt bạn là thành viên của nhóm với các thành viên của những nhóm khác (thông qua màu sắc hiển trên danh sách, xem bài diễn, xếp hạng... Tùy thuộc vào quyết định của người quản trị có cho phép hay không mà bạn có thể thay đổi nhóm mặc định của mình. Bạn cũng có thể được tự thêm vào hoặc tự mình tham gia vào các nhóm thành viên khác. Một vài nhóm có thể cho bạn lại thiết lập các phép bổ sung để xem một số thông tin của nhóm hay nâng cao tư cách tham gia của bạn trong một số lĩnh vực.',
            style: TextStyle(
              fontSize: 13.5,
              color: Colors.grey[300],
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),

          // 1. BẢNG 1: Tư cách thành viên của nhóm
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF161F36),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFF2E3B5F)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header bảng
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: const BoxDecoration(
                    color: Color(0xFF131A30),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(5)),
                    border: Border(bottom: BorderSide(color: Color(0xFF2E3B5F))),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Tư cách thành viên của nhóm',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFFFD700),
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        'Chọn',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFFFD700),
                        ),
                      ),
                    ],
                  ),
                ),

                // Dòng nhóm mặc định: Thành viên
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: const [
                                Icon(Icons.circle, size: 8, color: Color(0xFF2196F3)),
                                SizedBox(width: 6),
                                Text(
                                  'Thành viên',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF64B5F6),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Đây là một nhóm mặc định, những thành viên mới gia nhập được thêm vào nhóm này bởi người quản trị.',
                              style: TextStyle(
                                fontSize: 12.5,
                                color: Colors.grey[400],
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Radio<String>(
                        value: 'thanh_vien',
                        groupValue: _selectedGroupId,
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedGroupId = val);
                        },
                        activeColor: const Color(0xFF2196F3),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // 2. BẢNG 2: Không phải là thành viên của nhóm (24 nhóm chi tiết)
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF161F36),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFF2E3B5F)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header bảng
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: const BoxDecoration(
                    color: Color(0xFF131A30),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(5)),
                    border: Border(bottom: BorderSide(color: Color(0xFF2E3B5F))),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Không phải là thành viên của nhóm',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFFFD700),
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        'Chọn',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFFFD700),
                        ),
                      ),
                    ],
                  ),
                ),

                // Danh sách 24 nhóm
                ...List.generate(_otherGroups.length, (index) {
                  final group = _otherGroups[index];
                  final isLast = index == _otherGroups.length - 1;

                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      border: isLast ? null : const Border(bottom: BorderSide(color: Color(0xFF2E3B5F))),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                group['name'],
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.bold,
                                  color: group['color'],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                group['desc'],
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[400],
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Radio<String>(
                          value: group['id'],
                          groupValue: _selectedGroupId,
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedGroupId = val);
                          },
                          activeColor: const Color(0xFF2196F3),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 3. Thanh tác vụ đáy
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF131A30),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFF2E3B5F)),
            ),
            child: Wrap(
              spacing: 12,
              runSpacing: 10,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () {
                    _showBoxedSnackBar('Đã cập nhật nhóm mặc định thành công!');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2A3450),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                      side: const BorderSide(color: Color(0xFF3F4E75)),
                    ),
                  ),
                  child: const Text('Thay đổi nhóm mặc định', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                ),

                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      height: 34,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF161F36),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.white24, width: 1),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedGroupAction,
                          dropdownColor: const Color(0xFF131A30),
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                          icon: const Icon(Icons.arrow_drop_down, color: Colors.white, size: 18),
                          items: const [
                            DropdownMenuItem(value: 'info', child: Text('Xem thông tin của nhóm')),
                            DropdownMenuItem(value: 'join', child: Text('Gửi yêu cầu tham gia nhóm')),
                            DropdownMenuItem(value: 'leave', child: Text('Rời khỏi nhóm')),
                          ],
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedGroupAction = val);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        _showBoxedSnackBar('Đang thực hiện thao tác trên nhóm được chọn...');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2A3450),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                          side: const BorderSide(color: Color(0xFF3F4E75)),
                        ),
                      ),
                      child: const Text('Xác nhận', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }



  // Khối Khám phá thêm (Hình 5)
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

  void _showBoxedSnackBar(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
        padding: EdgeInsets.zero,
        margin: const EdgeInsets.only(bottom: 24),
        duration: const Duration(seconds: 3),
        content: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1024),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
              decoration: BoxDecoration(
                color: const Color(0xFF1E2640),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF4CAF50)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.4),
                    spreadRadius: 1,
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_outline, color: Color(0xFF4CAF50), size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      message,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
