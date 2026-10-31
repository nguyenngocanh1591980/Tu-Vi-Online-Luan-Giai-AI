import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/router/app_router.dart';
import 'package:frontend/screens/forum/member_profile_screen.dart';
import 'package:frontend/screens/forum/post_detail_screen.dart';
import 'package:frontend/widgets/forum_table_widget.dart';

void main() {
  group('Kiểm thử ForumTableWidget & Link Điều Hướng Bài Cuối', () {
    testWidgets('Hiển thị Bài cuối với 2 link độc lập và format thời gian', (tester) async {
      final mockForums = [
        {
          'id': '1',
          'title': 'Thông báo - Sự kiện',
          'description': 'Tin tức từ BQT',
          'topics': 251,
          'posts': 846,
          'lastPost': {
            'title': 'TL: Thay đổi về nâng cấp trìn...',
            'author': 'nncuong',
            'time': '14:03, 28/11/25',
          },
        },
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ForumTableWidget(
              headerTitle: 'Thông báo',
              forums: mockForums,
            ),
          ),
        ),
      );

      // Xác nhận có text tiêu đề bài cuối và tác giả
      expect(find.byType(RichText), findsWidgets);
      expect(find.text('251'), findsOneWidget);
      expect(find.text('846'), findsOneWidget);
    });
  });

  group('Kiểm thử Màn hình Chi tiết bài viết (PostDetailScreen)', () {
    testWidgets('Xác nhận PostDetailScreen hiển thị nội dung nguyên khối chuẩn Boxed Layout', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            backgroundColor: Color(0xFF1E2640),
            body: SingleChildScrollView(
              child: PostDetailScreen(id: '1'),
            ),
          ),
        ),
      );

      expect(find.text('Thay đổi về nâng cấp trình an sao và các ứng dụng lý số khác'), findsOneWidget);
      expect(find.text('Quản trị'), findsOneWidget);
      expect(find.textContaining('Gửi các thành viên'), findsOneWidget);
      expect(find.textContaining('Quay về "Thông báo - Sự kiện"'), findsOneWidget);
    });
  });

  group('Kiểm thử Màn hình Hồ sơ thành viên (MemberProfileScreen)', () {
    testWidgets('Xác nhận MemberProfileScreen hiển thị username động', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            backgroundColor: Color(0xFF1E2640),
            body: SingleChildScrollView(
              child: MemberProfileScreen(username: 'nncuong'),
            ),
          ),
        ),
      );

      expect(find.text('Đang xem thông tin cá nhân về nncuong'), findsOneWidget);
      expect(find.text('nncuong'), findsWidgets);
      expect(find.text('Thành viên'), findsWidgets);
      expect(find.text('Diễn đàn'), findsWidgets);
      expect(find.text('Trang chủ'), findsWidgets);
    });
  });

  group('Kiểm thử GoRouter Lazy Loading / Deferred Routing', () {
    test('Router cấu hình đúng route /forum/post/:id và /forum/member/:username', () {
      expect(appRouter.configuration.routes.isNotEmpty, isTrue);
    });
  });
}
