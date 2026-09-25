import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/screens/forum/unanswered_posts_screen.dart';
import 'package:frontend/screens/forum/search_screen.dart';
import 'package:frontend/widgets/breadcrumb_widget.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Kiểm thử màn hình "Bài chưa được trả lời" (UnansweredPostsScreen) - Bảo toàn 100% Hình 2', () {
    testWidgets('Xác nhận Boxed Layout 1024px, dính khít Header, 25 chủ đề và dòng 4 highlight nền vàng',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 1024);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: UnansweredPostsScreen(),
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

      // 3. Khối Card tổng dính khít Header margin: top 0, bottom 24 và nền #1E2640
      final cardFinder = find.descendant(
        of: cbFinder,
        matching: find.byType(Container),
      );
      final Container card = tester.widget(cardFinder.first);
      expect(card.margin, equals(const EdgeInsets.only(top: 0, bottom: 24.0)));
      final BoxDecoration dec = card.decoration as BoxDecoration;
      expect(dec.color, equals(const Color(0xFF1E2640)));
      expect(dec.borderRadius, equals(const BorderRadius.vertical(bottom: Radius.circular(8))));

      // 4. Header & Tìm kiếm & Cụm phân trang
      expect(find.text('Bài chưa được trả lời'), findsOneWidget);
      expect(find.text('< Quay về tìm kiếm nâng cao'), findsWidgets);
      expect(find.text('Tìm trong những kết quả'), findsOneWidget);
      expect(find.text('Đã tìm thấy nhiều hơn 1000 kết quả'), findsWidgets);

      // 5. Header bảng
      expect(find.text('Chủ đề'), findsOneWidget);
      expect(find.text('Trả lời'), findsOneWidget);
      expect(find.text('Xem'), findsOneWidget);
      expect(find.text('Bài cuối'), findsOneWidget);

      // 6. Các chủ đề từ Hình 2
      expect(find.text('Nhật nguyệt tịnh minh Bát toạ lương ninh'), findsOneWidget);
      expect(find.text('Xin các cao nhân luận giúp lá số Liêm Trinh - Phá Quân tại Dậu [mệnh tại Dậu...]'), findsOneWidget);
      expect(find.text('Phụ nữ mang thai có nên Cắm phòng cúng?'), findsOneWidget);
      expect(find.text('Khi nào cần thay đổi thói quen ăn uống và vận động?'), findsOneWidget);
      expect(find.text('Mệnh nguyên thủ quốc gia'), findsOneWidget);
      expect(find.text('Có những ngày...'), findsOneWidget);

      // 7. Xác nhận dòng thứ 4 được bôi highlight nền vàng hổ phách nổi bật
      final highlightRowFinder = find.byWidgetPredicate(
        (w) =>
            w is Container &&
            w.decoration is BoxDecoration &&
            (w.decoration as BoxDecoration).color == const Color(0xFF3E3418),
      );
      expect(highlightRowFinder, findsOneWidget);

      // 8. Đúng 3 mục Khám phá thêm của Hình 2
      expect(find.text('Khám phá thêm'), findsOneWidget);
      expect(find.text('Nhà cung cấp dịch vụ diễn đàn và trò chuyện'), findsOneWidget);
      expect(find.text('Thiết kế và nghệ thuật thị giác'), findsOneWidget);
      expect(find.text('Thuốc nhuộm & Chất nhuộm'), findsOneWidget);
    });
  });

  group('Kiểm thử màn hình "Tìm kiếm" (SearchScreen) - Bảo toàn 100% Hình 4', () {
    testWidgets('Xác nhận Boxed Layout 1024px, 2 Tabs, Khung Google Cải tiến và 3 mục Khám phá thêm',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 1024);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: SearchScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Scaffold nền #F0F2F5
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

      // 3. Khối Card tổng dính khít Header margin: top 0, bottom 24 và nền #1E2640
      final cardFinder = find.descendant(
        of: cbFinder,
        matching: find.byType(Container),
      );
      final Container card = tester.widget(cardFinder.first);
      expect(card.margin, equals(const EdgeInsets.only(top: 0, bottom: 24.0)));

      // 4. Header & 2 Tabs
      expect(find.text('Tìm kiếm'), findsWidgets);
      expect(find.text('Tìm kiếm nâng cao'), findsOneWidget);

      // 5. Khung tìm kiếm Google Cải tiến
      expect(find.text('CẢI TIẾN'), findsOneWidget);
      expect(
        find.byWidgetPredicate((w) => w is RichText && w.text.toPlainText().contains('Google')),
        findsOneWidget,
      );

      // 6. Đúng 3 mục Khám phá thêm của Hình 4
      expect(find.text('Khám phá thêm'), findsOneWidget);
      expect(find.text('Tạo Thiết Kế'), findsOneWidget);
      expect(find.text('Phối Màu Nhuộm'), findsOneWidget);
      expect(find.text('Nâng Cấp OS'), findsOneWidget);
    });
  });

  group('Kiểm thử Router và Breadcrumb', () {
    testWidgets('Điều hướng và Breadcrumb cho /forum/unanswered-posts và /forum/search',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 1024);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final testRouter = GoRouter(
        initialLocation: '/forum/unanswered-posts',
        routes: [
          GoRoute(
            path: '/forum/unanswered-posts',
            builder: (context, state) => const Scaffold(
              body: Column(
                children: [
                  BreadcrumbWidget(),
                  Expanded(child: UnansweredPostsScreen()),
                ],
              ),
            ),
          ),
          GoRoute(
            path: '/forum/search',
            builder: (context, state) => const Scaffold(
              body: Column(
                children: [
                  BreadcrumbWidget(),
                  Expanded(child: SearchScreen()),
                ],
              ),
            ),
          ),
          GoRoute(
            path: '/forum',
            builder: (context, state) => const Scaffold(body: Text('Forum')),
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: testRouter,
        ),
      );
      await tester.pumpAndSettle();

      // Kiểm tra Breadcrumb "Trang chủ » Diễn đàn » Bài chưa được trả lời"
      final breadcrumbFinder = find.byType(BreadcrumbWidget);
      expect(find.descendant(of: breadcrumbFinder, matching: find.text('Trang chủ')), findsOneWidget);
      expect(find.descendant(of: breadcrumbFinder, matching: find.text('Diễn đàn')), findsOneWidget);
      expect(find.descendant(of: breadcrumbFinder, matching: find.text('Bài chưa được trả lời')), findsWidgets);

      // Chuyển sang /forum/search
      testRouter.go('/forum/search');
      await tester.pumpAndSettle();

      expect(find.descendant(of: breadcrumbFinder, matching: find.text('Tìm kiếm')), findsWidgets);
      expect(find.byType(SearchScreen), findsOneWidget);
    });
  });
}
