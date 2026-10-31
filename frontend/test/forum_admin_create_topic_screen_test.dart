import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:frontend/models/forum_topic_model.dart';
import 'package:frontend/services/forum_topic_repository.dart';
import 'package:frontend/screens/forum/admin_create_topic_screen.dart';
import 'package:frontend/utils/boxed_snack_bar.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;

/// Mock Repository để kiểm thử luồng tạo bài viết
class MockForumTopicRepository implements ForumTopicRepository {
  final List<ForumTopicItem> createdTopics = [];
  Map<String, List<ForumTopicItem>> mockData = {
    'pinned': [],
    'topics': [],
    'all': [],
  };

  @override
  Future<Map<String, List<ForumTopicItem>>?> fetchTopics({String? categorySlug, http.Client? client}) async {
    return mockData;
  }

  @override
  Future<bool> createTopic(ForumTopicItem item, {http.Client? client}) async {
    createdTopics.add(item);
    return true;
  }

  @override
  Future<bool> updateTopic(dynamic topicId, ForumTopicItem item, {http.Client? client}) async {
    createdTopics.add(item);
    return true;
  }

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
  Future<ForumTopicItem?> fetchTopicDetail(dynamic id, {http.Client? client}) async => null;

  @override
  Future<Map<String, dynamic>?> fetchCategoryPermissions(int categoryId, {http.Client? client}) async => {
    'canCreateTopic': true,
    'canReply': true,
    'canEditOwnPost': true,
    'canDeleteOwnPost': true,
  };
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'jwt_token': 'fake_admin_token',
      'username': 'admin',
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

