import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/services/admin_auth_service.dart';
import 'package:frontend/screens/forum/forum_home_screen.dart';
import 'package:frontend/screens/forum/admin_delete_auth_screen.dart';
import 'package:frontend/screens/forum/admin_delete_categories_screen.dart';
import 'package:frontend/widgets/breadcrumb_widget.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'jwt_token': 'fake_admin_jwt_token',
      'username': 'admin',
    });
    await AdminAuthService.clearLockout();
  });

  group('1. Unit Test AdminAuthService: Logic 3 lớp và Khóa phạt 24h', () {
    test('Xác thực tuần tự 3 lớp chính xác ("xóa" -> "chuyên mục" -> "lớp học lý số")', () async {
      // Lớp 1
      final res1 = await AdminAuthService.verifyStep(1, 'xóa');
      expect(res1['success'], isTrue);
      expect(res1['nextStep'], equals(2));

      // Lớp 2
      final res2 = await AdminAuthService.verifyStep(2, 'chuyên mục');
      expect(res2['success'], isTrue);
      expect(res2['nextStep'], equals(3));

      // Lớp 3
      final res3 = await AdminAuthService.verifyStep(3, 'lớp học lý số');
      expect(res3['success'], isTrue);
      expect(res3['completed'], isTrue);
      expect(await AdminAuthService.isSessionValid(), isTrue);
    });

    test('Nhập sai ở lớp bất kỳ không kích hoạt khóa 24 giờ và báo lỗi quay về Trang chủ', () async {
      expect(await AdminAuthService.isLockedOut(), isFalse);

      final res = await AdminAuthService.verifyStep(1, 'sai_mat_khau');
      expect(res['success'], isFalse);
      expect(res['locked'], isFalse);

      // Xác nhận hệ thống KHÔNG bị khóa 24h
      expect(await AdminAuthService.isLockedOut(), isFalse);
      final remaining = await AdminAuthService.getRemainingLockout();
      expect(remaining, equals(Duration.zero));

      // Vẫn có thể thử lại ngay mà không bị chặn
      final resRetry = await AdminAuthService.verifyStep(1, 'xóa');
      expect(resRetry['success'], isTrue);
      expect(resRetry['nextStep'], equals(2));
    });
  });

  group('2. Widget Test: ForumHomeScreen - Nút đỏ & SnackBar thông báo', () {
    testWidgets('Kiểm tra nút đỏ "Xóa Chuyên mục và Lớp học Lý Số (Admin)" và kích hoạt SnackBar',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final router = GoRouter(
        initialLocation: '/forum',
        routes: [
          GoRoute(
            path: '/forum',
            builder: (context, state) => const Scaffold(body: ForumHomeScreen()),
          ),
          GoRoute(
            path: '/forum/admin-delete-auth',
            builder: (context, state) => const Scaffold(body: Text('Admin Delete Auth')),
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp.router(routerConfig: router),
      );
      await tester.pumpAndSettle();

      // Xác nhận nút đỏ có tên mới chuẩn xác
      final redButtonText = find.text('Xóa Chuyên mục và Lớp học Lý Số (Admin)');
      await tester.scrollUntilVisible(redButtonText, 300);
      expect(redButtonText, findsOneWidget);

      // Bấm nút đỏ -> kích hoạt SnackBar
      await tester.tap(redButtonText);
      await tester.pump(); // Start SnackBar animation

      expect(find.text('Xin cung cấp mật khẩu 3 lớp liên tiếp'), findsOneWidget);

      // Drain delayed timer
      await tester.pump(const Duration(milliseconds: 1300));
      await tester.pumpAndSettle();
    });
  });

  group('3. Widget Test: AdminDeleteAuthScreen - Giao diện & Logic 3 Lớp', () {
    testWidgets('Hiển thị Breadcrumb, Sub-nav 1 thanh vàng duy nhất và chuyển đổi Label 3 lớp',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final router = GoRouter(
        initialLocation: '/forum/admin-delete-auth',
        routes: [
          GoRoute(
            path: '/forum/admin-delete-auth',
            builder: (context, state) => const Scaffold(
              body: Column(
                children: [
                  BreadcrumbWidget(),
                  Expanded(child: AdminDeleteAuthScreen()),
                ],
              ),
            ),
          ),
          GoRoute(
            path: '/forum/admin-delete-categories',
            builder: (context, state) => const Scaffold(
              body: AdminDeleteCategoriesScreen(),
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

      // 1. Kiểm tra Breadcrumb và SubNavigation
      expect(find.text('Admin'), findsOneWidget);
      expect(find.text('Đăng nhập'), findsWidgets); // Breadcrumb and screen subtitle/button
      expect(find.text('Xóa chuyên mục và lớp học lý số'), findsOneWidget);

      // 2. Kiểm tra Tiêu đề & Tiến độ lớp 1
      expect(find.text('Tử Vi Online-AI'), findsOneWidget);
      expect(find.text('Xác thực bảo mật: Lớp 1 / 3'), findsOneWidget);
      expect(find.text('Mật khẩu lớp 1'), findsOneWidget);

      // 3. Nhập "xóa" cho lớp 1 và bấm Đăng Nhập
      final textFieldFinder = find.byType(TextField);
      await tester.enterText(textFieldFinder, 'xóa');
      final submitButton = find.widgetWithText(ElevatedButton, 'Đăng Nhập');
      await tester.tap(submitButton);
      await tester.pumpAndSettle();

      // Kiểm tra nhãn chuyển thành "Mật khẩu lớp 2"
      expect(find.text('Xác thực bảo mật: Lớp 2 / 3'), findsOneWidget);
      expect(find.text('Mật khẩu lớp 2'), findsOneWidget);

      // 4. Nhập "chuyên mục" cho lớp 2 và bấm Đăng Nhập
      await tester.enterText(textFieldFinder, 'chuyên mục');
      await tester.tap(submitButton);
      await tester.pumpAndSettle();

      // Kiểm tra nhãn chuyển thành "Mật khẩu lớp 3"
      expect(find.text('Xác thực bảo mật: Lớp 3 / 3'), findsOneWidget);
      expect(find.text('Mật khẩu lớp 3'), findsOneWidget);
    });

    testWidgets('Nhập sai mật khẩu kích hoạt thông báo phạt khóa 24 giờ',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 1024);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final router = GoRouter(
        initialLocation: '/forum/admin-delete-auth',
        routes: [
          GoRoute(
            path: '/forum/admin-delete-auth',
            builder: (context, state) => const Scaffold(
              body: AdminDeleteAuthScreen(),
            ),
          ),
          GoRoute(
            path: '/',
            builder: (context, state) => const Scaffold(body: Text('Trang chủ')),
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp.router(routerConfig: router),
      );
      await tester.pumpAndSettle();

      // Nhập sai mật khẩu ở lớp 1
      await tester.enterText(find.byType(TextField), 'sai_mat_khau');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Đăng Nhập'));
      await tester.pump();

      // Xác nhận SnackBar thông báo sai mật khẩu xuất hiện (không bị phạt khóa 24h)
      expect(find.textContaining('Mật khẩu lớp 1 không chính xác'), findsOneWidget);
      expect(await AdminAuthService.isLockedOut(), isFalse);

      // Drain delayed timer
      await tester.pump(const Duration(milliseconds: 1600));
      await tester.pumpAndSettle();
      expect(find.text('Trang chủ'), findsOneWidget);
    });
  });

  group('4. Widget Test: AdminDeleteCategoriesScreen - Boxed Layout & Xóa Y/N', () {
    testWidgets('Xác nhận Boxed Layout phẳng phiu, Text hỏi ở đỉnh, 2 nút đáy và Dialog Y/N',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 2400); // Đủ dài để hiển thị danh sách
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: AdminDeleteCategoriesScreen(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Kiểm tra dòng chữ hỏi ở đỉnh danh sách
      expect(find.text('Bạn định xóa chuyên mục hay lớp học lý số nào ?'), findsOneWidget);

      // 2. Kiểm tra danh mục chuyên mục hiện diện
      expect(find.text('Chuyên mục 1'), findsOneWidget);
      expect(find.text('Chuyên mục 2'), findsOneWidget);
      expect(find.text('Lớp học Lý số'), findsOneWidget);
      expect(find.text('Thông báo - Sự kiện'), findsOneWidget);
      expect(find.text('Kiến thức Tử vi'), findsOneWidget);
      expect(find.text('Lớp học tử vi'), findsOneWidget);
      expect(find.text('Xem Tử vi'), findsOneWidget);

      // 3. Chọn chuyên mục "Thông báo - Sự kiện"
      await tester.tap(find.text('Thông báo - Sự kiện'));
      await tester.pumpAndSettle();

      // 4. Cuộn xuống kiểm tra 2 nút bấm ở đáy
      final confirmDeleteFinder = find.text('Xác nhận xóa');
      await tester.scrollUntilVisible(confirmDeleteFinder, 500);
      expect(confirmDeleteFinder, findsOneWidget);
      expect(find.text('Trở về Trang chủ'), findsOneWidget);

      // 5. Bấm nút "Xác nhận xóa" -> Bật Dialog Y/N
      await tester.tap(confirmDeleteFinder);
      await tester.pumpAndSettle();

      expect(find.text('Xác nhận xóa'), findsWidgets);
      expect(
        find.text('Bạn chắc chắn muốn xóa chuyên mục [Thông báo - Sự kiện] này không (Y/N)'),
        findsOneWidget,
      );
      expect(find.text('N (Không)'), findsOneWidget);
      expect(find.text('Y (Đồng ý)'), findsOneWidget);

      // 6. Bấm N (Không) -> Dialog đóng, chuyên mục vẫn còn
      await tester.tap(find.text('N (Không)'));
      await tester.pumpAndSettle();
      expect(find.text('Thông báo - Sự kiện'), findsOneWidget);

      // 7. Bấm lại Xác nhận xóa -> Bấm Y (Đồng ý) -> Chuyên mục bị xóa khỏi State
      await tester.tap(confirmDeleteFinder);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Y (Đồng ý)'));
      await tester.pumpAndSettle();

      // Xác nhận "Thông báo - Sự kiện" đã biến mất khỏi màn hình
      expect(find.text('Thông báo - Sự kiện'), findsNothing);
      expect(find.textContaining('Đã xóa thành công chuyên mục [Thông báo - Sự kiện]'), findsOneWidget);
    });
  });
}
