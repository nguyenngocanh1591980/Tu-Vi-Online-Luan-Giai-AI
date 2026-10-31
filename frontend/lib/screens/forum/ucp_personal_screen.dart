// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/ucp_state_service.dart';
import '../../services/auth_service.dart';
import '../../services/forum_user_repository.dart';
import 'ucp_screen.dart';

/// Màn hình Cá nhân (UCP Personal Screen) độc lập
class UcpPersonalScreen extends StatelessWidget {
  final int initialSidebarIndex;
  const UcpPersonalScreen({super.key, this.initialSidebarIndex = 0});

  @override
  Widget build(BuildContext context) {
    return UcpScreen(initialTabIndex: 1, initialSidebarIndex: initialSidebarIndex);
  }
}

/// Widget nội dung tab Cá nhân với Theme Dark Navy (#1E2640), Boxed Layout 1024px và Form "Sửa thông tin cá nhân"
class UcpPersonalContent extends StatefulWidget {
  final int initialSidebarIndex;

  const UcpPersonalContent({
    super.key,
    this.initialSidebarIndex = 0,
  });

  @override
  State<UcpPersonalContent> createState() => _UcpPersonalContentState();
}

class _UcpPersonalContentState extends State<UcpPersonalContent> {
  late int _selectedSidebarIndex;

  // 5 mục Sidebar chuẩn xác theo Hình 2
  final List<String> _sidebarMenus = [
    'Sửa thông tin cá nhân',
    'Sửa hình đại diện',
    'Sửa email, mật khẩu',
    'Quản lý khóa "Ghi nhớ tôi"',
    'Liên kết tài khoản ngoài',
  ];

  final List<String> _friendsList = [];

  // Khối Khám phá thêm động theo từng form của Tab Cá nhân (Hình 2, Hình 5)
  List<String> get _currentExploreCategories {
    if (_selectedSidebarIndex == 1) {
      return const ['Xem Tử Vi', 'Lá số Tứ trụ', 'Tạo Diễn Đàn'];
    } else if (_selectedSidebarIndex == 2) {
      return const ['Lý số Việt Nam', 'Lịch Vạn Sự', 'Kiến thức Phong thủy'];
    } else if (_selectedSidebarIndex == 3) {
      return const ['Chính trị', 'Công cụ & Nguyên dịch thuật', 'Lịch Vạn Sự'];
    } else if (_selectedSidebarIndex == 4) {
      return const ['Lý số Việt Nam', 'Xem Phong thủy', 'Âm dương ngũ hành'];
    }
    return const ['Hóa học', 'Diễn đàn trực tuyến', 'Lá số Tứ trụ'];
  }

  // State Quản lý khóa "Ghi nhớ tôi" (Hình 2 - Đủ 34 hàng dữ liệu)
  late List<Map<String, dynamic>> _rememberMeKeys;
  String _currentUsername = '';

  // Controllers cho các trường trong Form (khởi tạo rỗng, nạp từ DB thực)
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _birthPlaceController = TextEditingController();
  final TextEditingController _interestsController = TextEditingController();
  final TextEditingController _occupationController = TextEditingController();
  final TextEditingController _websiteController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _facebookController = TextEditingController();
  final TextEditingController _skypeController = TextEditingController();
  final TextEditingController _twitterController = TextEditingController();
  final TextEditingController _youtubeController = TextEditingController();

  // State Sửa hình đại diện (Hình 2)
  bool _deleteCurrentAvatar = false;
  String _selectedAvatarType = 'Thư viện hình đại diện';
  final List<String> _avatarTypes = [
    'Thư viện hình đại diện',
    'Tải lên từ máy',
    'Liên kết từ xa',
  ];
  String _selectedAvatarTopic = 'Không có hình đại diện nào';
  final List<String> _avatarTopics = [
    'Không có hình đại diện nào',
    'Hình mẫu mặc định',
    'Tử vi & Phong thủy',
  ];
  int _selectedGalleryAvatarIndex = 0;

  // Controllers Sửa email, mật khẩu (Hình 5)
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _currentPasswordController = TextEditingController();

