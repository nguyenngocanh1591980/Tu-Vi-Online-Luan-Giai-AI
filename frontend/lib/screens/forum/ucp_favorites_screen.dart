import 'package:flutter/material.dart';
import 'ucp_screen.dart';

/// Màn hình Trang yêu thích (UCP Favorites Screen) độc lập
class UcpFavoritesScreen extends StatelessWidget {
  const UcpFavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const UcpScreen(initialSidebarIndex: 2);
  }
}

/// Widget nội dung Trang yêu thích được nhúng trực tiếp vào cột phải của UcpScreen
class UcpFavoritesContent extends StatelessWidget {
  const UcpFavoritesContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1E2640),
      padding: const EdgeInsets.all(18.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Tiêu đề Trang yêu thích
          const Text(
            'Trang yêu thích',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),

          // 2. Khung ghi chú hướng dẫn (Bảo toàn nguyên văn từ Hình 5)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14.0),
            decoration: BoxDecoration(
              color: const Color(0xFF161F36),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFF2E3B5F)),
            ),
            child: RichText(
              text: TextSpan(
                style: TextStyle(
                  fontSize: 13.5,
                  color: Colors.grey[300],
                  height: 1.5,
                ),
                children: const [
                  TextSpan(
                    text:
                        'Bạn có thể đánh dấu những chủ đề mình yêu thích trong trang này để dễ dàng xem lại sau này. Đánh dấu chọn vào ô kiểm trong bất cứ trang đánh dấu nào mà bạn muốn xóa rồi bấm vào nút ',
                  ),
                  TextSpan(
                    text: 'Gỡ bỏ những trang yêu thích đã đánh dấu',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  TextSpan(text: '.'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // 3. Dòng thông báo trạng thái rỗng
          Text(
            'Bạn không có trang yêu thích nào.',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey[200],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
