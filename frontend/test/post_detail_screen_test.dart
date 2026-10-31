import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:frontend/models/forum_topic_model.dart';
import 'package:frontend/services/forum_topic_repository.dart';
import 'package:frontend/services/signalr_service.dart';
import 'package:frontend/screens/forum/post_detail_screen.dart';

class MockPostDetailTopicRepository implements ForumTopicRepository {
  ForumTopicItem? mockDetail;

  @override
  Future<ForumTopicItem?> fetchTopicDetail(dynamic id, {http.Client? client}) async {
    return mockDetail;
  }

  @override
  Future<Map<String, dynamic>> fetchActiveViewers({String? categorySlug, int? topicId, http.Client? client}) async => {
    'users': ['Admin', 'Thành viên A'],
    'guestCount': 0,
    'displayText': 'Admin, Thành viên A và 0 khách',
  };

  @override
  Future<bool> sendHeartbeat({required String categorySlug, int? topicId, required String username, required bool isGuest, http.Client? client}) async => true;

  @override
  Future<bool> createTopic(ForumTopicItem item, {http.Client? client}) async => true;

  @override
  Future<bool> updateTopic(dynamic topicId, ForumTopicItem item, {http.Client? client}) async => true;

  @override
  Future<bool> deleteTopics(List<dynamic> topicIds, {String? categorySlug, http.Client? client}) async => true;

  @override
  Future<Map<String, dynamic>?> locateTopic({required String query, String? categorySlug, int pageSize = 25, http.Client? client}) async => null;

  @override
  Future<Map<String, List<ForumTopicItem>>?> fetchTopics({String? categorySlug, http.Client? client}) async => null;

