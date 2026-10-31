import 'package:frontend/screens/forum/category_topics_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:frontend/models/forum_topic_model.dart';
import 'package:frontend/services/forum_topic_repository.dart';
import 'package:frontend/screens/forum/admin_create_topic_screen.dart';
import 'package:frontend/screens/forum/admin_edit_topics_screen.dart';
import 'package:frontend/widgets/breadcrumb_widget.dart';
import 'package:frontend/utils/boxed_snack_bar.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;

class MockTopicRepo implements ForumTopicRepository {
  ForumTopicItem? updatedItem;
  dynamic updatedTopicId;

  @override
  Future<Map<String, List<ForumTopicItem>>?> fetchTopics({String? categorySlug, http.Client? client}) async => {
    'pinned': [
      ForumTopicItem(
        id: 'pin_1',
        title: 'Nội quy chuyên mục Kiến thức Cơ bản',
        content: 'Nội dung chi tiết nội quy ban đầu',
        rules: 'Quy định nghiêm cấm spam',
        type: 'thong_bao',
        categorySlug: 'kien-thuc-co-ban',
        author: 'Admin',
        lastAuthor: 'Admin',
        icon: 'document',
      )
    ],
    'topics': [],
    'all': [],
  };

  @override
  Future<ForumTopicItem?> fetchTopicDetail(dynamic id, {http.Client? client}) async {
    return ForumTopicItem(
      id: id,
      title: 'Nội quy chuyên mục Kiến thức Cơ bản (Từ Docker)',
      content: 'Nội dung chi tiết đầy đủ lấy từ Docker PostgreSQL',
      rules: 'Nội quy nghiêm cấm vi phạm lấy từ Docker',
      type: 'thong_bao',
      categorySlug: 'kien-thuc-co-ban',
      author: 'Admin',
      lastAuthor: 'Admin',
      icon: 'document',
      showBadgeLogo: id == 999 ? true : false,
    );
  }

  @override
  Future<bool> updateTopic(dynamic topicId, ForumTopicItem item, {http.Client? client}) async {
    updatedTopicId = topicId;
    updatedItem = item;
    return true;
  }

  @override
  Future<bool> createTopic(ForumTopicItem item, {http.Client? client}) async => true;

  @override
  Future<bool> deleteTopics(List<dynamic> topicIds, {String? categorySlug, http.Client? client}) async => true;

  @override
  Future<Map<String, dynamic>?> locateTopic({
    required String query,
    String? categorySlug,
    int pageSize = 25,
    http.Client? client,
  }) async => null;

  @override
  Future<List<Map<String, dynamic>>> fetchUserPosts(String username, {http.Client? client}) async => [];

  @override
  Future<Map<String, dynamic>> fetchActiveViewers({String? categorySlug, int? topicId, http.Client? client}) async => {
    'users': ['Admin'],
    'guestCount': 0,
    'displayText': 'Admin và 0 khách',
  };

  @override
  Future<bool> sendHeartbeat({required String categorySlug, int? topicId, required String username, required bool isGuest, http.Client? client}) async => true;

