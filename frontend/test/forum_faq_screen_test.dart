import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/screens/forum/faq_screen.dart';
import 'package:frontend/widgets/breadcrumb_widget.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Kiểm thử màn hình Hỏi đáp (FAQ) Boxed 1024px & Thanh trừng quảng cáo', () {
    testWidgets('Xác nhận Boxed Layout 1024px và dính khít Header (margin top: 0, bottom: 24) cho FaqScreen',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 1024);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: FaqScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Scaffold nền xám nhạt #F0F2F5
      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, equals(const Color(0xFFF0F2F5)));

      // 2. ConstrainedBox maxWidth 1024
      final cbFinder = find.descendant(
        of: find.byType(Center),
        matching: find.byType(ConstrainedBox),
      );
      expect(cbFinder, findsWidgets);
      final ConstrainedBox cb = tester.widget(cbFinder.first);
      expect(cb.constraints.maxWidth, equals(1024));

      // 3. Khối Card nền #1E2640, margin: top 0, bottom 24 và bo góc đáy 8
      final cardFinder = find.descendant(
        of: cbFinder,
        matching: find.byType(Container),
      );
      final Container card = tester.widget(cardFinder.first);
      expect(card.margin, equals(const EdgeInsets.only(top: 0, bottom: 24.0)));
      final BoxDecoration dec = card.decoration as BoxDecoration;
      expect(dec.color, equals(const Color(0xFF1E2640)));
      expect(dec.borderRadius, equals(const BorderRadius.vertical(bottom: Radius.circular(8))));
    });

    testWidgets('Xác nhận Thanh Trừng Quảng Cáo 100% (Không chứa bất kỳ text quảng cáo rác nào)',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 1024);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: FaqScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // 8 chuỗi quảng cáo cấm tuyệt đối không xuất hiện
      expect(find.text('Tìm kiếm bài viết'), findsNothing);
      expect(find.text('Tạo Email mới'), findsNothing);
      expect(find.text('Học Tiếng Anh'), findsNothing);
      expect(find.text('Mua Lịch Mới'), findsNothing);
      expect(find.text('Tải Trình Duyệt'), findsNothing);
      expect(find.text('Tra cứu xã hội'), findsNothing);
      expect(find.text('Chọn Tour ASEAN'), findsNothing);
      expect(find.text('Viết mã Code'), findsNothing);
    });

    testWidgets('Xác nhận Bảo Toàn Mục Lục và Các Nhóm Chủ Đề FAQ',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 1024);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: FaqScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Tiêu đề khối & Tiêu đề Mục lục
      expect(find.text('Những câu hỏi thường gặp (FAQ)'), findsOneWidget);
      expect(find.text('MỤC LỤC CÁC CHỦ ĐỀ HỎI ĐÁP'), findsOneWidget);

      // Các nhóm chủ đề lớn (xuất hiện cả ở mục lục và tiêu đề phân nhóm)
      expect(find.text('Các vấn đề khi đăng nhập và đăng ký'), findsWidgets);
      expect(find.text('Các thiết lập và tùy chọn người dùng'), findsWidgets);
      expect(find.text('Đăng bài viết'), findsWidgets);
      expect(find.text('Các mức độ định dạng và loại bài viết'), findsWidgets);
      expect(find.text('Vai trò người dùng và nhóm'), findsWidgets);
      expect(find.text('Bạn bè và kẻ thù'), findsWidgets);
      expect(find.text('Theo dõi và đánh dấu'), findsWidgets);
      expect(find.text('Tập tin đính kèm'), findsWidgets);
      expect(find.text('Tin nhắn cá nhân'), findsWidgets);
      expect(find.text('Thông báo'), findsWidgets);
      expect(find.text('Lưu trữ thông tin và Bản quyền'), findsWidgets);

      // Nút lên trên
      expect(find.text('Lên trên'), findsWidgets);

      // Chân trang phpBB
      expect(find.text('Powered by phpBB® Forum Software © phpBB Limited'), findsOneWidget);
      expect(find.text('Bản quyền tiếng Việt bởi vietphpbb.org'), findsOneWidget);
    });

    testWidgets('Kiểm tra Breadcrumb và điều hướng router cho /forum/faq',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 1024);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final testRouter = GoRouter(
        initialLocation: '/forum/faq',
        routes: [
          GoRoute(
            path: '/forum',
            builder: (context, state) => const Scaffold(body: Text('Forum Home Screen')),
          ),
          GoRoute(
            path: '/forum/faq',
            builder: (context, state) => const Scaffold(
              body: Column(
                children: [
                  BreadcrumbWidget(),
                  Expanded(child: FaqScreen()),
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

      // Kiểm tra breadcrumb: 'Diễn đàn' và 'Hỏi đáp'
      expect(find.text('Hỏi đáp'), findsWidgets);
      expect(find.text('Diễn đàn'), findsWidgets);
    });
  });
}
