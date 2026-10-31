import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/models/forum_topic_model.dart';
import 'package:frontend/screens/forum/admin_edit_topics_screen.dart';
import 'package:frontend/screens/forum/admin_create_topic_screen.dart';
import 'package:frontend/services/forum_topic_repository.dart';
import 'package:frontend/utils/boxed_snack_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_quill/flutter_quill.dart' as quill;

class MockVerificationTopicRepo implements ForumTopicRepository {
  final List<ForumTopicItem> mockTopics = [];

  MockVerificationTopicRepo() {
    // Khởi tạo 60 bài viết để test phân trang 25 dòng/trang (Trang 1: 25, Trang 2: 25, Trang 3: 10)
    for (int i = 1; i <= 60; i++) {
      mockTopics.add(ForumTopicItem(
        id: i,
        title: 'Sự kiện kiểm thử số $i',
        author: 'Admin',
        views: 100 + i,
        replies: i,
        lastAuthor: 'Admin',
        lastTime: '10:30, 26/10/26',
        categorySlug: 'thong-bao-su-kien',
        type: 'chu_de',
      ));
    }
  }

  @override
  Future<Map<String, List<ForumTopicItem>>?> fetchTopics({String? categorySlug, http.Client? client}) async {
    return {
      'pinned': [],
      'topics': mockTopics,
      'all': mockTopics,
    };
  }

  @override
  Future<bool> createTopic(ForumTopicItem item, {http.Client? client}) async {
    mockTopics.insert(0, item);
    return true;
  }

  @override
  Future<bool> updateTopic(dynamic topicId, ForumTopicItem item, {http.Client? client}) async => true;

  @override
  Future<bool> deleteTopics(List<dynamic> topicIds, {String? categorySlug, http.Client? client}) async => true;

  @override
  Future<Map<String, dynamic>?> locateTopic({required String query, String? categorySlug, int pageSize = 25, http.Client? client}) async => null;

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
  Future<Map<String, dynamic>?> fetchTopicReplies(dynamic topicId, {int page = 1, int limit = 10, http.Client? client}) async => {
    'total': 0,
    'page': page,
    'limit': limit,
    'replies': <Map<String, dynamic>>[],
  };

  @override
  Future<Map<String, dynamic>?> createTopicReply(dynamic topicId, {required String content, required String author, String? title, http.Client? client}) async => {
    'id': 999,
    'content': content,
    'author': author,
    'title': title,
    'created_at': '10:30, 29/10/26',
  };

  @override
  Future<Map<String, dynamic>?> fetchCategoryPermissions(int categoryId, {http.Client? client}) async => {
    'canCreateTopic': true,
    'canReply': true,
    'canEditOwnPost': true,
    'canDeleteOwnPost': true,
  };
}