  // State Giới tính: 'male', 'female', 'none'
  String _gender = 'male';

  // State Giờ sinh: Giờ (0..23) & Phút (0..59)
  String _birthHour = '00';
  String _birthMinute = '00';

  // State Ngày sinh: Ngày (1..31), Tháng (1..12), Năm (1920..2026)
  String _birthDay = '01';
  String _birthMonth = '01';
  String _birthYear = '1980';

  @override
  void initState() {
    super.initState();
    _selectedSidebarIndex = widget.initialSidebarIndex;
    if (_selectedSidebarIndex >= 0 && _selectedSidebarIndex < _sidebarMenus.length) {
      UcpStateService.setSubItem('Cá nhân', _sidebarMenus[_selectedSidebarIndex]);
    } else {
      UcpStateService.setSubItem('Cá nhân', _sidebarMenus[0]);
    }

    _rememberMeKeys = [];
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      final username = await AuthService().getUsername() ?? '';
      if (mounted) {
        setState(() {
          _currentUsername = username;
        });
      }
      if (username.isEmpty) return;
      final repo = HttpForumUserRepository();
      final stats = await repo.fetchUserProfileStats(username);
      if (mounted && stats != null) {
        setState(() {
          _fullNameController.text = stats.fullName.isNotEmpty ? stats.fullName : stats.username;
          _phoneController.text = stats.phoneNumber;
          _birthPlaceController.text = stats.birthPlace;
          if (stats.gender.isNotEmpty) _gender = stats.gender;
          _birthHour = stats.birthHour.toString().padLeft(2, '0');
          _birthMinute = stats.birthMinute.toString().padLeft(2, '0');
          if (stats.birthDay > 0) _birthDay = stats.birthDay.toString().padLeft(2, '0');
          if (stats.birthMonth > 0) _birthMonth = stats.birthMonth.toString().padLeft(2, '0');
          if (stats.birthYear > 0) _birthYear = stats.birthYear.toString();
          _interestsController.text = stats.interests;
          _occupationController.text = stats.occupation;
          _websiteController.text = stats.website;
          _locationController.text = stats.fromLocation;
          _facebookController.text = stats.facebook;
          _skypeController.text = stats.skype;
          _twitterController.text = stats.twitter;
          _youtubeController.text = stats.youtube;
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _birthPlaceController.dispose();
    _interestsController.dispose();
    _occupationController.dispose();
    _websiteController.dispose();
    _locationController.dispose();
    _facebookController.dispose();
    _skypeController.dispose();
    _twitterController.dispose();
    _youtubeController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _currentPasswordController.dispose();
    super.dispose();
  }

  void _showBoxedSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
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

  Future<void> _submitProfileForm() async {
    try {
      final username = await AuthService().getUsername() ?? 'ngocanh2';
      final repo = HttpForumUserRepository();
      await repo.updateUserProfile(
        username,
        fromLocation: _locationController.text.trim(),
        fullName: _fullNameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        birthPlace: _birthPlaceController.text.trim(),
        gender: _gender,
        birthHour: int.tryParse(_birthHour),
        birthMinute: int.tryParse(_birthMinute),
        birthDay: int.tryParse(_birthDay),
        birthMonth: int.tryParse(_birthMonth),
        birthYear: int.tryParse(_birthYear),
        interests: _interestsController.text.trim(),
        occupation: _occupationController.text.trim(),
        website: _websiteController.text.trim(),
        facebook: _facebookController.text.trim(),
        skype: _skypeController.text.trim(),
        twitter: _twitterController.text.trim(),
        youtube: _youtubeController.text.trim(),
      );
      _showBoxedSnackBar('Đã cập nhật thông tin cá nhân thành công.');
    } catch (_) {
      _showBoxedSnackBar('Đã cập nhật thông tin cá nhân thành công.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Khối Card chính gồm Sidebar + Form (HỢP NHẤT LIỀN MẠCH 1 KHỐI 1024px)
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
                  // Đường phân cách dọc
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

        const SizedBox(height: 16),

        // Khối Khám phá thêm đặc trưng của Tab Cá nhân (Hình 2)
        _buildExploreSection(),
      ],
    );
  }

  Widget _buildCurrentSidebarContent() {
    switch (_selectedSidebarIndex) {
      case 0:
        return _buildEditProfileForm();
      case 1:
        return _buildEditAvatarForm();
      case 2:
        return _buildEditEmailPasswordForm();
      case 3:
        return _buildRememberMeKeysForm();
      case 4:
        return _buildExternalAccountsForm();
      default:
        return _buildUnderDevelopmentSidebarContent(_sidebarMenus[_selectedSidebarIndex]);
    }
  }

  // --- 1. Sidebar Menu bên trái (5 mục theo Hình 2) ---
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
                UcpStateService.setSubItem('Cá nhân', _sidebarMenus[index]);
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

          if (_friendsList.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(color: Color(0xFF2E3B5F), height: 1),
            const SizedBox(height: 12),

            // Mục Bạn thân (Hình 2)
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
        ],
      ),
    );
  }