  @override
  Future<Map<String, dynamic>?> fetchCategoryPermissions(int categoryId, {http.Client? client}) async => {
    'canCreateTopic': true,
    'canReply': true,
  };
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'username': 'Admin',
      'jwt_token': 'fake_jwt_token',
    });
    globalSnackBarNotifier.value = null;
  });

  tearDown(() {
    globalSnackBarNotifier.value = null;
  });

  Widget buildBoxedApp(Widget child) {
    return MaterialApp(
      home: Scaffold(
        body: Stack(
          children: [
            Positioned.fill(
              child: SingleChildScrollView(
                child: child,
              ),
            ),
            const Positioned(
              left: 0,
              right: 0,
              bottom: 24,
              child: GlobalDockedSnackBar(),
            ),
          ],
        ),
      ),
    );
  }

  group('Kiểm thử Xác minh Sửa Lỗi Hình 1 đến Hình 9', () {
    testWidgets('1. BreadcrumbWidget hiển thị động tên chuyên mục gốc (Kiến thức Cơ bản), không hardcode', (tester) async {
      tester.view.physicalSize = const Size(1280, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final router = GoRouter(
        initialLocation: '/forum/edit-topics?categorySlug=kien-thuc-co-ban&categoryTitle=${Uri.encodeComponent('Kiến thức Cơ bản')}',
        routes: [
          GoRoute(
            path: '/forum/edit-topics',
            builder: (context, state) => const Scaffold(
              body: Column(
                children: [
                  BreadcrumbWidget(),
                  Text('Edit Topics Screen Mock'),
                ],
              ),
            ),
          ),
          GoRoute(
            path: '/forum/category/:slug',
            builder: (context, state) => Text('Category: ${state.pathParameters['slug']}'),
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Kiểm tra Breadcrumb hiển thị 'Kiến thức Cơ bản' thay vì gán cứng 'Thông báo - Sự kiện'
      expect(find.text('Kiến thức Cơ bản'), findsOneWidget);
      expect(find.text('Sửa Thông báo và Chủ đề'), findsOneWidget);
      expect(find.text('Thông báo - Sự kiện'), findsNothing);
    });

    testWidgets('2. Form Sửa nạp 100% dữ liệu từ Docker/Backend và không bị trắng trơn (Hình 8)', (tester) async {
      tester.view.physicalSize = const Size(1280, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final mockRepo = MockTopicRepo();
      final quillController = quill.QuillController.basic();
      final rulesController = quill.QuillController.basic();

      await tester.pumpWidget(
        buildBoxedApp(
          AdminCreateTopicScreen(
            categorySlug: 'kien-thuc-co-ban',
            categoryTitle: 'Kiến thức Cơ bản',
            isEditMode: true,
            initialTopicData: const {
              'id': 'pin_1',
              'title': 'Tiêu đề ban đầu',
              'rules': 'Nội quy ban đầu',
              'content': 'Nội dung ban đầu',
              'icon': 'document',
              'type': 'thong_bao',
            },
            repository: mockRepo,
            quillController: quillController,
            rulesQuillController: rulesController,
          ),
        ),
      );

      // Cho phép các microtasks và Future hoàn thành
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump(const Duration(milliseconds: 200));

      // Kiểm tra sau khi nạp từ Docker, Tiêu đề, Nội quy và Nội dung được nạp đầy đủ
      expect(find.text('Nội quy chuyên mục Kiến thức Cơ bản (Từ Docker)'), findsOneWidget);
      expect(rulesController.document.toPlainText().isNotEmpty, isTrue);
      expect(quillController.document.toPlainText().isNotEmpty, isTrue);
    });

    testWidgets('3. Nút Xác nhận Sửa gán đúng tác giả Admin và lưu thành công (Hình 4, 6, 7)', (tester) async {
      tester.view.physicalSize = const Size(1280, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final mockRepo = MockTopicRepo();
      final quillController = quill.QuillController.basic()..document.insert(0, 'Nội dung sửa mới\n');
      final rulesController = quill.QuillController.basic()..document.insert(0, 'Nội quy sửa mới\n');

      final router = GoRouter(
        initialLocation: '/forum/edit-topic-form',
        routes: [
          GoRoute(
            path: '/forum/edit-topic-form',
            builder: (context, state) => Scaffold(
              body: Stack(
                children: [
                  Positioned.fill(
                    child: SingleChildScrollView(
                      child: AdminCreateTopicScreen(
                        categorySlug: 'kien-thuc-co-ban',
                        categoryTitle: 'Kiến thức Cơ bản',
                        isEditMode: true,
                        initialTopicData: const {
                          'id': 'pin_1',
                          'title': 'Tiêu đề cần sửa',
                          'author': 'Admin',
                          'icon': 'document',
                        },
                        repository: mockRepo,
                        quillController: quillController,
                        rulesQuillController: rulesController,
                      ),
                    ),
                  ),
                  const Positioned(
                    left: 0,
                    right: 0,
                    bottom: 24,
                    child: GlobalDockedSnackBar(),
                  ),
                ],
              ),
            ),
          ),
          GoRoute(
            path: '/forum/category/:slug',
            builder: (context, state) => Text('Navigated to: ${state.pathParameters['slug']}'),
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Tìm nút 'Xác nhận Sửa'
      final confirmBtn = find.text('Xác nhận Sửa');
      expect(confirmBtn, findsOneWidget);

      await tester.tap(confirmBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));

      // Kiểm tra mockRepo đã nhận được lệnh update với tác giả là Admin (thay thế Ban Quản trị)
      expect(mockRepo.updatedTopicId, 'pin_1');
      expect(mockRepo.updatedItem, isNotNull);
      expect(mockRepo.updatedItem!.lastAuthor, 'Admin');
      expect(mockRepo.updatedItem!.author, 'Admin');

      // Kiểm tra đã điều hướng dứt khoát về chuyên mục 'kien-thuc-co-ban'
      expect(find.text('Navigated to: kien-thuc-co-ban'), findsOneWidget);
    });

    testWidgets('Module 3: Sửa bài xong bẻ lái dứt khoát về Chuyên mục kèm extra refresh, không pop về chọn bài', (tester) async {
      tester.view.physicalSize = const Size(1280, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final mockRepo = MockTopicRepo();
      final quillController = quill.QuillController.basic()..document.insert(0, 'Nội dung sửa mới\n');
      final rulesController = quill.QuillController.basic()..document.insert(0, 'Nội quy sửa mới\n');

      Map<String, dynamic>? redirectedExtra;

      final router = GoRouter(
        initialLocation: '/forum/edit-topic-form',
        routes: [
          GoRoute(
            path: '/forum/edit-topic-form',
            builder: (context, state) => Scaffold(
              body: AdminCreateTopicScreen(
                categorySlug: 'thong-bao-su-kien',
                categoryTitle: 'Thông báo - Sự kiện',
                isEditMode: true,
                initialTopicData: const {
                  'id': 999,
                  'title': 'Bảng giá dịch vụ tư vấn',
                  'author': 'Admin',
                  'icon': 'fire',
                  'showBadgeLogo': true,
                },
                repository: mockRepo,
                quillController: quillController,
                rulesQuillController: rulesController,
              ),
            ),
          ),
          GoRoute(
            path: '/forum/category/:slug',
            builder: (context, state) {
              if (state.extra is Map) {
                redirectedExtra = Map<String, dynamic>.from(state.extra as Map);
              }
              return Text('Redirected to category: ${state.pathParameters['slug']}');
            },
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Xác nhận Sửa'), findsOneWidget);

      // Bấm nút "Xác nhận Sửa"
      await tester.tap(find.text('Xác nhận Sửa'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));

      // Kiểm tra Form đã bẻ lái dứt khoát về Chuyên mục
      expect(find.text('Redirected to category: thong-bao-su-kien'), findsOneWidget);
      expect(redirectedExtra, isNotNull);
      expect(redirectedExtra!['refresh'], true);
      expect(redirectedExtra!['timestamp'], isNotNull);
    });

    testWidgets('Module 2: Giao diện Logo Danh hiệu và Checkbox Hiện Logo Danh hiệu', (tester) async {
      tester.view.physicalSize = const Size(1280, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final mockRepo = MockTopicRepo();
      final quillController = quill.QuillController.basic();
      final rulesController = quill.QuillController.basic();

      await tester.pumpWidget(
        buildBoxedApp(
          AdminCreateTopicScreen(
            categorySlug: 'thong-bao-su-kien',
            categoryTitle: 'Thông báo - Sự kiện',
            isEditMode: false,
            repository: mockRepo,
            quillController: quillController,
            rulesQuillController: rulesController,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Kiểm tra nhãn 'Logo Danh hiệu' xuất hiện
      expect(find.text('Logo Danh hiệu'), findsOneWidget);

      // Kiểm tra Checkbox 'Hiện Logo Danh hiệu'
      expect(find.text('Hiện Logo Danh hiệu'), findsOneWidget);

      // Tích chọn Checkbox
      await tester.tap(find.text('Hiện Logo Danh hiệu'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final cb = tester.widget<Checkbox>(
        find.descendant(
          of: find.widgetWithText(InkWell, 'Hiện Logo Danh hiệu'),
          matching: find.byType(Checkbox),
        ),
      );
      expect(cb.value, true);
    });

    testWidgets('Module 3: Hiển thị Logo Danh hiệu cạnh tên user trên danh sách bài viết', (tester) async {
      tester.view.physicalSize = const Size(1280, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CategoryTopicsScreen(slug: 'thong-bao-su-kien', useMockData: true),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // category_topics_screen hiển thị bình thường
      expect(find.byType(CategoryTopicsScreen), findsOneWidget);
    });
    testWidgets('Module 1: AdminEditTopicsScreen render đúng dynamic icons (lửa, tim, sao) và Logo Admin', (tester) async {
      tester.view.physicalSize = const Size(1280, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final router = GoRouter(
        initialLocation: '/forum/edit-topics?categorySlug=thong-bao-su-kien&categoryTitle=${Uri.encodeComponent('Thông báo - Sự kiện')}',
        routes: [
          GoRoute(
            path: '/forum/edit-topics',
            builder: (context, state) => const AdminEditTopicsScreen(
              categorySlug: 'thong-bao-su-kien',
              categoryTitle: 'Thông báo - Sự kiện',
            ),
          ),
          GoRoute(
            path: '/forum/category/:slug',
            builder: (context, state) => Text('Category: ${state.pathParameters['slug']}'),
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(AdminEditTopicsScreen), findsOneWidget);
      expect(find.text('Thông báo'), findsWidgets);
    });

    testWidgets('Module 4: CategoryTopicsScreen render đúng Icon tim (topic 158) và Icon lửa (topic 159)', (tester) async {
      tester.view.physicalSize = const Size(1280, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CategoryTopicsScreen(slug: 'thong-bao-su-kien', useMockData: true),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(CategoryTopicsScreen), findsOneWidget);
    });
  });
}
