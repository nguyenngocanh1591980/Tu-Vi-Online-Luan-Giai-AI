// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/ucp_state_service.dart';
import 'ucp_screen.dart';

/// Màn hình Hệ thống (UCP System Screen) độc lập
class UcpSystemScreen extends StatelessWidget {
  const UcpSystemScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const UcpScreen(initialTabIndex: 2);
  }
}

/// Widget nội dung tab Hệ thống với Theme Dark Navy (#1E2640) và Form chuẩn sắc nét
class UcpSystemContent extends StatefulWidget {
  final int initialSidebarIndex;

  const UcpSystemContent({
    super.key,
    this.initialSidebarIndex = 0,
  });

  @override
  State<UcpSystemContent> createState() => _UcpSystemContentState();
}

class _UcpSystemContentState extends State<UcpSystemContent> {
  late int _selectedSidebarIndex;

  // Thanh menu dọc 4 mục chuẩn theo Hình 5
  final List<String> _sidebarMenus = [
    'Sửa thiết lập cá nhân',
    'Sửa thiết lập gửi bài viết',
    'Sửa thiết lập xem bài viết',
    'Sửa tùy chọn thông báo',
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

  // Khối Khám phá thêm của Tab Hệ thống (Hình 5)
  List<String> get _currentExploreCategories {
    if (_selectedSidebarIndex == 2) {
      return const ['Huyền bí & Siêu linh', 'Đạo Phật', 'Âm dương ngũ hành'];
    }
    return const ['Toán học', 'Lá số Tứ trụ', 'Quản lý Kiến thức'];
  }

  // State các trường trong Form Sửa thiết lập cá nhân (Hình 5)
  bool _allowEmailContact = true;
  bool _receiveAdminEmail = true;
  bool _receiveOtherMessages = true;
  bool _alwaysHideOnline = false;

  String _selectedTheme = 'LySoVN';
  final List<String> _themes = ['LySoVN', 'prosilver', 'subsilver2'];

  String _selectedTimezoneDisplay = 'UTC+07:00 - 19 Tháng 9 2026, 14:52';
  final List<String> _timezoneDisplays = [
    'UTC+07:00 - 19 Tháng 9 2026, 14:52',
    'UTC+08:00 - 19 Tháng 9 2026, 15:52',
    'UTC+00:00 - 19 Tháng 9 2026, 07:52',
  ];

  String _selectedTimezoneValue = 'UTC+7';
  final List<String> _timezoneValues = [
    'UTC-12', 'UTC-11', 'UTC-10', 'UTC-9', 'UTC-8', 'UTC-7', 'UTC-6', 'UTC-5',
    'UTC-4', 'UTC-3', 'UTC-2', 'UTC-1', 'UTC+0', 'UTC+1', 'UTC+2', 'UTC+3',
    'UTC+4', 'UTC+5', 'UTC+6', 'UTC+7', 'UTC+8', 'UTC+9', 'UTC+10', 'UTC+11', 'UTC+12'
  ];

  String _selectedDateFormat = '14:52, 19/09/26';
  final List<String> _dateFormats = [
    '14:52, 19/09/26',
    'd/m/Y H:i',
    'Y-m-d H:i:s',
    'D M d, Y g:i a',
  ];

  // State Form Sửa thiết lập xem bài viết (Hình 5)
  // 5 Radio Button Có / Không
  bool _viewPostImages = true;
  bool _viewPostFlash = true;
  bool _viewPostSmilies = true;
  bool _viewPostSignatures = true;
  bool _viewPostAvatars = true;

  // Dropdown Nhóm Chủ đề (Hình 1, Hình 2, Hình 3)
  String _topicTimeFilter = 'Tất cả chủ đề';
  final List<String> _topicTimeFilters = const [
    'Tất cả chủ đề',
    '1 ngày',
    '7 ngày',
    '2 tuần',
    '1 tháng',
    '3 tháng',
    '6 tháng',
    '1 năm',
  ];

  String _topicSortBy = 'Ngày gửi';
  final List<String> _topicSortBys = const [
    'Người tạo',
    'Ngày gửi',
    'Trả lời',
    'Tiêu đề',
    'Xem',
  ];

  String _topicSortOrder = 'Giảm dần';
  final List<String> _topicSortOrders = const [
    'Giảm dần',
    'Tăng dần',
  ];

  // Dropdown Nhóm Bài viết (Hình 4, Hình 2, Hình 3)
  String _postTimeFilter = 'Tất cả bài viết';
  final List<String> _postTimeFilters = const [
    'Tất cả bài viết',
    '1 ngày',
    '7 ngày',
    '2 tuần',
    '1 tháng',
    '3 tháng',
    '6 tháng',
    '1 năm',
  ];

  String _postSortBy = 'Ngày gửi';
  final List<String> _postSortBys = const [
    'Người tạo',
    'Ngày gửi',
    'Tiêu đề',
  ];

  String _postSortOrder = 'Tăng dần';
  final List<String> _postSortOrders = const [
    'Tăng dần',
    'Giảm dần',
  ];

  // Trạng thái hiển thị trang thông báo thành công sau khi Xác nhận (Hình 4 & Hình 5)
  bool _isSuccess = false;

  @override
  void initState() {
    super.initState();
    _selectedSidebarIndex = widget.initialSidebarIndex;
    if (_selectedSidebarIndex >= 0 && _selectedSidebarIndex < _sidebarMenus.length) {
      UcpStateService.setSubItem('Hệ thống', _sidebarMenus[_selectedSidebarIndex]);
    } else {
      UcpStateService.setSubItem('Hệ thống', _sidebarMenus[0]);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isSuccess) {
      return UcpSuccessMessage(
        onBack: () {
          setState(() {
            _isSuccess = false;
          });
        },
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Khối Card chính gồm Sidebar + Nội dung tương ứng
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

        const SizedBox(height: 20),

        // Khối Khám phá thêm đặc trưng của Tab Hệ thống (Hình 5)
        _buildExploreMoreSection(),
      ],
    );
  }

  Widget _buildCurrentSidebarContent() {
    switch (_selectedSidebarIndex) {
      case 0:
        return _buildEditPersonalSettingsForm();
      case 2:
        return _buildEditPostViewSettingsForm();
      default:
        return _buildUnderDevelopmentSidebarContent(_sidebarMenus[_selectedSidebarIndex]);
    }
  }

  // Sidebar Menu bên trái
  Widget _buildSidebar() {
    return Container(
      color: const Color(0xFF161F36),
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Các mục menu của tab Hệ thống (4 mục theo Hình 5)
          ...List.generate(_sidebarMenus.length, (index) {
            final isSelected = _selectedSidebarIndex == index;
            return InkWell(
              onTap: () {
                setState(() {
                  _selectedSidebarIndex = index;
                });
                UcpStateService.setSubItem('Hệ thống', _sidebarMenus[index]);
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

  // --- Nội dung Form Sửa thiết lập cá nhân (Hình 5) ---
  Widget _buildEditPersonalSettingsForm() {
    return Container(
      color: const Color(0xFF1E2640),
      padding: const EdgeInsets.all(18.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tiêu đề
          const Text(
            'Sửa thiết lập cá nhân',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 14),

          // Khối bao bọc Form
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: const Color(0xFF161F36),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFF2E3B5F)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Cho phép các thành viên khác liên hệ với tôi qua email
                _buildRadioRow(
                  label: 'Cho phép các thành viên khác liên hệ với tôi qua email:',
                  value: _allowEmailContact,
                  onChanged: (val) {
                    setState(() {
                      _allowEmailContact = val ?? true;
                    });
                  },
                ),
                const Divider(color: Color(0xFF2E3B5F), height: 24),

                // 2. Nhận những thông tin qua email từ quản trị viên
                _buildRadioRow(
                  label: 'Nhận những thông tin qua email từ quản trị viên:',
                  value: _receiveAdminEmail,
                  onChanged: (val) {
                    setState(() {
                      _receiveAdminEmail = val ?? true;
                    });
                  },
                ),
                const Divider(color: Color(0xFF2E3B5F), height: 24),

                // 3. Nhận tin nhắn từ các thành viên khác
                _buildRadioRow(
                  label: 'Nhận tin nhắn từ các thành viên khác:',
                  value: _receiveOtherMessages,
                  subtitle: 'Lưu ý rằng các điều hành viên hay quản trị viên luôn có thể gửi tin nhắn cho bạn.',
                  onChanged: (val) {
                    setState(() {
                      _receiveOtherMessages = val ?? true;
                    });
                  },
                ),
                const Divider(color: Color(0xFF2E3B5F), height: 24),

                // 4. Luôn ẩn trạng thái trực tuyến của tôi
                _buildRadioRow(
                  label: 'Luôn ẩn trạng thái trực tuyến của tôi:',
                  value: _alwaysHideOnline,
                  subtitle: 'Thay đổi thiết lập này sẽ không có hiệu lực cho đến lần ghé thăm kế tiếp của bạn.',
                  onChanged: (val) {
                    setState(() {
                      _alwaysHideOnline = val ?? false;
                    });
                  },
                ),
                const Divider(color: Color(0xFF2E3B5F), height: 24),

                // 5. Giao diện Dropdown
                _buildDropdownRow(
                  label: 'Giao diện:',
                  child: _buildStyledDropdown<String>(
                    value: _selectedTheme,
                    items: _themes.map((theme) {
                      return DropdownMenuItem<String>(
                        value: theme,
                        child: Text(theme),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _selectedTheme = val;
                        });
                      }
                    },
                  ),
                ),
                const Divider(color: Color(0xFF2E3B5F), height: 24),

                // 6. Múi giờ Dropdown (2 Dropdown theo Hình 5)
                _buildDropdownRow(
                  label: 'Múi giờ:',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildStyledDropdown<String>(
                        value: _selectedTimezoneDisplay,
                        items: _timezoneDisplays.map((item) {
                          return DropdownMenuItem<String>(
                            value: item,
                            child: Text(item),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _selectedTimezoneDisplay = val;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 8),
                      _buildStyledDropdown<String>(
                        value: _selectedTimezoneValue,
                        items: _timezoneValues.map((tz) {
                          return DropdownMenuItem<String>(
                            value: tz,
                            child: Text(tz),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _selectedTimezoneValue = val;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ),
                const Divider(color: Color(0xFF2E3B5F), height: 24),

                // 7. Định dạng ngày tháng của bạn Dropdown
                _buildDropdownRow(
                  label: 'Định dạng ngày tháng của bạn:',
                  subtitle: 'Sử dụng cú pháp giống như hàm date() trong PHP.',
                  child: _buildStyledDropdown<String>(
                    value: _selectedDateFormat,
                    items: _dateFormats.map((fmt) {
                      return DropdownMenuItem<String>(
                        value: fmt,
                        child: Text(fmt),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _selectedDateFormat = val;
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Nút Xác nhận
          Center(
            child: ElevatedButton(
              onPressed: () {
                setState(() {
                  _isSuccess = true;
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2A3450),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                  side: const BorderSide(color: Color(0xFF3F4E75)),
                ),
                elevation: 2,
              ),
              child: const Text(
                'Xác nhận',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Nội dung Form Sửa thiết lập xem bài viết (Hình 5) ---
  Widget _buildEditPostViewSettingsForm() {
    return Container(
      color: const Color(0xFF1E2640),
      padding: const EdgeInsets.all(18.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tiêu đề
          const Text(
            'Sửa thiết lập xem bài viết',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 14),

          // Khối bao bọc Form
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: const Color(0xFF161F36),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFF2E3B5F)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Hiển thị hình ảnh trong các bài viết
                _buildRadioRow(
                  label: 'Hiển thị hình ảnh trong các bài viết:',
                  value: _viewPostImages,
                  onChanged: (val) {
                    setState(() {
                      _viewPostImages = val ?? true;
                    });
                  },
                ),
                const Divider(color: Color(0xFF2E3B5F), height: 24),

                // 2. Hiển thị những tập tin Flash
                _buildRadioRow(
                  label: 'Hiển thị những tập tin Flash:',
                  value: _viewPostFlash,
                  onChanged: (val) {
                    setState(() {
                      _viewPostFlash = val ?? true;
                    });
                  },
                ),
                const Divider(color: Color(0xFF2E3B5F), height: 24),

                // 3. Hiển thị những biểu tượng vui
                _buildRadioRow(
                  label: 'Hiển thị những biểu tượng vui:',
                  value: _viewPostSmilies,
                  onChanged: (val) {
                    setState(() {
                      _viewPostSmilies = val ?? true;
                    });
                  },
                ),
                const Divider(color: Color(0xFF2E3B5F), height: 24),

                // 4. Hiển thị chữ ký cá nhân
                _buildRadioRow(
                  label: 'Hiển thị chữ ký cá nhân:',
                  value: _viewPostSignatures,
                  onChanged: (val) {
                    setState(() {
                      _viewPostSignatures = val ?? true;
                    });
                  },
                ),
                const Divider(color: Color(0xFF2E3B5F), height: 24),

                // 5. Hiển thị hình đại diện
                _buildRadioRow(
                  label: 'Hiển thị hình đại diện:',
                  value: _viewPostAvatars,
                  onChanged: (val) {
                    setState(() {
                      _viewPostAvatars = val ?? true;
                    });
                  },
                ),
                const Divider(color: Color(0xFF2E3B5F), height: 24),

                // --- Nhóm Chủ Đề (Hình 1, 2, 3) ---
                // 6. Hiển thị những chủ đề cách đây
                _buildDropdownRow(
                  label: 'Hiển thị những chủ đề cách đây:',
                  child: _buildStyledDropdown<String>(
                    value: _topicTimeFilter,
                    items: _topicTimeFilters.map((item) {
                      return DropdownMenuItem<String>(
                        value: item,
                        child: Text(item),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _topicTimeFilter = val;
                        });
                      }
                    },
                  ),
                ),
                const Divider(color: Color(0xFF2E3B5F), height: 24),

                // 7. Hiển thị những chủ đề sắp xếp theo
                _buildDropdownRow(
                  label: 'Hiển thị những chủ đề sắp xếp theo:',
                  child: _buildStyledDropdown<String>(
                    value: _topicSortBy,
                    items: _topicSortBys.map((item) {
                      return DropdownMenuItem<String>(
                        value: item,
                        child: Text(item),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _topicSortBy = val;
                        });
                      }
                    },
                  ),
                ),
                const Divider(color: Color(0xFF2E3B5F), height: 24),

                // 8. Hiển thị chủ đề theo thứ tự
                _buildDropdownRow(
                  label: 'Hiển thị chủ đề theo thứ tự:',
                  child: _buildStyledDropdown<String>(
                    value: _topicSortOrder,
                    items: _topicSortOrders.map((item) {
                      return DropdownMenuItem<String>(
                        value: item,
                        child: Text(item),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _topicSortOrder = val;
                        });
                      }
                    },
                  ),
                ),
                const Divider(color: Color(0xFF2E3B5F), height: 24),

                // --- Nhóm Bài Viết (Hình 4, 2, 3) ---
                // 9. Hiển thị những bài viết cách đây
                _buildDropdownRow(
                  label: 'Hiển thị những bài viết cách đây:',
                  child: _buildStyledDropdown<String>(
                    value: _postTimeFilter,
                    items: _postTimeFilters.map((item) {
                      return DropdownMenuItem<String>(
                        value: item,
                        child: Text(item),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _postTimeFilter = val;
                        });
                      }
                    },
                  ),
                ),
                const Divider(color: Color(0xFF2E3B5F), height: 24),

                // 10. Hiển thị những bài viết sắp xếp theo
                _buildDropdownRow(
                  label: 'Hiển thị những bài viết sắp xếp theo:',
                  child: _buildStyledDropdown<String>(
                    value: _postSortBy,
                    items: _postSortBys.map((item) {
                      return DropdownMenuItem<String>(
                        value: item,
                        child: Text(item),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _postSortBy = val;
                        });
                      }
                    },
                  ),
                ),
                const Divider(color: Color(0xFF2E3B5F), height: 24),

                // 11. Hiển thị bài viết theo thứ tự
                _buildDropdownRow(
                  label: 'Hiển thị bài viết theo thứ tự:',
                  child: _buildStyledDropdown<String>(
                    value: _postSortOrder,
                    items: _postSortOrders.map((item) {
                      return DropdownMenuItem<String>(
                        value: item,
                        child: Text(item),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _postSortOrder = val;
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Nút Xác nhận
          Center(
            child: ElevatedButton(
              onPressed: () {
                setState(() {
                  _isSuccess = true;
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2A3450),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                  side: const BorderSide(color: Color(0xFF3F4E75)),
                ),
                elevation: 2,
              ),
              child: const Text(
                'Xác nhận',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Row câu hỏi Radio Button (Có / Không)
  Widget _buildRadioRow({
    required String label,
    required bool value,
    required ValueChanged<bool?> onChanged,
    String? subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[400],
                    height: 1.4,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: 16),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Radio<bool>(
                  value: true,
                  groupValue: value,
                  onChanged: onChanged,
                  activeColor: const Color(0xFF2196F3),
                ),
                const Text(
                  'Có',
                  style: TextStyle(fontSize: 13.5, color: Colors.white),
                ),
              ],
            ),
            const SizedBox(width: 16),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Radio<bool>(
                  value: false,
                  groupValue: value,
                  onChanged: onChanged,
                  activeColor: const Color(0xFF2196F3),
                ),
                const Text(
                  'Không',
                  style: TextStyle(fontSize: 13.5, color: Colors.white),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  // Row cho Dropdown
  Widget _buildDropdownRow({
    required String label,
    required Widget child,
    String? subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 4,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[400],
                    height: 1.4,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 6,
          child: child,
        ),
      ],
    );
  }

  // Dropdown phong cách Dark Navy
  Widget _buildStyledDropdown<T>({
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFF131A30),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFF2E3B5F), width: 1),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          dropdownColor: const Color(0xFF131A30),
          focusColor: const Color(0xFF2A324D),
          icon: const Icon(Icons.arrow_drop_down, color: Colors.white70),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13.5,
          ),
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }

  // Khối báo đang phát triển trong các mục menu khác của Hệ thống
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
                UcpStateService.setSubItem('Hệ thống', _sidebarMenus[0]);
              },
              icon: const Icon(Icons.arrow_back, size: 14, color: Color(0xFFFFD700)),
              label: const Text(
                'Về Sửa thiết lập cá nhân',
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

  // Khối Khám phá thêm của Tab Hệ thống (Hình 5)
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
          ...List.generate(_currentExploreCategories.length, (index) {
            final title = _currentExploreCategories[index];
            final isLast = index == _currentExploreCategories.length - 1;

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
}

/// Component Trang Thông Báo Thành Công (Hình 5)
/// Chuẩn Boxed Layout 1024px, Theme Dark Navy (#1E2640), triệt tiêu khe hở trắng
class UcpSuccessMessage extends StatelessWidget {
  final VoidCallback? onBack;
  final String title;
  final String message;
  final String backLabel;
  final List<String> exploreCategories;

  const UcpSuccessMessage({
    super.key,
    this.onBack,
    this.title = 'Thông tin',
    this.message = 'Sở thích cá nhân của bạn đã được cập nhật thành công.',
    this.backLabel = 'Quay về bảng thiết lập cá nhân',
    this.exploreCategories = const [
      'Xem Phong thủy',
      'Thiên văn học',
      'Kiến thức Phong thủy',
    ],
  });

  @override
  Widget build(BuildContext context) {
    final cardContent = Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Khối Khám phá thêm (Hình 5: Nằm trên, 3 mục: Xem Phong thủy, Thiên văn học, Kiến thức Phong thủy)
          _buildExploreSection(),
          const SizedBox(height: 16),

          // 2. Khối Thông tin (Hình 5: Nền #131A30, viền #2E3B5F, bo góc 6px)
          _buildInfoBox(context),
          const SizedBox(height: 28),

          // 3. Footer Diễn đàn
          _buildForumFooter(context),
        ],
      ),
    );

    final hasParentScaffold = Scaffold.maybeOf(context) != null;
    if (hasParentScaffold) {
      return cardContent;
    }

    return Material(color: Colors.transparent, child: 
      
      SingleChildScrollView(
        child: cardContent,
      ),
    );
  }

  // Khối Khám phá thêm (Hình 5)
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
          ...List.generate(exploreCategories.length, (index) {
            final item = exploreCategories[index];
            final isLast = index == exploreCategories.length - 1;

            return InkWell(
              onTap: () {},
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  border: isLast ? null : const Border(bottom: BorderSide(color: Color(0xFF2E3B5F))),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      item,
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

  // Khối Thông tin (Hình 5)
  Widget _buildInfoBox(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF131A30),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF2E3B5F)),
      ),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          const Divider(color: Color(0xFF2E3B5F), height: 1),
          const SizedBox(height: 14),
          Text(
            message,
            style: const TextStyle(
              fontSize: 13.5,
              color: Color(0xFFE0E0E0),
              height: 1.45,
            ),
          ),
          const SizedBox(height: 14),
          InkWell(
            onTap: onBack,
            child: Text(
              backLabel,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.bold,
                color: Color(0xFFEF5350),
                decoration: TextDecoration.underline,
                decorationColor: Color(0xFFEF5350),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Footer Diễn đàn (Hình 5)
  Widget _buildForumFooter(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            InkWell(
              onTap: () => context.go('/forum'),
              child: Row(
                children: const [
                  Icon(Icons.home, size: 14, color: Color(0xFFEF5350)),
                  SizedBox(width: 4),
                  Text(
                    'Trang chủ',
                    style: TextStyle(fontSize: 12, color: Color(0xFFEF5350)),
                  ),
                  Text(' • ', style: TextStyle(fontSize: 12, color: Colors.white54)),
                  Text(
                    'Diễn đàn',
                    style: TextStyle(fontSize: 12, color: Color(0xFFEF5350)),
                  ),
                ],
              ),
            ),
            Flexible(
              child: Wrap(
                alignment: WrapAlignment.end,
                spacing: 8,
                children: const [
                  Text('Liên hệ', style: TextStyle(fontSize: 11.5, color: Colors.white54)),
                  Text('•', style: TextStyle(fontSize: 11.5, color: Colors.white54)),
                  Text('Chia sẻ', style: TextStyle(fontSize: 11.5, color: Colors.white54)),
                  Text('•', style: TextStyle(fontSize: 11.5, color: Colors.white54)),
                  Text('Chúng tôi', style: TextStyle(fontSize: 11.5, color: Colors.white54)),
                  Text('•', style: TextStyle(fontSize: 11.5, color: Colors.white54)),
                  Text('Thành viên', style: TextStyle(fontSize: 11.5, color: Colors.white54)),
                  Text('•', style: TextStyle(fontSize: 11.5, color: Colors.white54)),
                  Text('Xóa hết cookie', style: TextStyle(fontSize: 11.5, color: Colors.white54)),
                  Text('Múi giờ UTC+07:00', style: TextStyle(fontSize: 11.5, color: Colors.white54)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const Text(
          'Powered by phpBB® Forum Software © phpBB Limited',
          style: TextStyle(fontSize: 11, color: Colors.white38),
        ),
        const SizedBox(height: 4),
        const Text(
          'Chính sách bảo mật | Điều khoản tham gia',
          style: TextStyle(fontSize: 11, color: Color(0xFFEF5350)),
        ),
      ],
    );
  }
}
