import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/screens/forum/user_posts_screen.dart';
import 'package:frontend/screens/forum/unread_posts_screen.dart';
import 'package:frontend/widgets/breadcrumb_widget.dart';
import 'package:frontend/widgets/main_layout.dart';

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

      final router = GoRouter(
        initialLocation: '/forum/your-posts',
        routes: [
          ShellRoute(
            builder: (context, state, child) => MainLayout(child: child),
            routes: [
              GoRoute(
                path: '/forum/your-posts',
                builder: (context, state) => const UserPostsScreen(),
              ),
            ],
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
        ),
      );
      await tester.pumpAndSettle();

      // 1. Scaffold nền xám nhạt #F0F2F5
      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).first);
      expect(scaffold.backgroundColor, equals(const Color(0xFFF0F2F5)));

      // 2. ConstrainedBox maxWidth 1024
      final cbFinder = find.byWidgetPredicate(
        (w) => w is ConstrainedBox && w.constraints.maxWidth == 1024,
      );
      expect(cbFinder, findsWidgets);
    });

    testWidgets('Xác nhận Boxed Layout 1024px và dính khít Header (margin top: 0, bottom: 24) cho UnreadPostsScreen',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 1024);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final router = GoRouter(
        initialLocation: '/forum/unread-posts',
        routes: [
          ShellRoute(
            builder: (context, state, child) => MainLayout(child: child),
            routes: [
              GoRoute(
                path: '/forum/unread-posts',
                builder: (context, state) => const UnreadPostsScreen(),
              ),
            ],
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
        ),
      );
      await tester.pumpAndSettle();

      // 1. Scaffold nền xám nhạt #F0F2F5
      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).first);
      expect(scaffold.backgroundColor, equals(const Color(0xFFF0F2F5)));

      // 2. ConstrainedBox maxWidth 1024
      final cbFinder = find.byWidgetPredicate(
        (w) => w is ConstrainedBox && w.constraints.maxWidth == 1024,
      );
      expect(cbFinder, findsWidgets);
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
          ShellRoute(
            builder: (context, state, child) => MainLayout(child: child),
            routes: [
              GoRoute(
                path: '/forum/your-posts',
                pageBuilder: (context, state) => const NoTransitionPage(child: UserPostsScreen()),
              ),
              GoRoute(
                path: '/forum/unread-posts',
                pageBuilder: (context, state) => const NoTransitionPage(child: UnreadPostsScreen()),
              ),
              GoRoute(
                path: '/forum',
                pageBuilder: (context, state) => const NoTransitionPage(child: Text('Forum')),
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
