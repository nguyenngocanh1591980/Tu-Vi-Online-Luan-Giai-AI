import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/ucp_state_service.dart';
import '../../utils/boxed_snack_bar.dart';
import 'ucp_subscriptions_screen.dart';
import 'ucp_favorites_screen.dart';
import 'ucp_drafts_screen.dart';
import 'ucp_attachments_screen.dart';
import 'ucp_notifications_screen.dart';
import 'ucp_personal_screen.dart';
import 'ucp_system_screen.dart';
import 'ucp_messages_screen.dart';
import 'ucp_groups_screen.dart';
import 'ucp_friends_screen.dart';

class UcpScreen extends StatefulWidget {
  final int initialTabIndex;
  final int initialSidebarIndex;

  const UcpScreen({
    super.key,
    this.initialTabIndex = 0,
    this.initialSidebarIndex = 0,
  });

  @override
  State<UcpScreen> createState() => _UcpScreenState();
}

class _UcpScreenState extends State<UcpScreen> {
  late int _selectedTabIndex;
  late int _selectedSidebarIndex;

  @override
  void initState() {
    super.initState();
    _selectedTabIndex = widget.initialTabIndex;
    _selectedSidebarIndex = widget.initialSidebarIndex;

    if (_selectedTabIndex == 1) {
      UcpStateService.setSubItem('Cá nhân', 'Sửa thông tin cá nhân');
    } else if (_selectedTabIndex == 2) {
      UcpStateService.setSubItem('Hệ thống', 'Sửa thiết lập cá nhân');
    } else if (_selectedSidebarIndex > 0 && _selectedSidebarIndex < _sidebarMenus.length) {
      UcpStateService.setSubItem(_tabs[_selectedTabIndex], _sidebarMenus[_selectedSidebarIndex]);
    } else {
      UcpStateService.setTab(_tabs[_selectedTabIndex]);
    }

    UcpStateService.onResetToOverview = () {
      if (mounted) {
        setState(() {
          _selectedTabIndex = 0;
          _selectedSidebarIndex = 0;
        });
      }
    };
    UcpStateService.onClearSubItem = () {
      if (mounted) {
        setState(() {
          _selectedSidebarIndex = 0;
        });
      }
    };
    UcpStateService.onSelectTab = (tabIndex) {
      if (mounted && tabIndex >= 0 && tabIndex < _tabs.length) {
        setState(() {
          _selectedTabIndex = tabIndex;
          _selectedSidebarIndex = 0;
        });
        if (tabIndex == 1) {
          UcpStateService.setSubItem('Cá nhân', 'Sửa thông tin cá nhân');
        } else if (tabIndex == 2) {
          UcpStateService.setSubItem('Hệ thống', 'Sửa thiết lập cá nhân');
        } else {
          UcpStateService.setTab(_tabs[tabIndex]);
        }
      }
    };
  }

  @override
  void dispose() {
    UcpStateService.onResetToOverview = null;
    UcpStateService.onClearSubItem = null;
    UcpStateService.onSelectTab = null;
    super.dispose();
  }

  final List<String> _tabs = [
    'Tổng quan',
    'Cá nhân',
    'Hệ thống',
    'Tin nhắn',
    'Nhóm',
    'Bạn bè',
  ];

  final List<String> _sidebarMenus = [
    'Trang trước',
    'Bảng theo dõi',
    'Trang yêu thích',
    'Bản nháp đã lưu',
    'Tập tin đính kèm',
    'Quản lý các thông báo',
  ];

  final List<String> _friendsList = [
    'hoangnguyenhuu',
    'phamquynh',
    'nncuong',
    'tuattnb',
    'điều hành 8',
    'điều hành 6',
    'Quản lý',
  ];

