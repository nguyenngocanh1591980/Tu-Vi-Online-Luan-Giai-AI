import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class BreadcrumbWidget extends StatelessWidget {
  const BreadcrumbWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Lấy uri hiện tại từ go_router
    final uri = GoRouterState.of(context).uri;
    final path = uri.path;

    // Phân tích và gán chuỗi breadcrumb dựa trên path
    List<Widget> breadcrumbs = [
      const Icon(Icons.home, color: Color(0xFF8B0000), size: 18),
      const SizedBox(width: 4),
      _buildCrumbText('Trang chủ', onTap: () => context.go('/')),
    ];

    if (path == '/almanac') {
      breadcrumbs.addAll([
        _buildDivider(),
        _buildCrumbText('Ứng dụng'),
        _buildDivider(),
        _buildCrumbText('Lịch vạn sự'),
      ]);
    } else if (path == '/horoscope') {
      breadcrumbs.addAll([
        _buildDivider(),
        _buildCrumbText('Ứng dụng'),
        _buildDivider(),
        _buildCrumbText('Lá số Tử vi'),
      ]);
    } else if (path == '/forum') {
      breadcrumbs.addAll([
        _buildDivider(),
        _buildCrumbText('Diễn đàn'),
      ]);
    } else if (path == '/login') {
      breadcrumbs.addAll([
        _buildDivider(),
        _buildCrumbText('Thành viên'),
        _buildDivider(),
        _buildCrumbText('Đăng nhập'),
      ]);
    } else if (path == '/verify') {
      breadcrumbs.addAll([
        _buildDivider(),
        _buildCrumbText('Xác thực Email'),
      ]);
    } else if (path == '/shared') {
      breadcrumbs.addAll([
        _buildDivider(),
        _buildCrumbText('Lá số chia sẻ'),
      ]);
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xFFF9F9F9),
        border: Border(
          bottom: BorderSide(color: Color(0xFFE0E0E0), width: 1),
        ),
      ),
      child: Row(
        children: breadcrumbs,
      ),
    );
  }

  Widget _buildDivider() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 6),
      child: Icon(Icons.keyboard_arrow_left, color: Color(0xFF8B0000), size: 16, textDirection: TextDirection.rtl),
    );
  }

  Widget _buildCrumbText(String text, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF8B0000),
          fontWeight: FontWeight.bold,
          fontSize: 15,
        ),
      ),
    );
  }
}
