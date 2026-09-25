import 'package:flutter/material.dart';
import 'ucp_screen.dart';

/// Màn hình Bản nháp đã lưu (UCP Drafts Screen) độc lập
class UcpDraftsScreen extends StatelessWidget {
  const UcpDraftsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const UcpScreen(initialSidebarIndex: 3);
  }
}

/// Widget nội dung Bản nháp đã lưu được nhúng trực tiếp vào cột phải của UcpScreen
class UcpDraftsContent extends StatelessWidget {
  const UcpDraftsContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1E2640),
      padding: const EdgeInsets.all(18.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Tiêu đề Bản nháp đã lưu
          const Text(
            'Bản nháp đã lưu',
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
              color: const Color(0xFF161F36),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFF2E3B5F)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Với bảng điều khiển này, bạn có thể xem, sửa và xóa những bản nháp đã lưu của mình.',
                  style: TextStyle(
                    fontSize: 13.5,
                    color: Colors.grey[300],
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Không có bản nháp nào được lưu.',
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
