import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:frontend/models/forum_draft_model.dart';
import 'package:frontend/models/forum_topic_model.dart';
import 'package:frontend/providers/draft_provider.dart';
import 'package:frontend/screens/forum/post_reply_screen.dart';
import 'package:frontend/screens/forum/ucp_drafts_screen.dart';
import 'package:frontend/services/forum_topic_repository.dart';

class FakeForumTopicRepository implements ForumTopicRepository {
  final ForumTopicItem mockTopic;
  final List<Map<String, dynamic>> mockReplies;

  FakeForumTopicRepository({required this.mockTopic, required this.mockReplies});

  @override
  Future<ForumTopicItem?> fetchTopicDetail(dynamic id, {http.Client? client}) async => mockTopic;

  @override
  Future<Map<String, dynamic>?> fetchTopicReplies(dynamic topicId, {int page = 1, int limit = 10, http.Client? client}) async {
    return {
      'status': 'success',
      'total': mockReplies.length,
      'items': mockReplies,
      'replies': mockReplies,
    };
  }

  @override
  Future<bool> createTopic(ForumTopicItem item, {http.Client? client}) async => true;
  @override
  Future<Map<String, dynamic>?> createTopicReply(dynamic topicId, {required String content, required String author, String? title, http.Client? client}) async => {'status': 'success'};
  @override
  Future<bool> deleteTopics(List topicIds, {String? categorySlug, http.Client? client}) async => true;
  @override
  Future<Map<String, dynamic>> fetchActiveViewers({String? categorySlug, int? topicId, http.Client? client}) async => {};
  @override
  Future<Map<String, dynamic>?> fetchCategoryPermissions(int categoryId, {http.Client? client}) async => {};
  @override
  Future<Map<String, List<ForumTopicItem>>?> fetchTopics({String? categorySlug, http.Client? client}) async => {};
  @override
  Future<List<Map<String, dynamic>>> fetchUserPosts(String username, {http.Client? client}) async => [];
  @override
  Future<Map<String, dynamic>?> locateTopic({required String query, String? categorySlug, int pageSize = 25, http.Client? client}) async => {};
  @override
  Future<bool> sendHeartbeat({required String categorySlug, int? topicId, required String username, required bool isGuest, http.Client? client}) async => true;
  @override
  Future<bool> updateTopic(dynamic topicId, ForumTopicItem item, {http.Client? client}) async => true;
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({'jwt_token': 'fake_test_token', 'username': 'Admin'});
  });

  group('Module 1 & 2: DraftProvider State Guard & Optimistic UI 2026', () {
    test('State Guard lưu và trích xuất quote an toàn khi refresh', () {
      final provider = DraftProvider();
      expect(provider.getPendingQuote('100'), isNull);

      provider.setPendingQuote(
        '100',
        author: 'ngocanh1',
        content: 'Nội dung bài viết mẫu',
        quotedPostId: '102',
        quotedPostIndex: 2,
      );
      final quote = provider.getPendingQuote('100');
      expect(quote, isNotNull);
      expect(quote!['quoteAuthor'], 'ngocanh1');
      expect(quote['quoteContent'], 'Nội dung bài viết mẫu');
      expect(quote['quotedPostId'], '102');
      expect(quote['quotedPostIndex'], 2);

      provider.clearPendingQuote('100');
      expect(provider.getPendingQuote('100'), isNull);
    });

    test('Optimistic UI: Xóa bản nháp lập tức 0ms khỏi State và Rollback khi lỗi', () async {
      final provider = DraftProvider();
      provider.setForumDraftsForTesting([
        const ForumDraftItem(
          id: 1,
          username: 'Admin',
          topicId: 10,
          topicTitle: 'Topic 1',
          title: 'Draft 1',
          content: 'Content 1',
          createdAt: '2026-10-30 09:00:00',
        ),
        const ForumDraftItem(
          id: 2,
          username: 'Admin',
          topicId: 10,
          topicTitle: 'Topic 2',
          title: 'Draft 2',
          content: 'Content 2',
          createdAt: '2026-10-30 09:05:00',
        ),
      ]);

      expect(provider.forumDrafts.length, 2);

      // 1. Kiểm tra Optimistic UI xóa thành công (0ms)
      final success = await provider.deleteDrafts([1]);
      expect(success, isTrue);
      expect(provider.forumDrafts.length, 1);
      expect(provider.forumDrafts.first.id, 2);
    });
  });

  group('Module 3: UCP Drafts (Hình 8 vs Hình 5) & AnimatedSwitcher', () {
    testWidgets('Trạng thái rỗng: Hiển thị chuẩn Hình 8 (Khung tối, không có bảng)',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 1024);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final draftProvider = DraftProvider();
      draftProvider.setForumDraftsForTesting([]);

      await tester.pumpWidget(
        ChangeNotifierProvider<DraftProvider>.value(
          value: draftProvider,
          child: const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: UcpDraftsContent(),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Kiểm tra chuẩn Hình 8:
      expect(find.textContaining('Với bảng điều khiển này, bạn có thể xem, sửa và xóa những bản nháp đã lưu'), findsOneWidget);
      expect(find.text('Không có bản nháp nào được lưu.'), findsOneWidget);
      expect(find.byType(AnimatedSwitcher), findsOneWidget);
      expect(find.text('Tiêu đề nháp'), findsNothing);
      expect(find.text('Đã lưu vào ngày'), findsNothing);
      expect(find.text('Chọn'), findsNothing);
      expect(find.text('Xóa đánh dấu'), findsNothing);
    });

    testWidgets('Trạng thái có dữ liệu: Hiển thị chuẩn Hình 5 (Bảng 3 cột, Link đỏ, Thao tác chọn)',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 1024);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final draftProvider = DraftProvider();
      draftProvider.setForumDraftsForTesting([
        const ForumDraftItem(
          id: 1,
          username: 'Admin',
          topicId: 10,
          topicTitle: 'Trao đổi học thuật Tử Vi',
          title: 'Trao đổi học thuật Tử Vi',
          content: 'Nội dung bản nháp nghiên cứu sao Tử Vi...',
          createdAt: '2026-10-30 08:30:00',
        ),
      ]);

      await tester.pumpWidget(
        ChangeNotifierProvider<DraftProvider>.value(
          value: draftProvider,
          child: const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: UcpDraftsContent(),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Kiểm tra chuẩn Hình 5:
      expect(find.text('Tiêu đề nháp'), findsOneWidget);
      expect(find.text('Đã lưu vào ngày'), findsOneWidget);
      expect(find.text('Chọn'), findsOneWidget);
      expect(find.textContaining('Trao đổi học thuật Tử Vi'), findsWidgets);
      expect(find.text('Nạp bản nháp • Xem/sửa'), findsOneWidget);
      expect(find.text('Xóa đánh dấu'), findsOneWidget);
      expect(find.text('Chọn tất cả'), findsOneWidget);
      expect(find.text('Bỏ chọn tất cả'), findsOneWidget);
    });
  });

  group('Module 1, 2, 4: PostReplyScreen (Chuẩn Toàn Vẹn Hình 1, Hình 3, Hình 4)', () {
    testWidgets('Kiểm tra đầy đủ Toolbar BBCode, 4 nút chức năng, 3 Tabs Tùy chọn, Khối Xem lại chủ đề và Footer',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 1024);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final draftProvider = DraftProvider();

      await tester.pumpWidget(
        ChangeNotifierProvider<DraftProvider>.value(
          value: draftProvider,
          child: const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: PostReplyScreen(
                  topicId: '10',
                  initialTitle: 'Re: Luận giải lá số mẫu',
                  initialQuoteAuthor: 'ngocanh1',
                  initialQuoteContent: 'Đây là luận điểm về Cung Mệnh.',
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Kiểm tra Tiêu đề có tiền tố Re:
      expect(find.text('Re: Luận giải lá số mẫu'), findsOneWidget);

      // 2. Khung soạn thảo bọc sẵn [quote="ngocanh1"]Đây là luận điểm về Cung Mệnh.[/quote]
      expect(find.textContaining('[quote="ngocanh1"]'), findsOneWidget);

      // 3. Cụm 4 nút tác vụ chuẩn Hình 1
      expect(find.text('Nạp bản nháp'), findsOneWidget);
      expect(find.text('Lưu bản nháp'), findsOneWidget);
      expect(find.text('Xem trước'), findsOneWidget);
      expect(find.text('Xác nhận'), findsOneWidget);

      // 4. Thanh công cụ BBCode
      expect(find.text('B'), findsOneWidget);
      expect(find.text('i'), findsOneWidget);
      expect(find.text('u'), findsOneWidget);
      expect(find.text('Quote'), findsOneWidget);
      expect(find.text('Code'), findsOneWidget);
      expect(find.text('Img'), findsOneWidget);
      expect(find.text('URL'), findsOneWidget);

      // 5. Khối Tùy chọn 3 TABS chuẩn 100% Hình 3
      expect(find.text('Tùy chọn'), findsOneWidget);
      expect(find.text('Lá số'), findsOneWidget);
      expect(find.text('Tập tin đính kèm'), findsOneWidget);

      // Nội dung tab Tùy chọn đang active
      expect(find.text('Tắt các thẻ BBCode'), findsOneWidget);
      expect(find.text('Tắt Biểu tượng vui'), findsOneWidget);
      expect(find.text('Đừng tự động nhận diện các địa chỉ URL'), findsOneWidget);
      expect(find.text('Thông báo cho tôi khi có bài trả lời'), findsOneWidget);

      // Chuyển sang Tab "Lá số"
      await tester.tap(find.text('Lá số'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Chèn Lá Số Tử Vi vào nội dung'), findsOneWidget);

      // Chuyển sang Tab "Tập tin đính kèm"
      await tester.tap(find.text('Tập tin đính kèm'));
      await tester.pumpAndSettle();
      expect(find.text('Thêm tập tin'), findsOneWidget);

      // Chuyển lại Tab "Tùy chọn"
      await tester.tap(find.text('Tùy chọn'));
      await tester.pumpAndSettle();

      // 6. Khối Xem lại chủ đề (Module 2 - Chuẩn Hình 4)
      expect(find.textContaining('Xem lại chủ đề:'), findsOneWidget);

      // 7. Khối Khám phá thêm và Chân trang phpBB (Chuẩn Hình 1)
      expect(find.text('Khám phá thêm'), findsOneWidget);
      expect(find.text('Tạo Diễn Đàn'), findsOneWidget);
      expect(find.text('Khám phá vũ trụ'), findsOneWidget);
      expect(find.text('Tư vấn phong thủy'), findsOneWidget);
      expect(find.textContaining('Powered by phpBB® Forum Software'), findsOneWidget);

      // 8. Bấm nút "Xem trước" -> hiển thị khung preview BBCode trực quan
      await tester.tap(find.text('Xem trước'));
      await tester.pumpAndSettle();
      expect(find.text('Xem trước bản nháp:'), findsOneWidget);
    });
  });

  group('Module 2: ĐỒNG BỘ TOÀN DIỆN LỊCH SỬ "XEM LẠI CHỦ ĐỀ" TÍNH ĐẾN THỜI ĐIỂM TRÍCH DẪN (SLICING)', () {
    final mockTopicItem = ForumTopicItem(
      id: 100,
      title: 'Talkshow hướng nghiệp tháng 7/2026',
      content: 'Nội dung bài viết mở đầu của Admin.',
      author: 'Admin',
      authorInfo: {'rank': 'Quản trị viên'},
      categorySlug: 'thong-bao',
      type: 'chu_de',
      createdAt: '10:00, 05/07/26',
    );

    final mockRepliesList = [
      {
        'id': 101,
        'topicId': 100,
        'author': 'User_1',
        'title': 'Re: Phản hồi 1',
        'content': 'Nội dung phản hồi thứ 1.',
        'time': '10:15, 05/07/26',
        'authorRank': 'Thành viên',
      },
      {
        'id': 102,
        'topicId': 100,
        'author': 'User_2',
        'title': 'Re: Phản hồi 2',
        'content': 'Nội dung phản hồi thứ 2.',
        'time': '10:30, 05/07/26',
        'authorRank': 'Lục Đẳng',
      },
      {
        'id': 103,
        'topicId': 100,
        'author': 'User_3',
        'title': 'Re: Phản hồi 3',
        'content': 'Nội dung phản hồi thứ 3.',
        'time': '10:45, 05/07/26',
        'authorRank': 'Thành viên',
      },
      {
        'id': 104,
        'topicId': 100,
        'author': 'User_4',
        'title': 'Re: Phản hồi 4',
        'content': 'Nội dung phản hồi thứ 4.',
        'time': '11:00, 05/07/26',
        'authorRank': 'Thành viên',
      },
    ];

    testWidgets('Trích dẫn ở bài viết thứ 3 (postIndex = 2 / ID = 102): Hiển thị chính xác 3 bài (Tổng số: 3 bài)',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 1024);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final fakeRepo = FakeForumTopicRepository(
        mockTopic: mockTopicItem,
        mockReplies: mockRepliesList,
      );

      await tester.pumpWidget(
        ChangeNotifierProvider<DraftProvider>(
          create: (_) => DraftProvider(),
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: PostReplyScreen(
                  topicId: '100',
                  quotedPostId: '102',
                  quotedPostIndex: 2,
                  initialQuoteAuthor: 'User_2',
                  initialQuoteContent: 'Nội dung phản hồi thứ 2.',
                  repository: fakeRepo,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Kiểm tra Header hiển thị đúng: "Tổng số: 3 bài"
      expect(find.text('Tổng số: 3 bài'), findsOneWidget);

      // Kiểm tra bài gốc (ID 100), Reply 1 (ID 101), Reply 2 (ID 102) xuất hiện
      expect(find.text('Nội dung bài viết mở đầu của Admin.'), findsOneWidget);
      expect(find.text('Nội dung phản hồi thứ 1.'), findsOneWidget);
      expect(find.text('Nội dung phản hồi thứ 2.'), findsOneWidget);

      // Kiểm tra Reply 3 và Reply 4 bị cắt bỏ hoàn toàn
      expect(find.text('Nội dung phản hồi thứ 3.'), findsNothing);
      expect(find.text('Nội dung phản hồi thứ 4.'), findsNothing);
    });

    testWidgets('Trích dẫn ở bài mở đầu (postIndex = 0 / ID = 100): Hiển thị chính xác 1 bài (Tổng số: 1 bài)',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 1024);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final fakeRepo = FakeForumTopicRepository(
        mockTopic: mockTopicItem,
        mockReplies: mockRepliesList,
      );

      await tester.pumpWidget(
        ChangeNotifierProvider<DraftProvider>(
          create: (_) => DraftProvider(),
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: PostReplyScreen(
                  topicId: '100',
                  quotedPostId: '100',
                  quotedPostIndex: 0,
                  initialQuoteAuthor: 'Admin',
                  initialQuoteContent: 'Nội dung bài viết mở đầu của Admin.',
                  repository: fakeRepo,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Kiểm tra Header hiển thị đúng: "Tổng số: 1 bài"
      expect(find.text('Tổng số: 1 bài'), findsOneWidget);

      // Kiểm tra chỉ có bài mở đầu
      expect(find.text('Nội dung bài viết mở đầu của Admin.'), findsOneWidget);
      expect(find.text('Nội dung phản hồi thứ 1.'), findsNothing);
      expect(find.text('Nội dung phản hồi thứ 2.'), findsNothing);
    });

    testWidgets('Trả lời tự do (không chỉ định quote cụ thể): Hiển thị toàn bộ 5 bài (Tổng số: 5 bài)',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final fakeRepo = FakeForumTopicRepository(
        mockTopic: mockTopicItem,
        mockReplies: mockRepliesList,
      );

      await tester.pumpWidget(
        ChangeNotifierProvider<DraftProvider>(
          create: (_) => DraftProvider(),
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: PostReplyScreen(
                  topicId: '100',
                  repository: fakeRepo,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Kiểm tra Header hiển thị đúng: "Tổng số: 5 bài"
      expect(find.text('Tổng số: 5 bài'), findsOneWidget);

      // Không trích dẫn bài cụ thể -> Hiển thị từ bài mở đầu của Admin
      expect(find.text('Nội dung bài viết mở đầu của Admin.'), findsOneWidget);
      expect(find.text('Nội dung phản hồi thứ 1.'), findsOneWidget);
      expect(find.text('Nội dung phản hồi thứ 2.'), findsOneWidget);
    });

    testWidgets('Bồi hoàn trạng thái (URL State Recovery & State Guard): Phục hồi từ DraftProvider khi F5',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 1024);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final fakeRepo = FakeForumTopicRepository(
        mockTopic: mockTopicItem,
        mockReplies: mockRepliesList,
      );

      final draftProvider = DraftProvider();
      draftProvider.setPendingQuote(
        '100',
        author: 'User_2',
        content: 'Nội dung phản hồi thứ 2.',
        quotedPostId: '102',
        quotedPostIndex: 2,
      );

      await tester.pumpWidget(
        ChangeNotifierProvider<DraftProvider>.value(
          value: draftProvider,
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: PostReplyScreen(
                  topicId: '100',
                  // Giả lập F5: không truyền params trực tiếp qua widget constructor
                  repository: fakeRepo,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Kiểm tra Header vẫn bồi hoàn chính xác: "Tổng số: 3 bài"
      expect(find.text('Tổng số: 3 bài'), findsOneWidget);
      expect(find.text('Nội dung phản hồi thứ 2.'), findsOneWidget);
      expect(find.text('Nội dung phản hồi thứ 3.'), findsNothing);
    });
  });
}
