import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/models/forum_category_model.dart';
import 'package:frontend/providers/forum_category_provider.dart';
import 'package:frontend/screens/forum/admin_delete_categories_screen.dart';
import 'package:frontend/screens/forum/forum_home_screen.dart';
import 'package:frontend/widgets/forum_table_widget.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({'jwt_token': 'fake_admin_token'});
  });

  group('1. Unit Test ForumCategoryProvider: Batch Delete', () {
    test('Xóa đồng thời nhiều chuyên mục khỏi các nhóm khác nhau', () async {
      final provider = ForumCategoryProvider();

      final itemG1 = provider.group1Categories.firstWhere((c) => c.title == 'Thông báo - Sự kiện');
      final itemG2 = provider.group2Categories.firstWhere((c) => c.title == 'Lớp học tử vi');
      final itemG3 = provider.group3Categories.firstWhere((c) => c.title == 'Xem Tử vi');

      expect(provider.group1Categories.any((c) => c.title == 'Thông báo - Sự kiện'), isTrue);
      expect(provider.group2Categories.any((c) => c.title == 'Lớp học tử vi'), isTrue);
      expect(provider.group3Categories.any((c) => c.title == 'Xem Tử vi'), isTrue);

      await provider.removeCategories([itemG1, itemG2, itemG3]);

      expect(provider.group1Categories.any((c) => c.title == 'Thông báo - Sự kiện'), isFalse);
      expect(provider.group2Categories.any((c) => c.title == 'Lớp học tử vi'), isFalse);
      expect(provider.group3Categories.any((c) => c.title == 'Xem Tử vi'), isFalse);
    });
  });

  group('2. Widget Test: AdminDeleteCategoriesScreen - Giao diện & Chức năng Xóa Hàng Loạt', () {
    testWidgets('Xác nhận Header, Checkbox thay thế Icon và Bottom Bar 2 nút',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 3200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final categoryProvider = ForumCategoryProvider();

      await tester.pumpWidget(
        ChangeNotifierProvider<ForumCategoryProvider>.value(
          value: categoryProvider,
          child: const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: AdminDeleteCategoriesScreen(),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Tiêu đề Header chuẩn (Top Bar motif Hình 4) và Footer Breadcrumb
      expect(
        find.text('Xóa các Chuyên mục và Lớp học Lý số (Admin)'),
        findsNWidgets(2), // 1 ở Top Bar, 1 ở Footer Breadcrumb
      );
      expect(find.text('Về Diễn đàn'), findsOneWidget);

      // 2. Các Checkbox hiện diện thay thế icon cho toàn bộ danh sách
      expect(find.byType(Checkbox), findsWidgets);

      // 3. Thanh công cụ đáy chứa 2 nút chuẩn
      expect(find.text('Xem trước'), findsOneWidget);
      expect(find.text('Xác nhận xóa (Y/N)'), findsOneWidget);

      // 4. Footer phpBB và Breadcrumb chân trang
      expect(find.text('Powered by phpBB® Forum Software © phpBB Limited'), findsOneWidget);
      expect(find.text('Chính sách bảo mật'), findsOneWidget);
      expect(find.text('Điều khoản tham gia'), findsOneWidget);

      // 5. Container bọc ngoài nền #1E2640 bo góc 8px
      final containerFinder = find.descendant(
        of: find.byType(AdminDeleteCategoriesScreen),
        matching: find.byWidgetPredicate(
          (w) => w is Container && (w.decoration is BoxDecoration && (w.decoration as BoxDecoration).color == const Color(0xFF1E2640)),
        ),
      );
      expect(containerFinder, findsWidgets);
    });

    testWidgets('Kiểm tra nút "Xem trước" (Preview Modal) với các mục được chọn',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 3200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final categoryProvider = ForumCategoryProvider();

      await tester.pumpWidget(
        ChangeNotifierProvider<ForumCategoryProvider>.value(
          value: categoryProvider,
          child: const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: AdminDeleteCategoriesScreen(),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Bấm "Xem trước" khi chưa chọn mục nào -> Không bật Dialog
      await tester.tap(find.text('Xem trước'));
      await tester.pumpAndSettle();
      expect(find.byType(Dialog), findsNothing);

      // 2. Tích chọn "Thông báo - Sự kiện" và "Kiến thức Cơ bản"
      await tester.tap(find.text('Thông báo - Sự kiện'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Kiến thức Cơ bản'));
      await tester.pumpAndSettle();

      // 3. Bấm "Xem trước" -> Mở Modal Dialog liệt kê 2 mục
      await tester.tap(find.text('Xem trước'));
      await tester.pumpAndSettle();

      expect(find.byType(Dialog), findsOneWidget);
      expect(find.text('Danh sách các mục được chọn xóa (2)'), findsOneWidget);
      expect(find.text('Các chuyên mục / lớp học sẽ xóa'), findsOneWidget);

      // 4. Bấm "Đóng xem trước"
      await tester.tap(find.text('Đóng xem trước'));
      await tester.pumpAndSettle();
      expect(find.byType(Dialog), findsNothing);
    });

    testWidgets('Kiểm tra luồng "Xác nhận xóa (Y/N)" với lựa chọn [N] (Hủy) và [Y] (Đồng ý)',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 3200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final categoryProvider = ForumCategoryProvider();

      final router = GoRouter(
        initialLocation: '/forum/delete-categories',
        routes: [
          GoRoute(
            path: '/forum',
            builder: (context, state) => const Scaffold(
              body: Text('Trang chủ Diễn đàn'),
            ),
          ),
          GoRoute(
            path: '/forum/delete-categories',
            builder: (context, state) => const Scaffold(
              body: SingleChildScrollView(
                child: AdminDeleteCategoriesScreen(),
              ),
            ),
          ),
        ],
      );

      await tester.pumpWidget(
        ChangeNotifierProvider<ForumCategoryProvider>.value(
          value: categoryProvider,
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Bấm "Xác nhận xóa (Y/N)" khi chưa chọn mục nào -> Bị chặn
      await tester.tap(find.text('Xác nhận xóa (Y/N)'));
      await tester.pumpAndSettle();
      expect(find.byType(Dialog), findsNothing);

      // 2. Tích chọn "Thông báo - Sự kiện"
      await tester.tap(find.text('Thông báo - Sự kiện'));
      await tester.pumpAndSettle();

      // 3. Bấm "Xác nhận xóa (Y/N)" -> Bật Dialog Y/N
      await tester.tap(find.text('Xác nhận xóa (Y/N)'));
      await tester.pumpAndSettle();

      expect(find.byType(Dialog), findsOneWidget);
      expect(find.text('Bạn muốn xóa không?'), findsOneWidget);
      expect(find.text('N (Hủy)'), findsOneWidget);
      expect(find.text('Y (Đồng ý)'), findsOneWidget);

      // 4. Bấm N (Hủy) -> Đóng dialog, mục chưa bị xóa
      await tester.tap(find.text('N (Hủy)'));
      await tester.pumpAndSettle();
      expect(find.byType(Dialog), findsNothing);
      expect(categoryProvider.group1Categories.any((c) => c.title == 'Thông báo - Sự kiện'), isTrue);

      // 5. Bấm lại "Xác nhận xóa (Y/N)" -> Bấm Y (Đồng ý)
      await tester.tap(find.text('Xác nhận xóa (Y/N)'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Y (Đồng ý)'));
      await tester.pumpAndSettle();

      // 6. Mục đã bị xóa khỏi Provider và chuyển hướng về /forum
      expect(categoryProvider.group1Categories.any((c) => c.title == 'Thông báo - Sự kiện'), isFalse);
      expect(find.text('Trang chủ Diễn đàn'), findsOneWidget);
    });

    testWidgets('Kiểm tra nút đỏ trên ForumHomeScreen điều hướng tới /forum/delete-categories',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 3200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final categoryProvider = ForumCategoryProvider();

      final router = GoRouter(
        initialLocation: '/forum',
        routes: [
          GoRoute(
            path: '/forum',
            builder: (context, state) => const Scaffold(
              body: SingleChildScrollView(
                child: ForumHomeScreen(),
              ),
            ),
          ),
          GoRoute(
            path: '/forum/delete-categories',
            builder: (context, state) => const Scaffold(
              body: SingleChildScrollView(
                child: AdminDeleteCategoriesScreen(),
              ),
            ),
          ),
        ],
      );

      await tester.pumpWidget(
        ChangeNotifierProvider<ForumCategoryProvider>.value(
          value: categoryProvider,
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Bấm nút đỏ "Xóa Chuyên mục và Lớp học Lý Số (Admin)"
      final redButtonFinder = find.byWidgetPredicate((w) => w is Text && w.data != null && w.data!.startsWith('Xóa') && w.data!.contains('Lớp học Lý'));
      await tester.scrollUntilVisible(redButtonFinder, 300, scrollable: find.byType(Scrollable).first);
      expect(redButtonFinder, findsOneWidget);
      await tester.tap(redButtonFinder);
      await tester.pumpAndSettle();

      // Đã chuyển sang màn hình AdminDeleteCategoriesScreen
      expect(find.byType(AdminDeleteCategoriesScreen), findsOneWidget);
      expect(find.text('Xóa các Chuyên mục và Lớp học Lý số (Admin)'), findsAtLeastNWidgets(1));
    });
  });
}
