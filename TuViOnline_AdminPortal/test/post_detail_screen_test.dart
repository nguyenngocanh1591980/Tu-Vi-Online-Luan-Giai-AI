import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:frontend/models/forum_topic_model.dart';
import 'package:frontend/services/forum_topic_repository.dart';
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
  Future<Map<String, List<ForumTopicItem>>?> fetchTopics({String? categorySlug, http.Client? client}) async => null;

  @override
  Future<List<Map<String, dynamic>>> fetchUserPosts(String username, {http.Client? client}) async => [];

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

  group('Kiểm thử Màn hình Chi tiết Bài viết (PostDetailScreen) - Chuẩn 100% Hình 1', () {
    testWidgets('1. Kiểm tra Card bài viết nền TRẮNG #FFFFFF, Profile cột trái, Badge SÁNG LẬP chuẩn Hình 1', (tester) async {
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

      // Kiểm tra Tiêu đề hiển thị đúng chữ
      expect(find.text('Talkshow hướng nghiệp tháng 7/2026'), findsWidgets);
      expect(find.text('nncuong'), findsWidgets);
      expect(find.text('SÁNG LẬP'), findsOneWidget);
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

    testWidgets('2. Kiểm tra render khối Nội quy chuyên mục viền đỏ chuẩn Hình 3, toàn bộ chữ đỏ, không còn nút Tải lại tiêu chuẩn', (tester) async {
      tester.view.physicalSize = const Size(1280, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final mockRepo = MockPostDetailTopicRepository();
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

      // Kiểm tra nhãn "Nội quy chuyên mục" hiển thị 1 lần duy nhất, đã lọc bỏ dòng chữ lặp lại
      expect(find.text('Nội quy chuyên mục'), findsOneWidget);
      expect(find.text('Nội qui chuyên mục'), findsNothing);
      expect(find.text('Nội quy bắt buộc: Không spam, không quảng cáo dịch vụ trái phép.'), findsOneWidget);
      // Nút "Tải lại tiêu chuẩn" đã bị gỡ bỏ theo yêu cầu người dùng
      expect(find.text('Tải lại tiêu chuẩn'), findsNothing);

      // Kiểm tra màu chữ của Tiêu đề (đỏ đậm 13.0) và nội dung (đỏ 12.5)
      final titleText = tester.widget<Text>(find.text('Nội quy chuyên mục'));
      expect(titleText.style?.color, equals(const Color(0xFFC62828)));
      expect(titleText.style?.fontSize, equals(13.0));

      final bodyText = tester.widget<Text>(find.text('Nội quy bắt buộc: Không spam, không quảng cáo dịch vụ trái phép.'));
      expect(bodyText.style?.color, equals(const Color(0xFFEF5350)));
      expect(bodyText.style?.fontSize, equals(12.5));
    });

    testWidgets('3. Kiểm tra ẩn/hiện khối "Trả lời nhanh" nền #ECEFF1 theo cờ enableQuickReply', (tester) async {
      tester.view.physicalSize = const Size(1280, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final mockRepo = MockPostDetailTopicRepository();

      // 3.1: Trường hợp enableQuickReply = true -> Khối Trả lời nhanh hiển thị với 2 nút chuẩn phpBB
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

      // Kiểm tra Toolbar Rich Text đầy đủ chuẩn 100% Hình 2
      expect(find.text('B'), findsOneWidget);
      expect(find.text('I'), findsOneWidget);
      expect(find.text('U'), findsOneWidget);
      expect(find.text('Cỡ chữ'), findsOneWidget);
      expect(find.text('A'), findsOneWidget);
      expect(find.byIcon(Icons.format_list_numbered), findsOneWidget);
      expect(find.byIcon(Icons.format_list_bulleted), findsOneWidget);
      expect(find.byIcon(Icons.image_outlined), findsOneWidget);
      expect(find.byIcon(Icons.table_chart_outlined), findsOneWidget);
      expect(find.byIcon(Icons.smart_display_outlined), findsOneWidget);

      // Kiểm tra Khối Trả lời nhanh có nền #ECEFF1
      final containers = tester.widgetList<Container>(
        find.descendant(
          of: find.byType(PostDetailScreen),
          matching: find.byType(Container),
        ),
      );
      final quickReplyContainer = containers.firstWhere(
        (c) => c.decoration is BoxDecoration && (c.decoration as BoxDecoration).color == const Color(0xFFECEFF1),
      );
      expect(quickReplyContainer, isNotNull);

      // 3.2: Trường hợp enableQuickReply = false -> Khối Trả lời nhanh bị ẩn hoàn toàn
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

    testWidgets('4. Kiểm tra thanh Action Bar dưới chuẩn Hình 3, cụm tiện ích Hình 4 và Jump Dropdown chuẩn Hình 5', (tester) async {
      tester.view.physicalSize = const Size(1280, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final mockRepo = MockPostDetailTopicRepository();
      mockRepo.mockDetail = const ForumTopicItem(
        id: 103,
        title: 'Thông báo kiểm tra Footer',
        type: 'thong_bao',
        categoryName: 'Thông báo - Sự kiện',
        categorySlug: 'thong-bao-su-kien',
        author: 'Admin',
        content: 'Nội dung kiểm tra thanh bar dưới cùng.',
        rules: '',
        enableQuickReply: true,
        replies: 7,
      );

      await tester.pumpWidget(
        buildDetailApp(
          PostDetailScreen(
            id: '103',
            repository: mockRepo,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Kiểm tra thanh Action Bar trên chuẩn Hình 4 và thanh dưới chuẩn Hình 3
      expect(find.text('Trả lời bài viết'), findsWidgets);
      expect(find.byIcon(Icons.share), findsWidgets);
      expect(find.byIcon(Icons.build), findsWidgets);
      expect(find.text('Tìm trong chủ đề này'), findsOneWidget);
      expect(find.byIcon(Icons.settings), findsWidgets);
      // Nút sắp xếp [ ⇊ | ▾ ] chuẩn Hình 3 ở thanh dưới
      expect(find.byIcon(Icons.filter_list), findsOneWidget);

      // Kiểm tra cụm 4 nút tiện ích bài viết chuẩn 100% Hình 4
      expect(find.byIcon(Icons.flag_outlined), findsOneWidget);
      expect(find.byIcon(Icons.format_quote), findsWidgets);
      expect(find.byIcon(Icons.favorite), findsOneWidget);
      expect(find.text('0'), findsOneWidget);

      // Kiểm tra Jump Dropdown "Chuyển đến" hoạt động chuẩn Hình 5
      expect(find.byType(DropdownButton<String>), findsOneWidget);
      expect(find.text('Chuyển đến'), findsOneWidget);

      // Kiểm tra thanh Đang xem chuyên mục
      expect(
        find.byWidgetPredicate(
          (widget) => widget is RichText && widget.text.toPlainText().contains('Đang xem chuyên mục này:'),
        ),
        findsOneWidget,
      );
      // Nút giả lập bạn bè đã bị loại bỏ
      expect(find.text('Bạn bè: Quan điểm'), findsNothing);

      // Kiểm tra Khối Khám phá thêm (Hình 1)
      expect(find.text('Khám phá thêm'), findsOneWidget);
      expect(find.text('Tạo Diễn Đàn'), findsOneWidget);
      expect(find.text('Khám phá vũ trụ'), findsOneWidget);
      expect(find.text('Tư vấn phong thủy'), findsOneWidget);

      // Kiểm tra Footer điều hướng và phân trang
      expect(find.text('‹ Quay về "Thông báo - Sự kiện"'), findsOneWidget);
      expect(find.text('8 bài viết • Trang 1 trên 1'), findsWidgets);
    });
  });
}