  group('Kiểm thử Màn hình Tạo bài viết (AdminCreateTopicScreen) - Hình 1, 2, 3, 4 & 5', () {
    testWidgets('1. Kiểm tra render đủ các thành phần: Checkbox Nội quy, Checkbox Trả lời nhanh, AnimatedSize', (tester) async {
      tester.view.physicalSize = const Size(1280, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final mockRepo = MockForumTopicRepository();

      await tester.pumpWidget(
        buildBoxedApp(
          AdminCreateTopicScreen(
            repository: mockRepo,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Kiểm tra Header & Nút chức năng
      expect(find.text('Tạo thêm thông báo và Sự kiện mới (Ban Quản Trị)'), findsWidgets);
      expect(find.text('Tạo thêm Thông Báo mới'), findsOneWidget);
      expect(find.text('Tạo thêm Sự kiện mới'), findsOneWidget);

      // Mặc định _showRules = false nên khối editor Nội quy bị ẩn
      expect(find.byType(quill.QuillEditor), findsOneWidget); // Chỉ có 1 Content Editor

      // Kiểm tra Checkbox "Thêm mục Trả lời nhanh" (mặc định true)
      expect(find.text('Thêm mục Trả lời nhanh'), findsOneWidget);
      final quickReplyCheckboxFinder = find.descendant(
        of: find.ancestor(
          of: find.text('Thêm mục Trả lời nhanh'),
          matching: find.byType(InkWell),
        ),
        matching: find.byType(Checkbox),
      );
      expect(quickReplyCheckboxFinder, findsOneWidget);
      final Checkbox checkbox = tester.widget(quickReplyCheckboxFinder);
      expect(checkbox.value, isTrue);

      // Kiểm tra Checkbox "Nội quy Chuyên mục" (mặc định false)
      expect(find.text('Nội quy Chuyên mục'), findsOneWidget);
      final rulesCheckboxFinder = find.descendant(
        of: find.ancestor(
          of: find.text('Nội quy Chuyên mục'),
          matching: find.byType(InkWell),
        ),
        matching: find.byType(Checkbox),
      );
      expect(rulesCheckboxFinder, findsOneWidget);
      final Checkbox rulesCheckbox = tester.widget(rulesCheckboxFinder);
      expect(rulesCheckbox.value, isFalse);

      // Tích chọn checkbox "Nội quy Chuyên mục"
      await tester.tap(find.text('Nội quy Chuyên mục'));
      await tester.pumpAndSettle();

      // Bây giờ cả 2 Editor đều hiển thị
      expect(find.byType(quill.QuillEditor), findsNWidgets(2));
      final quillEditors = tester.widgetList<quill.QuillEditor>(find.byType(quill.QuillEditor));
      expect(quillEditors.any((e) => e.config.placeholder == 'Xin vui lòng nhập nội quy Chuyên mục...'), isTrue);
      expect(quillEditors.any((e) => e.config.placeholder == 'Nhập nội dung mô tả hoặc thông tin chi tiết...'), isTrue);
    });

    testWidgets('2. Kiểm tra chuyển đổi chế độ giữa Thông báo và Sự kiện', (tester) async {
      tester.view.physicalSize = const Size(1280, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final mockRepo = MockForumTopicRepository();

      await tester.pumpWidget(
        buildBoxedApp(
          AdminCreateTopicScreen(
            repository: mockRepo,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Mặc định chế độ Thông Báo
      expect(find.text('Tên Thông báo mới'), findsOneWidget);
      expect(find.text('Nhập Tên Thông báo mới'), findsOneWidget);
      expect(find.text('Nội dung Thông báo mới'), findsOneWidget);

      // Click chuyển sang "Tạo thêm Sự kiện mới"
      await tester.tap(find.text('Tạo thêm Sự kiện mới'));
      await tester.pumpAndSettle();

      // Các label và hint cập nhật sang Sự kiện
      expect(find.text('Tên Sự kiện mới'), findsOneWidget);
      expect(find.text('Nhập Tên Sự kiện mới'), findsOneWidget);
      expect(find.text('Nội dung Sự kiện mới'), findsOneWidget);
      // Checkbox vẫn giữ nguyên
      expect(find.text('Nội quy Chuyên mục'), findsOneWidget);
      expect(find.text('Thêm mục Trả lời nhanh'), findsOneWidget);
    });

    testWidgets('3. Kiểm tra Validation động theo trạng thái Checkbox Nội quy', (tester) async {
      tester.view.physicalSize = const Size(1280, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final mockRepo = MockForumTopicRepository();
      final rulesController = quill.QuillController.basic();
      final contentController = quill.QuillController.basic();

      await tester.pumpWidget(
        buildBoxedApp(
          AdminCreateTopicScreen(
            repository: mockRepo,
            rulesQuillController: rulesController,
            quillController: contentController,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Bước 3.1: Tiêu đề trống -> Báo lỗi nhập Tên Thông báo mới
      await tester.tap(find.text('Xác nhận'));
      await tester.pumpAndSettle();

      expect(find.text('Vui lòng nhập Tên Thông báo mới'), findsWidgets);
      expect(mockRepo.createdTopics.isEmpty, isTrue);

      // Nhập tiêu đề
      await tester.enterText(find.byType(TextField).first, 'Tiêu đề thông báo kiểm thử');
      await tester.pumpAndSettle();

      // Khi _showRules == false: bỏ qua validation nội quy, kiểm tra nội dung
      await tester.tap(find.text('Xác nhận'));
      await tester.pumpAndSettle();

      expect(find.text('Vui lòng nhập Nội dung Thông báo mới'), findsWidgets);
      expect(mockRepo.createdTopics.isEmpty, isTrue);

      // Bật Checkbox "Nội quy Chuyên mục" (_showRules = true)
      await tester.tap(find.text('Nội quy Chuyên mục'));
      await tester.pumpAndSettle();

      // Bây giờ bấm Xác nhận -> bắt buộc phải nhập nội quy!
      await tester.tap(find.text('Xác nhận'));
      await tester.pumpAndSettle();

      expect(find.text('Vui lòng nhập nội quy'), findsWidgets);
      expect(mockRepo.createdTopics.isEmpty, isTrue);

      // Nhập Nội quy
      rulesController.document.insert(0, 'Nội quy chuyên mục kiểm thử');
      await tester.pumpAndSettle();

      // Bấm Xác nhận -> Báo lỗi nội dung vì nội dung vẫn trống
      await tester.tap(find.text('Xác nhận'));
      await tester.pumpAndSettle();

      expect(find.text('Vui lòng nhập Nội dung Thông báo mới'), findsWidgets);
      expect(mockRepo.createdTopics.isEmpty, isTrue);
    });

    testWidgets('4. Kiểm tra Popup Dialog Xem trước động (Hình 3 & Hình 4)', (tester) async {
      tester.view.physicalSize = const Size(1280, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final mockRepo = MockForumTopicRepository();
      final rulesController = quill.QuillController.basic();
      final contentController = quill.QuillController.basic();

      contentController.document.insert(0, 'Chi tiết nội dung thông báo hệ thống.');

      await tester.pumpWidget(
        buildBoxedApp(
          AdminCreateTopicScreen(
            repository: mockRepo,
            rulesQuillController: rulesController,
            quillController: contentController,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Nhập tiêu đề
      await tester.enterText(find.byType(TextField).first, 'Bảo trì hệ thống định kỳ');
      await tester.pumpAndSettle();

      // Bấm Xem trước khi _showRules == false (không cần nội quy)
      await tester.tap(find.text('Xem trước'));
      await tester.pumpAndSettle();

      // Kiểm tra Header Dialog Xem trước: Thông báo mới
      expect(find.text('Xem trước Thông Báo mới'), findsOneWidget);
      expect(find.text('Bảo trì hệ thống định kỳ'), findsWidgets);
      expect(find.text('Mục Cho vào: Thông Báo'), findsOneWidget);
      expect(find.textContaining('Chi tiết nội dung thông báo'), findsOneWidget);

      // Bấm nút Đóng
      await tester.tap(find.text('Đóng'));
      await tester.pumpAndSettle();

      expect(find.text('Xem trước Thông Báo mới'), findsNothing);
    });

    testWidgets('5. Kiểm tra Nút Xác nhận gửi đủ payload bền vững (Rules, EnableQuickReply)', (tester) async {
      tester.view.physicalSize = const Size(1280, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final mockRepo = MockForumTopicRepository();
      final rulesController = quill.QuillController.basic();
      final contentController = quill.QuillController.basic();

      contentController.document.insert(0, 'Nội dung bài viết hoàn chỉnh.');

      await tester.pumpWidget(
        buildBoxedApp(
          AdminCreateTopicScreen(
            repository: mockRepo,
            rulesQuillController: rulesController,
            quillController: contentController,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Nhập tiêu đề và Xác nhận tạo Thông báo khi _showRules == false (rules rỗng)
      await tester.enterText(find.byType(TextField).first, 'Thông báo chính thức V1');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Xác nhận'));
      await tester.pumpAndSettle();

      expect(mockRepo.createdTopics.length, equals(1));
      final topic1 = mockRepo.createdTopics.first;
      expect(topic1.title, equals('Thông báo chính thức V1'));
      expect(topic1.type, equals('thong_bao'));
      expect(topic1.rules, equals(''));
      expect(topic1.enableQuickReply, isTrue);
      expect(topic1.lastTime, isNot(equals('Vừa xong')));
      expect(RegExp(r'^\d{2}:\d{2}, \d{2}/\d{2}/\d{2}$').hasMatch(topic1.lastTime), isTrue);

      // Tạo Sự kiện thứ 2: Bật Checkbox Nội quy và nhập nội quy
      await tester.tap(find.text('Tạo thêm Sự kiện mới'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, 'Chủ đề trao đổi học thuật');
      await tester.pumpAndSettle();

      // Bật Checkbox "Nội quy Chuyên mục"
      await tester.tap(find.text('Nội quy Chuyên mục'));
      await tester.pumpAndSettle();

      rulesController.document.insert(0, 'Quy chuẩn thảo luận diễn đàn.');
      await tester.pumpAndSettle();

      // Bỏ tick checkbox "Thêm mục Trả lời nhanh"
      await tester.tap(find.text('Thêm mục Trả lời nhanh'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Xác nhận'));
      await tester.pumpAndSettle();

      expect(mockRepo.createdTopics.length, equals(2));
      final topic2 = mockRepo.createdTopics[1];
      expect(topic2.title, equals('Chủ đề trao đổi học thuật'));
      expect(topic2.type, equals('chu_de'));
      expect(topic2.rules, contains('Quy chuẩn thảo luận'));
      expect(topic2.enableQuickReply, isFalse);
      expect(RegExp(r'^\d{2}:\d{2}, \d{2}/\d{2}/\d{2}$').hasMatch(topic2.lastTime), isTrue);
    });
  });
}
