import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/models/forum_topic_model.dart';
import 'package:frontend/providers/draft_provider.dart';
import 'package:frontend/providers/upload_manager.dart';
import 'package:frontend/screens/forum/admin_create_topic_screen.dart';
import 'package:frontend/screens/forum/post_detail_screen.dart';
import 'package:frontend/services/forum_topic_repository.dart';
import 'package:frontend/services/signalr_service.dart';
import 'package:frontend/theme/app_theme.dart';
import 'package:frontend/widgets/forum_image_embed_builder.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _TrackingForumRepo implements ForumTopicRepository {
  ForumTopicItem? detail;
  int fetchDetailCount = 0;
  int fetchRepliesCount = 0;

  @override
  Future<ForumTopicItem?> fetchTopicDetail(dynamic id, {http.Client? client}) async {
    fetchDetailCount++;
    return detail;
  }

  @override
  Future<Map<String, dynamic>> fetchActiveViewers({
    String? categorySlug,
    int? topicId,
    http.Client? client,
  }) async =>
      {
        'users': ['Admin'],
        'guestCount': 0,
        'displayText': 'Admin và 0 khách',
      };

  @override
  Future<bool> sendHeartbeat({
    required String categorySlug,
    int? topicId,
    required String username,
    required bool isGuest,
    http.Client? client,
  }) async =>
      true;

  @override
  Future<bool> createTopic(ForumTopicItem item, {http.Client? client}) async => true;

  @override
  Future<bool> updateTopic(dynamic topicId, ForumTopicItem item, {http.Client? client}) async =>
      true;

  @override
  Future<bool> deleteTopics(List<dynamic> topicIds,
          {String? categorySlug, http.Client? client}) async =>
      true;

  @override
  Future<Map<String, dynamic>?> locateTopic({
    required String query,
    String? categorySlug,
    int pageSize = 25,
    http.Client? client,
  }) async =>
      null;

  @override
  Future<Map<String, List<ForumTopicItem>>?> fetchTopics(
          {String? categorySlug, http.Client? client}) async =>
      null;

  @override
  Future<List<Map<String, dynamic>>> fetchUserPosts(String username,
          {http.Client? client}) async =>
      [];

  @override
  Future<Map<String, dynamic>?> fetchTopicReplies(dynamic topicId,
      {int page = 1, int limit = 10, http.Client? client}) async {
    fetchRepliesCount++;
    return {
      'total': 0,
      'totalPages': 1,
      'page': page,
      'limit': limit,
      'items': <Map<String, dynamic>>[],
    };
  }

  @override
  Future<Map<String, dynamic>?> createTopicReply(
    dynamic topicId, {
    required String content,
    required String author,
    String? title,
    http.Client? client,
  }) async =>
      {
        'status': 'success',
        'data': {
          'id': 999,
          'topicId': topicId,
          'author': author,
          'title': title ?? 'Re: Test',
          'content': content,
        },
      };

  @override
  Future<Map<String, dynamic>?> fetchCategoryPermissions(int categoryId,
          {http.Client? client}) async =>
      {
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
      'auth_token': 'fake_admin_token',
      'username': 'admin',
      'role': 'admin',
    });
    UploadManager.instance.clearAllForTesting();
  });

  group('Kiểm thử Toàn diện 3 Module & Tối ưu Công nghệ 2026', () {
    test('Module 1 (Distributed GC): UploadManager quản lý vòng đời pending -> committed và đồng bộ Backend', () async {
      expect(identical(UploadManager(), UploadManager.instance), isTrue);

      Map<String, dynamic>? capturedCommitPayload;
      final mockClient = MockClient((request) async {
        expect(request.url.toString(), equals('http://localhost:8000/api/upload/image/commit'));
        capturedCommitPayload = jsonDecode(request.body) as Map<String, dynamic>;
        return http.Response(jsonEncode({'status': 'success', 'committed': 1}), 200);
      });

      UploadManager.instance.registerPending(
        filename: 'img_20261029_182324_13889f.png',
        url: 'http://localhost:8000/uploads/img_20261029_182324_13889f.png',
        sessionKey: 'session_edit_91',
      );

      expect(UploadManager.instance.pendingFilenames, contains('img_20261029_182324_13889f.png'));
      expect(UploadManager.instance.committedFilenames, isEmpty);

      final ok = await UploadManager.instance.commitForTopic(
        topicId: '91',
        sessionKey: 'session_edit_91',
        client: mockClient,
      );

      expect(ok, isTrue);
      expect(UploadManager.instance.pendingFilenames, isEmpty);
      expect(UploadManager.instance.committedFilenames, contains('img_20261029_182324_13889f.png'));
      expect(capturedCommitPayload?['topicId'], equals('91'));
      expect(capturedCommitPayload?['filenames'], contains('img_20261029_182324_13889f.png'));
    });

    testWidgets(
      'Module 2 (QuillEditor + KeepAlive BlockEmbed): Màn hình Sửa Thông báo render ảnh trực quan (KHÔNG hiện mã HTML thô <img src=...)',
      (tester) async {
        tester.view.physicalSize = const Size(1280, 1800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        const imgUrl = 'http://localhost:8000/uploads/img_20261029_182324_13889f.png';
        final repo = _TrackingForumRepo()
          ..detail = const ForumTopicItem(
            id: 91,
            title: 'Talkshow hướng nghiệp tháng 7/2026',
            type: 'thong_bao',
            categorySlug: 'thong-bao-su-kien',
            author: 'nncuong',
            content:
                'Nội dung thông báo mở đầu\n<img src="$imgUrl" style="max-width: 100%; height: auto;"/>\nĐoạn kết thông báo.',
            rules: 'Nội quy chuyên mục chuẩn.',
          );

        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider(create: (_) => DraftProvider()),
              ChangeNotifierProvider<UploadManager>.value(value: UploadManager.instance),
            ],
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              localizationsDelegates: const [
                quill.FlutterQuillLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: quill.FlutterQuillLocalizations.supportedLocales,
              home: Scaffold(
                body: SingleChildScrollView(
                  child: AdminCreateTopicScreen(
                    categorySlug: 'thong-bao-su-kien',
                    categoryTitle: 'Thông báo - Sự kiện',
                    isEditMode: true,
                    repository: repo,
                    initialTopicData: const {
                      'id': 91,
                      'title': 'Talkshow hướng nghiệp tháng 7/2026',
                      'type': 'thong_bao',
                      'content':
                          'Nội dung thông báo mở đầu<img src="$imgUrl" style="max-width: 100%; height: auto;"/>Đoạn kết thông báo.',
                      'rules': 'Nội quy chuyên mục chuẩn.',
                    },
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.runAsync(() async {
          await Future<void>.delayed(const Duration(milliseconds: 350));
        });
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));

        // 1. Tuyệt đối không hiển thị chuỗi mã HTML thô <img src=... trong trình soạn thảo
        expect(find.textContaining('<img src='), findsNothing);

        // 2. Render trực quan KeepAliveForumImage bên trong QuillEditor với cacheWidth + BoxFit.contain
        expect(find.byType(KeepAliveForumImage), findsWidgets);

        final renderedNetworkImage = tester.widgetList<Image>(find.byType(Image)).where((img) {
          ImageProvider provider = img.image;
          int? cachedW;
          if (provider is ResizeImage) {
            cachedW = provider.width;
            provider = provider.imageProvider;
          }
          return provider is NetworkImage &&
              provider.url == imgUrl &&
              cachedW != null &&
              img.fit == BoxFit.contain;
        });
        expect(renderedNetworkImage, isNotEmpty);
      },
    );

    testWidgets(
      'Module 3 (Singleton + Resilient SignalR + Noto Font Fallback): Chống nhân bản kết nối, tự động fetch lại dữ liệu khi Reconnect và cấu hình Font Fallback',
      (tester) async {
        tester.view.physicalSize = const Size(1280, 1600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        // 1. Kiểm tra Singleton Pattern tuyệt đối
        final s1 = SignalRService();
        final s2 = SignalRService();
        expect(identical(s1, s2), isTrue);
        expect(identical(s1, signalRService), isTrue);

        // 2. Kiểm tra cấu hình Automatic Reconnect chuẩn [0, 2000, 10000, 30000]
        expect(SignalRService.automaticReconnectDelays, equals(const [0, 2000, 10000, 30000]));

        // 3. Kiểm tra cô lập listener giữa nhiều màn hình (đóng màn hình con không làm mất listener màn hình cha)
        int parentCalls = 0;
        int childCalls = 0;
        void parentCb(List<Object?>? _) => parentCalls++;
        void childCb(List<Object?>? _) => childCalls++;

        signalRService.listenToTopicUpdated(parentCb);
        signalRService.listenToTopicUpdated(childCb);
        signalRService.removeTopicUpdatedListener(childCb);
        signalRService.dispatchForumEventForTest('OnTopicUpdated', const [
          {'id': 1}
        ]);
        expect(parentCalls, equals(1));
        expect(childCalls, equals(0));
        signalRService.removeTopicUpdatedListener(parentCb);

        // 4. Kiểm tra ThemeData Font Fallback triệt tiêu cảnh báo thiếu Noto fonts
        final theme = AppTheme.lightTheme;
        expect(theme.textTheme.bodyMedium?.fontFamily, equals('Roboto'));
        expect(
          theme.textTheme.bodyMedium?.fontFamilyFallback,
          containsAll(<String>['Roboto', 'NotoFallbackSymbols', 'Arial', 'Noto Sans']),
        );

        // 5. Kiểm tra Resilient SignalR: phát sự kiện onReconnected tự động kéo lại dữ liệu mới nhất
        final repo = _TrackingForumRepo()
          ..detail = const ForumTopicItem(
            id: 91,
            title: 'Talkshow hướng nghiệp tháng 7/2026',
            type: 'thong_bao',
            author: 'nncuong',
            content: 'Nội dung kiểm thử khôi phục kết nối mạng.',
          );

        await tester.pumpWidget(
          MaterialApp(
            theme: theme,
            home: Scaffold(
              body: SingleChildScrollView(
                child: PostDetailScreen(id: '91', repository: repo),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final initialDetailCount = repo.fetchDetailCount;
        final initialRepliesCount = repo.fetchRepliesCount;

        // Giả lập sự kiện mạng khôi phục kết nối WebSocket thành công
        signalRService.simulateReconnected('conn-restored-2026');
        await tester.pumpAndSettle();

        expect(repo.fetchDetailCount, greaterThan(initialDetailCount));
        expect(repo.fetchRepliesCount, greaterThan(initialRepliesCount));
      },
    );
  });
}
