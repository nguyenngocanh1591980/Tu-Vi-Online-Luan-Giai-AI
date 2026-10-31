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

  group('Kiểm thử Màn hình Tạo bài viết (AdminCreateTopicScreen) - Hình 1, 2 & 3', () {
    testWidgets('1. Kiểm tra render đủ các thành phần: 2 Editor, Checkbox Trả lời nhanh, Nhãn Nội quy', (tester) async {
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
      expect(find.text('Tạo thêm thông báo và Chủ đề mới (Ban Quản Trị)'), findsWidgets);
      expect(find.text('Tạo thêm Thông Báo mới'), findsOneWidget);
      expect(find.text('Tạo thêm Chủ đề mới'), findsOneWidget);

      // Kiểm tra nhãn Nội quy Chuyên mục & 2 Quill Editor
      expect(find.text('Nội quy Chuyên mục'), findsOneWidget);
      final quillEditors = tester.widgetList<quill.QuillEditor>(find.byType(quill.QuillEditor));
      expect(quillEditors.any((e) => e.config.placeholder == 'Xin vui lòng nhập nội quy Chuyên mục...'), isTrue);
      expect(quillEditors.any((e) => e.config.placeholder == 'Nhập nội dung mô tả hoặc thông tin chi tiết...'), isTrue);

      // Kiểm tra Checkbox "Thêm mục Trả lời nhanh" (mặc định được tích chọn true)
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

      // Kiểm tra ConstrainedBox của cả 2 editor có giới hạn maxHeight: 400
      final constrainedBoxes = tester.widgetList<ConstrainedBox>(find.byType(ConstrainedBox));
      final editorConstraints = constrainedBoxes.where(
        (box) => box.constraints.maxHeight == 400.0 && box.constraints.minHeight == 140.0,
      );
      expect(editorConstraints.length, greaterThanOrEqualTo(2));

      // Kiểm tra 2 thanh cuộn RawScrollbar hiển thị rõ nét (thumb & track) cho văn bản dài nhiều trang A4
      final scrollbars = tester.widgetList<RawScrollbar>(find.byType(RawScrollbar)).toList();
      expect(scrollbars.length, greaterThanOrEqualTo(2));
      expect(scrollbars.any((s) => s.thumbVisibility == true && s.trackVisibility == true), isTrue);
    });

    testWidgets('2. Kiểm tra chuyển đổi chế độ giữa Thông báo và Chủ đề', (tester) async {
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

      // Click chuyển sang "Tạo thêm Chủ đề mới"
      await tester.tap(find.text('Tạo thêm Chủ đề mới'));
      await tester.pumpAndSettle();

      // Các label và hint cập nhật sang Chủ đề
      expect(find.text('Tên Chủ đề mới'), findsOneWidget);
      expect(find.text('Nhập Tên Chủ đề mới'), findsOneWidget);
      expect(find.text('Nội dung Chủ đề mới'), findsOneWidget);
      // Nhãn Nội quy và Checkbox vẫn giữ nguyên
      expect(find.text('Nội quy Chuyên mục'), findsOneWidget);
      expect(find.text('Thêm mục Trả lời nhanh'), findsOneWidget);
    });

    testWidgets('3. Kiểm tra Validation bắt buộc 3 trường (Tiêu đề, Nội quy, Nội dung)', (tester) async {
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

      // Bước 3.2: Nhập tiêu đề, nhưng Nội quy trống -> Báo lỗi nhập Nội quy Chuyên mục
      await tester.enterText(find.byType(TextField).first, 'Tiêu đề thông báo kiểm thử');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Xác nhận'));
      await tester.pumpAndSettle();

      expect(find.text('Vui lòng nhập Nội quy Chuyên mục'), findsWidgets);
      expect(mockRepo.createdTopics.isEmpty, isTrue);

      // Bước 3.3: Nhập Nội quy, nhưng Nội dung trống -> Báo lỗi nhập Nội dung Thông báo mới
      rulesController.document.insert(0, 'Nội quy chuyên mục kiểm thử bắt buộc tuân thủ');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Xác nhận'));
      await tester.pumpAndSettle();

      expect(find.text('Vui lòng nhập Nội dung Thông báo mới'), findsWidgets);
      expect(mockRepo.createdTopics.isEmpty, isTrue);
    });

    testWidgets('4. Kiểm tra Popup Dialog Xem trước động (Hình 3)', (tester) async {
      tester.view.physicalSize = const Size(1280, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final mockRepo = MockForumTopicRepository();
      final rulesController = quill.QuillController.basic();
      final contentController = quill.QuillController.basic();

      rulesController.document.insert(0, 'Quy định nội bộ chuyên mục hướng nghiệp.');
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

      // Bấm Xem trước
      await tester.tap(find.text('Xem trước'));
      await tester.pumpAndSettle();

      // Kiểm tra Header Dialog Xem trước: Thông báo mới (Dòng 1 chữ vàng sáng Hình 3)
      expect(find.text('Xem trước Thông Báo mới'), findsOneWidget);
      final titleWidget = tester.widget<Text>(find.text('Xem trước Thông Báo mới'));
      expect(titleWidget.style?.color, const Color(0xFFFFD700));

      // Kiểm tra Tên bài viết ở dòng 2 (chữ vàng sáng)
      expect(find.text('Bảo trì hệ thống định kỳ'), findsWidgets);
      final topicTitleWidget = tester.widget<Text>(find.text('Bảo trì hệ thống định kỳ').last);
      expect(topicTitleWidget.style?.color, const Color(0xFFFFD700));

      // Kiểm tra Dòng 3 "Mục Cho vào: Thông Báo" (chữ vàng sáng)
      expect(find.text('Mục Cho vào: Thông Báo'), findsOneWidget);
      final targetFolderWidget = tester.widget<Text>(find.text('Mục Cho vào: Thông Báo'));
      expect(targetFolderWidget.style?.color, const Color(0xFFFFD700));

      // Kiểm tra Nội quy và Nội dung
      expect(find.textContaining('Quy định nội bộ chuyên mục'), findsOneWidget);
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

      rulesController.document.insert(0, 'Quy chuẩn thảo luận diễn đàn.');
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

      // Nhập tiêu đề và Xác nhận tạo Thông báo
      await tester.enterText(find.byType(TextField).first, 'Thông báo chính thức V1');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Xác nhận'));
      await tester.pumpAndSettle();

      expect(mockRepo.createdTopics.length, equals(1));
      final topic1 = mockRepo.createdTopics.first;
      expect(topic1.title, equals('Thông báo chính thức V1'));
      expect(topic1.type, equals('thong_bao'));
      expect(topic1.rules, contains('Quy chuẩn thảo luận'));
      expect(topic1.enableQuickReply, isTrue);

      // Tạo Chủ đề thứ 2 và bỏ chọn Checkbox Trả lời nhanh
      await tester.tap(find.text('Tạo thêm Chủ đề mới'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, 'Chủ đề trao đổi học thuật');
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
    });
  });
}