  final List<Map<String, String>> _announcements = [
    {
      'title': 'Talkshow hướng nghiệp tháng 7/2026',
      'author': 'nncuong',
      'time': '10:01, 02/07/26',
      'lastAuthor': 'nncuong',
      'lastTime': '10:50, 23/07/26',
    },
    {
      'title': 'Tư vấn có ủng hộ phí để duy trì diễn đàn',
      'author': 'Ban tư vấn',
      'time': '15:45, 31/05/13',
      'lastAuthor': 'Ban tư vấn',
      'lastTime': '15:45, 31/05/13',
    },
    {
      'title': 'Hướng dẫn sử dụng diễn đàn',
      'author': 'Admin',
      'time': '21:37, 20/12/08',
      'lastAuthor': 'Admin',
      'lastTime': '21:37, 20/12/08',
    },
    {
      'title': 'Bảng giá dịch vụ tư vấn tại Lý số Hội quán',
      'author': 'Admin',
      'time': '13:35, 08/12/08',
      'lastAuthor': 'Admin',
      'lastTime': '13:35, 08/12/08',
    },
    {
      'title': 'Nội quy diễn đàn Lý số Việt Nam',
      'author': 'Admin',
      'time': '10:16, 04/09/08',
      'lastAuthor': 'Admin',
      'lastTime': '10:16, 04/09/08',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Material(color: Colors.transparent, child: 
      
      SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Title Bar
            _buildTitleBar(),
            const SizedBox(height: 16),

            // 2. Nội dung chính: Tabs + Sidebar + Main Area
            _buildUcpTabs(),
            if (_selectedTabIndex == 0)
              _buildMainLayout(context)
            else if (_selectedTabIndex == 1)
              UcpPersonalContent(
                initialSidebarIndex: _selectedSidebarIndex >= 0 ? _selectedSidebarIndex : 0,
              )
            else if (_selectedTabIndex == 2)
              UcpSystemContent(
                initialSidebarIndex: _selectedSidebarIndex >= 0 ? _selectedSidebarIndex : 0,
              )
            else if (_selectedTabIndex == 3)
              UcpMessagesContent(
                initialSidebarIndex: _selectedSidebarIndex >= 0 ? _selectedSidebarIndex : 0,
              )
            else if (_selectedTabIndex == 4)
              UcpGroupsContent(
                initialSidebarIndex: _selectedSidebarIndex >= 0 ? _selectedSidebarIndex : 0,
              )
            else if (_selectedTabIndex == 5)
              UcpFriendsContent(
                initialSidebarIndex: _selectedSidebarIndex >= 0 ? _selectedSidebarIndex : 0,
              )
            else
              _buildUnderDevelopmentLayout(context, _tabs[_selectedTabIndex]),
            const SizedBox(height: 28),
            _buildForumFooter(),
          ],
        ),
      ),
    );
  }

  // --- 1. Title Bar (Đóng hộp giao diện y hệt Tin nhắn riêng - Hình 5) ---
  Widget _buildTitleBar() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF131A30), // Đồng bộ với inbox_screen
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF2A3450), width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: const [
              Icon(Icons.person, color: Color(0xFFFFD700), size: 20),
              SizedBox(width: 10),
              Text(
                'Thiết lập cá nhân',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFFD700),
                  letterSpacing: 0.5,
                ),
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

  // --- 2. UCP Horizontal Tabs ---
  Widget _buildUcpTabs() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(_tabs.length, (index) {
          final isSelected = _selectedTabIndex == index;
          return MouseRegion(
            cursor: SystemMouseCursors.click,
            child: InkWell(
              onTap: () {
                setState(() {
                  _selectedTabIndex = index;
                  _selectedSidebarIndex = 0;
                });
                if (index == 1) {
                  UcpStateService.setSubItem('Cá nhân', 'Sửa thông tin cá nhân');
                } else if (index == 2) {
                  UcpStateService.setSubItem('Hệ thống', 'Sửa thiết lập cá nhân');
                } else {
                  UcpStateService.setTab(_tabs[index]);
                }
                if (index > 5) {
                  _showBoxedSnackBar('Tính năng "${_tabs[index]}" đang được phát triển.');
                }
              },
              hoverColor: Colors.white.withValues(alpha: 0.05),
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
              focusColor: Colors.transparent,
              child: Container(
                margin: const EdgeInsets.only(right: 4),
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF131A30),
                      // Remove borderRadius from here to avoid non-uniform border crash
                      border: Border(
                        top: BorderSide(
                          color: isSelected ? const Color(0xFFFFD700) : const Color(0xFF2E3B5F),
                          width: isSelected ? 2.5 : 1,
                        ),
                        left: const BorderSide(color: Color(0xFF2E3B5F), width: 1),
                        right: const BorderSide(color: Color(0xFF2E3B5F), width: 1),
                        bottom: const BorderSide(color: Color(0xFF2E3B5F), width: 1),
                      ),
                    ),
                    child: Text(
                      _tabs[index],
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? const Color(0xFFFFD700) : Colors.white,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // --- 3. Main Layout (Sidebar + Content) ---
  Widget _buildMainLayout(BuildContext context) {
    return Container(
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

          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Left Column: Sidebar (width: 220)
                SizedBox(
                  width: 220,
                  child: _buildSidebar(),
                ),
                // Divider giữa Sidebar và Content
                const VerticalDivider(
                  color: Color(0xFF2E3B5F),
                  width: 1,
                  thickness: 1,
                ),
                // Right Column: Content
                Expanded(
                  child: _buildCurrentSidebarContent(),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // Điều hướng hiển thị Component tương ứng của Sidebar
  Widget _buildCurrentSidebarContent() {
    switch (_selectedSidebarIndex) {
      case 1:
        return const UcpSubscriptionsContent();
      case 2:
        return const UcpFavoritesContent();
      case 3:
        return const UcpDraftsContent();
      case 4:
        return const UcpAttachmentsContent();
      case 5:
        return const UcpNotificationsContent();
      case 0:
      default:
        if (_selectedSidebarIndex <= 0) {
          return _buildTrangTruocContent();
        }
        return _buildUnderDevelopmentSidebarContent(_sidebarMenus[_selectedSidebarIndex]);
    }
  }

  // --- 4. Sidebar Menu & Bạn thân ---
  Widget _buildSidebar() {
    return Container(
      color: const Color(0xFF161F36),
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Các menu mục của tab
          ...List.generate(_sidebarMenus.length, (index) {
            final isSelected = (_selectedSidebarIndex <= 0 && index == 0) || _selectedSidebarIndex == index;
            return InkWell(
              onTap: () {
                setState(() {
                  _selectedSidebarIndex = index;
                });
                UcpStateService.setSubItem(_tabs[_selectedTabIndex], _sidebarMenus[index]);
                if (index > 5) {
                  _showBoxedSnackBar('Mục "${_sidebarMenus[index]}" đang được phát triển.');
                }
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

  // --- 5. Main Content: Trang trước ---
  Widget _buildTrangTruocContent() {
    return Container(
      color: const Color(0xFF1E2640),
      padding: const EdgeInsets.all(18.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tiêu đề Trang trước
          const Text(
            'Trang trước',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),

          // Lời chào mở đầu
          Text(
            'Chào mừng bạn đến với bảng thiết lập cá nhân của mình. Với bảng điều khiển này, bạn có thể quản lí, xem và cập nhật thông tin cá nhân, thiết lập những sở thích cá nhân, theo dõi các chuyên mục và chủ đề mà mình quan tâm. Nếu được cấp phép, bạn cũng có thể gửi tin nhắn đến các thành viên khác. Hãy chắc chắn rằng bạn đã đọc qua các thông báo quan trọng nếu có trước khi tiếp tục.',
            style: TextStyle(
              fontSize: 13.5,
              color: Colors.grey[300],
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),

          // Khối: NHỮNG THÔNG BÁO QUAN TRỌNG
          _buildAnnouncementsSection(),
          const SizedBox(height: 20),

          // Khối: HOẠT ĐỘNG CỦA BẠN
          _buildUserActivitySection(),
        ],
      ),
    );
  }

  // Bảng Những thông báo quan trọng
  Widget _buildAnnouncementsSection() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF161F36),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF2E3B5F)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header thanh tiêu đề bảng
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xFF131A30),
              borderRadius: BorderRadius.vertical(top: Radius.circular(5)),
              border: Border(bottom: BorderSide(color: Color(0xFF2E3B5F))),
            ),
            child: const Text(
              'NHỮNG THÔNG BÁO QUAN TRỌNG',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.bold,
                color: Color(0xFFFFD700),
                letterSpacing: 0.5,
              ),
            ),
          ),

          // Danh sách các thông báo
          ...List.generate(_announcements.length, (index) {
            final item = _announcements[index];
            final isLast = index == _announcements.length - 1;

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                border: isLast ? null : const Border(bottom: BorderSide(color: Color(0xFF2E3B5F))),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon Info
                  const Padding(
                    padding: EdgeInsets.only(top: 2, right: 10),
                    child: Icon(Icons.info_outline, color: Color(0xFF90CAF9), size: 18),
                  ),

                  // Cột trái: Tiêu đề & Người gửi
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        InkWell(
                          onTap: () {},
                          child: Text(
                            item['title']!,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'gửi bởi ${item['author']} - ${item['time']}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[400],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Cột phải: Bài cuối gửi bởi
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Bài cuối gửi bởi ',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[400],
                            ),
                          ),
                          Text(
                            item['lastAuthor']!,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFEF5350),
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.reply, size: 12, color: Color(0xFFEF5350)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item['lastTime']!,
                        style: TextStyle(
                          fontSize: 11.5,
                          color: Colors.grey[400],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // Bảng Hoạt động của bạn
  Widget _buildUserActivitySection() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF161F36),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF2E3B5F)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header thanh tiêu đề bảng
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xFF131A30),
              borderRadius: BorderRadius.vertical(top: Radius.circular(5)),
              border: Border(bottom: BorderSide(color: Color(0xFF2E3B5F))),
            ),
            child: const Text(
              'HOẠT ĐỘNG CỦA BẠN',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.bold,
                color: Color(0xFFFFD700),
                letterSpacing: 0.5,
              ),
            ),
          ),

          // Nội dung hoạt động
          Padding(
            padding: const EdgeInsets.all(14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildActivityRow('Tham gia:', '12:03, 04/07/12'),
                const SizedBox(height: 8),
                _buildActivityRow('Lần hoạt động trước:', '16:38, 18/09/26'),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 140,
                      child: Text(
                        'Số bài viết:',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[400],
                        ),
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text(
                                '35',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '|',
                                style: TextStyle(color: Colors.grey[500]),
                              ),
                              const SizedBox(width: 6),
                              InkWell(
                                onTap: () {},
                                child: const Text(
                                  'Xem những bài viết của bạn',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFFEF5350),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '(0.01 bài viết/ngày / 0.00% trong tổng số bài viết)',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[400],
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
        ],
      ),
    );
  }

  Widget _buildActivityRow(String label, String value) {
    return Row(
      children: [
        SizedBox(
          width: 140,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.grey[400],
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            color: Colors.white,
          ),
        ),
      ],
    );
  }



  // --- 7. Footer Diễn Đàn ---
  Widget _buildForumFooter() {
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
                  InkWell(
                    onTap: () {
                      setState(() {
                        _selectedTabIndex = 0;
                        _selectedSidebarIndex = 0;
                      });
                      UcpStateService.reset();
                    },
                    child: const Text('Thiết lập cá nhân', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFEF5350))),
                  ),
                  const SizedBox(width: 6),
                  const Text('<', style: TextStyle(color: Colors.white38, fontSize: 12)),
                  const SizedBox(width: 6),
                  if (_selectedSidebarIndex >= 0 && _selectedSidebarIndex < _sidebarMenus.length) ...[
                    InkWell(
                      onTap: () {
                        setState(() {
                          _selectedSidebarIndex = -1;
                        });
                        UcpStateService.setTab(_tabs[_selectedTabIndex]);
                      },
                      child: Text(
                        _tabs[_selectedTabIndex],
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFEF5350)),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text('<', style: TextStyle(color: Colors.white38, fontSize: 12)),
                    const SizedBox(width: 6),
                    Text(
                      _sidebarMenus[_selectedSidebarIndex],
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ] else ...[
                    Text(
                      _tabs[_selectedTabIndex],
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
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

  // --- 8. Màn hình báo Tính năng đang phát triển cho các Tab khác ---
  Widget _buildUnderDevelopmentLayout(BuildContext context, String tabName) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 380),
      decoration: BoxDecoration(
        color: const Color(0xFF161F36),
        border: Border.all(color: const Color(0xFF2E3B5F)),
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(6),
          bottomLeft: Radius.circular(6),
          bottomRight: Radius.circular(6),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFF131A30),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFFFD700).withValues(alpha: 0.3), width: 2),
              ),
              child: const Icon(
                Icons.construction_rounded,
                size: 44,
                color: Color(0xFFFFD700),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Tính năng "$tabName" đang được phát triển',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Chức năng này hiện đang được hoàn thiện và sẽ ra mắt trong bản cập nhật tới.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.5,
                color: Colors.grey[400],
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _selectedTabIndex = 0;
                  _selectedSidebarIndex = -1;
                });
                UcpStateService.reset();
              },
              icon: const Icon(Icons.arrow_back, size: 16, color: Colors.black87),
              label: const Text(
                'Quay lại Tổng quan',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Colors.black87,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFD700),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Khối báo đang phát triển trong nội dung Sidebar con
  Widget _buildUnderDevelopmentSidebarContent(String title) {
    return Container(
      color: const Color(0xFF1E2640),
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.construction_rounded, size: 36, color: Color(0xFFFFD700)),
            const SizedBox(height: 16),
            Text(
              'Mục "$title" đang được phát triển',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Nội dung đang được cập nhật và hoàn thiện.',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 20),
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _selectedSidebarIndex = 0;
                });
                UcpStateService.setSubItem(_tabs[_selectedTabIndex], _sidebarMenus[0]);
              },
              icon: const Icon(Icons.arrow_back, size: 14, color: Color(0xFFFFD700)),
              label: const Text(
                'Về Trang trước',
                style: TextStyle(
                  color: Color(0xFFFFD700),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Thanh thông báo nổi chuẩn Boxed — dùng helper toàn cục
  void _showBoxedSnackBar(String message) {
    showBoxedSnackBar(context, message);
  }
}
