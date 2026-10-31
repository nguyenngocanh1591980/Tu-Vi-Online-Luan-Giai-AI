import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/models/forum_topic_model.dart';
import 'package:frontend/providers/draft_provider.dart';
import 'package:frontend/screens/forum/post_reply_screen.dart';
import 'package:frontend/services/forum_topic_repository.dart';
import 'package:frontend/services/breadcrumb_state_service.dart';
import 'package:frontend/services/signalr_service.dart';
import 'package:frontend/widgets/breadcrumb_widget.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;

class MockPostReplyTopicRepository implements ForumTopicRepository {
  @override
  Future<ForumTopicItem?> fetchTopicDetail(dynamic id, {http.Client? client}) async {
    return const ForumTopicItem(
      id: '165',
      title: 'Talkshow hướng nghiệp tháng 7/2026',
      type: 'announcement',
      author: 'Admin',
      content: 'Nội dung bài viết gốc của chủ đề',
      createdAt: '10:00, 26/10/2026',
      categoryName: 'Thông báo - Sự kiện',
      categorySlug: 'thong-bao-su-kien',
    );
  }

  @override
  Future<Map<String, dynamic>?> fetchTopicReplies(dynamic topicId, {int page = 1, int limit = 10, http.Client? client}) async {
    return {
      'replies': [
        {
          'id': 'reply_1',
          'author': 'User1',
          'content': 'Phản hồi số 1',
          'created_at': '11:00, 26/10/2026',
          'authorRank': 'Thành viên',
        },
        {
          'id': 'reply_2',
          'author': 'User2',
          'content': 'Phản hồi số 2',
          'created_at': '12:00, 26/10/2026',
          'authorRank': 'Thành viên',
        },
      ],
      'total': 2,
    };
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('1. Kiểm thử Trả lời tổng (isQuoteAction = false): Hiển thị toàn bộ 3 bài viết chuẩn Hình 4', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 1024);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final mockRepo = MockPostReplyTopicRepository();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => DraftProvider()),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: PostReplyScreen(
                topicId: '165',
                isQuoteAction: false,
                repository: mockRepo,
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // 1. Khối "Xem lại chủ đề"
    expect(find.textContaining('Xem lại chủ đề'), findsOneWidget);

    // 2. Tổng số: 3 bài (1 gốc + 2 replies)
    expect(find.text('Tổng số: 3 bài'), findsOneWidget);

    // 3. Không có badge Snapshot vì đây là Trả lời tổng
    expect(find.text('Snapshot'), findsNothing);

    // 4. Có đủ cả 3 bài
    expect(find.text('Nội dung bài viết gốc của chủ đề'), findsOneWidget);
    expect(find.text('Phản hồi số 1'), findsOneWidget);
    expect(find.text('Phản hồi số 2'), findsOneWidget);
  });

  testWidgets('2. Kiểm thử Trả lời kèm trích dẫn (isQuoteAction = true, quotedPostIndex = 1): Cắt mảng hiển thị đúng 2 bài chuẩn Hình 2', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 1024);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final mockRepo = MockPostReplyTopicRepository();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => DraftProvider()),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: PostReplyScreen(
                topicId: '165',
                isQuoteAction: true,
                quotedPostIndex: 1, // Trích dẫn bài phản hồi thứ 1 (vị trí 1 tính từ 0)
                repository: mockRepo,
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // 1. Tổng số: 2 bài (Bài gốc index 0 + Phản hồi 1 index 1)
    expect(find.text('Tổng số: 2 bài'), findsOneWidget);

    // 2. Có badge Snapshot hiển thị chỉ báo khóa tĩnh
    expect(find.text('Snapshot'), findsOneWidget);

    // 3. Kiểm tra bài gốc và phản hồi 1 hiển thị
    expect(find.text('Nội dung bài viết gốc của chủ đề'), findsOneWidget);
    expect(find.text('Phản hồi số 1'), findsOneWidget);

    // 4. Phản hồi số 2 (index 2) KHÔNG hiển thị vì nằm sau bài trích dẫn
    expect(find.text('Phản hồi số 2'), findsNothing);
  });

  testWidgets('3. Kiểm thử SignalR Snapshot Guard: isQuoteAction = true không nhận bài mới; isQuoteAction = false nhận bài mới', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 1024);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final mockRepo = MockPostReplyTopicRepository();

    // A. Thử nghiệm với isQuoteAction = true (Snapshot Guard bật)
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => DraftProvider()),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: PostReplyScreen(
                topicId: '165',
                isQuoteAction: true,
                quotedPostIndex: 1,
                repository: mockRepo,
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('Tổng số: 2 bài'), findsOneWidget);

    // Giả lập SignalR phát sự kiện ReplyCreated cho topicId = 165
    final incomingReply = {
      'id': 'reply_realtime_99',
      'topicId': '165',
      'author': 'UserRealtime',
      'content': 'Bài mới real-time',
      'time': 'Vừa xong',
    };
    signalRService.dispatchForumEventForTest('ReplyCreated', [jsonEncode(incomingReply)]);
    await tester.pumpAndSettle();

    // Vẫn giữ nguyên 2 bài vì Snapshot Guard khóa luồng
    expect(find.text('Tổng số: 2 bài'), findsOneWidget);
    expect(find.text('Bài mới real-time'), findsNothing);
  });

  testWidgets('4. Kiểm thử Type-Safe Query Guard: Fallback an toàn khi quotedPostIndex không hợp lệ', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 1024);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final mockRepo = MockPostReplyTopicRepository();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => DraftProvider()),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: PostReplyScreen(
                topicId: '165',
                isQuoteAction: true,
                quotedPostIndex: -1, // Giá trị lỗi/âm
                repository: mockRepo,
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Tự động fallback về Trả lời tổng: hiển thị đủ cả 3 bài mà không crash màn hình đỏ
    expect(find.text('Tổng số: 3 bài'), findsOneWidget);
    expect(find.text('Nội dung bài viết gốc của chủ đề'), findsOneWidget);
    expect(find.text('Phản hồi số 1'), findsOneWidget);
    expect(find.text('Phản hồi số 2'), findsOneWidget);
  });

  testWidgets('5. Kiểm thử Breadcrumb: Hiển thị đủ 4 cấp động chuẩn xác', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 1024);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    BreadcrumbStateService.updateCurrentTopic(
      topicId: '165',
      categorySlug: 'thong-bao-su-kien',
      categoryTitle: 'Thông báo - Sự kiện',
      topicTitle: 'Talkshow hướng nghiệp tháng 7/2026',
    );

    final router = GoRouter(
      initialLocation: '/forum/topic/165',
      routes: [
        GoRoute(
          path: '/forum/topic/:id',
          builder: (context, state) => const Scaffold(
            body: Column(
              children: [
                BreadcrumbWidget(),
                Text('Post Detail Screen Content'),
              ],
            ),
          ),
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: router,
      ),
    );

    await tester.pumpAndSettle();

    // Kiểm tra 4 cấp đường dẫn
    // Cấp 1: Trang chủ
    expect(find.text('Trang chủ'), findsOneWidget);
    // Cấp 2: Diễn đàn
    expect(find.text('Diễn đàn'), findsOneWidget);
    // Cấp 3: Thông báo - Sự kiện
    expect(find.text('Thông báo - Sự kiện'), findsOneWidget);
    // Cấp 4: Tiêu đề bài viết
    expect(find.text('Talkshow hướng nghiệp tháng 7/2026'), findsOneWidget);
  });
}
