import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:frontend/models/forum_topic_model.dart';
import 'package:frontend/services/forum_topic_repository.dart';
import 'package:frontend/screens/forum/admin_create_topic_screen.dart';
import 'package:frontend/screens/forum/category_topics_screen.dart';
import 'package:frontend/utils/boxed_snack_bar.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;

/// Mock Repository để kiểm thử luồng tạo và hiển thị bài viết
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
    'users': ['ChatGPT User'],
    'guestCount': 0,
    'displayText': 'ChatGPT User và 0 khách',
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

  group('Kiểm thử Form Nhập liệu Động (AdminCreateTopicScreen) - Hình 9 & 10', () {
    testWidgets('Kiểm tra Header, 2 nút chức năng, Label Tên và Nút Nội dung theo State', (tester) async {
      tester.view.physicalSize = const Size(1280, 1400);
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

      // 1. Kiểm tra Header
      expect(find.text('Tạo thêm thông báo và Chủ đề mới (Ban Quản Trị)'), findsWidgets);
      expect(find.text('Về Chuyên mục'), findsOneWidget);

      // 2. Kiểm tra Row chứa 2 nút chức năng
      expect(find.text('Tạo thêm Thông Báo mới'), findsOneWidget);
      expect(find.text('Tạo thêm Chủ đề mới'), findsOneWidget);

      // 3. Mặc định State là Nút 1 (Thông báo): Label 'Tên Thông báo mới', hint 'Nhập Tên Thông báo mới', và nút 'Nội dung Thông báo mới'
      expect(find.text('Tên Thông báo mới'), findsOneWidget);
      expect(find.text('Nhập Tên Thông báo mới'), findsOneWidget);
      expect(find.text('Nội dung Thông báo mới'), findsOneWidget);
      expect(find.text('Biểu tượng Thông Báo hoặc Chủ đề mới'), findsOneWidget);

      // 4. Click chuyển sang Nút 2 (Chủ đề mới)
      await tester.tap(find.text('Tạo thêm Chủ đề mới'));
      await tester.pumpAndSettle();

      // Label, Hint và Nút nội dung tự động cập nhật sang Chủ đề (Hình 9)
      expect(find.text('Tên Chủ đề mới'), findsOneWidget);
      expect(find.text('Nhập Tên Chủ đề mới'), findsOneWidget);
      expect(find.text('Nội dung Chủ đề mới'), findsOneWidget);

      // 5. Click quay lại Nút 1 (Thông báo mới)
      await tester.tap(find.text('Tạo thêm Thông Báo mới'));
      await tester.pumpAndSettle();

      expect(find.text('Tên Thông báo mới'), findsOneWidget);
      expect(find.text('Nhập Tên Thông báo mới'), findsOneWidget);
      expect(find.text('Nội dung Thông báo mới'), findsOneWidget);
    });

    testWidgets('Kiểm tra Validation bắt buộc nhập tiêu đề và bắt buộc nhập nội dung (Not Null Rich Text)', (tester) async {
      tester.view.physicalSize = const Size(1280, 1400);
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

      // 1. Để trống tiêu đề và bấm Xác nhận -> Báo lỗi nhập Tên
      await tester.tap(find.text('Xác nhận'));
      await tester.pumpAndSettle();

      expect(find.text('Vui lòng nhập Tên Thông báo mới'), findsWidgets);
      expect(mockRepo.createdTopics.isEmpty, isTrue);

      // 2. Nhập tiêu đề nhưng để trống Nội quy -> Báo lỗi nhập Nội quy Chuyên mục
      await tester.enterText(find.byType(TextField).first, 'Thông báo bảo trì máy chủ');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Xác nhận'));
      await tester.pumpAndSettle();

      expect(find.text('Vui lòng nhập Nội quy Chuyên mục'), findsWidgets);
      expect(mockRepo.createdTopics.isEmpty, isTrue);
    });

    testWidgets('Kiểm tra Nút Xem trước mở Layout Preview', (tester) async {
      tester.view.physicalSize = const Size(1280, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final mockRepo = MockForumTopicRepository();
      final rulesController = quill.QuillController.basic();
      rulesController.document.insert(0, 'Nội quy chuyên mục quy định chung.');
      final quillController = quill.QuillController.basic();
      quillController.document.insert(0, 'Nội dung chi tiết thông báo xem trước');

      await tester.pumpWidget(
        buildBoxedApp(
          AdminCreateTopicScreen(
            repository: mockRepo,
            rulesQuillController: rulesController,
            quillController: quillController,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Nhập tiêu đề
      await tester.enterText(find.byType(TextField).first, 'Thông báo bảo trì hệ thống');
      await tester.pumpAndSettle();

      // Bấm Xem trước
      await tester.tap(find.text('Xem trước'));
      await tester.pumpAndSettle();

      // Dialog mở ra hiển thị tiêu đề và nút Đóng
      expect(find.text('Xem trước: Thông báo mới'), findsOneWidget);
      expect(find.text('Thông báo bảo trì hệ thống'), findsWidgets);
      expect(find.textContaining('Nội dung chi tiết thông báo'), findsWidgets);

      // Bấm Đóng dialog
      await tester.tap(find.text('Đóng'));
      await tester.pumpAndSettle();

      expect(find.text('Xem trước: Thông báo mới'), findsNothing);
    });

    testWidgets('Kiểm tra Nút Xác nhận gửi payload với type chính xác lên Repository khi đủ tiêu đề và nội dung', (tester) async {
      tester.view.physicalSize = const Size(1280, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final mockRepo = MockForumTopicRepository();
      final rulesController = quill.QuillController.basic();
      rulesController.document.insert(0, 'Nội quy chuyên mục quy định chung.');
      final quillController = quill.QuillController.basic();
      quillController.document.insert(0, 'Chi tiết nội dung bài viết từ Rich Text Editor');

      await tester.pumpWidget(
        buildBoxedApp(
          AdminCreateTopicScreen(
            repository: mockRepo,
            rulesQuillController: rulesController,
            quillController: quillController,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Tạo Thông báo mới
      await tester.enterText(find.byType(TextField).first, 'Thông báo quan trọng từ BQT');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Xác nhận'));
      await tester.pumpAndSettle();

      expect(mockRepo.createdTopics.length, equals(1));
      expect(mockRepo.createdTopics.first.title, equals('Thông báo quan trọng từ BQT'));
      expect(mockRepo.createdTopics.first.type, equals('thong_bao'));
      expect(mockRepo.createdTopics.first.content, contains('Chi tiết nội dung'));

      // 2. Chuyển sang tạo Chủ đề mới
      await tester.tap(find.text('Tạo thêm Chủ đề mới'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, 'Chủ đề thảo luận tử vi chuyên sâu');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Xác nhận'));
      await tester.pumpAndSettle();

      expect(mockRepo.createdTopics.length, equals(2));
      expect(mockRepo.createdTopics[1].title, equals('Chủ đề thảo luận tử vi chuyên sâu'));
      expect(mockRepo.createdTopics[1].type, equals('chu_de'));
    });
  });

  group('Kiểm thử Hiển thị Real-time trên CategoryTopicsScreen - Hình 1, 4 & 5', () {
    testWidgets('Kiểm tra text các nút Admin chuẩn xác (Ban Quản Trị)', (tester) async {
      tester.view.physicalSize = const Size(1280, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        buildBoxedApp(
          const CategoryTopicsScreen(slug: 'thong-bao-su-kien'),
        ),
      );
      await tester.pumpAndSettle();

      // Nút 1 & 2 đã đổi hậu tố thành Ban Quản Trị
      expect(find.text('Tạo thêm Thông báo và Chủ đề mới (Ban Quản Trị)'), findsOneWidget);
      expect(find.text('Sửa thông báo và Chủ đề (Ban Quản trị)'), findsOneWidget);
      // Nút 3 giữ nguyên
      expect(find.text('Xóa Thông báo và Chủ đề (Admin)'), findsOneWidget);
    });

    testWidgets('Dữ liệu mới tạo hiển thị ở DÒNG TRÊN CÙNG của bảng tương ứng (Hình 4 & Hình 5)', (tester) async {
      tester.view.physicalSize = const Size(1280, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final mockRepo = MockForumTopicRepository();
      mockRepo.mockData = {
        'pinned': [
          const ForumTopicItem(
            id: 101,
            title: 'THÔNG BÁO MỚI NHẤT VỪA TẠO',
            type: 'thong_bao',
            author: 'Ban Quản trị',
          ),
        ],
        'topics': [
          const ForumTopicItem(
            id: 201,
            title: 'CHỦ ĐỀ MỚI NHẤT VỪA TẠO',
            type: 'chu_de',
            author: 'Thành viên VIP',
          ),
        ],
        'all': [],
      };

      await tester.pumpWidget(
        buildBoxedApp(
          CategoryTopicsScreen(
            slug: 'thong-bao-su-kien',
            topicRepository: mockRepo,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Kiểm tra thông báo mới xuất hiện ở bảng Thông báo (Hình 4)
      expect(find.text('THÔNG BÁO MỚI NHẤT VỪA TẠO'), findsOneWidget);
      // Kiểm tra chủ đề mới xuất hiện ở bảng Chủ đề (Hình 5)
      expect(find.text('CHỦ ĐỀ MỚI NHẤT VỪA TẠO'), findsOneWidget);
    });
  });
}
