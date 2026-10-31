import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/screens/forum/forum_home_screen.dart';
import 'package:frontend/screens/forum/category_topics_screen.dart';
import 'package:frontend/providers/forum_category_provider.dart';
import 'package:frontend/providers/forum_stats_provider.dart';
import 'package:frontend/widgets/breadcrumb_widget.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget buildApp(Widget child, {bool isLoggedIn = false, String username = 'User', String role = 'User'}) {
    SharedPreferences.setMockInitialValues({
      if (isLoggedIn) 'auth_token': 'fake_jwt_token',
      if (isLoggedIn) 'jwt_token': 'fake_jwt_token',
      if (isLoggedIn) 'username': username,
      if (isLoggedIn) 'role': role,
    });

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ForumCategoryProvider(autoFetch: false)),
        ChangeNotifierProvider(create: (_) => ForumStatsProvider(autoFetch: false)),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(child: child),
        ),
      ),
    );
  }

  group('XÁC MINH TOÀN DIỆN 4 NHIỆM VỤ - TỐI ƯU GIAO DIỆN VÀ PHÂN QUYỀN RBAC', () {
    testWidgets('NHIỆM VỤ 1: Trang chủ hiển thị 3 nút Admin chuẩn tên và cùng hàng với Đánh dấu đã xem (Hình 1)', (tester) async {
      tester.view.physicalSize = const Size(1024, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildApp(const ForumHomeScreen(), isLoggedIn: true, role: 'Admin'));
      await tester.pumpAndSettle();

      // 1. Kiểm tra chính xác tên 3 nút mới
      expect(find.text('Chuyên Mục và Lớp Học Mới'), findsOneWidget);
      expect(find.text('Sửa Chuyên Mục Và Lớp học'), findsOneWidget);
      expect(find.text('Xóa Chuyên mục và Lớp học'), findsOneWidget);

      // 2. Kiểm tra text "Đánh dấu đã xem tất cả các chuyên mục"
      expect(find.text('Đánh dấu đã xem tất cả các chuyên mục'), findsOneWidget);

      // 3. Kiểm tra chúng nằm trong cùng 1 Row ngang
      final markReadFinder = find.text('Đánh dấu đã xem tất cả các chuyên mục');
      final parentRow = find.ancestor(of: markReadFinder, matching: find.byType(Row));
      expect(parentRow, findsWidgets);

      // 4. Xác nhận không có ngoại lệ tràn viền (A RenderFlex overflowed)
      expect(tester.takeException(), isNull);
    });

    testWidgets('NHIỆM VỤ 2: Chi tiết chuyên mục hiển thị đồng loạt 3 nút Admin với text mới (Hình 2 & 3)', (tester) async {
      tester.view.physicalSize = const Size(1024, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildApp(const CategoryTopicsScreen(slug: 'thong-bao-su-kien'), isLoggedIn: true, role: 'Admin'));
      await tester.pumpAndSettle();

      // 1. Kiểm tra 3 nút Admin trên CategoryTopicsScreen
      expect(find.text('Thông báo và Sự kiện mới'), findsOneWidget);
      expect(find.text('Sửa Thông báo và Sự kiện'), findsOneWidget);
      expect(find.text('Xóa Thông báo và Sự kiện'), findsOneWidget);

      expect(tester.takeException(), isNull);
    });

    testWidgets('NHIỆM VỤ 3 & 4 (Từ chối): User thường / Chưa phân quyền vào Lớp học tử vi bị chặn truy cập (Hình 6)', (tester) async {
      tester.view.physicalSize = const Size(1024, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      // User thường không có quyền
      await tester.pumpWidget(buildApp(const CategoryTopicsScreen(slug: 'lop-hoc-tu-vi'), isLoggedIn: true, username: 'user_thuong', role: 'User'));
      await tester.pumpAndSettle();

      // Cảnh báo hạn chế Hình 6
      expect(find.text('Bạn không được cấp phép để xem các chủ đề trong chuyên mục này.'), findsOneWidget);
      expect(find.text('Thể loại này không có chuyên mục.'), findsOneWidget);

      // Tiêu đề trang
      expect(find.text('Lớp học Tử vi'), findsOneWidget);
      expect(find.text('Chuyên mục dành cho lớp học tử vi'), findsOneWidget);

      expect(tester.takeException(), isNull);
    });

    testWidgets('NHIỆM VỤ 3 & 4 (Chấp thuận): Tài khoản Admin vào Lớp học tử vi được mở khóa danh sách bài viết & Bảng Nội Quy (Hình 7 & 8)', (tester) async {
      tester.view.physicalSize = const Size(1024, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      // Tài khoản Admin được Full quyền
      await tester.pumpWidget(buildApp(const CategoryTopicsScreen(slug: 'lop-hoc-tu-vi'), isLoggedIn: true, username: 'Admin', role: 'Admin'));
      await tester.pumpAndSettle();

      // 1. Tiêu đề trang
      expect(find.text('Lớp học Tử vi'), findsOneWidget);

      // 2. Bảng Nội Quy có tiêu đề "Nội Quy Lớp Học Tử vi" (Hình 8)
      expect(find.text('Nội Quy Lớp Học Tử vi'), findsOneWidget);
      expect(find.textContaining('Đây là chuyên mục dành cho việc xem lá số tử vi'), findsOneWidget);

      // 3. Hiển thị 3 nút Admin
      expect(find.text('Thông báo và Chủ đề mới'), findsOneWidget);
      expect(find.text('Sửa Thông Báo và Chủ đề'), findsOneWidget);
      expect(find.text('Xóa Thông Báo và Chủ đề'), findsOneWidget);

      // 4. Danh sách bài viết không bị rỗng (Hình 7)
      expect(find.textContaining('65 năm Việt Nam - Cuba'), findsWidgets);

      expect(tester.takeException(), isNull);
    });

    testWidgets('NHIỆM VỤ 4: Breadcrumb Widget map chuẩn xác slug lop-hoc-tu-vi sang "Lớp học Tử vi"', (tester) async {
      tester.view.physicalSize = const Size(1024, 300);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      SharedPreferences.setMockInitialValues({});

      final router = GoRouter(
        initialLocation: '/forum/category/lop-hoc-tu-vi',
        routes: [
          GoRoute(
            path: '/forum/category/:slug',
            builder: (context, state) => const Scaffold(
              body: BreadcrumbWidget(),
            ),
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Trang chủ'), findsOneWidget);
      expect(find.text('Diễn đàn'), findsOneWidget);
      expect(find.text('Lớp học Tử vi'), findsOneWidget);

      expect(tester.takeException(), isNull);
    });
  });
}