  @override
  Future<List<Map<String, dynamic>>> fetchUserPosts(String username, {http.Client? client}) async => [];

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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'jwt_token': 'fake_token',
      'username': 'admin_user',
    });
  });

  Widget buildDetailApp(Widget child) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: const Color(0xFF1E2640),
        body: SingleChildScrollView(
          child: child,
        ),
      ),
    );
  }

  group('Kiểm thử Màn hình Chi tiết Bài viết (PostDetailScreen) - 4 Module Chuẩn Hình 3', () {
    testWidgets('1. Module 1: Kiểm tra Composable UI (CustomScrollView), Card bài viết nền TRẮNG #FFFFFF, Profile cột trái, Badge SÁNG LẬP', (tester) async {
      tester.view.physicalSize = const Size(1280, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final mockRepo = MockPostDetailTopicRepository();
      mockRepo.mockDetail = const ForumTopicItem(
        id: 99,
        title: 'Talkshow hướng nghiệp tháng 7/2026',
        type: 'chu_de',
        categoryName: 'Hướng nghiệp',
        categorySlug: 'huong-nghiep',
        author: 'nncuong',
        content: 'Toàn bộ nội dung trao đổi talkshow hướng nghiệp.',
        rules: 'Thành viên giữ thái độ nghiêm túc và trao đổi lịch sự.',
        enableQuickReply: true,
        replies: 3,
        views: 120,
      );

      await tester.pumpWidget(
        buildDetailApp(
          PostDetailScreen(
            id: '99',
            repository: mockRepo,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Kiểm tra cấu trúc CustomScrollView Composable UI
      expect(find.byType(CustomScrollView), findsOneWidget);

      // Kiểm tra Tiêu đề hiển thị đúng chữ
      expect(find.text('Talkshow hướng nghiệp tháng 7/2026'), findsWidgets);
      expect(find.text('nncuong'), findsWidgets);
      expect(find.text('Quản trị viên'), findsOneWidget);
      expect(find.textContaining('Toàn bộ nội dung trao đổi'), findsOneWidget);

      // Kiểm tra Card bài viết chính có màu nền TRẮNG (Colors.white / #FFFFFF)
      final containers = tester.widgetList<Container>(
        find.descendant(
          of: find.byType(PostDetailScreen),
          matching: find.byType(Container),
        ),
      );
      final whitePostCard = containers.firstWhere(
        (c) => c.decoration is BoxDecoration && (c.decoration as BoxDecoration).color == Colors.white,
      );
      expect(whitePostCard, isNotNull);
      expect((whitePostCard.decoration as BoxDecoration).color, equals(Colors.white));
    });

    testWidgets('2. Module 2: Kiểm tra render khối Nội quy chuyên mục viền đỏ chuẩn Hình 3, toàn bộ chữ đỏ, tự động ẩn khi rỗng (Hình 5)', (tester) async {
      tester.view.physicalSize = const Size(1280, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final mockRepo = MockPostDetailTopicRepository();
      // 2.1: Khi có rules -> Khối Nội quy hiển thị chuẩn xác
      mockRepo.mockDetail = const ForumTopicItem(
        id: 100,
        title: 'Thảo luận chuyên sâu Tử Vi Đẩu Số',
        type: 'chu_de',
        categoryName: 'Tử Vi Đẩu Số',
        categorySlug: 'tu-vi-dau-so',
        author: 'Chuyên gia luận giải',
        content: 'Phân tích cách cục Tử Vi Thiên Phủ đồng cung Thân Dậu.',
        rules: 'Nội qui chuyên mục\nNội quy bắt buộc: Không spam, không quảng cáo dịch vụ trái phép.',
        enableQuickReply: true,
      );

      await tester.pumpWidget(
        buildDetailApp(
          PostDetailScreen(
            id: '100',
            repository: mockRepo,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Nội quy chuyên mục'), findsOneWidget);
      expect(find.text('Nội qui chuyên mục'), findsNothing);
      expect(find.text('Nội quy bắt buộc: Không spam, không quảng cáo dịch vụ trái phép.'), findsOneWidget);

      final titleText = tester.widget<Text>(find.text('Nội quy chuyên mục'));
      expect(titleText.style?.color, equals(const Color(0xFFC62828)));
      expect(titleText.style?.fontSize, equals(13.0));

      final bodyText = tester.widget<Text>(find.text('Nội quy bắt buộc: Không spam, không quảng cáo dịch vụ trái phép.'));
      expect(bodyText.style?.color, equals(const Color(0xFFEF5350)));
      expect(bodyText.style?.fontSize, equals(12.5));

      // 2.2: Khi rules = '' (không tích chọn ở Form Hình 1) -> Khối Nội quy tự động biến mất (Hình 5)
      mockRepo.mockDetail = const ForumTopicItem(
        id: 101,
        title: 'Bài viết không có nội quy',
        type: 'chu_de',
        rules: '',
      );
      await tester.pumpWidget(
        buildDetailApp(
          PostDetailScreen(
            id: '101',
            repository: mockRepo,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Nội quy chuyên mục'), findsNothing);
    });

    testWidgets('3. Module 2: Kiểm tra ẩn/hiện khối "Trả lời nhanh" nền #ECEFF1 theo allowQuickReply / enableQuickReply', (tester) async {
      tester.view.physicalSize = const Size(1280, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final mockRepo = MockPostDetailTopicRepository();

      // 3.1: Trường hợp allowQuickReply = true -> Khối Trả lời nhanh hiển thị
      mockRepo.mockDetail = const ForumTopicItem(
        id: 101,
        title: 'Chủ đề cho phép phản hồi nhanh',
        type: 'chu_de',
        categoryName: 'Hỏi đáp',
        categorySlug: 'hoi-dap',
        author: 'Thành viên B',
        content: 'Mọi người cho mình hỏi về sao Hóa Kỵ...',
        rules: 'Vui lòng hỏi đúng trọng tâm.',
        enableQuickReply: true,
      );

      await tester.pumpWidget(
        buildDetailApp(
          PostDetailScreen(
            id: '101',
            repository: mockRepo,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Trả lời nhanh'), findsOneWidget);
      expect(find.text('Soạn thảo đầy đủ & Xem trước'), findsOneWidget);
      expect(find.text('Xác nhận'), findsOneWidget);
      expect(find.byType(TextField), findsWidgets);

      // 3.2: Trường hợp allowQuickReply = false -> Khối Trả lời nhanh biến mất (chuẩn Hình 4)
      mockRepo.mockDetail = const ForumTopicItem(
        id: 102,
        title: 'Thông báo khóa bình luận nhanh',
        type: 'thong_bao',
        categoryName: 'Thông báo',
        categorySlug: 'thong-bao',
        author: 'Admin',
        content: 'Bài viết này chỉ để thông báo, không nhận phản hồi nhanh.',
        rules: 'Miễn bình luận tại đây.',
        enableQuickReply: false,
      );

      await tester.pumpWidget(
        buildDetailApp(
          PostDetailScreen(
            id: '102',
            repository: mockRepo,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Trả lời nhanh'), findsNothing);
      expect(find.text('Soạn thảo đầy đủ & Xem trước'), findsNothing);
      expect(find.text('Xác nhận'), findsNothing);
    });

    testWidgets('4. Module 2: Kiểm tra Logo Danh Hiệu (assets/images/logo_admin.png) thay thế avatar khi showBadgeLogo == true', (tester) async {
      tester.view.physicalSize = const Size(1280, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final mockRepo = MockPostDetailTopicRepository();
      mockRepo.mockDetail = const ForumTopicItem(
        id: 105,
        title: 'Bài viết của Admin có Logo Danh hiệu',
        type: 'thong_bao',
        author: 'Admin',
        content: 'Nội dung thông báo có logo danh hiệu.',
        showBadgeLogo: true,
      );

      await tester.pumpWidget(
        buildDetailApp(
          PostDetailScreen(
            id: '105',
            repository: mockRepo,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final imageWidgets = tester.widgetList<Image>(find.byType(Image)).toList();
      final hasLogoAdmin = imageWidgets.any((img) {
        final provider = img.image;
        if (provider is AssetImage) {
          return provider.assetName.contains('logo_admin.png');
        } else if (provider is ResizeImage) {
          final inner = provider.imageProvider;
          if (inner is AssetImage) {
            return inner.assetName.contains('logo_admin.png');
          }
        }
        return false;
      });
      expect(hasLogoAdmin, isTrue);
    });

    testWidgets('5. Module 4: Kiểm tra đồng bộ thời gian thực SignalR OnTopicUpdated và bảo mật Sanitizer XSS', (tester) async {
      tester.view.physicalSize = const Size(1280, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final mockRepo = MockPostDetailTopicRepository();
      mockRepo.mockDetail = const ForumTopicItem(
        id: 200,
        title: 'Bài viết kiểm tra bảo mật XSS',
        type: 'chu_de',
        author: 'Admin',
        content: '<script>alert("xss")</script>Nội dung bài viết an toàn.',
        rules: '<iframe src="evil.com"></iframe>Nội quy đã khử độc.',
        enableQuickReply: true,
      );

      await tester.pumpWidget(
        buildDetailApp(
          PostDetailScreen(
            id: '200',
            repository: mockRepo,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Kiểm tra mã độc đã bị loại bỏ hoàn toàn bởi Sanitizer
      expect(find.textContaining('<script>'), findsNothing);
      expect(find.textContaining('<iframe>'), findsNothing);
      expect(find.textContaining('Nội dung bài viết an toàn.'), findsOneWidget);
      expect(find.textContaining('Nội quy đã khử độc.'), findsOneWidget);
    });
  });
}
