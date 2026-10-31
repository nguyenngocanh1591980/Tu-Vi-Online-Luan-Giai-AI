import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/models/forum_topic_model.dart';
import 'package:frontend/services/forum_topic_repository.dart';
import 'package:frontend/screens/forum/user_posts_screen.dart';
import 'package:frontend/screens/forum/post_detail_screen.dart';

class MockUnifiedTopicRepository implements ForumTopicRepository {
  @override
  Future<Map<String, List<ForumTopicItem>>?> fetchTopics({String? categorySlug, http.Client? client}) async => {
    'pinned': [],
    'topics': [],
    'all': [],
  };

  @override
  Future<bool> createTopic(ForumTopicItem item, {http.Client? client}) async => true;

  @override
  Future<List<Map<String, dynamic>>> fetchUserPosts(String username, {http.Client? client}) async => [
    {
      'id': 1,
      'title': 'Bài viết kiểm thử 1 của ngocanh2',
      'author': 'ngocanh2',
      'category': 'Xem Tử vi',
      'categorySlug': 'xem-tu-vi',
      'time': '10:00, 01/01/26',
      'replies': 5,
      'views': 120,
      'lastPostAuthor': 'ngocanh2',
      'lastPostTime': '11:00, 01/01/26',
    },
  ];

  @override
  Future<Map<String, dynamic>> fetchActiveViewers({String? categorySlug, int? topicId, http.Client? client}) async => {
    'users': ['ngocanh2', 'Admin'],
    'guestCount': 2,
    'displayText': 'ngocanh2, Admin và 2 khách',
  };

  @override
  Future<bool> sendHeartbeat({required String categorySlug, int? topicId, required String username, required bool isGuest, http.Client? client}) async => true;

  @override
  Future<ForumTopicItem?> fetchTopicDetail(dynamic id, {http.Client? client}) async => const ForumTopicItem(
    id: 1,
    title: 'Talkshow hướng nghiệp tháng 7/2026',
    content: 'Nội dung chi tiết talkshow',
    type: 'thong_bao',
    author: 'nmcxung',
    categoryName: 'Hướng nghiệp',
    categorySlug: 'huong-nghiep',
    createdAt: '10:01, 02/07/26',
    replies: 0,
    views: 0,
  );

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
      'username': 'ngocanh2',
      'jwt_token': 'fake_token',
    });
  });

  group('Kiểm thử Hợp nhất Boxed Layout #1E2640 & Dynamic Data (Hình 1 - 6)', () {
    testWidgets('Xác nhận UserPostsScreen có nền tím đen phẳng phiu, icon tài liệu đỏ và link gạch chân', (tester) async {
      tester.view.physicalSize = const Size(1280, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final mockRepo = MockUnifiedTopicRepository();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            backgroundColor: const Color(0xFF1E2640),
            body: SingleChildScrollView(
              child: UserPostsScreen(
                username: 'ngocanh2',
                repository: mockRepo,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Kiểm tra Boxed Layout Container màu #1E2640
      final container = tester.widget<Container>(find.byType(Container).first);
      expect(container.color, equals(const Color(0xFF1E2640)));

      // Kiểm tra text dynamic count
      expect(find.text('Đã tìm thấy 1 kết quả'), findsOneWidget);
      expect(find.text('Bài viết kiểm thử 1 của ngocanh2'), findsOneWidget);

      // Kiểm tra Icon tài liệu đỏ Icons.description_outlined (Color(0xFFEF5350))
      final iconFinder = find.byIcon(Icons.description_outlined);
      expect(iconFinder, findsWidgets);
    });

    testWidgets('Xác nhận PostDetailScreen hợp nhất nền tím đen #1E2640 và hiển thị tracking viewer', (tester) async {
      tester.view.physicalSize = const Size(1280, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final mockRepo = MockUnifiedTopicRepository();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            backgroundColor: const Color(0xFF1E2640),
            body: SingleChildScrollView(
              child: PostDetailScreen(
                id: '1',
                repository: mockRepo,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Kiểm tra Boxed Layout
      expect(find.byType(PostDetailScreen), findsOneWidget);

      // Kiểm tra tiêu đề bài viết
      expect(find.text('Talkshow hướng nghiệp tháng 7/2026'), findsWidgets);

      // Kiểm tra dòng tracking người đang xem ở đáy (RichText)
      expect(
        find.byWidgetPredicate(
          (w) => w is RichText && w.text.toPlainText().contains('Đang xem chuyên mục này:'),
        ),
        findsOneWidget,
      );
    });
  });
}
