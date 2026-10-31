import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/screens/forum/category_topics_screen.dart';
import 'package:frontend/screens/forum/post_detail_screen.dart';
import 'package:frontend/services/auth_service.dart';
import 'package:frontend/widgets/forum_table_widget.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('1. Bóc Tách Sự Kiện Click & HitTest Độc Lập Trên Toàn Bộ Danh Sách (Hình 5)', () {
    testWidgets('Xác nhận hàng không bị bọc InkWell tổng và Khu vực Thống kê (Hình 2) hoàn toàn tĩnh không click', (tester) async {
      tester.view.physicalSize = const Size(1280, 3200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      String? tappedCategory;
      final mockForums = [
        {
          'id': '1',
          'title': 'Thông báo - Sự kiện',
          'description': 'Thông báo chính thức của Ban quản trị diễn đàn Lý Số Việt Nam',
          'topics': 251,
          'posts': 846,
          'lastPost': {
            'postId': '101',
            'title': 'TL: Thay đổi về nâng cấp trìn...',
            'author': 'nncuong',
            'authorColor': const Color(0xFFEF5350),
            'time': '14:03, 28/11/25',
          },
        },
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ForumTableWidget(
              headerTitle: 'Chuyên mục 1',
              forums: mockForums,
              onCategoryTap: (context, title) {
                tappedCategory = title;
              },
            ),
          ),
        ),
      );

      // 1. Bấm vào text '251' (Chủ đề) hoặc '846' (Bài viết) -> KHÔNG kích hoạt categoryTap
      tappedCategory = null;
      await tester.tap(find.text('251'));
      await tester.pumpAndSettle();
      expect(tappedCategory, isNull, reason: 'Khu vực thống kê Chủ đề (Hình 2) không được phép bấm');

      await tester.tap(find.text('846'));
      await tester.pumpAndSettle();
      expect(tappedCategory, isNull, reason: 'Khu vực thống kê Bài viết (Hình 2) không được phép bấm');

      // 2. Bấm vào thời gian '14:03, 28/11/25' (text tĩnh ngoài vùng bấm) -> KHÔNG kích hoạt categoryTap
      await tester.tap(find.text('14:03, 28/11/25'));
      await tester.pumpAndSettle();
      expect(tappedCategory, isNull, reason: 'Thời gian là text tĩnh ngoài vùng bấm');

      // 3. Bấm vào Text Tiêu đề chuyên mục (Hình 1) -> Mở danh sách chủ đề
      await tester.tap(find.text('Thông báo - Sự kiện'));
      await tester.pumpAndSettle();
      expect(tappedCategory, equals('Thông báo - Sự kiện'), reason: 'Click tiêu đề chuyên mục (Hình 1) phải mở danh sách chủ đề');

      // 4. Bấm vào Icon chuyên mục (Hình 1) -> Mở danh sách chủ đề
      tappedCategory = null;
      final iconFinder = find.byWidgetPredicate(
        (w) => w is Icon && w.icon == Icons.description_outlined,
      );
      expect(iconFinder, findsOneWidget);
      await tester.tap(iconFinder);
      await tester.pumpAndSettle();
      expect(tappedCategory, equals('Thông báo - Sự kiện'), reason: 'Click Icon chuyên mục (Hình 1) phải mở danh sách chủ đề');
    });

    testWidgets('Xác nhận 2 Link độc lập tại Bài cuối (Hình 3: Tiêu đề bài, Hình 4: Nick thành viên)', (tester) async {
      tester.view.physicalSize = const Size(1280, 3200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final mockForums = [
        {
          'id': '1',
          'title': 'Thông báo - Sự kiện',
          'description': 'Tin tức BQT',
          'topics': 10,
          'posts': 20,
          'lastPost': {
            'postId': '99',
            'title': 'TL: Thay đổi về nâng cấp trìn...',
            'author': 'nncuong',
            'authorColor': const Color(0xFFEF5350),
            'time': '14:03, 28/11/25',
          },
        },
      ];

      String? pushedRoute;
      final testRouter = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => Scaffold(
              body: ForumTableWidget(
                headerTitle: 'Thông báo',
                forums: mockForums,
              ),
            ),
          ),
          GoRoute(
            path: '/forum/post/:id',
            builder: (context, state) {
              pushedRoute = state.uri.toString();
              return Text('Post: ${state.pathParameters['id']}');
            },
          ),
          GoRoute(
            path: '/forum/member/:username',
            builder: (context, state) {
              pushedRoute = state.uri.toString();
              return Text('Member: ${state.pathParameters['username']}');
            },
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: testRouter,
        ),
      );
      await tester.pumpAndSettle();

      // Tìm đúng RichText chứa nội dung bài cuối
      final richTextFinder = find.byWidgetPredicate(
        (w) => w is RichText && w.text.toPlainText().contains('TL: Thay đổi về nâng cấp trìn...'),
      );
      expect(richTextFinder, findsOneWidget);

      final RichText richText = tester.widget(richTextFinder);
      final TextSpan span = richText.text as TextSpan;
      expect(span.children, isNotNull);

      // 1. TextSpan Tiêu đề bài (Hình 3)
      final titleSpan = span.children!.whereType<TextSpan>().firstWhere(
        (s) => s.text != null && s.text!.contains('TL: Thay đổi về nâng cấp trìn...'),
      );
      expect(titleSpan.recognizer, isA<TapGestureRecognizer>());
      (titleSpan.recognizer as TapGestureRecognizer).onTap!();
      await tester.pumpAndSettle();
      expect(pushedRoute, equals('/forum/post/99'), reason: 'Click tiêu đề bài (Hình 3) nhảy tới chi tiết bài viết');

      // Pop quay lại trang chủ bảng diễn đàn
      testRouter.pop();
      await tester.pumpAndSettle();

      // 2. TextSpan Tác giả (Hình 4)
      final freshRichText = tester.widget<RichText>(richTextFinder);
      final freshSpan = freshRichText.text as TextSpan;
      final authorSpan = freshSpan.children!.whereType<TextSpan>().firstWhere(
        (s) => s.text == 'nncuong',
      );
      expect(authorSpan.recognizer, isA<TapGestureRecognizer>());
      (authorSpan.recognizer as TapGestureRecognizer).onTap!();
      await tester.pumpAndSettle();
      expect(pushedRoute, equals('/forum/member/nncuong'), reason: 'Click tên tác giả (Hình 4) nhảy tới trang hồ sơ thành viên');
    });
  });

  group('2. Phân Quyền RBAC Frontend: Chuyên Mục "Thông báo - Sự kiện" vs Các Chuyên Mục Khác', () {
    testWidgets('User thường (hoặc Guest) vào "Thông báo - Sự kiện": Ẩn các nút "Chủ đề mới" và "Trả lời" (Chỉ xem)', (tester) async {
      tester.view.physicalSize = const Size(1280, 3200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      SharedPreferences.setMockInitialValues({
        'jwt_token': 'user_token',
        'role': 'User',
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: CategoryTopicsScreen(key: ValueKey('user_view'), slug: 'thong-bao-su-kien'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Nút "Chủ đề mới" (hoặc "Tạo chủ đề mới") phải bị ẩn hoàn toàn
      expect(find.byKey(const ValueKey('btn_new_topic')), findsNothing);
      expect(find.text('Chủ đề mới'), findsNothing);

      // Nút "Trả lời" hành động phải bị ẩn hoàn toàn (không tính cột header của bảng)
      expect(find.byKey(const ValueKey('btn_reply_topic')), findsNothing);
    });

    testWidgets('Admin vào "Thông báo - Sự kiện": Hiển thị đầy đủ nút "Chủ đề mới" và "Trả lời"', (tester) async {
      tester.view.physicalSize = const Size(1280, 3200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      SharedPreferences.setMockInitialValues({
        'jwt_token': 'admin_token',
        'role': 'Admin',
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: CategoryTopicsScreen(key: ValueKey('admin_view'), slug: 'thong-bao-su-kien'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Admin có toàn quyền -> Hiển thị cả 2 nút
      expect(find.byKey(const ValueKey('btn_new_topic')), findsWidgets);
      expect(find.text('Chủ đề mới'), findsWidgets);

      expect(find.byKey(const ValueKey('btn_reply_topic')), findsWidgets);
    });

    testWidgets('User thường vào chuyên mục thảo luận khác (ví dụ "Kiến thức Cơ bản"): Hiển thị nút bình thường', (tester) async {
      tester.view.physicalSize = const Size(1280, 3200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      SharedPreferences.setMockInitialValues({
        'jwt_token': 'user_token',
        'role': 'User',
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: CategoryTopicsScreen(key: ValueKey('user_co_ban'), slug: 'kien-thuc-co-ban'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Các chuyên mục khác user thường được tương tác bình thường
      expect(find.byKey(const ValueKey('btn_new_topic')), findsWidgets);
      expect(find.text('Chủ đề mới'), findsWidgets);
      expect(find.byKey(const ValueKey('btn_reply_topic')), findsWidgets);
    });

    testWidgets('PostDetailScreen trong "Thông báo - Sự kiện": User thường không có nút Trả lời, Admin có nút Trả lời', (tester) async {
      tester.view.physicalSize = const Size(1280, 3200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      // 1. Kiểm tra với User thường
      SharedPreferences.setMockInitialValues({
        'jwt_token': 'user_token',
        'role': 'User',
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PostDetailScreen(key: ValueKey('user_post'), id: '1'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('btn_post_reply')), findsNothing);

      // 2. Kiểm tra với Admin
      SharedPreferences.setMockInitialValues({
        'jwt_token': 'admin_token',
        'role': 'Admin',
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PostDetailScreen(key: ValueKey('admin_post'), id: '1'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('btn_post_reply')), findsOneWidget);
    });
  });

  group('3. AuthService State & RBAC Logic Verification', () {
    test('AuthService.getRole và AuthService.isAdmin hoạt động đúng theo token và RAM/prefs', () async {
      final auth = AuthService();

      SharedPreferences.setMockInitialValues({});
      expect(await auth.isAdmin(), isFalse);
      expect(await auth.getRole(), isNull);

      SharedPreferences.setMockInitialValues({'role': 'User'});
      expect(await auth.isAdmin(), isFalse);
      expect(await auth.getRole(), equals('User'));

      SharedPreferences.setMockInitialValues({'role': 'Admin'});
      expect(await auth.isAdmin(), isTrue);
      expect(await auth.getRole(), equals('Admin'));
    });
  });
}
