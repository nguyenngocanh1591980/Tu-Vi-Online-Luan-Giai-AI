import 'package:flutter/material.dart';
import 'ucp_screen.dart';

/// Màn hình Tập tin đính kèm (UCP Attachments Screen) độc lập
class UcpAttachmentsScreen extends StatelessWidget {
  const UcpAttachmentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const UcpScreen(initialSidebarIndex: 4);
  }
}

/// Widget nội dung Tập tin đính kèm được nhúng trực tiếp vào cột phải của UcpScreen
class UcpAttachmentsContent extends StatelessWidget {
  const UcpAttachmentsContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1E2640),
      padding: const EdgeInsets.all(18.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Tiêu đề Tập tin đính kèm của bạn (Bảo toàn nguyên văn từ Hình 5)
          const Text(
            'Tập tin đính kèm của bạn',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),

          // 2. Khung thông báo hướng dẫn và trạng thái (Bảo toàn nguyên văn từ Hình 5)
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
                  'Đây là danh sách tất cả các tập tin đính kèm mà bạn đã gửi trong diễn đàn.',
                  style: TextStyle(
                    fontSize: 13.5,
                    color: Colors.grey[300],
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Bạn chưa tải lên bất kì tập tin nào.',
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
