import 'package:flutter/material.dart';

class MobileBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const MobileBottomNavBar({
    Key? key,
    required this.currentIndex,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: currentIndex,
      onTap: onTap,
      selectedItemColor: Colors.red.shade900,
      unselectedItemColor: Colors.grey,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Trang chủ',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.apps),
          label: 'Ứng dụng',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.forum),
          label: 'Diễn đàn',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Cá nhân',
        ),
      ],
    );
  }
}
