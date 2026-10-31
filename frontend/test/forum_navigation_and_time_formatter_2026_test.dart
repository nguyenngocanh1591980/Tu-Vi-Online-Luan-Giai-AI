import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/utils/time_formatter.dart';
import 'package:frontend/models/forum_topic_model.dart';
import 'package:frontend/widgets/breadcrumb_widget.dart';
import 'package:frontend/widgets/main_navigation_bar.dart';
import 'package:frontend/providers/auth_provider.dart';
import 'package:frontend/providers/wallet_provider.dart';
import 'package:frontend/providers/forum_stats_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('1. TimeFormatter 2026 Standards Tests', () {
    test('Null hoặc chuỗi rỗng không bao giờ trả về "null"', () {
      final resNull = TimeFormatter.formatVietnamTime(null);
      final resEmpty = TimeFormatter.formatVietnamTime('');
      final resWhitespace = TimeFormatter.formatVietnamTime('   ');
      final resLiteralNull = TimeFormatter.formatVietnamTime('null');

      expect(resNull, isNot(contains('null')));
      expect(resEmpty, isNot(contains('null')));
      expect(resWhitespace, isNot(contains('null')));
      expect(resLiteralNull, isNot(contains('null')));

      // Phải có định dạng HH:mm, dd/MM/yy
      final regex = RegExp(r'^\d{2}:\d{2}, \d{2}/\d{2}/\d{2}$');
      expect(regex.hasMatch(resNull), isTrue);
      expect(regex.hasMatch(resEmpty), isTrue);
    });

    test('Chuyển đổi chuỗi ISO 8601 sang múi giờ UTC+7 chuẩn xác', () {
      // 2026-10-29 08:00:00 UTC = 15:00:00 UTC+7 ngày 29/10/26
      const isoUtc = '2026-10-29T08:00:00Z';
      final formatted = TimeFormatter.formatVietnamTime(isoUtc);
      expect(formatted, equals('15:00, 29/10/26'));
    });

    test('Chuyển đổi số timestamp millis sang UTC+7 chuẩn xác', () {
      final dtUtc = DateTime.utc(2026, 10, 29, 3, 30); // 10:30 UTC+7
      final millis = dtUtc.millisecondsSinceEpoch;
      final formatted = TimeFormatter.formatVietnamTime(millis);
      expect(formatted, equals('10:30, 29/10/26'));
    });

    test('Chuyển đổi chuỗi số timestamp', () {
      final dtUtc = DateTime.utc(2026, 5, 1, 1, 15); // 08:15 UTC+7 ngày 01/05/26
      final millisStr = dtUtc.millisecondsSinceEpoch.toString();
      final formatted = TimeFormatter.formatVietnamTime(millisStr);
      expect(formatted, equals('08:15, 01/05/26'));
    });
  });

  group('2. ForumTopicItem toMap() Serialization Tests', () {
    test('toMap() bảo toàn trường "time" từ createdAt hoặc lastTime', () {
      final topic = ForumTopicItem(
        id: 'tp-1',
        title: 'Chủ đề kiểm thử',
        type: 'chu_de',
        author: 'Admin',
        createdAt: '14:20, 29/10/26',
        lastTime: '14:20, 29/10/26',
      );

      final map = topic.toMap();
      expect(map['time'], isNotNull);
      expect(map['time'], equals('14:20, 29/10/26'));
      expect(map['author'], equals('Admin'));
    });
  });

  group('3. BreadcrumbWidget & Menu Liên kết Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({'jwt_token': 'test_token'});
    });

    testWidgets('Menu Liên kết hiển thị đầy đủ 10 mục điều hướng bao gồm Trang chủ Diễn đàn', (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final router = GoRouter(
        initialLocation: '/forum/category/thong-bao-su-kien',
        routes: [
          GoRoute(
            path: '/forum/category/:slug',
            builder: (context, state) => const Scaffold(
              body: Column(
                children: [
                  BreadcrumbWidget(),
                  Text('Category Page'),
                ],
              ),
            ),
          ),
          GoRoute(path: '/forum', builder: (context, state) => const Text('Forum Home')),
          GoRoute(path: '/forum/new-posts', builder: (context, state) => const Text('New Posts')),
          GoRoute(path: '/forum/recent-posts', builder: (context, state) => const Text('Recent Posts')),
          GoRoute(path: '/forum/your-posts', builder: (context, state) => const Text('Your Posts')),
          GoRoute(path: '/forum/unread-posts', builder: (context, state) => const Text('Unread Posts')),
          GoRoute(path: '/forum/unanswered-posts', builder: (context, state) => const Text('Unanswered Posts')),
          GoRoute(path: '/forum/search', builder: (context, state) => const Text('Search')),
          GoRoute(path: '/forum/faq', builder: (context, state) => const Text('FAQ')),
          GoRoute(path: '/forum/members', builder: (context, state) => const Text('Members')),
          GoRoute(path: '/forum/team', builder: (context, state) => const Text('Team')),
        ],
      );

      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
        ),
      );
      await tester.pumpAndSettle();

      // Kiểm tra thanh breadcrumb hiển thị đúng
      expect(find.text('Trang chủ'), findsOneWidget);
      expect(find.text('Diễn đàn'), findsOneWidget);
      expect(find.text('Thông báo - Sự kiện'), findsOneWidget);

      // Tìm nút "Liên kết"
      final linkBtn = find.text('Liên kết');
      expect(linkBtn, findsOneWidget);

      // Mở menu Liên kết
      await tester.tap(linkBtn);
      await tester.pumpAndSettle();

      // Kiểm tra các tùy chọn menu hiện ra
      expect(find.text('Trang chủ Diễn đàn'), findsOneWidget);
      expect(find.text('Bài viết mới'), findsWidgets);
      expect(find.text('Bài gần đây'), findsWidgets);
      expect(find.text('Bài của bạn'), findsWidgets);
      expect(find.text('Bài chưa xem'), findsWidgets);
      expect(find.text('Bài chưa được trả lời'), findsWidgets);
      expect(find.text('Tìm kiếm'), findsWidgets);
      expect(find.text('Hỏi đáp'), findsWidgets);
      expect(find.text('Thành viên'), findsWidgets);
      expect(find.text('Chúng tôi'), findsWidgets);

      // Click vào "Trang chủ Diễn đàn"
      await tester.tap(find.text('Trang chủ Diễn đàn'));
      await tester.pumpAndSettle();

      expect(find.text('Forum Home'), findsOneWidget);
    });

    testWidgets('Breadcrumb hiển thị chuẩn xác khi vào chi tiết bài viết /forum/post/:id', (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final router = GoRouter(
        initialLocation: '/forum/post/100?categorySlug=thong-bao-su-kien',
        routes: [
          GoRoute(
            path: '/forum/post/:id',
            builder: (context, state) => const Scaffold(
              body: Column(
                children: [
                  BreadcrumbWidget(),
                  Text('Post Detail Screen'),
                ],
              ),
            ),
          ),
          GoRoute(path: '/forum', builder: (context, state) => const Text('Forum Home')),
          GoRoute(path: '/forum/category/:slug', builder: (context, state) => const Text('Category Screen')),
        ],
      );

      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Trang chủ'), findsOneWidget);
      expect(find.text('Diễn đàn'), findsOneWidget);
      expect(find.text('Thông báo - Sự kiện'), findsOneWidget);
      expect(find.text('Chi tiết bài viết'), findsOneWidget);
    });
  });

  group('4. MainNavigationBar Dropdown Diễn đàn ▼ Tests', () {
    testWidgets('Dropdown Diễn đàn ▼ chứa mục Trang chủ Diễn đàn và điều hướng tới /forum', (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const Scaffold(
              body: MainNavigationBar(),
            ),
          ),
          GoRoute(
            path: '/forum',
            builder: (context, state) => const Scaffold(
              body: Text('Forum HomeScreen Arrived'),
            ),
          ),
        ],
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AuthProvider()),
            ChangeNotifierProvider(create: (_) => WalletProvider()),
            ChangeNotifierProvider(create: (_) => ForumStatsProvider()),
          ],
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tìm nút ▼ của menu Diễn đàn
      final arrowDownFinder = find.text('▼');
      expect(arrowDownFinder, findsWidgets);

      // Nhấn vào mũi tên thứ 2 (menu Diễn đàn)
      await tester.tap(arrowDownFinder.last);
      await tester.pumpAndSettle();

      // Kiểm tra sự xuất hiện của mục Trang chủ Diễn đàn
      expect(find.text('Trang chủ Diễn đàn'), findsOneWidget);

      // Nhấn chọn Trang chủ Diễn đàn
      await tester.tap(find.text('Trang chủ Diễn đàn'));
      await tester.pumpAndSettle();

      // Xác nhận điều hướng thành công ra /forum
      expect(find.text('Forum HomeScreen Arrived'), findsOneWidget);
    });
  });
}
