import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../providers/wallet_provider.dart';

class MainNavigationBar extends StatelessWidget implements PreferredSizeWidget {
  const MainNavigationBar({Key? key}) : super(key: key);

  @override
  Size get preferredSize => const Size.fromHeight(60.0);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade300, width: 1),
        ),
      ),
      child: Row(
        children: [
          // Left Side Menu
          Container(
            color: Colors.grey.shade200,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            alignment: Alignment.center,
            child: Text(
              'Trang chủ',
              style: TextStyle(
                color: Colors.red.shade900,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 20),
          PopupMenuButton<String>(
            tooltip: '',
            offset: const Offset(0, 50),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                children: [
                  Text(
                    'Ứng dụng',
                    style: TextStyle(
                      color: Colors.red.shade900,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.arrow_drop_down, color: Colors.red.shade900, size: 20),
                ],
              ),
            ),
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              PopupMenuItem<String>(
                value: 'lich_van_su',
                child: Text('Lịch vạn sự', style: TextStyle(color: Colors.red.shade900, fontWeight: FontWeight.bold)),
              ),
              PopupMenuItem<String>(
                value: 'la_so_tu_vi',
                child: Text('Lá số Tử vi', style: TextStyle(color: Colors.red.shade900, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(width: 20),
          _buildDropdownItem('Diễn đàn'),
          const SizedBox(width: 20),
          _buildMenuItem('Thư viện'),
          const SizedBox(width: 20),
          _buildMenuItem('Liên hệ'),
          const Spacer(), // Pushes icons to the right
          
          // Right Side Icons
          IconButton(
            icon: Icon(Icons.flash_on, color: Colors.red.shade900),
            onPressed: () {},
          ),
          IconButton(
            icon: Icon(Icons.notifications_none, color: Colors.red.shade900),
            onPressed: () {},
          ),
          IconButton(
            icon: Icon(Icons.mail_outline, color: Colors.red.shade900),
            onPressed: () {},
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.person_outline, color: Colors.red.shade900),
            offset: const Offset(0, 50),
            onSelected: (String result) async {
              if (result == 'logout') {
                final authService = AuthService();
                await authService.logout();
                Provider.of<WalletProvider>(context, listen: false).clear();
                Navigator.of(context).pushReplacementNamed('/login');
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              PopupMenuItem<String>(
                value: 'header',
                enabled: false,
                child: Text('Gacon1980', style: TextStyle(color: Colors.red.shade900, fontSize: 16)),
              ),
              const PopupMenuDivider(),
              PopupMenuItem<String>(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.tune, color: Colors.red.shade900, size: 20),
                    const SizedBox(width: 8),
                    const Text('Thiết lập cá nhân', style: TextStyle(color: Colors.black87)),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem<String>(
                value: 'profile',
                child: Row(
                  children: [
                    Icon(Icons.person, color: Colors.red.shade900, size: 20),
                    const SizedBox(width: 8),
                    const Text('Xem thông tin cá nhân', style: TextStyle(color: Colors.black87)),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem<String>(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.power_settings_new, color: Colors.red.shade900, size: 20),
                    const SizedBox(width: 8),
                    const Text('Thoát', style: TextStyle(color: Colors.black87)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
        ],
      ),
    );
  }

  Widget _buildMenuItem(String title) {
    return InkWell(
      onTap: () {},
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Text(
          title,
          style: TextStyle(
            color: Colors.red.shade900,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownItem(String title) {
    return InkWell(
      onTap: () {},
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Text(
              title,
              style: TextStyle(
                color: Colors.red.shade900,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.arrow_drop_down, color: Colors.red.shade900, size: 20),
          ],
        ),
      ),
    );
  }
}
