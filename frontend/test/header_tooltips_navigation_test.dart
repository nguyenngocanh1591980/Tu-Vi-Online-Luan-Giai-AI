import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/widgets/main_navigation_bar.dart';
import 'package:frontend/providers/wallet_provider.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({
      'jwt_token': 'fake_jwt_token_123',
      'username': 'Gacon1980',
    });
  });

  Widget createTestWidget({required GoRouter router}) {
    return ChangeNotifierProvider<WalletProvider>(
      create: (_) => WalletProvider(),
      child: MaterialApp.router(
        routerConfig: router,
      ),
    );
  }

  group('Kiểm thử Tooltip Xanh Da Trời và Phím Tắt 4 Icon Header', () {
    testWidgets('Xác nhận 4 Tooltip tồn tại, có nền Xanh Da Trời (#00BFFF) và thông điệp chuẩn xác',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 1024);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final testRouter = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const Scaffold(
              appBar: PreferredSize(
                preferredSize: Size.fromHeight(60),
                child: MainNavigationBar(),
              ),
              body: Center(child: Text('Home Content')),
            ),
          ),
          GoRoute(
            path: '/forum/new-posts',
            builder: (context, state) => const Scaffold(body: Text('New Posts Screen')),
          ),
          GoRoute(
            path: '/forum/inbox',
            builder: (context, state) => const Scaffold(body: Text('Inbox Screen')),
          ),
        ],
      );

      await tester.pumpWidget(createTestWidget(router: testRouter));
      await tester.pumpAndSettle();

      // 1. Kiểm tra 4 Tooltip tồn tại
      final tooltipNewPostsFinder = find.byWidgetPredicate(
        (widget) => widget is Tooltip && widget.message == 'Bài viết mới',
      );
      final tooltipNotifyFinder = find.byWidgetPredicate(
        (widget) => widget is Tooltip && widget.message == 'Thông báo',
      );
      final tooltipMessagesFinder = find.byWidgetPredicate(
        (widget) => widget is Tooltip && widget.message == 'Tin nhắn',
      );
      final tooltipProfileFinder = find.byWidgetPredicate(
        (widget) => widget is Tooltip && widget.message == 'Thiết lập cá nhân',
      );

      expect(tooltipNewPostsFinder, findsOneWidget);
      expect(tooltipNotifyFinder, findsOneWidget);
      expect(tooltipMessagesFinder, findsOneWidget);
      expect(tooltipProfileFinder, findsOneWidget);

      // 2. Kiểm tra màu nền Tooltip là Xanh Da Trời (0xFF00BFFF)
      final Tooltip tooltipNewPosts = tester.widget(tooltipNewPostsFinder);
      final BoxDecoration dec = tooltipNewPosts.decoration as BoxDecoration;
      expect(dec.color, equals(const Color(0xFF00BFFF)));
      expect(tooltipNewPosts.textStyle?.color, equals(Colors.white));

      final Tooltip tooltipNotify = tester.widget(tooltipNotifyFinder);
      final BoxDecoration decNotify = tooltipNotify.decoration as BoxDecoration;
      expect(decNotify.color, equals(const Color(0xFF00BFFF)));

      final Tooltip tooltipMessages = tester.widget(tooltipMessagesFinder);
      final BoxDecoration decMessages = tooltipMessages.decoration as BoxDecoration;
      expect(decMessages.color, equals(const Color(0xFF00BFFF)));

      final Tooltip tooltipProfile = tester.widget(tooltipProfileFinder);
      final BoxDecoration decProfile = tooltipProfile.decoration as BoxDecoration;
      expect(decProfile.color, equals(const Color(0xFF00BFFF)));
    });

    testWidgets('Xác nhận phím tắt click Icon Tia Sét điều hướng trực tiếp sang /forum/new-posts',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 1024);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final testRouter = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const Scaffold(
              appBar: PreferredSize(
                preferredSize: Size.fromHeight(60),
                child: MainNavigationBar(),
              ),
              body: Center(child: Text('Home Content')),
            ),
          ),
          GoRoute(
            path: '/forum/new-posts',
            builder: (context, state) => const Scaffold(body: Text('New Posts Screen')),
          ),
          GoRoute(
            path: '/forum/inbox',
            builder: (context, state) => const Scaffold(body: Text('Inbox Screen')),
          ),
        ],
      );

      await tester.pumpWidget(createTestWidget(router: testRouter));
      await tester.pumpAndSettle();

      // Click vào Icon Tia Sét
      final flashIconFinder = find.byIcon(Icons.flash_on);
      expect(flashIconFinder, findsOneWidget);
      await tester.ensureVisible(flashIconFinder);
      await tester.pumpAndSettle();
      await tester.tap(flashIconFinder);
      await tester.pumpAndSettle();

      // Xác nhận đã điều hướng tới New Posts Screen
      expect(find.text('New Posts Screen'), findsOneWidget);
    });

    testWidgets('Xác nhận phím tắt click Icon Phong Bì điều hướng trực tiếp sang /forum/inbox (Hộp thư nhận)',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 1024);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final testRouter = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const Scaffold(
              appBar: PreferredSize(
                preferredSize: Size.fromHeight(60),
                child: MainNavigationBar(),
              ),
              body: Center(child: Text('Home Content')),
            ),
          ),
          GoRoute(
            path: '/forum/new-posts',
            builder: (context, state) => const Scaffold(body: Text('New Posts Screen')),
          ),
          GoRoute(
            path: '/forum/inbox',
            builder: (context, state) => const Scaffold(body: Text('Inbox Screen')),
          ),
        ],
      );

      await tester.pumpWidget(createTestWidget(router: testRouter));
      await tester.pumpAndSettle();

      // Click vào Icon Phong Bì (email_outlined)
      final emailIconFinder = find.byIcon(Icons.email_outlined);
      expect(emailIconFinder, findsOneWidget);
      await tester.ensureVisible(emailIconFinder);
      await tester.pumpAndSettle();
      await tester.tap(emailIconFinder);
      await tester.pumpAndSettle();

      // Xác nhận đã điều hướng tới Inbox Screen
      expect(find.text('Inbox Screen'), findsOneWidget);
    });

    testWidgets('Xác nhận click Icon Quả Chuông mở Panel Thông Báo',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 1024);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final testRouter = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const Scaffold(
              appBar: PreferredSize(
                preferredSize: Size.fromHeight(60),
                child: MainNavigationBar(),
              ),
              body: Center(child: Text('Home Content')),
            ),
          ),
        ],
      );

      await tester.pumpWidget(createTestWidget(router: testRouter));
      await tester.pumpAndSettle();

      // Click vào Icon Quả Chuông
      final bellIconFinder = find.byIcon(Icons.notifications_outlined);
      expect(bellIconFinder, findsOneWidget);
      await tester.ensureVisible(bellIconFinder);
      await tester.pumpAndSettle();
      await tester.tap(bellIconFinder);
      await tester.pumpAndSettle();

      // Xác nhận panel thông báo mở ra
      expect(find.text('THÔNG BÁO'), findsOneWidget);
      expect(find.text('Bạn không có thông báo'), findsOneWidget);
    });
  });
}
