import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/models/forum_category_model.dart';
import 'package:frontend/models/forum_draft_model.dart';
import 'package:frontend/providers/draft_provider.dart';
import 'package:frontend/providers/forum_category_provider.dart';
import 'package:frontend/screens/forum/admin_create_category_screen.dart';
import 'package:frontend/screens/forum/ucp_drafts_screen.dart';
import 'package:frontend/widgets/forum_table_widget.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({'jwt_token': 'fake_admin_token'});
  });

  group('Kiểm thử Luồng UX Form, Xem Trước và Quản Lý Bản Nháp', () {
    testWidgets('Bước 1: Kiểm tra tính năng thu gọn / mở rộng dải chọn Icon (Collapsible)',
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

      // Mặc định: Thanh thu gọn, hiển thị Text và nhãn "Không dùng", chưa hiển thị dải icon
      expect(find.text('Biểu tượng Chuyên mục hoặc Lớp học mới'), findsOneWidget);
      expect(find.text('Không dùng'), findsOneWidget);
      expect(find.text('🔥'), findsNothing);
      expect(find.byIcon(Icons.keyboard_arrow_down), findsOneWidget);

      // Bấm vào thanh để mở rộng
      await tester.tap(find.text('Biểu tượng Chuyên mục hoặc Lớp học mới'));
      await tester.pumpAndSettle();

      // Trạng thái mở rộng: Mũi tên hướng lên, hiển thị đủ các radio icon
      expect(find.byIcon(Icons.keyboard_arrow_up), findsOneWidget);
      expect(find.text('🔥'), findsOneWidget);
      expect(find.text('⭐'), findsOneWidget);

      // Chọn icon sao ⭐
      await tester.tap(find.text('⭐'));
      await tester.pumpAndSettle();

      // Bấm thu gọn lại
      await tester.tap(find.text('Biểu tượng Chuyên mục hoặc Lớp học mới'));
      await tester.pumpAndSettle();

      // Thanh đã thu gọn và hiển thị preview icon ⭐ đã chọn
      expect(find.byIcon(Icons.keyboard_arrow_down), findsOneWidget);
      expect(find.text('⭐'), findsOneWidget);
      expect(find.text('🔥'), findsNothing);
    });

    testWidgets('Bước 2: Kiểm tra nút "Xem trước" tái sử dụng ForumTableWidget',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 1024);
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
                child: AdminCreateCategoryScreen(),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Bấm "Xem trước" khi chưa nhập tiêu đề -> Bị chặn và báo lỗi
      await tester.tap(find.text('Xem trước'));
      await tester.pumpAndSettle();
      expect(find.byType(Dialog), findsNothing);

      // 2. Nhập tiêu đề
      final titleFieldFinder = find.byType(TextField).first;
      await tester.enterText(titleFieldFinder, 'Chuyên mục Xem Trước Test');
      await tester.pumpAndSettle();

      // 3. Bấm "Xem trước" -> Mở Dialog chứa ForumTableWidget
      await tester.tap(find.text('Xem trước'));
      await tester.pumpAndSettle();

      expect(find.byType(Dialog), findsOneWidget);
      expect(find.text('Xem trước: Chuyên mục 1'), findsOneWidget);

      // Xác nhận ForumTableWidget được tái sử dụng chuẩn xác trong modal
      expect(find.byType(ForumTableWidget), findsOneWidget);
      expect(find.descendant(of: find.byType(Dialog), matching: find.text('Chuyên mục Xem Trước Test')), findsOneWidget);
      expect(find.text('Chủ đề'), findsOneWidget);
      expect(find.text('Bài viết'), findsOneWidget);
      expect(find.text('Bài cuối'), findsOneWidget);

      // Đảm bảo dữ liệu tạm thời chưa bị lưu vào ForumCategoryProvider
      expect(
        categoryProvider.group1Categories.any((c) => c.title == 'Chuyên mục Xem Trước Test'),
        isFalse,
      );

      // 4. Bấm "Đóng xem trước"
      await tester.tap(find.text('Đóng xem trước'));
      await tester.pumpAndSettle();
      expect(find.byType(Dialog), findsNothing);
    });

    testWidgets('Bước 3: Kiểm tra luồng "Lưu bản nháp", DraftProvider và màn hình UcpDraftsScreen',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 1024);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final draftProvider = DraftProvider();

      final testRouter = GoRouter(
        initialLocation: '/forum/create-category',
        routes: [
          GoRoute(
            path: '/forum/create-category',
            builder: (context, state) => const Scaffold(
              body: SingleChildScrollView(
                child: AdminCreateCategoryScreen(),
              ),
            ),
          ),
          GoRoute(
            path: '/forum/ucp/drafts',
            builder: (context, state) => const Scaffold(
              body: SingleChildScrollView(
                child: UcpDraftsContent(),
              ),
            ),
          ),
        ],
      );

      await tester.pumpWidget(
        ChangeNotifierProvider<DraftProvider>.value(
          value: draftProvider,
          child: MaterialApp.router(
            routerConfig: testRouter,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Xác nhận trên form AdminCreateCategoryScreen KHÔNG CÒN nút "Lưu bản nháp"
      expect(find.text('Lưu bản nháp'), findsNothing);
      expect(find.text('Xem trước'), findsOneWidget);
      expect(find.text('Xác nhận'), findsOneWidget);

      // 2. Thêm bản nháp vào DraftProvider và chuyển sang /forum/ucp/drafts
      draftProvider.setForumDraftsForTesting([
        const ForumDraftItem(
          id: 1,
          username: 'ngocanh1',
          topicId: 10,
          topicTitle: 'Chuyên Mục Huyền Học',
          title: 'Bản nháp Chuyên Mục Huyền Học',
          content: 'Nội dung bản nháp mô tả',
          createdAt: '2026-10-30 09:00:00',
        ),
      ]);
      testRouter.go('/forum/ucp/drafts');
      await tester.pumpAndSettle();

      // 3. Kiểm tra DraftProvider đã lưu trữ bản nháp
      expect(draftProvider.forumDrafts.length, equals(1));
      expect(draftProvider.forumDrafts.first.title, equals('Bản nháp Chuyên Mục Huyền Học'));

      // 4. Kiểm tra màn hình đã chuyển hướng tới /forum/ucp/drafts hiển thị chuẩn Hình 4 & Hình 6
      expect(find.byType(UcpDraftsContent), findsOneWidget);
      expect(find.text('Tiêu đề nháp'), findsOneWidget);
      expect(find.text('Đã lưu vào ngày'), findsOneWidget);
      expect(find.text('Chọn'), findsOneWidget);
      expect(find.textContaining('Bản nháp Chuyên Mục Huyền Học'), findsWidgets);
      expect(find.text('Nạp bản nháp • Xem/sửa'), findsOneWidget);
      expect(find.text('Xóa đánh dấu'), findsOneWidget);
      // Khối thông báo tĩnh "Không có bản nháp nào được lưu." chưa xuất hiện vì đã có dữ liệu
      expect(find.text('Không có bản nháp nào được lưu.'), findsNothing);

      // 5. Khi xóa hết: danh sách trống, hiển thị lại chuẩn Hình 8
      draftProvider.setForumDraftsForTesting([]);
      await tester.pumpAndSettle();

      expect(draftProvider.forumDrafts.isEmpty, isTrue);
      expect(find.text('Không có bản nháp nào được lưu.'), findsOneWidget);
      expect(find.text('Tiêu đề nháp'), findsNothing);
    });
  });
}
