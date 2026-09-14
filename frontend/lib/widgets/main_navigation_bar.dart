import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:ui' as ui;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import '../providers/wallet_provider.dart';

class MainNavigationBar extends StatefulWidget {
  const MainNavigationBar({Key? key}) : super(key: key);

  @override
  State<MainNavigationBar> createState() => _MainNavigationBarState();
}

class _MainNavigationBarState extends State<MainNavigationBar> {
  bool _isLoggedIn = false;
  String _username = '';
  bool _isAppMenuOpen = false;
  bool _isForumMenuOpen = false;

  @override
  void initState() {
    super.initState();
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
    Provider.of<WalletProvider>(context, listen: false).clear();
    setState(() {
      _isLoggedIn = false;
      _username = '';
    });
    context.go('/login');
  }

  Widget _navItem(String title, {bool isActive = false, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Text(
          title,
          style: TextStyle(
            color: isActive ? const Color(0xFFD4AF37) : Colors.white70,
            fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
        child: Container(
          color: const Color(0xFF0B1021).withOpacity(0.95), // Solid for web compatibility
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Logo & Brand
              InkWell(
                onTap: () => context.go('/'),
                child: Row(
                  children: [
                    const Icon(Icons.camera, color: Color(0xFF00E5FF), size: 32),
                    const SizedBox(width: 12),
                    const Text(
                      'Diễn Đàn Tử Vi Online-AI',
                      style: TextStyle(
                        color: Color(0xFFD4AF37),
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                        shadows: [
                          Shadow(color: Color(0xFFD4AF37), blurRadius: 4),
                        ]
                      ),
                    ),
                  ],
                ),
              ),

              // Navigation Menu
              Row(
                children: [
                  _navItem('Trang chủ', isActive: true, onTap: () => context.go('/')),
                  
                  // Menu Ứng dụng
                  Theme(
                    data: Theme.of(context).copyWith(
                      splashColor: Colors.transparent,
                      highlightColor: Colors.transparent,
                    ),
                    child: PopupMenuButton<String>(
                      offset: const Offset(0, 40),
                      color: const Color(0xFFF5F5F5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                      tooltip: 'Ứng dụng',
                      onOpened: () => setState(() => _isAppMenuOpen = true),
                      onCanceled: () => setState(() => _isAppMenuOpen = false),
                      onSelected: (String result) {
                        setState(() => _isAppMenuOpen = false);
                        if (result == 'horoscope') context.go('/horoscope');
                        else if (result == 'almanac') context.go('/almanac');
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(value: 'almanac', child: Text('Lịch Vạn Sự', style: TextStyle(color: Color(0xFF8B0000), fontWeight: FontWeight.bold, fontSize: 16))),
                        const PopupMenuItem(value: 'horoscope', child: Text('Lá số Tử vi', style: TextStyle(color: Color(0xFF8B0000), fontWeight: FontWeight.bold, fontSize: 16))),
                        const PopupMenuItem(value: 'almanac', child: Text('Đổi Lịch Âm Dương', style: TextStyle(color: Color(0xFF8B0000), fontWeight: FontWeight.bold, fontSize: 16))),
                      ],
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'Ứng dụng ▼',
                          style: TextStyle(
                            color: _isAppMenuOpen ? const Color(0xFF00E5FF) : const Color(0xFFD4AF37),
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            shadows: _isAppMenuOpen ? const [Shadow(color: Color(0xFF00E5FF), blurRadius: 8)] : null,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Menu Diễn đàn
                  Theme(
                    data: Theme.of(context).copyWith(
                      splashColor: Colors.transparent,
                      highlightColor: Colors.transparent,
                    ),
                    child: PopupMenuButton<String>(
                      offset: const Offset(0, 40),
                      color: const Color(0xFFF5F5F5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                      tooltip: 'Diễn đàn',
                      onOpened: () => setState(() => _isForumMenuOpen = true),
                      onCanceled: () => setState(() => _isForumMenuOpen = false),
                      onSelected: (String result) {
                        setState(() => _isForumMenuOpen = false);
                        if (result == 'bai_viet_moi' || result == 'bai_chua_xem') {
                          context.go('/forum');
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(value: 'bai_viet_moi', child: Text('Bài viết mới', style: TextStyle(color: Color(0xFF8B0000), fontWeight: FontWeight.bold, fontSize: 16))),
                        const PopupMenuItem(value: 'bai_chua_xem', child: Text('Bài chưa xem', style: TextStyle(color: Color(0xFF8B0000), fontWeight: FontWeight.bold, fontSize: 16))),
                        PopupMenuItem(value: 'tim_kiem', child: Row(
                          children: const [
                            Icon(Icons.search, color: Color(0xFF8B0000), size: 20),
                            SizedBox(width: 8),
                            Text('Tìm kiếm', style: TextStyle(color: Color(0xFF8B0000), fontWeight: FontWeight.bold, fontSize: 16)),
                          ],
                        )),
                      ],
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'Diễn đàn ▼',
                          style: TextStyle(
                            color: _isForumMenuOpen ? const Color(0xFF00E5FF) : Colors.white70,
                            fontWeight: _isForumMenuOpen ? FontWeight.bold : FontWeight.w500,
                            fontSize: 16,
                            shadows: _isForumMenuOpen ? const [Shadow(color: Color(0xFF00E5FF), blurRadius: 8)] : null,
                          ),
                        ),
                      ),
                    ),
                  ),

                  _navItem('Thư viện'),
                  _navItem('Liên hệ'),
                  const SizedBox(width: 24),

                  // User Auth Section
                  if (_isLoggedIn) ...[
                    const Icon(Icons.flash_on, color: Color(0xFFD4AF37), size: 24),
                    const SizedBox(width: 16),
                    const Icon(Icons.notifications_outlined, color: Colors.white70, size: 24),
                    const SizedBox(width: 16),
                    const Icon(Icons.email_outlined, color: Colors.white70, size: 24),
                    const SizedBox(width: 16),
                    PopupMenuButton<String>(
                      offset: const Offset(0, 48),
                      color: const Color(0xFF0B1021).withOpacity(0.95),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: const BorderSide(color: Color(0xFFD4AF37), width: 2),
                      ),
                      onSelected: (val) {
                        if (val == 'logout') _onLogout();
                      },
                      child: const CircleAvatar(
                        backgroundColor: Color(0xFFC62828),
                        radius: 18,
                        child: Icon(Icons.person, size: 20, color: Colors.white),
                      ),
                      itemBuilder: (context) => [
                        PopupMenuItem(enabled: false, child: Text('$_username', style: const TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold))),
                        const PopupMenuDivider(),
                        const PopupMenuItem(value: 'profile', child: Text('Thiết lập cá nhân', style: TextStyle(color: Colors.white))),
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
                  ] else ...[
                    ElevatedButton(
                      onPressed: () => context.go('/login'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF009688),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: const BorderSide(color: Color(0xFFD4AF37), width: 1),
                        ),
                      ),
                      child: const Text('ĐĂNG NHẬP', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () => context.go('/login'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFC62828),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: const BorderSide(color: Color(0xFFD4AF37), width: 1),
                        ),
                      ),
                      child: const Text('ĐĂNG KÝ', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