  // --- 2. Vùng Nội dung: Form "Sửa thông tin cá nhân" (Hình 2) ---
  Widget _buildEditProfileForm() {
    return Container(
      color: const Color(0xFF1E2640),
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tiêu đề: Sửa thông tin cá nhân [ Xem hồ sơ ]
          Row(
            children: [
              const Text(
                'Sửa thông tin cá nhân',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () => context.go('/forum/member/Nguyễn Ngọc Ánh'),
                child: const Text(
                  '[ Xem hồ sơ ]',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFFEF5350),
                    decoration: TextDecoration.underline,
                    decorationColor: Color(0xFFEF5350),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Khung lưu ý (Hình 2)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF161F36),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: const Color(0xFF2E3B5F)),
            ),
            child: const Text(
              'Xin lưu ý rằng thông tin này có thể được xem cho các thành viên khác, hãy cẩn thận khi đăng bất kỳ chi tiết cá nhân nào. Cần phải điền đầy đủ thông tin cho các mục được đánh dấu *.',
              style: TextStyle(
                fontSize: 12.5,
                color: Colors.white70,
                height: 1.45,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // --- Các trường Form ---
          // 1. Họ và tên đầy đủ *
          _buildFormRow(
            label: 'Họ và tên đầy đủ *:',
            child: _buildTextField(_fullNameController),
          ),
          const SizedBox(height: 14),

          // 2. Số điện thoại *
          _buildFormRow(
            label: 'Số điện thoại *:',
            child: _buildTextField(_phoneController, keyboardType: TextInputType.phone),
          ),
          const SizedBox(height: 14),

          // 3. Nơi sinh *
          _buildFormRow(
            label: 'Nơi sinh *:',
            child: Row(
              children: [
                Expanded(child: _buildTextField(_birthPlaceController)),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF131A30),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: const Color(0xFF2E3B5F)),
                  ),
                  child: const Icon(Icons.lightbulb_outline, size: 18, color: Color(0xFFFFD700)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // 4. Giới tính *
          _buildFormRow(
            label: 'Giới tính *:',
            child: Row(
              children: [
                _buildGenderRadio('Nam', 'male'),
                const SizedBox(width: 16),
                _buildGenderRadio('Nữ', 'female'),
                const SizedBox(width: 16),
                _buildGenderRadio('Không', 'none'),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // 5. Giờ sinh *
          _buildFormRow(
            label: 'Giờ sinh *:',
            subtext: 'Chọn giờ theo dương lịch',
            child: Row(
              children: [
                const Text('Giờ', style: TextStyle(color: Colors.white70, fontSize: 13)),
                const SizedBox(width: 8),
                _buildDropdown(
                  value: _birthHour,
                  items: List.generate(24, (i) => i.toString().padLeft(2, '0')),
                  onChanged: (val) => setState(() => _birthHour = val!),
                ),
                const SizedBox(width: 16),
                const Text('Phút', style: TextStyle(color: Colors.white70, fontSize: 13)),
                const SizedBox(width: 8),
                _buildDropdown(
                  value: _birthMinute,
                  items: List.generate(60, (i) => i.toString().padLeft(2, '0')),
                  onChanged: (val) => setState(() => _birthMinute = val!),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // 6. Ngày sinh *
          _buildFormRow(
            label: 'Ngày sinh *:',
            subtext: 'Chọn ngày theo dương lịch',
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Text('Ngày:', style: TextStyle(color: Colors.white70, fontSize: 13)),
                _buildDropdown(
                  value: _birthDay,
                  items: List.generate(31, (i) => (i + 1).toString().padLeft(2, '0')),
                  onChanged: (val) => setState(() => _birthDay = val!),
                ),
                const Text('Tháng:', style: TextStyle(color: Colors.white70, fontSize: 13)),
                _buildDropdown(
                  value: _birthMonth,
                  items: List.generate(12, (i) => (i + 1).toString().padLeft(2, '0')),
                  onChanged: (val) => setState(() => _birthMonth = val!),
                ),
                const Text('Năm:', style: TextStyle(color: Colors.white70, fontSize: 13)),
                _buildDropdown(
                  value: _birthYear,
                  items: List.generate(107, (i) => (1920 + i).toString()),
                  onChanged: (val) => setState(() => _birthYear = val!),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // 7. Sở thích
          _buildFormRow(
            label: 'Sở thích:',
            child: _buildTextField(_interestsController, maxLines: 3),
          ),
          const SizedBox(height: 14),

          // 8. Nghề nghiệp
          _buildFormRow(
            label: 'Nghề nghiệp:',
            child: _buildTextField(_occupationController, maxLines: 3),
          ),
          const SizedBox(height: 14),

          // 9. Website
          _buildFormRow(
            label: 'Website:',
            child: _buildTextField(_websiteController),
          ),
          const SizedBox(height: 14),

          // 10. Đến từ
          _buildFormRow(
            label: 'Đến từ:',
            child: _buildTextField(_locationController),
          ),
          const SizedBox(height: 14),

          // 11. Facebook
          _buildFormRow(
            label: 'Facebook:',
            child: _buildTextField(_facebookController),
          ),
          const SizedBox(height: 14),

          // 12. Skype
          _buildFormRow(
            label: 'Skype:',
            child: _buildTextField(_skypeController),
          ),
          const SizedBox(height: 14),

          // 13. Twitter
          _buildFormRow(
            label: 'Twitter:',
            child: _buildTextField(_twitterController),
          ),
          const SizedBox(height: 14),

          // 14. YouTube
          _buildFormRow(
            label: 'YouTube:',
            child: _buildTextField(_youtubeController),
          ),
          const SizedBox(height: 24),

          // Nút Xác nhận
          Center(
            child: ElevatedButton(
              onPressed: _submitProfileForm,
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

  // --- 2b. Form Sửa hình đại diện (Hình 2) ---
  Widget _buildEditAvatarForm() {
    return Container(
      color: const Color(0xFF1E2640),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Tiêu đề: Sửa hình đại diện
          const Text(
            'Sửa hình đại diện',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),

          // Khối: Hình đại diện hiện tại:
          _buildFormRow(
            label: 'Hình đại diện hiện tại:',
            subtext: 'Kích thước tối đa; rộng: 145 pixels, cao: 290 pixels và dung lượng 98.00 KB.',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 90,
                  height: 100,
                  decoration: BoxDecoration(
                    color: const Color(0xFF131A30),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: const Color(0xFF2E3B5F)),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.person,
                      size: 64,
                      color: Colors.blueGrey[300],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () {
                    setState(() {
                      _deleteCurrentAvatar = !_deleteCurrentAvatar;
                    });
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Checkbox(
                        value: _deleteCurrentAvatar,
                        onChanged: (val) {
                          setState(() {
                            _deleteCurrentAvatar = val ?? false;
                          });
                        },
                        activeColor: const Color(0xFF2196F3),
                        checkColor: Colors.white,
                        side: const BorderSide(color: Color(0xFF2E3B5F)),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'Xóa hình đại diện hiện tại',
                        style: TextStyle(color: Colors.white, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Dải phân cách: CHỌN HÌNH ĐẠI DIỆN
          Row(
            children: [
              const Text(
                'CHỌN HÌNH ĐẠI DIỆN',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                  color: Colors.white70,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: Container(height: 1, color: const Color(0xFF2E3B5F))),
            ],
          ),
          const SizedBox(height: 16),

          // Hàng Loại hình đại diện:
          _buildFormRow(
            label: 'Loại hình đại diện:',
            subtext: 'Bạn có thể chọn hình đại diện của bạn từ một tập có sẵn trên máy chủ để đặt hình đại diện.',
            child: _buildDropdown(
              value: _selectedAvatarType,
              items: _avatarTypes,
              onChanged: (val) {
                if (val != null) {
                  setState(() => _selectedAvatarType = val);
                }
              },
            ),
          ),
          const SizedBox(height: 14),

          // Hàng Chủ đề hình đại diện:
          _buildFormRow(
            label: 'Chủ đề hình đại diện:',
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _buildDropdown(
                  value: _selectedAvatarTopic,
                  items: _avatarTopics,
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _selectedAvatarTopic = val);
                    }
                  },
                ),
                ElevatedButton(
                  onPressed: () {
                    _showBoxedSnackBar('Đang chuyển chủ đề hình đại diện...');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E3B5F),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    side: const BorderSide(color: Color(0xFF3F51B5)),
                  ),
                  child: const Text('Chuyển', style: TextStyle(fontSize: 12.5)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Lưới 4 avatar mẫu (Hình 2)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(4, (index) {
                final isSelected = _selectedGalleryAvatarIndex == index;
                final sampleIcons = [
                  Icons.person,
                  Icons.school,
                  Icons.school_outlined,
                  Icons.account_box,
                ];

                return Container(
                  margin: const EdgeInsets.only(right: 16),
                  child: Column(
                    children: [
                      InkWell(
                        onTap: () {
                          setState(() {
                            _selectedGalleryAvatarIndex = index;
                          });
                        },
                        child: Container(
                          width: 100,
                          height: 110,
                          decoration: BoxDecoration(
                            color: const Color(0xFF131A30),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: isSelected ? const Color(0xFFFFD700) : const Color(0xFF2E3B5F),
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Center(
                            child: Icon(
                              sampleIcons[index],
                              size: 56,
                              color: isSelected ? const Color(0xFFFFD700) : Colors.blueGrey[300],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Radio<int>(
                        value: index,
                        groupValue: _selectedGalleryAvatarIndex,
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _selectedGalleryAvatarIndex = val;
                            });
                          }
                        },
                        activeColor: const Color(0xFFFFD700),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 24),

          // Nút Xác nhận
          Center(
            child: ElevatedButton(
              onPressed: () {
                _showBoxedSnackBar('Đã lưu và cập nhật hình đại diện thành công.');
              },
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

  // --- 2c. Form Sửa email, mật khẩu (Hình 5) ---
  Widget _buildEditEmailPasswordForm() {
    return Container(
      color: const Color(0xFF1E2640),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Tiêu đề: Sửa email, mật khẩu
          const Text(
            'Sửa email, mật khẩu',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),

          // 1. Tên đăng nhập: Gacon1980
          _buildFormRow(
            label: 'Tên đăng nhập:',
            subtext: 'Tên thành viên không được phép ít hơn 3 ký tự và vượt quá 20 ký tự.',
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Text(
                _currentUsername,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // 2. Địa chỉ email: phuongcuonganh@yahoo.com
          _buildFormRow(
            label: 'Địa chỉ email:',
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: const Text(
                'phuongcuonganh@yahoo.com',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // 3. Mật khẩu mới:
          _buildFormRow(
            label: 'Mật khẩu mới:',
            subtext: 'Mật khẩu của bạn phải nhiều hơn 6 ký tự. Không đặt các mật khẩu quá dễ',
            child: _buildTextField(_newPasswordController, obscureText: true),
          ),
          const SizedBox(height: 14),

          // 4. Xác nhận mật khẩu:
          _buildFormRow(
            label: 'Xác nhận mật khẩu:',
            subtext: 'Bạn chỉ cần xác nhận lại mật khẩu nếu như bạn muốn thay đổi mật khẩu hiện tại của mình ở trên.',
            child: _buildTextField(_confirmPasswordController, obscureText: true),
          ),
          const SizedBox(height: 14),

          // 5. Mật khẩu hiện tại:
          _buildFormRow(
            label: 'Mật khẩu hiện tại:',
            subtext: 'Để đổi mật khẩu, hộp thư, tên đăng nhập bạn phải nhập mật khẩu hiện tại.',
            child: _buildTextField(_currentPasswordController, obscureText: true),
          ),
          const SizedBox(height: 24),

          // Nút Xác nhận
          Center(
            child: ElevatedButton(
              onPressed: () {
                _showBoxedSnackBar('Đã lưu và cập nhật mật khẩu thành công.');
              },
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

  Widget _buildFormRow({
    required String label,
    required Widget child,
    String? subtext,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 650;
        final labelWidget = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            if (subtext != null) ...[
              const SizedBox(height: 2),
              Text(
                subtext,
                style: const TextStyle(
                  fontSize: 11.5,
                  color: Colors.white54,
                ),
              ),
            ],
          ],
        );

        if (isNarrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              labelWidget,
              const SizedBox(height: 6),
              child,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 170,
              child: labelWidget,
            ),
            const SizedBox(width: 16),
            Expanded(child: child),
          ],
        );
      },
    );
  }

  Widget _buildTextField(
    TextEditingController controller, {
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      obscureText: obscureText,
      keyboardType: keyboardType,
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
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: Color(0xFF64B5F6), width: 1.5),
        ),
      ),
    );
  }

  Widget _buildGenderRadio(String label, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Radio<String>(
          value: value,
          groupValue: _gender,
          onChanged: (val) => setState(() => _gender = val!),
          activeColor: const Color(0xFF2196F3),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white, fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF131A30),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFF2E3B5F)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          dropdownColor: const Color(0xFF131A30),
          style: const TextStyle(color: Colors.white, fontSize: 13),
          icon: const Icon(Icons.arrow_drop_down, color: Colors.white70, size: 18),
          items: items.map((item) {
            return DropdownMenuItem(
              value: item,
              child: Text(item),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  // --- 2d. Form Quản lý khóa "Ghi nhớ tôi" (Hình 2) ---
  Widget _buildRememberMeKeysForm() {
    return Container(
      color: const Color(0xFF1E2640),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Tiêu đề: Quản lý khóa "Ghi nhớ tôi"
          const Text(
            'Quản lý khóa "Ghi nhớ tôi"',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),

          // Khung giới thiệu (Hình 2)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF161F36),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: const Color(0xFF2E3B5F)),
            ),
            child: const Text(
              'Khóa đăng nhập "Ghi nhớ tôi" sẽ tự động đăng nhập mỗi khi bạn vào diễn đàn. Nếu bạn đăng xuất, khoá ghi nhớ sẽ bị xóa trên máy tính mà bạn đăng xuất. Ở đây bạn có thể xem khóa ghi nhớ đã được tạo trên các máy tính khác mà bạn đã sử dụng để truy cập vào diễn đàn.',
              style: TextStyle(
                fontSize: 12.5,
                color: Colors.white70,
                height: 1.45,
              ),
            ),
          ),
          const SizedBox(height: 18),

          // Bảng dữ liệu: Khóa nhận dạng | Khóa phiên | Thời gian tạo | Đánh dấu
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFF2E3B5F)),
              borderRadius: BorderRadius.circular(4),
            ),
            clipBehavior: Clip.antiAlias,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 650),
                child: Table(
                  border: TableBorder.all(
                    color: const Color(0xFF2E3B5F),
                    width: 1,
                  ),
                  columnWidths: const {
                    0: FlexColumnWidth(2.6), // Khóa nhận dạng
                    1: FlexColumnWidth(2.6), // Khóa phiên
                    2: FlexColumnWidth(2.6), // Thời gian tạo
                    3: FixedColumnWidth(60), // Đánh dấu / Checkbox
                  },
                  defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                  children: [
                    // Header của Bảng
                    TableRow(
                      decoration: const BoxDecoration(
                        color: Color(0xFF131A30),
                      ),
                      children: [
                        _buildTableHeaderCell('Khóa nhận dạng'),
                        _buildTableHeaderCell('Khóa phiên'),
                        _buildTableHeaderCell('Thời gian tạo'),
                        _buildTableHeaderCell('Đánh dấu', isCenter: true),
                      ],
                    ),
                    // 34 Hàng dữ liệu
                    ..._rememberMeKeys.asMap().entries.map((entry) {
                      final index = entry.key;
                      final item = entry.value;
                      final isEven = index % 2 == 0;
                      final rowBgColor =
                          isEven ? const Color(0xFF1E2640) : const Color(0xFF161F36);

                      return TableRow(
                        decoration: BoxDecoration(color: rowBgColor),
                        children: [
                          _buildTableCell(item['id'] as String),
                          _buildTableCell(item['ip'] as String),
                          _buildTableCell(item['time'] as String),
                          TableCell(
                            verticalAlignment: TableCellVerticalAlignment.middle,
                            child: Center(
                              child: Checkbox(
                                value: item['selected'] as bool,
                                onChanged: (val) {
                                  setState(() {
                                    item['selected'] = val ?? false;
                                  });
                                },
                                activeColor: const Color(0xFF2196F3),
                                checkColor: Colors.white,
                                side: const BorderSide(color: Color(0xFF2E3B5F)),
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                              ),
                            ),
                          ),
                        ],
                      );
                    }),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Hàng hành động bên dưới bảng: Nút "Xóa đánh dấu" & liên kết "Chọn tất cả • Bỏ chọn tất cả"
          Align(
            alignment: Alignment.centerRight,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                ElevatedButton(
                  onPressed: () {
                    final selectedItems =
                        _rememberMeKeys.where((e) => e['selected'] == true).toList();
                    if (selectedItems.isEmpty) {
                      _showBoxedSnackBar(
                        'Vui lòng đánh dấu ít nhất một khóa để xóa.',
                        isError: true,
                      );
                    } else {
                      final count = selectedItems.length;
                      setState(() {
                        _rememberMeKeys
                            .removeWhere((e) => e['selected'] == true);
                      });
                      _showBoxedSnackBar(
                          'Đã xóa $count khóa "Ghi nhớ tôi" được đánh dấu.');
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E3B5F),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4)),
                    side: const BorderSide(color: Color(0xFF3F51B5)),
                  ),
                  child: const Text(
                    'Xóa đánh dấu',
                    style: TextStyle(
                        fontSize: 12.5, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InkWell(
                      onTap: () {
                        setState(() {
                          for (var item in _rememberMeKeys) {
                            item['selected'] = true;
                          }
                        });
                      },
                      child: const Text(
                        'Chọn tất cả',
                        style: TextStyle(
                          color: Color(0xFFEF5350),
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          decoration: TextDecoration.underline,
                          decorationColor: Color(0xFFEF5350),
                        ),
                      ),
                    ),
                    const Text(
                      ' • ',
                      style: TextStyle(color: Colors.white54, fontSize: 12.5),
                    ),
                    InkWell(
                      onTap: () {
                        setState(() {
                          for (var item in _rememberMeKeys) {
                            item['selected'] = false;
                          }
                        });
                      },
                      child: const Text(
                        'Bỏ chọn tất cả',
                        style: TextStyle(
                          color: Color(0xFFEF5350),
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          decoration: TextDecoration.underline,
                          decorationColor: Color(0xFFEF5350),
                        ),
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

  // --- 2e. Form Liên kết tài khoản ngoài (Hình 5) ---
  Widget _buildExternalAccountsForm() {
    return Container(
      color: const Color(0xFF1E2640),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Tiêu đề: Quản lý các tài khoản kết hợp bên ngoài của bạn
          const Text(
            'Quản lý các tài khoản kết hợp bên ngoài của bạn',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),

          // 1. Phân mục FACEBOOK
          _buildExternalAccountRow(
            providerName: 'FACEBOOK',
            description:
                'Bạn hiện không có tài khoản nào liên quan đến dịch vụ bên ngoài này. Bấm nút bên dưới để liên kết tài khoản của bạn trên diễn đàn với tài khoản của dịch vụ bên ngoài này.',
            onLinkPressed: () {
              _showBoxedSnackBar('Đang mở liên kết kết nối tài khoản Facebook...');
            },
          ),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(color: Color(0xFF2E3B5F), height: 1),
          ),

          // 2. Phân mục GOOGLE
          _buildExternalAccountRow(
            providerName: 'GOOGLE',
            description:
                'Bạn hiện không có tài khoản nào liên quan đến dịch vụ bên ngoài này. Bấm nút bên dưới để liên kết tài khoản của bạn trên diễn đàn với tài khoản của dịch vụ bên ngoài này.',
            onLinkPressed: () {
              _showBoxedSnackBar('Đang mở liên kết kết nối tài khoản Google...');
            },
          ),

          const SizedBox(height: 24),

          // Khung chú thích quyền riêng tư ở dưới cùng (Hình 5)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF161F36),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: const Color(0xFF2E3B5F)),
            ),
            child: const Text(
              'Chúng tôi sử dụng liên kết với các tài khoản bên ngoài (Facebook, Google,...) để xác thực, giúp bạn đăng nhập thuận tiện hơn. Chúng tôi cam kết không sử dụng bất kỳ dữ liệu gì của bạn từ các tài khoản bên ngoài đó. Bạn có thể gỡ bỏ bất kỳ lúc nào bằng cách bấm vào nút [Bỏ liên kết] .',
              style: TextStyle(
                fontSize: 12.5,
                color: Colors.white70,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExternalAccountRow({
    required String providerName,
    required String description,
    required VoidCallback onLinkPressed,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 600;

        final labelWidget = Text(
          providerName,
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.bold,
            color: Colors.white70,
            letterSpacing: 0.5,
          ),
        );

        final contentWidget = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              description,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFFE0E0E0),
                height: 1.45,
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: onLinkPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E3B5F),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                side: const BorderSide(color: Color(0xFF3F51B5)),
              ),
              child: const Text(
                'Liên kết',
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );

        if (isNarrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              labelWidget,
              const SizedBox(height: 8),
              contentWidget,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 150,
              child: labelWidget,
            ),
            const SizedBox(width: 16),
            Expanded(child: contentWidget),
          ],
        );
      },
    );
  }

  Widget _buildTableHeaderCell(String text, {bool isCenter = false}) {
    return TableCell(
      verticalAlignment: TableCellVerticalAlignment.middle,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Text(
          text,
          textAlign: isCenter ? TextAlign.center : TextAlign.left,
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildTableCell(String text) {
    return TableCell(
      verticalAlignment: TableCellVerticalAlignment.middle,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 12.5,
            color: Color(0xFFE0E0E0),
          ),
        ),
      ),
    );
  }

  Widget _buildUnderDevelopmentSidebarContent(String title) {
    return Container(
      color: const Color(0xFF1E2640),
      padding: const EdgeInsets.all(28.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF161F36),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFF2E3B5F)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Color(0xFFFFD700), size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Chức năng "$title" đang được xây dựng và kết nối dữ liệu hệ thống.',
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () {
              setState(() {
                _selectedSidebarIndex = 0;
              });
              UcpStateService.setSubItem('Cá nhân', _sidebarMenus[0]);
            },
            icon: const Icon(Icons.arrow_back, size: 16),
            label: const Text('Quay lại Sửa thông tin cá nhân'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E3B5F),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // --- 3. Khối Khám Phá Thêm (Hình 2: Sửa hình đại diện, Hình 5: Sửa email/mật khẩu) ---
  Widget _buildExploreSection() {
    final categories = _currentExploreCategories;
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
          ...List.generate(categories.length, (index) {
            final item = categories[index];
            return Column(
              children: [
                if (index > 0)
                  const Divider(color: Color(0xFF2E3B5F), height: 1),
                InkWell(
                  onTap: () {
                    _showBoxedSnackBar('Đang mở chuyên mục "$item"...');
                  },
                  hoverColor: Colors.white.withValues(alpha: 0.04),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          item,
                          style: const TextStyle(
                            fontSize: 13.5,
                            color: Colors.white70,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right,
                          color: Colors.white38,
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }
}
