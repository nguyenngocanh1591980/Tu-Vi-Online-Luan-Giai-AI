import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import '../providers/wallet_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/forum_stats_provider.dart';

class MainNavigationBar extends StatefulWidget {
  const MainNavigationBar({super.key});

  @override
  State<MainNavigationBar> createState() => _MainNavigationBarState();
}

class _MainNavigationBarState extends State<MainNavigationBar> {
  bool _isLoggedIn = false;
  String _username = '';
  bool _isAppMenuOpen = false;
  bool _isForumMenuOpen = false;
  bool _isPushNotificationEnabled = false;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Lắng nghe sự thay đổi của route để cập nhật lại Header (ví dụ: sau khi login xong gọi context.go)
    GoRouterState.of(context);
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    final username = prefs.getString('username') ?? '';
    
    if (mounted) {
      setState(() {
        _isLoggedIn = token != null && token.isNotEmpty;
        _username = username;
      });
    }
  }

  void _onLogout() async {
    final authService = AuthService();
    await authService.logout();
    if (!mounted) return;
    context.read<AuthProvider>().logout();
    context.read<ForumStatsProvider>().notifyUserLogout();
    Provider.of<WalletProvider>(context, listen: false).clear();
    setState(() {
      _isLoggedIn = false;
      _username = '';
    });
    context.go('/login');
  }

  Widget _buildHeaderTooltip({
    required String message,
    required Widget child,
  }) {
    return Tooltip(
      message: message,
      verticalOffset: 20,
      preferBelow: true,
      waitDuration: const Duration(milliseconds: 150),
      showDuration: const Duration(milliseconds: 1500),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF00BFFF), // Xanh da trời (Light Blue / DeepSkyBlue)
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      textStyle: const TextStyle(
        color: Colors.white,
        fontSize: 12.5,
        fontWeight: FontWeight.bold,
      ),
      child: child,
    );
  }

  Widget _navItem(String title, {bool isActive = false, Color? textColor, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Text(
          title,
          style: TextStyle(
            color: textColor ?? (isActive ? const Color(0xFFD4AF37) : Colors.white70),
            fontWeight: (isActive || textColor != null) ? FontWeight.bold : FontWeight.w500,
            fontSize: 15,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final isLoggedIn = authProvider.isLoggedIn || _isLoggedIn;
    final currentUsername = authProvider.username.isNotEmpty ? authProvider.username : _username;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFF0B1021),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
              // Logo & Brand
              InkWell(
                onTap: () => context.go('/'),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.camera, color: Color(0xFF00E5FF), size: 28),
                    const SizedBox(width: 8),
                    const Text(
                      'Diễn đàn Tử Vi Online - AI',
                      style: TextStyle(
                        color: Color(0xFFD4AF37),
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                        shadows: [
                          Shadow(color: Color(0xFFD4AF37), blurRadius: 4),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Navigation Menu & Actions
              Flexible(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _navItem('Trang chủ', isActive: true, onTap: () => context.go('/')),
                      
                      // Menu Ứng dụng
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          InkWell(
                            onTap: () => context.go('/apps'),
                            child: Padding(
                              padding: const EdgeInsets.only(left: 10, right: 3, top: 8, bottom: 8),
                              child: Text(
                                'Ứng dụng',
                                style: TextStyle(
                                  color: _isAppMenuOpen ? const Color(0xFF00E5FF) : const Color(0xFFD4AF37),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  shadows: _isAppMenuOpen ? const [Shadow(color: Color(0xFF00E5FF), blurRadius: 8)] : null,
                                ),
                              ),
                            ),
                          ),
                          Theme(
                            data: Theme.of(context).copyWith(
                              splashColor: Colors.transparent,
                              highlightColor: Colors.transparent,
                            ),
                            child: PopupMenuButton<String>(
                              offset: const Offset(0, 40),
                              color: const Color(0xFF131A30),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                              tooltip: 'Ứng dụng',
                              onOpened: () => setState(() => _isAppMenuOpen = true),
                              onCanceled: () => setState(() => _isAppMenuOpen = false),
                              onSelected: (String result) {
                                setState(() => _isAppMenuOpen = false);
                                String target = '';
                                if (result == 'horoscope') {
                                  target = '/horoscope';
                                } else if (result == 'almanac') {
                                  target = '/almanac';
                                }
                                if (target.isNotEmpty) {
                                  context.go(target);
                                }
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem(value: 'almanac', child: Text('Lịch Vạn Sự', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15))),
                                const PopupMenuItem(value: 'horoscope', child: Text('Lá số Tử vi', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15))),
                                const PopupMenuItem(value: 'almanac', child: Text('Đổi Lịch Âm Dương', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15))),
                              ],
                              child: Padding(
                                padding: const EdgeInsets.only(right: 10, top: 8, bottom: 8),
                                child: Text(
                                  '▼',
                                  style: TextStyle(
                                    color: _isAppMenuOpen ? const Color(0xFF00E5FF) : const Color(0xFFD4AF37),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    shadows: _isAppMenuOpen ? const [Shadow(color: Color(0xFF00E5FF), blurRadius: 8)] : null,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      // Menu Diễn đàn
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          InkWell(
                            onTap: () {
                              context.go('/forum');
                            },
                            child: Padding(
                              padding: const EdgeInsets.only(left: 10, right: 3, top: 8, bottom: 8),
                              child: Text(
                                'Diễn đàn',
                                style: TextStyle(
                                  color: _isForumMenuOpen ? const Color(0xFF00E5FF) : const Color(0xFFD4AF37),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  shadows: _isForumMenuOpen ? const [Shadow(color: Color(0xFF00E5FF), blurRadius: 8)] : null,
                                ),
                              ),
                            ),
                          ),
                          Theme(
                            data: Theme.of(context).copyWith(
                              splashColor: Colors.transparent,
                              highlightColor: Colors.transparent,
                            ),
                            child: PopupMenuButton<String>(
                              offset: const Offset(0, 40),
                              color: const Color(0xFF131A30),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                              tooltip: 'Danh mục diễn đàn',
                              onOpened: () => setState(() => _isForumMenuOpen = true),
                              onCanceled: () => setState(() => _isForumMenuOpen = false),
                              onSelected: (String result) {
                                setState(() => _isForumMenuOpen = false);
                                String target = '';
                                if (result == 'bai_viet_moi') {
                                  target = '/forum/new-posts';
                                } else if (result == 'bai_chua_xem') {
                                  target = '/forum/unread-posts';
                                } else if (result == 'bai_cua_ban') {
                                  target = '/forum/your-posts';
                                } else if (result == 'bai_chua_tra_loi') {
                                  target = '/forum/unanswered-posts';
                                } else if (result == 'tim_kiem') {
                                  target = '/forum/search';
                                }
                                
                                if (!_isLoggedIn && target.isNotEmpty) {
                                  context.go('/login?redirect=$target');
                                } else if (target.isNotEmpty) {
                                  context.go(target);
                                }
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem(value: 'bai_viet_moi', child: Text('Bài viết mới', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15))),
                                const PopupMenuItem(value: 'bai_chua_xem', child: Text('Bài chưa xem', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15))),
                                const PopupMenuItem(value: 'bai_cua_ban', child: Text('Bài của bạn', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15))),
                                const PopupMenuItem(value: 'bai_chua_tra_loi', child: Text('Bài chưa được trả lời', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15))),
                                PopupMenuItem(value: 'tim_kiem', child: Row(
                                  children: const [
                                    Icon(Icons.search, color: Colors.white, size: 18),
                                    SizedBox(width: 6),
                                    Text('Tìm kiếm', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                                  ],
                                )),
                              ],
                              child: Padding(
                                padding: const EdgeInsets.only(right: 10, top: 8, bottom: 8),
                                child: Text(
                                  '▼',
                                  style: TextStyle(
                                    color: _isForumMenuOpen ? const Color(0xFF00E5FF) : const Color(0xFFD4AF37),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    shadows: _isForumMenuOpen ? const [Shadow(color: Color(0xFF00E5FF), blurRadius: 8)] : null,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      _navItem('Thư viện'),
                      _navItem(
                        'Liên hệ',
                        textColor: const Color(0xFFD4AF37),
                        onTap: () => context.go('/contact'),
                      ),
                      const SizedBox(width: 14),

                      // User Auth Section
                      if (isLoggedIn) ...[
                        _buildHeaderTooltip(
                          message: 'Bài viết mới',
                          child: InkWell(
                            onTap: () => context.go('/forum/new-posts'),
                            child: const Icon(Icons.flash_on, color: Color(0xFFD4AF37), size: 22),
                          ),
                        ),
                        const SizedBox(width: 14),
                        MenuAnchor(
                          style: const MenuStyle(
                            backgroundColor: WidgetStatePropertyAll(Colors.transparent),
                            elevation: WidgetStatePropertyAll(0),
                            padding: WidgetStatePropertyAll(EdgeInsets.zero),
                          ),
                          builder: (BuildContext context, MenuController controller, Widget? child) {
                            return _buildHeaderTooltip(
                              message: 'Thông báo',
                              child: InkWell(
                                onTap: () {
                                  if (controller.isOpen) {
                                    controller.close();
                                  } else {
                                    controller.open();
                                  }
                                },
                                child: const Icon(Icons.notifications_outlined, color: Colors.white70, size: 22),
                              ),
                            );
                          },
                          menuChildren: [
                            Container(
                              width: 320,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF9F9F9),
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 10,
                                    offset: Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text(
                                          'THÔNG BÁO',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black,
                                          ),
                                        ),
                                        InkWell(
                                          onTap: () {},
                                          child: const Text(
                                            'Thiết lập',
                                            style: TextStyle(
                                              color: Color(0xFF8B0000),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Divider(height: 1, thickness: 1, color: Colors.black12),
                                  const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 32),
                                    child: Text(
                                      'Bạn không có thông báo',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  ),
                                  const Divider(height: 1, thickness: 1, color: Colors.black12),
                                  InkWell(
                                    onTap: () {},
                                    child: const Padding(
                                      padding: EdgeInsets.symmetric(vertical: 12),
                                      child: Center(
                                        child: Text(
                                          'Xem tất cả',
                                          style: TextStyle(color: Color(0xFF8B0000)),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const Divider(height: 1, thickness: 1, color: Colors.black12),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                         const Expanded(
                                           child: Text('Bật thông báo đẩy:', style: TextStyle(color: Colors.black87)),
                                         ),
                                        StatefulBuilder(
                                          builder: (context, setStateSB) {
                                            return Switch(
                                              value: _isPushNotificationEnabled,
                                              onChanged: (val) {
                                                setStateSB(() {
                                                  _isPushNotificationEnabled = val;
                                                });
                                                setState(() {
                                                  _isPushNotificationEnabled = val;
                                                });
                                              },
                                              activeThumbColor: const Color(0xFF8B0000),
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 14),
                        _buildHeaderTooltip(
                          message: 'Tin nhắn',
                          child: InkWell(
                            onTap: () => context.go('/forum/inbox'),
                            child: const Icon(Icons.email_outlined, color: Colors.white70, size: 22),
                          ),
                        ),
                        const SizedBox(width: 14),
                        _buildHeaderTooltip(
                          message: 'Thiết lập cá nhân',
                          child: PopupMenuButton<String>(
                            tooltip: '',
                            offset: const Offset(0, 48),
                            color: const Color(0xFF0B1021).withValues(alpha: 0.95),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: const BorderSide(color: Color(0xFFD4AF37), width: 2),
                            ),
                            onSelected: (val) {
                              if (val == 'logout') {
                                _onLogout();
                              } else if (val == 'profile') {
                                context.go('/forum/ucp');
                              } else if (val == 'view_profile') {
                                context.go('/forum/member/$currentUsername');
                              }
                            },
                            child: const CircleAvatar(
                              backgroundColor: Color(0xFFC62828),
                              radius: 17,
                              child: Icon(Icons.person, size: 19, color: Colors.white),
                            ),
                            itemBuilder: (context) => [
                              PopupMenuItem(enabled: false, child: Text(currentUsername, style: const TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold))),
                              const PopupMenuDivider(),
                              const PopupMenuItem(value: 'profile', child: Text('Thiết lập cá nhân', style: TextStyle(color: Colors.white))),
                              const PopupMenuItem(value: 'view_profile', child: Text('Xem thông tin cá nhân', style: TextStyle(color: Colors.white))),
                              const PopupMenuDivider(),
                              const PopupMenuItem(value: 'logout', child: Row(
                                children: [
                                  Icon(Icons.power_settings_new, color: Color(0xFFD32F2F), size: 20),
                                  SizedBox(width: 8),
                                  Text('Thoát', style: TextStyle(color: Colors.white)),
                                ],
                              )),
                            ],
                          ),
                        ),
                      ] else ...[
                        ElevatedButton(
                          onPressed: () => context.go('/login?tab=login'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF009688),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: const BorderSide(color: Color(0xFFD4AF37), width: 1),
                            ),
                          ),
                          child: const Text('ĐĂNG NHẬP', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () => context.go('/terms'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFC62828),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: const BorderSide(color: Color(0xFFD4AF37), width: 1),
                            ),
                          ),
                          child: const Text('ĐĂNG KÝ', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
    );
  }
}
