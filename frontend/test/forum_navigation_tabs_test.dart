import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/screens/forum/user_posts_screen.dart';
import 'package:frontend/screens/forum/unread_posts_screen.dart';
import 'package:frontend/widgets/breadcrumb_widget.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Kiểm thử điều hướng & Breadcrumb & Boxed Layout 1024px dính khít Header', () {
    testWidgets('Xác nhận Boxed Layout 1024px và dính khít Header (margin top: 0, bottom: 24) cho UserPostsScreen',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 1024);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: UserPostsScreen(),
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

    testWidgets('Xác nhận Boxed Layout 1024px và dính khít Header (margin top: 0, bottom: 24) cho UnreadPostsScreen',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 1024);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: UnreadPostsScreen(),
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

    testWidgets('Kiểm tra Breadcrumb và Router cho /forum/your-posts và /forum/unread-posts',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 1024);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final testRouter = GoRouter(
        initialLocation: '/forum/your-posts',
        routes: [
          GoRoute(
            path: '/forum/your-posts',
            builder: (context, state) => const Scaffold(
              body: Column(
                children: [
                  BreadcrumbWidget(),
                  Expanded(child: UserPostsScreen()),
                ],
              ),
            ),
          ),
          GoRoute(
            path: '/forum/unread-posts',
            builder: (context, state) => const Scaffold(
              body: Column(
                children: [
                  BreadcrumbWidget(),
                  Expanded(child: UnreadPostsScreen()),
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

      // Kiểm tra breadcrumb "Trang chủ » Diễn đàn » Bài của bạn"
      final breadcrumbFinder = find.byType(BreadcrumbWidget);
      expect(find.descendant(of: breadcrumbFinder, matching: find.text('Trang chủ')), findsOneWidget);
      expect(find.descendant(of: breadcrumbFinder, matching: find.text('Diễn đàn')), findsOneWidget);
      expect(find.descendant(of: breadcrumbFinder, matching: find.text('Bài của bạn')), findsWidgets);

      // Chuyển sang /forum/unread-posts
      testRouter.go('/forum/unread-posts');
      await tester.pumpAndSettle();

      expect(find.descendant(of: breadcrumbFinder, matching: find.text('Bài chưa xem')), findsWidgets);
      expect(find.byType(UnreadPostsScreen), findsOneWidget);
    });
  });
}
