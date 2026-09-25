import 'package:flutter/material.dart';
import 'ucp_screen.dart';

/// Màn hình Quản lý các thông báo (UCP Notifications Screen) độc lập
class UcpNotificationsScreen extends StatelessWidget {
  const UcpNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const UcpScreen(initialSidebarIndex: 5);
  }
}

/// Widget nội dung Quản lý các thông báo được nhúng trực tiếp vào cột phải của UcpScreen
class UcpNotificationsContent extends StatelessWidget {
  const UcpNotificationsContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1E2640),
      padding: const EdgeInsets.all(18.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Tiêu đề Quản lý các thông báo
          const Text(
            'Quản lý các thông báo',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),

          // 2. Khung thông báo hướng dẫn và trạng thái (Bảo toàn nguyên văn từ Hình 2)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14.0),
            decoration: BoxDecoration(
              color: const Color(0xFF131A30),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFF2E3B5F)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ở đây bạn có thể xem tất cả các thông báo đã qua.',
                  style: TextStyle(
                    fontSize: 13.5,
                    color: Colors.grey[300],
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Bạn không có thông báo',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[200],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
