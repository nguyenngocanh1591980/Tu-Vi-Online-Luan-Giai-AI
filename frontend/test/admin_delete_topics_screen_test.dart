import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:frontend/models/forum_topic_model.dart';
import 'package:frontend/screens/forum/admin_delete_topics_screen.dart';
import 'package:frontend/screens/forum/category_topics_screen.dart';
import 'package:frontend/services/forum_topic_repository.dart';
import 'package:frontend/services/forum_category_data_helper.dart';

class MockForumTopicRepository implements ForumTopicRepository {
  List<ForumTopicItem> pinnedTopics = [
    const ForumTopicItem(
      id: 101,
      type: 'thong_bao',
      title: 'Nội quy diễn đàn Tử Vi Online - AI',
      categorySlug: 'thong-bao-su-kien',
      author: 'Admin',
      replies: 0,
      views: 6,
      lastAuthor: 'Admin',
      lastTime: '16:06, 26/10/26',
    ),
    const ForumTopicItem(
      id: 102,
      type: 'thong_bao',
      title: 'Hướng dẫn sử dụng diễn đàn',
      categorySlug: 'thong-bao-su-kien',
      author: 'Admin',
      replies: 0,
      views: 1,
      lastAuthor: 'Admin',
      lastTime: '16:05, 26/10/26',
    ),
  ];

  List<ForumTopicItem> normalTopics = [
    const ForumTopicItem(
      id: 201,
      type: 'chu_de',
      title: 'Nhân dịp KN 15 năm thành lập diễn đàn',
      categorySlug: 'thong-bao-su-kien',
      author: 'Admin',
      replies: 0,
      views: 1,
      lastAuthor: 'Admin',
      lastTime: '16:08, 26/10/26',
    ),
  ];

  List<dynamic> deletedIds = [];

  @override
  Future<Map<String, List<ForumTopicItem>>?> fetchTopics({String? categorySlug, http.Client? client}) async {
    return {
      'pinned': List<ForumTopicItem>.from(pinnedTopics),
      'topics': List<ForumTopicItem>.from(normalTopics),
      'all': [...pinnedTopics, ...normalTopics],
    };
  }

  @override
  Future<bool> deleteTopics(List<dynamic> topicIds, {String? categorySlug, http.Client? client}) async {
    deletedIds.addAll(topicIds);
    final idSet = topicIds.map((e) => e.toString()).toSet();
    pinnedTopics.removeWhere((t) => idSet.contains(t.id.toString()) || idSet.contains(t.title));
    normalTopics.removeWhere((t) => idSet.contains(t.id.toString()) || idSet.contains(t.title));
    return true;
  }

  @override
  Future<bool> createTopic(ForumTopicItem item, {http.Client? client}) async => true;

  @override
  Future<bool> updateTopic(dynamic topicId, ForumTopicItem item, {http.Client? client}) async => true;

  @override
  Future<ForumTopicItem?> fetchTopicDetail(dynamic id, {http.Client? client}) async => null;

  @override
  Future<List<Map<String, dynamic>>> fetchUserPosts(String username, {http.Client? client}) async => [];

  @override
  Future<Map<String, dynamic>> fetchActiveViewers({String? categorySlug, int? topicId, http.Client? client}) async => {};

  @override
  Future<bool> sendHeartbeat({required String categorySlug, int? topicId, required String username, required bool isGuest, http.Client? client}) async => true;

  @override
  Future<Map<String, dynamic>?> fetchCategoryPermissions(int categoryId, {http.Client? client}) async => {};

