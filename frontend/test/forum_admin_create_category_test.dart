import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/providers/forum_category_provider.dart';
import 'package:frontend/screens/forum/admin_create_category_screen.dart';
import 'package:frontend/screens/forum/forum_home_screen.dart';
import 'package:frontend/widgets/breadcrumb_widget.dart';
import 'package:frontend/widgets/main_layout.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({'jwt_token': 'fake_admin_token'});
  });

  group('Kiểm thử màn hình Tạo Chuyên mục / Lớp học (AdminCreateCategoryScreen)', () {
    testWidgets('Xác nhận Boxed Layout 1024px, nền Tím đen #1E2640 trải dài liền mạch (Bước 1)',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 1024);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final testRouter = GoRouter(
        initialLocation: '/forum/create-category',
        routes: [
          ShellRoute(
            builder: (context, state, shellChild) => MainLayout(child: shellChild),
            routes: [
              GoRoute(
                path: '/forum/create-category',
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

      // 1. Scaffold ngoài cùng nền xám sáng #F0F2F5
      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).first);
      expect(scaffold.backgroundColor, equals(const Color(0xFFF0F2F5)));

      // 2. ConstrainedBox maxWidth 1024
      final cbFinder = find.byWidgetPredicate(
        (w) => w is ConstrainedBox && w.constraints.maxWidth == 1024,
      );
      expect(cbFinder, findsWidgets);

      // 3. Khối AdminCreateCategoryScreen nền #1E2640 liền mạch không bị phân cắt (Bước 1)
      final containerFinder = find.descendant(
        of: find.byType(AdminCreateCategoryScreen),
        matching: find.byWidgetPredicate(
          (w) => w is Container && (w.color == const Color(0xFF1E2640) ||
                 (w.decoration is BoxDecoration && (w.decoration as BoxDecoration).color == const Color(0xFF1E2640))),
        ),
      );
      expect(containerFinder, findsWidgets);

      // 4. Breadcrumb cập nhật chính xác (Bước 2 Hành động 2)
      final bcFinder = find.byType(BreadcrumbWidget);
      expect(find.descendant(of: bcFinder, matching: find.text('Trang chủ')), findsOneWidget);
      expect(find.descendant(of: bcFinder, matching: find.text('Diễn đàn')), findsOneWidget);
      expect(find.descendant(of: bcFinder, matching: find.text('Tạo thêm Chuyên mục và Lớp học Lý số mới (Admin)')), findsOneWidget);
    });

    testWidgets('Kiểm tra logic Toggle 3 nút chọn và thay đổi Label động theo Bước 3',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 1024);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: AdminCreateCategoryScreen(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Mặc định: Nút "Tạo thêm Chuyên mục 1 mới" được chọn
      expect(find.text('Tạo thêm Chuyên mục 1 mới'), findsOneWidget);
      expect(find.text('Tạo thêm Chuyên mục 2 mới'), findsOneWidget);
      expect(find.text('Tạo thêm Lớp học Lý số mới'), findsOneWidget);
      expect(find.text('Tên Chuyên mục 1 tạo mới'), findsOneWidget);
      expect(find.text('Tên Chuyên mục 2 tạo mới'), findsNothing);
      expect(find.text('Tên Lớp học Lý số mới'), findsNothing);

      // 2. Bấm vào "Tạo thêm Chuyên mục 2 mới"
      await tester.tap(find.text('Tạo thêm Chuyên mục 2 mới'));
      await tester.pumpAndSettle();

      // Label đổi sang "Tên Chuyên mục 2 tạo mới"
      expect(find.text('Tên Chuyên mục 2 tạo mới'), findsOneWidget);
      expect(find.text('Tên Chuyên mục 1 tạo mới'), findsNothing);
      expect(find.text('Tên Lớp học Lý số mới'), findsNothing);

      // 3. Bấm vào "Tạo thêm Lớp học Lý số mới"
      await tester.tap(find.text('Tạo thêm Lớp học Lý số mới'));
      await tester.pumpAndSettle();

      // Label đổi sang "Tên Lớp học Lý số mới"
      expect(find.text('Tên Lớp học Lý số mới'), findsOneWidget);
      expect(find.text('Tên Chuyên mục 1 tạo mới'), findsNothing);
      expect(find.text('Tên Chuyên mục 2 tạo mới'), findsNothing);

      // 4. Bấm lại vào "Tạo thêm Chuyên mục 1 mới"
      await tester.tap(find.text('Tạo thêm Chuyên mục 1 mới'));
      await tester.pumpAndSettle();

      // Label quay lại "Tên Chuyên mục 1 tạo mới"
      expect(find.text('Tên Chuyên mục 1 tạo mới'), findsOneWidget);
      expect(find.text('Tên Chuyên mục 2 tạo mới'), findsNothing);
      expect(find.text('Tên Lớp học Lý số mới'), findsNothing);
    });

    testWidgets('Xác nhận Thanh Bar tiêu đề chuẩn (Bước 2 Hành động 1) và không còn chữ "Bài viết mới"',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 1024);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: AdminCreateCategoryScreen(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Tiêu đề "Bài viết mới" đã được sửa thành "Tạo thêm Chuyên mục và Lớp học Lý số mới (Admin)"
      expect(find.text('Tạo thêm Chuyên mục và Lớp học Lý số mới (Admin)'), findsWidgets);
      expect(find.text('Bài viết mới'), findsNothing);

      // 2. Không còn Header tĩnh "TẠO CHỦ ĐỀ MỚI"
      expect(find.text('TẠO CHỦ ĐỀ MỚI'), findsNothing);
    });

    testWidgets('Xác nhận Dải Radio Icon (Hình 4 + Bổ sung), Toolbar nguyên bản (Hình 5), và Footer Diễn đàn',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 1024);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: AdminCreateCategoryScreen(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Bước 3 Hành động 1: XÓA BỎ cụm "Biểu tượng bài viết:" tự chế
      expect(find.text('Biểu tượng bài viết:'), findsNothing);
      expect(find.text('Biểu tượng Chuyên mục hoặc Lớp học mới'), findsOneWidget);
      expect(find.text('Không dùng'), findsOneWidget);
      expect(find.text('🔥'), findsNothing);

      // Bấm vào thanh để mở rộng (Expanded)
      await tester.tap(find.text('Biểu tượng Chuyên mục hoặc Lớp học mới'));
      await tester.pumpAndSettle();

      // Các Radio Icon gốc khi mở rộng
      expect(find.text('🔥'), findsOneWidget);
      expect(find.text('⭐'), findsOneWidget);
      expect(find.text('☢️'), findsOneWidget);
      expect(find.text('💖'), findsOneWidget);
      expect(find.text('💡'), findsOneWidget);
      expect(find.text('❓'), findsOneWidget);
      expect(find.text('⚠️'), findsOneWidget);
      expect(find.text('ℹ️'), findsOneWidget);
      expect(find.text('📖'), findsOneWidget);
      expect(find.text('🙏'), findsOneWidget);
      expect(find.byIcon(Icons.description_outlined), findsWidgets); // Bổ sung tài liệu

      // 2. Bước 3 Hành động 2: Toolbar nguyên bản Hình 5
      expect(find.text('B'), findsOneWidget);
      expect(find.text('I'), findsOneWidget);
      expect(find.text('U'), findsOneWidget);
      expect(find.text('Cỡ chữ'), findsOneWidget);
      expect(find.text('A'), findsOneWidget);
      expect(find.byIcon(Icons.format_list_bulleted), findsOneWidget);
      expect(find.byIcon(Icons.format_list_numbered), findsOneWidget);
      expect(find.byIcon(Icons.format_quote), findsOneWidget);
      expect(find.byIcon(Icons.visibility_off), findsOneWidget);
      expect(find.byIcon(Icons.link), findsOneWidget);
      expect(find.byIcon(Icons.link_off), findsOneWidget);
      expect(find.byIcon(Icons.photo_outlined), findsOneWidget);
      expect(find.byIcon(Icons.table_chart_outlined), findsOneWidget);
      expect(find.byIcon(Icons.sentiment_satisfied_alt), findsOneWidget);
      expect(find.byIcon(Icons.smart_display), findsOneWidget);
      expect(find.byIcon(Icons.undo), findsOneWidget);
      expect(find.byIcon(Icons.redo), findsOneWidget);
      expect(find.byIcon(Icons.fullscreen), findsOneWidget);

      // 2 nút hành động (đã bỏ nút Lưu bản nháp)
      expect(find.text('Lưu bản nháp'), findsNothing);
      expect(find.text('Xem trước'), findsOneWidget);
      expect(find.text('Xác nhận'), findsOneWidget);

      // Cụm Tùy chọn (3 checkbox, đã xóa checkbox thứ 4)
      expect(find.text('Tùy chọn'), findsOneWidget);
      expect(find.text('Tắt các thẻ BBCode'), findsOneWidget);
      expect(find.text('Tắt Biểu tượng vui'), findsOneWidget);
      expect(find.text('Đừng tự động nhận diện các địa chỉ URL'), findsOneWidget);
      expect(find.text('Thông báo cho tôi khi có bài trả lời'), findsNothing);

      // Footer Diễn đàn (Hình 1 đã khôi phục, chỉ xóa bỏ khối liên kết Hình 2)
      expect(find.text('Powered by phpBB® Forum Software © phpBB Limited'), findsOneWidget);
      expect(find.text('Chính sách bảo mật'), findsOneWidget);
      expect(find.text('Điều khoản tham gia'), findsOneWidget);
      // Dải liên kết phụ trong Hình 2 đã bị xóa hoàn toàn
      expect(find.text('Xóa hết cookie'), findsNothing);
      expect(find.text('Liên hệ'), findsNothing);
      expect(find.text('Chia sẻ'), findsNothing);
      expect(find.text('Chúng tôi'), findsNothing);
      expect(find.text('Thành viên'), findsNothing);
      expect(find.text('Múi giờ UTC+07:00'), findsNothing);
      expect(find.text('Về Diễn đàn'), findsOneWidget); // Header form
    });

    testWidgets('Kiểm tra điều hướng từ Trang chủ Diễn đàn tới /forum/create-category và màu nút xanh ngọc',
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
              body: SingleChildScrollView(
                child: ForumHomeScreen(),
              ),
            ),
          ),
          GoRoute(
            path: '/forum/create-category',
            builder: (context, state) => const Scaffold(
              body: SingleChildScrollView(
                child: AdminCreateCategoryScreen(),
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

      // 1. Xác nhận nút Admin xuất hiện trên Trang chủ với màu teal
      final adminBtnFinder = find.text('Tạo thêm Chuyên mục và Lớp học Lý số mới (Admin)');
      expect(adminBtnFinder, findsOneWidget);
      
      final elevatedBtn = tester.widget<ElevatedButton>(
        find.ancestor(of: adminBtnFinder, matching: find.byWidgetPredicate((w) => w is ElevatedButton)),
      );
      expect(elevatedBtn.style?.backgroundColor?.resolve({}), equals(Colors.teal));

      // 2. Bấm nút Admin
      await tester.tap(adminBtnFinder);
      await tester.pumpAndSettle();

      // 3. Xác nhận đã điều hướng tới AdminCreateCategoryScreen
      expect(find.byType(AdminCreateCategoryScreen), findsOneWidget);
    });

    testWidgets('Kiểm tra validation trường Tên bắt buộc nhập: để trống bị chặn Submit',
        (WidgetTester tester) async {
      final categoryProvider = ForumCategoryProvider();

      await tester.pumpWidget(
        ChangeNotifierProvider<ForumCategoryProvider>.value(
          value: categoryProvider,
          child: const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: AdminCreateCategoryScreen(),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final initialCount = categoryProvider.group1Categories.length;

      // Bấm nút "Xác nhận" khi chưa nhập tiêu đề
      final confirmBtn = find.text('Xác nhận');
      expect(confirmBtn, findsOneWidget);
      await tester.tap(confirmBtn);
      await tester.pumpAndSettle();

      // Xác nhận bị block không thêm vào provider
      expect(categoryProvider.group1Categories.length, equals(initialCount));

      // Xác nhận hiển thị thông báo lỗi
      expect(find.text('Vui lòng nhập tên chuyên mục tạo mới'), findsWidgets);
    });

    testWidgets('Kiểm tra luồng submit tạo chuyên mục động, chọn icon và hiển thị trên ForumHomeScreen',
        (WidgetTester tester) async {
      final categoryProvider = ForumCategoryProvider();

      tester.view.physicalSize = const Size(1280, 1024);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final testRouter = GoRouter(
        initialLocation: '/forum/create-category',
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
            path: '/forum/create-category',
            builder: (context, state) => const Scaffold(
              body: SingleChildScrollView(
                child: AdminCreateCategoryScreen(),
              ),
            ),
          ),
        ],
      );

      await tester.pumpWidget(
        ChangeNotifierProvider<ForumCategoryProvider>.value(
          value: categoryProvider,
          child: MaterialApp.router(
            routerConfig: testRouter,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Mở rộng dải icon và chọn icon ngọn lửa 🔥
      await tester.tap(find.text('Biểu tượng Chuyên mục hoặc Lớp học mới'));
      await tester.pumpAndSettle();
      final fireIconFinder = find.text('🔥');
      expect(fireIconFinder, findsOneWidget);
      await tester.tap(fireIconFinder);
      await tester.pumpAndSettle();

      // 2. Nhập tên chuyên mục
      final titleFieldFinder = find.byType(TextField).first;
      await tester.enterText(titleFieldFinder, 'Chuyên mục Phong Thủy Thực Chiến');
      await tester.pumpAndSettle();

      // 3. Bấm nút "Xác nhận"
      final confirmBtn = find.text('Xác nhận');
      expect(confirmBtn, findsOneWidget);
      await tester.tap(confirmBtn);
      await tester.pumpAndSettle();

      // 4. Kiểm tra dữ liệu được thêm vào Provider thành công
      final addedItem = categoryProvider.group1Categories.firstWhere(
        (cat) => cat.title == 'Chuyên mục Phong Thủy Thực Chiến',
      );
      expect(addedItem.icon, equals('🔥'));
      expect(addedItem.groupType, anyOf(equals('ChuyenMuc1'), equals('Chuyên mục 1')));

      // 5. Kiểm tra màn hình đã chuyển về ForumHomeScreen và hiển thị chuyên mục mới với đúng icon và title
      expect(find.byType(ForumHomeScreen), findsOneWidget);
      expect(find.text('Chuyên mục Phong Thủy Thực Chiến'), findsOneWidget);
      expect(find.text('🔥'), findsOneWidget);
    });

    testWidgets('Kiểm tra phân loại groupType (LopHoc, ChuyenMuc2) theo nút bấm Hình 10',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 1024);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final categoryProvider = ForumCategoryProvider();

      final testRouter = GoRouter(
        initialLocation: '/forum/create-category',
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
            path: '/forum/create-category',
            builder: (context, state) => const Scaffold(
              body: SingleChildScrollView(
                child: AdminCreateCategoryScreen(),
              ),
            ),
          ),
        ],
      );

      await tester.pumpWidget(
        ChangeNotifierProvider<ForumCategoryProvider>.value(
          value: categoryProvider,
          child: MaterialApp.router(
            routerConfig: testRouter,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Chuyển sang "Tạo thêm Lớp học Lý số mới" (Hình 10)
      await tester.tap(find.text('Tạo thêm Lớp học Lý số mới'));
      await tester.pumpAndSettle();

      // 2. Nhập tiêu đề lớp học
      final titleFieldFinder = find.byType(TextField).first;
      await tester.enterText(titleFieldFinder, 'Lớp Học Luận Đoán Thực Chiến');
      await tester.pumpAndSettle();

      // 3. Bấm xác nhận
      await tester.tap(find.text('Xác nhận'));
      await tester.pumpAndSettle();

      // 4. Xác nhận phân loại vào group2 (Lớp học Lý số)
      final addedClass = categoryProvider.group2Categories.firstWhere(
        (cat) => cat.title == 'Lớp Học Luận Đoán Thực Chiến',
      );
      expect(addedClass.groupType, anyOf(equals('LopHoc'), equals('Lớp học Lý số')));
      expect(find.byType(ForumHomeScreen), findsOneWidget);
      expect(find.text('Lớp Học Luận Đoán Thực Chiến'), findsOneWidget);
    });
  });
}
