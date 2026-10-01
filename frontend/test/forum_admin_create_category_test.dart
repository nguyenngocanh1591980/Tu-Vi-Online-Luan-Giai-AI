import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/screens/forum/admin_create_category_screen.dart';
import 'package:frontend/screens/forum/forum_home_screen.dart';
import 'package:frontend/widgets/breadcrumb_widget.dart';
import 'package:frontend/widgets/main_layout.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({'jwt_token': 'fake_admin_token'});
  });

  group('Kiểm thử màn hình Tạo Chuyên mục / Lớp học (AdminCreateCategoryScreen)', () {
    testWidgets('Xác nhận Boxed Layout 1024px, nền Tím than #1E2640, viền #2E3B5F và bo góc đáy 8px',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 1024);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final testRouter = GoRouter(
        initialLocation: '/create-category',
        routes: [
          ShellRoute(
            builder: (context, state, shellChild) => MainLayout(child: shellChild),
            routes: [
              GoRoute(
                path: '/create-category',
                builder: (context, state) => const AdminCreateCategoryScreen(),
              ),
            ],
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: testRouter,
        ),
      );
      await tester.pumpAndSettle();

      // 1. Scaffold nền sáng #F0F2F5
      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).first);
      expect(scaffold.backgroundColor, equals(const Color(0xFFF0F2F5)));

      // 2. ConstrainedBox maxWidth 1024
      final cbFinder = find.descendant(
        of: find.byType(Center),
        matching: find.byType(ConstrainedBox),
      );
      expect(cbFinder, findsWidgets);
      final ConstrainedBox cb = tester.widget(cbFinder.first);
      expect(cb.constraints.maxWidth, equals(1024));

      // 3. Khối Card tổng nền #1E2640, viền #2E3B5F, margin top 0, bottom 24
      final cardFinder = find.descendant(
        of: cbFinder,
        matching: find.byType(Container),
      );
      final Container card = tester.widget(cardFinder.first);
      expect(card.margin, equals(const EdgeInsets.only(top: 0, bottom: 24.0)));
      final BoxDecoration dec = card.decoration as BoxDecoration;
      expect(dec.color, equals(const Color(0xFF1E2640)));
      expect(dec.borderRadius, equals(const BorderRadius.vertical(bottom: Radius.circular(8))));
      expect((dec.border as Border).top.color, equals(const Color(0xFF2E3B5F)));
    });

    testWidgets('Kiểm tra logic Toggle 2 nút chọn và thay đổi Label động',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 1024);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: AdminCreateCategoryScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Mặc định: Nút "Tạo Chuyên mục 1 mới" được chọn
      expect(find.text('Tạo Chuyên mục 1 mới'), findsOneWidget);
      expect(find.text('Tạo Chuyên mục 2 mới'), findsOneWidget);
      expect(find.text('Tạo Lớp học Lý Số mới'), findsOneWidget);
      expect(find.text('Tên Chuyên mục 1 mới:'), findsOneWidget);
      expect(find.text('Tên Chuyên mục 2 mới:'), findsNothing);
      expect(find.text('Tên Lớp học Lý số mới:'), findsNothing);

      // 2. Bấm vào "Tạo Chuyên mục 2 mới"
      await tester.tap(find.text('Tạo Chuyên mục 2 mới'));
      await tester.pumpAndSettle();

      // Label đổi sang "Tên Chuyên mục 2 mới:"
      expect(find.text('Tên Chuyên mục 2 mới:'), findsOneWidget);
      expect(find.text('Tên Chuyên mục 1 mới:'), findsNothing);
      expect(find.text('Tên Lớp học Lý số mới:'), findsNothing);

      // 3. Bấm vào "Tạo Lớp học Lý Số mới"
      await tester.tap(find.text('Tạo Lớp học Lý Số mới'));
      await tester.pumpAndSettle();

      // Label đổi sang "Tên Lớp học Lý số mới:"
      expect(find.text('Tên Lớp học Lý số mới:'), findsOneWidget);
      expect(find.text('Tên Chuyên mục 1 mới:'), findsNothing);
      expect(find.text('Tên Chuyên mục 2 mới:'), findsNothing);

      // 4. Bấm lại vào "Tạo Chuyên mục 1 mới"
      await tester.tap(find.text('Tạo Chuyên mục 1 mới'));
      await tester.pumpAndSettle();

      // Label quay lại "Tên Chuyên mục 1 mới:"
      expect(find.text('Tên Chuyên mục 1 mới:'), findsOneWidget);
      expect(find.text('Tên Chuyên mục 2 mới:'), findsNothing);
      expect(find.text('Tên Lớp học Lý số mới:'), findsNothing);
    });

    testWidgets('Xác nhận XÓA BỎ hoàn toàn các thành phần thừa (Header tĩnh, Tabs phụ, Khối khám phá thêm)',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 1024);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: AdminCreateCategoryScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Header tĩnh "TẠO CHỦ ĐỀ MỚI" không tồn tại
      expect(find.text('TẠO CHỦ ĐỀ MỚI'), findsNothing);
      expect(find.text('Tạo chủ đề mới'), findsNothing);

      // 2. Tabs "Lá số" và "Tập tin đính kèm" không tồn tại
      expect(find.text('Lá số'), findsNothing);
      expect(find.text('Tập tin đính kèm'), findsNothing);

      // 3. Khối "Khám phá thêm" và các danh mục con không tồn tại
      expect(find.text('Khám phá thêm'), findsNothing);
      expect(find.text('Người Đông Nam Á & Cư dân vùng Đảo Thái Bình Dương'), findsNothing);
      expect(find.text('Đi chung xe'), findsNothing);
    });

    testWidgets('Xác nhận giữ nguyên BBCode Editor, 3 nút hành động và cụm Tùy chọn',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 1024);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: AdminCreateCategoryScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Biểu tượng bài viết
      expect(find.text('Biểu tượng bài viết:'), findsOneWidget);
      expect(find.text('Không dùng'), findsOneWidget);

      // 2. BBCode Editor Toolbar & 3 nút hành động
      expect(find.text('B'), findsOneWidget);
      expect(find.text('i'), findsOneWidget);
      expect(find.text('u'), findsOneWidget);
      expect(find.text('Cỡ chữ'), findsOneWidget);
      expect(find.text('Lưu bản nháp'), findsOneWidget);
      expect(find.text('Xem trước'), findsOneWidget);
      expect(find.text('Xác nhận'), findsOneWidget);

      // 3. Cụm Tùy chọn (4 checkbox)
      expect(find.text('Tùy chọn'), findsOneWidget);
      expect(find.text('Tắt các thẻ BBCode'), findsOneWidget);
      expect(find.text('Tắt Biểu tượng vui'), findsOneWidget);
      expect(find.text('Đừng tự động nhận diện các địa chỉ URL'), findsOneWidget);
      expect(find.text('Thông báo cho tôi khi có bài trả lời'), findsOneWidget);

      // 4. Nút Về Diễn đàn
      expect(find.text('Về Diễn đàn'), findsOneWidget);
    });

    testWidgets('Kiểm tra điều hướng từ Trang chủ Diễn đàn tới /forum/create-category và Breadcrumb',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 1024);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final testRouter = GoRouter(
        initialLocation: '/forum',
        routes: [
          GoRoute(
            path: '/forum',
            builder: (context, state) => const Scaffold(
              body: Column(
                children: [
                  BreadcrumbWidget(),
                  Expanded(child: ForumHomeScreen()),
                ],
              ),
            ),
          ),
          GoRoute(
            path: '/forum/create-category',
            builder: (context, state) => const Scaffold(
              body: Column(
                children: [
                  BreadcrumbWidget(),
                  Expanded(
                    child: SingleChildScrollView(
                      child: AdminCreateCategoryScreen(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: testRouter,
        ),
      );
      await tester.pumpAndSettle();

      // Xác nhận nút Admin xuất hiện trên Trang chủ
      final adminBtn = find.text('Tạo chuyên mục và Lớp học mới (Admin)');
      expect(adminBtn, findsOneWidget);

      // Bấm nút Admin
      await tester.tap(adminBtn);
      await tester.pumpAndSettle();

      // Xác nhận đã điều hướng tới AdminCreateCategoryScreen
      expect(find.byType(AdminCreateCategoryScreen), findsOneWidget);

      // Xác nhận Breadcrumb hiển thị đúng đường dẫn
      final bcFinder = find.byType(BreadcrumbWidget);
      expect(find.descendant(of: bcFinder, matching: find.text('Trang chủ')), findsOneWidget);
      expect(find.descendant(of: bcFinder, matching: find.text('Diễn đàn')), findsOneWidget);
      expect(find.descendant(of: bcFinder, matching: find.text('Tạo chuyên mục / Lớp học (Admin)')), findsOneWidget);
    });
  });
}
