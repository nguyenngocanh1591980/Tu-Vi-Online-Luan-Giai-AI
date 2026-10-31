import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:frontend/models/forum_topic_model.dart';
import 'package:frontend/screens/forum/post_detail_screen.dart';
import 'package:frontend/services/forum_topic_repository.dart';
import 'package:frontend/widgets/forum_image_embed_builder.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class MockPasteTopicRepo implements ForumTopicRepository {
  ForumTopicItem? mockDetail;

  @override
  Future<ForumTopicItem?> fetchTopicDetail(dynamic id, {http.Client? client}) async => mockDetail;

  @override
  Future<Map<String, dynamic>> fetchActiveViewers({String? categorySlug, int? topicId, http.Client? client}) async => {
    'users': ['Admin'],
    'guestCount': 0,
    'displayText': 'Admin và 0 khách',
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
    'page': 1,
    'limit': 10,
    'items': <Map<String, dynamic>>[],
    'replies': <Map<String, dynamic>>[],
  };

  @override
  Future<Map<String, dynamic>?> createTopicReply(dynamic topicId, {required String content, required String author, String? title, http.Client? client}) async => null;

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
      'username': 'Admin',
      'role': 'admin',
    });
  });

  group('Kiểm thử Tích hợp Copy/Paste Ảnh vào Editor & QuickReply (Module 1 & 2)', () {
    test('1. Chèn BlockEmbed.image(url) vào đúng vị trí con trỏ trong QuillController (KHÔNG chèn mã HTML thô)', () {
      final controller = quill.QuillController.basic();
      controller.document.insert(0, 'Chào mừng các bạn đến diễn đàn!\n');

      // Giả lập con trỏ ở vị trí 10
      controller.updateSelection(
        const TextSelection.collapsed(offset: 10),
        quill.ChangeSource.local,
      );

      const imageUrl = 'http://localhost:8000/uploads/img_20261029_test.jpg';
      insertImageBlockIntoQuill(controller, imageUrl);

      // PlainText tuyệt đối không chứa mã HTML thô <img src=...
      final plain = controller.document.toPlainText();
      expect(plain.contains('<img'), isFalse);

      // Delta chứa BlockEmbed image chuẩn xác
      final deltaOps = controller.document.toDelta().toJson();
      final hasImageEmbed = deltaOps.any(
        (op) => op['insert'] is Map && op['insert']['image'] == imageUrl,
      );
      expect(hasImageEmbed, isTrue);

      // Khi serialize để lưu vào Docker DB vẫn sinh ra thẻ <img> chuẩn tỷ lệ
      final serialized = serializeQuillDocumentToForumContent(controller.document);
      expect(
        serialized.contains(
          '<img src="http://localhost:8000/uploads/img_20261029_test.jpg" style="max-width: 100%; height: auto;"/>',
        ),
        isTrue,
      );
    });

    test('2. Chèn thẻ HTML <img> vào QuickReply TextEditingController', () {
      final quickReply = TextEditingController(text: 'Nội dung phản hồi');
      quickReply.selection = const TextSelection.collapsed(offset: 8);

      const imageUrl = 'http://localhost:8000/uploads/img_reply_test.jpg';
      const tag = '<img src="$imageUrl" style="max-width: 100%; height: auto;"/>';

      final text = quickReply.text;
      final sel = quickReply.selection;
      final start = sel.start;
      final end = sel.end;
      final newText = text.replaceRange(start, end, tag);

      quickReply.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: start + tag.length),
      );

      expect(quickReply.text.contains('<img src="http://localhost:8000/uploads/img_reply_test.jpg" style="max-width: 100%; height: auto;"/>'), isTrue);
      expect(quickReply.selection.baseOffset, equals(8 + tag.length));
    });

    testWidgets('3. PostDetailScreen render đúng thẻ <img> đã dán qua KeepAliveForumImage (có cacheWidth)', (tester) async {
      tester.view.physicalSize = const Size(1280, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final repo = MockPasteTopicRepo();
      repo.mockDetail = const ForumTopicItem(
        id: 301,
        title: 'Chủ đề chứa ảnh vừa dán từ clipboard',
        type: 'thong_bao',
        author: 'Admin',
        content: 'Đoạn văn mở đầu<img src="http://localhost:8000/uploads/img_pasted.jpg" style="max-width: 100%; height: auto;"/>Đoạn kết thúc.',
        enableQuickReply: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: PostDetailScreen(id: '301', repository: repo),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(KeepAliveForumImage), findsOneWidget);

      final imageFinders = find.byType(Image);
      final hasPastedImage = tester.widgetList<Image>(imageFinders).any((img) {
        ImageProvider provider = img.image;
        if (provider is ResizeImage) {
          provider = provider.imageProvider;
        }
        if (provider is NetworkImage) {
          return provider.url.contains('uploads/img_pasted.jpg');
        }
        return false;
      });

      expect(hasPastedImage, isTrue);
    });
  });
}