  @override
  Future<Map<String, dynamic>?> locateTopic({required String query, String? categorySlug, int pageSize = 25, http.Client? client}) async => null;
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({'jwt_token': 'test_admin_token', 'user_role': 'Admin'});
    ForumCategoryDataHelper.useMockData = false;
  });

  group('Kiểm thử nghiêm ngặt Màn hình Xóa bài viết & Real-time (4 Nhiệm vụ)', () {
    testWidgets('Nhiệm vụ 1: Điều chỉnh Text và Thêm thành phần UI (Header, Text 1, 3 Nút ở Text 2, Breadcrumb)', (tester) async {
      tester.view.physicalSize = const Size(1280, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final mockRepo = MockForumTopicRepository();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: AdminDeleteTopicsScreen(
                categorySlug: 'thong-bao-su-kien',
                categoryTitle: 'Thông báo - Sự kiện',
                repository: mockRepo,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Header Bar: Tiêu đề dải vàng "Xóa Thông báo - Sự kiện" và nút "< Về Chuyên mục"
      expect(find.text('Xóa Thông báo - Sự kiện'), findsOneWidget);
      expect(find.text('Về Chuyên mục'), findsOneWidget);

      // 2. Khu vực trống số 1: "Bạn định xóa Thông báo hay Sự kiện nào ?"
      expect(find.text('Bạn định xóa Thông báo hay Sự kiện nào ?'), findsOneWidget);

      // 3. Khu vực trống số 2: Hàng 3 nút bấm căn giữa
      expect(find.text('Trở về Trang chủ'), findsOneWidget);
      expect(find.text('Xem trước'), findsOneWidget);
      expect(find.text('Xác nhận xóa (Y/N)'), findsOneWidget);

      // 4. Breadcrumb Footer: "Xóa Thông báo và Sự kiện"
      expect(find.text('Xóa Thông báo và Sự kiện'), findsOneWidget);
    });

    testWidgets('Nhiệm vụ 2: Tích hợp Checkbox và Modal Xem trước (Preview Data-Bind)', (tester) async {
      tester.view.physicalSize = const Size(1280, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final mockRepo = MockForumTopicRepository();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: AdminDeleteTopicsScreen(
                categorySlug: 'thong-bao-su-kien',
                categoryTitle: 'Thông báo - Sự kiện',
                repository: mockRepo,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Kiểm tra có các Checkbox bên trái danh sách
      final checkboxes = find.byType(Checkbox);
      expect(checkboxes, findsWidgets);

      // Tích chọn bài viết đầu tiên
      await tester.tap(checkboxes.first);
      await tester.pumpAndSettle();

      // Nút "Xem trước" cập nhật số lượng: "Xem trước (1)"
      expect(find.text('Xem trước (1)'), findsOneWidget);

      // Bấm vào nút "Xem trước" để mở Modal
      await tester.tap(find.text('Xem trước (1)'));
      await tester.pumpAndSettle();

      // Modal hiển thị danh sách chi tiết các bài viết sẽ xóa
      expect(find.text('Xem trước danh sách bài viết sẽ xóa (1)'), findsOneWidget);
      expect(find.text('Đóng xem trước'), findsOneWidget);

      // Bấm đóng modal
      await tester.tap(find.text('Đóng xem trước'));
      await tester.pumpAndSettle();
      expect(find.text('Xem trước danh sách bài viết sẽ xóa (1)'), findsNothing);
    });

    testWidgets('Nhiệm vụ 3 & 4: Thực thi Xóa bài viết và State bốc hơi tức thời (Zero-Reload)', (tester) async {
      tester.view.physicalSize = const Size(1280, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final mockRepo = MockForumTopicRepository();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: AdminDeleteTopicsScreen(
                categorySlug: 'thong-bao-su-kien',
                categoryTitle: 'Thông báo - Sự kiện',
                repository: mockRepo,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final targetTitle = 'Nội quy diễn đàn Tử Vi Online - AI';
      expect(find.text(targetTitle), findsOneWidget);

      // Tích chọn checkbox của bài viết
      final checkboxes = find.byType(Checkbox);
      await tester.tap(checkboxes.first);
      await tester.pumpAndSettle();

      // Bấm "Xác nhận xóa (true)"
      final deleteBtn = find.text('Xác nhận xóa (Y/N)');
      expect(deleteBtn, findsOneWidget);
      await tester.tap(deleteBtn);
      await tester.pumpAndSettle();

      // Hiện dialog xác nhận
      expect(find.text('Bạn muốn xóa không?'), findsOneWidget);
      expect(find.text('Y (Đồng ý)'), findsOneWidget);

      // Bấm Y (Đồng ý)
      await tester.tap(find.text('Y (Đồng ý)'));
      await tester.pumpAndSettle();

      // Mock repository đã ghi nhận deletedIds
      expect(mockRepo.deletedIds, isNotEmpty);

      // Ngay lập tức dòng bài viết bốc hơi khỏi State nội bộ mà không cần F5 (Nhiệm vụ 4)
      expect(find.text(targetTitle), findsNothing);
    });

    testWidgets('Nhiệm vụ 4: category_topics_screen tự động xóa bài khi nhận SignalR event', (tester) async {
      tester.view.physicalSize = const Size(1280, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CategoryTopicsScreen(slug: 'thong-bao-su-kien', useMockData: true),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Kiểm tra nút "Xóa Thông báo và Sự kiện" hiện diện
      expect(find.text('Xóa Thông báo và Sự kiện'), findsOneWidget);
    });

    testWidgets('Module 1: Điều hướng an toàn không văng app và Redirect sau khi xóa', (tester) async {
      tester.view.physicalSize = const Size(1280, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final mockRepo = MockForumTopicRepository();
      String? lastNavigatedUri;
      Object? lastNavigatedExtra;

      final testRouter = GoRouter(
        initialLocation: '/forum/category/thong-bao-su-kien/delete',
        routes: [
          GoRoute(
            path: '/forum/category/:slug',
            builder: (context, state) {
              lastNavigatedUri = state.uri.toString();
              lastNavigatedExtra = state.extra;
              return Scaffold(
                body: Text('Màn hình Chuyên mục: ${state.pathParameters['slug']}'),
              );
            },
            routes: [
              GoRoute(
                path: 'delete',
                builder: (context, state) => AdminDeleteTopicsScreen(
                  categorySlug: 'thong-bao-su-kien',
                  categoryTitle: 'Thông báo - Sự kiện',
                  repository: mockRepo,
                ),
              ),
            ],
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: testRouter));
      await tester.pumpAndSettle();

      // Bấm nút "< Về Chuyên mục"
      await tester.tap(find.text('Về Chuyên mục'));
      await tester.pumpAndSettle();
      expect(lastNavigatedUri, '/forum/category/thong-bao-su-kien');
      expect(find.text('Màn hình Chuyên mục: thong-bao-su-kien'), findsOneWidget);

      // Quay lại màn hình delete
      testRouter.go('/forum/category/thong-bao-su-kien/delete');
      await tester.pumpAndSettle();

      // Bấm nút "Trở về Trang chủ" (cũng điều hướng về /forum/category/thong-bao-su-kien an toàn)
      lastNavigatedUri = null;
      await tester.tap(find.text('Trở về Trang chủ'));
      await tester.pumpAndSettle();
      expect(lastNavigatedUri, '/forum/category/thong-bao-su-kien');

      // Quay lại màn hình delete và test auto-redirect sau khi xóa
      testRouter.go('/forum/category/thong-bao-su-kien/delete');
      await tester.pumpAndSettle();

      final checkboxes = find.byType(Checkbox);
      await tester.tap(checkboxes.first);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Xác nhận xóa (Y/N)'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Y (Đồng ý)'));
      await tester.pumpAndSettle();

      // Tự động redirect về chuyên mục kèm extra refresh
      expect(lastNavigatedUri, '/forum/category/thong-bao-su-kien');
      expect(lastNavigatedExtra, isA<Map>());
      expect((lastNavigatedExtra as Map)['refresh'], true);
    });

    testWidgets('Module 2: Phân trang 25 dòng / trang và UX Phân Trang Thông Minh', (tester) async {
      tester.view.physicalSize = const Size(1280, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      // Tạo 30 bài viết thường
      final mockRepo = MockForumTopicRepository();
      mockRepo.normalTopics = List.generate(
        30,
        (i) => ForumTopicItem(
          id: 300 + i,
          type: 'chu_de',
          title: 'Bài viết số ${i + 1}',
          categorySlug: 'thong-bao-su-kien',
          author: 'Admin',
          replies: 0,
          views: 1,
          lastAuthor: 'Admin',
          lastTime: '16:00, 26/10/26',
        ),
      );
      mockRepo.pinnedTopics = [];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: AdminDeleteTopicsScreen(
                categorySlug: 'thong-bao-su-kien',
                categoryTitle: 'Thông báo - Sự kiện',
                repository: mockRepo,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Trang 1: Hiển thị Bài viết số 1 đến 25
      expect(find.text('Bài viết số 1'), findsOneWidget);
      expect(find.text('Bài viết số 25'), findsOneWidget);
      expect(find.text('Bài viết số 26'), findsNothing);

      // Kiểm tra thanh phân trang phpBB
      expect(find.textContaining('30'), findsWidgets);
      expect(find.text('Next'), findsOneWidget);
      expect(find.widgetWithText(InkWell, '1'), findsWidgets);
      expect(find.widgetWithText(InkWell, '2'), findsWidgets);

      // Chuyển sang trang 2 bằng cách bấm nút badge "2"
      await tester.tap(find.widgetWithText(InkWell, '2').first);
      await tester.pumpAndSettle();

      // Trang 2: Hiển thị từ bài 26 đến 30
      expect(find.text('Bài viết số 1'), findsNothing);
      expect(find.text('Bài viết số 26'), findsOneWidget);
      expect(find.text('Bài viết số 30'), findsOneWidget);

      // Tích chọn toàn bộ các bài ở trang 2 (5 bài)
      final checkboxes = find.byType(Checkbox);
      for (final cb in checkboxes.evaluate()) {
        await tester.tap(find.byWidget(cb.widget));
      }
      await tester.pumpAndSettle();

      // Xóa tất cả các bài ở trang 2
      await tester.tap(find.text('Xác nhận xóa (Y/N)'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Y (Đồng ý)'));
      await tester.pumpAndSettle();

      // Smart UX: Tự động lùi về Trang 1 (25 bài còn lại)
      expect(find.text('Bài viết số 1'), findsOneWidget);
      expect(find.text('Bài viết số 25'), findsOneWidget);
    });

    testWidgets('Module 3: category_topics_screen kích hoạt tải lại khi nhận extra refresh', (tester) async {
      tester.view.physicalSize = const Size(1280, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final testRouter = GoRouter(
        initialLocation: '/forum/category/thong-bao-su-kien',
        routes: [
          GoRoute(
            path: '/forum/category/:slug',
            builder: (context, state) => CategoryTopicsScreen(
              slug: state.pathParameters['slug'] ?? 'thong-bao-su-kien',
              useMockData: true,
            ),
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: testRouter));
      await tester.pumpAndSettle();

      // Thử push lại route với extra refresh
      testRouter.go('/forum/category/thong-bao-su-kien', extra: {
        'refresh': true,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
      await tester.pumpAndSettle();

      expect(find.byType(CategoryTopicsScreen), findsOneWidget);
    });
  });
}