Widget buildTestApp(Widget child) {
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'jwt_token': 'fake_token',
      'username': 'admin',
    });
    globalSnackBarNotifier.value = null;
  });

  group('Kiểm thử Toàn diện 4 Module - Báo cáo Nghiêm ngặt', () {
    testWidgets('Module 3: Phân trang 25 dòng/trang & Xóa text Đánh dấu/Về (Hình 3)', (tester) async {
      tester.view.physicalSize = const Size(1280, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final repo = MockVerificationTopicRepo();

      await tester.pumpWidget(
        buildTestApp(
          AdminEditTopicsScreen(
            categorySlug: 'thong-bao-su-kien',
            repository: repo,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Kiểm tra tuyệt đối KHÔNG còn text "Đánh dấu đã xem tất cả" và "Về"
      expect(find.textContaining('Đánh dấu đã xem tất cả'), findsNothing);
      expect(find.text('Về'), findsNothing);

      // 2. Kiểm tra cụm phân trang xuất hiện (nút 1, 2, 3, Next)
      expect(find.text('1'), findsWidgets);
      expect(find.text('2'), findsWidgets);
      expect(find.text('3'), findsWidgets);
      expect(find.text('Next'), findsWidgets);

      // 3. Trang 1 hiển thị đúng 25 bài (từ số 1 đến 25)
      expect(find.text('Sự kiện kiểm thử số 1'), findsOneWidget);
      expect(find.text('Sự kiện kiểm thử số 25'), findsOneWidget);
      expect(find.text('Sự kiện kiểm thử số 26'), findsNothing);

      // 4. Chuyển sang Trang 2
      await tester.tap(find.text('2').first);
      await tester.pumpAndSettle();

      // Trang 2 hiển thị từ bài 26 đến 50
      expect(find.text('Sự kiện kiểm thử số 1'), findsNothing);
      expect(find.text('Sự kiện kiểm thử số 26'), findsOneWidget);
      expect(find.text('Sự kiện kiểm thử số 50'), findsOneWidget);
      expect(find.text('Sự kiện kiểm thử số 51'), findsNothing);

      // 5. Chuyển sang Trang 3
      await tester.tap(find.text('3').first);
      await tester.pumpAndSettle();

      // Trang 3 hiển thị 10 bài cuối (51 đến 60)
      expect(find.text('Sự kiện kiểm thử số 51'), findsOneWidget);
      expect(find.text('Sự kiện kiểm thử số 60'), findsOneWidget);
    });

    testWidgets('Module 4: Checkbox Nội quy Chuyên mục & AnimatedSize & Validation (Hình 4, 5)', (tester) async {
      tester.view.physicalSize = const Size(1280, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final repo = MockVerificationTopicRepo();
      final rulesController = quill.QuillController.basic();
      final contentController = quill.QuillController.basic();
      contentController.document.insert(0, 'Nội dung chi tiết thông báo.');

      await tester.pumpWidget(
        buildTestApp(
          AdminCreateTopicScreen(
            repository: repo,
            rulesQuillController: rulesController,
            quillController: contentController,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Kiểm tra sự tồn tại của AnimatedSize
      expect(find.byType(AnimatedSize), findsWidgets);

      // 2. Mặc định _showRules = false, Editor Nội quy ẩn
      expect(find.text('Nội quy Chuyên mục'), findsOneWidget);
      expect(find.byType(quill.QuillEditor), findsOneWidget); // Chỉ có content editor

      // 3. Tích chọn "Nội quy Chuyên mục" -> Editor hiển thị mượt mà
      await tester.tap(find.text('Nội quy Chuyên mục'));
      await tester.pumpAndSettle();
      expect(find.byType(quill.QuillEditor), findsNWidgets(2)); // Cả 2 editor đều xuất hiện

      // 4. Bỏ trống nội quy rồi bấm Xác nhận -> Báo lỗi "Vui lòng nhập nội quy"
      await tester.enterText(find.byType(TextField).first, 'Tiêu đề test validation');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Xác nhận'));
      await tester.pump();
      expect(find.text('Vui lòng nhập nội quy'), findsOneWidget);

      // 5. Nhập nội quy -> Bấm Xác nhận thành công
      rulesController.document.insert(0, 'Nội quy bắt buộc tuân thủ!');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Xác nhận'));
      await tester.pumpAndSettle();

      expect(repo.mockTopics.first.title, equals('Tiêu đề test validation'));
      expect(repo.mockTopics.first.rules, contains('Nội quy bắt buộc'));
      expect(repo.mockTopics.first.lastTime, isNot(contains('Vừa xong')));
      expect(RegExp(r'^\d{2}:\d{2}, \d{2}/\d{2}/\d{2}$').hasMatch(repo.mockTopics.first.lastTime), isTrue);
    });

    testWidgets('Module 1: ForumTopicItem fromMap loại bỏ hoàn toàn Vừa xong', (tester) async {
      final topicWithVuaXong = ForumTopicItem.fromMap({
        'id': 999,
        'title': 'Test bài viết vừa xong',
        'author': 'Tester',
        'lastTime': 'Vừa xong',
      });

      expect(topicWithVuaXong.lastTime, isNot(equals('Vừa xong')));
      expect(RegExp(r'^\d{2}:\d{2}, \d{2}/\d{2}/\d{2}$').hasMatch(topicWithVuaXong.lastTime), isTrue);
    });
  });
}
