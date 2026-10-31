import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/services/forum_category_data_helper.dart';

void main() {
  group('ForumCategoryDataHelper - Dynamic Category & LRU Cache Tests', () {
    setUp(() {
      ForumCategoryDataHelper.clearCache();
    });

    test('1. Kiểm tra ánh xạ tiêu đề chuẩn (Deep Link Guard)', () {
      expect(ForumCategoryDataHelper.getCategoryTitle('kien-thuc-co-ban'), equals('Kiến thức Cơ bản'));
      expect(ForumCategoryDataHelper.getCategoryTitle('kien-thuc-tu-vi'), equals('Kiến thức Tử vi'));
      expect(ForumCategoryDataHelper.getCategoryTitle('lop-hoc-tu-vi'), equals('Lớp học tử vi'));
      expect(ForumCategoryDataHelper.getCategoryTitle('thong-bao-su-kien'), equals('Thông báo - Sự kiện'));
      expect(ForumCategoryDataHelper.getCategoryTitle('cuoc-song-muon-mau'), equals('Cuộc sống muôn màu'));
      expect(ForumCategoryDataHelper.getCategoryTitle('cau-lac-bo-giao-luu-ket-ban'), equals('Câu lạc bộ - Giao lưu - Kết bạn'));
    });

    test('2. Kiểm tra tính hợp lệ của slug (isValidCategorySlug)', () {
      expect(ForumCategoryDataHelper.isValidCategorySlug('kien-thuc-co-ban'), isTrue);
      expect(ForumCategoryDataHelper.isValidCategorySlug(''), isFalse);
      expect(ForumCategoryDataHelper.isValidCategorySlug(null), isFalse);
      expect(ForumCategoryDataHelper.isValidCategorySlug('undefined'), isFalse);
      expect(ForumCategoryDataHelper.isValidCategorySlug('null'), isFalse);
    });

    test('3. Kiểm tra danh sách chủ đề chuẩn xác cho Kiến thức Cơ bản (Hình 4)', () {
      final topics = ForumCategoryDataHelper.getTopicsForCategory('kien-thuc-co-ban');
      expect(topics, isNotEmpty);
      expect(topics.any((t) => t['title'].toString().contains('Cảnh báo năm 2026')), isTrue);
      expect(topics.any((t) => t['title'].toString().contains('Kiến thức Cơ bản: Hiểu SÂU RỘNG')), isTrue);
    });

    test('4. Kiểm tra danh sách thông báo ghim mặc định đủ 5 bài (Hình 4)', () {
      final pinned = ForumCategoryDataHelper.getPinnedTopicsForCategory('kien-thuc-co-ban');
      expect(pinned.length, equals(5));
      expect(pinned.any((p) => p['title'].toString().contains('Talkshow hướng nghiệp')), isTrue);
      expect(pinned.any((p) => p['title'].toString().contains('Nội quy diễn đàn')), isTrue);
    });

    test('5. Kiểm tra cơ chế LRU Cache (Giới hạn tối đa 5 chuyên mục trong RAM)', () {
      final slugs = [
        'kien-thuc-co-ban',
        'kien-thuc-tu-vi',
        'lop-hoc-tu-vi',
        'lop-hoc-tu-tru',
        'lop-hoc-dich-ly',
        'thong-bao-su-kien', // Chuyên mục thứ 6 -> giải phóng slug đầu tiên ('kien-thuc-co-ban')
      ];

      for (var s in slugs) {
        ForumCategoryDataHelper.getTopicsForCategory(s);
      }

      // Kiểm tra danh sách vẫn hoạt động hoàn hảo khi truy cập lại slug bị evict
      final reloaded = ForumCategoryDataHelper.getTopicsForCategory('kien-thuc-co-ban');
      expect(reloaded, isNotEmpty);
    });

    test('6. Kiểm tra Thuật toán Zero-Cost In-Place Insertion (Đẩy lên Index 0)', () {
      const slug = 'kien-thuc-co-ban';
      final initialTopics = ForumCategoryDataHelper.getTopicsForCategory(slug);
      final initialCount = initialTopics.length;

      // Cập nhật một bài viết hiện có
      final updatedTopic = {
        'id': 'ktcb_2',
        'title': 'Kiến thức Cơ bản: Hiểu SÂU RỘNG [ĐÃ SỬA CẬP NHẬT]',
        'type': 'chu_de',
        'lastTime': '10:00, 23/10/26',
      };

      ForumCategoryDataHelper.insertOrUpdateTopicInCache(slug, updatedTopic);

      final cachedAfterUpdate = ForumCategoryDataHelper.getTopicsForCategory(slug);
      // Vị trí đầu tiên (Index 0) phải chính là bài viết vừa sửa!
      expect(cachedAfterUpdate.first['id'], equals('ktcb_2'));
      expect(cachedAfterUpdate.first['title'], equals('Kiến thức Cơ bản: Hiểu SÂU RỘNG [ĐÃ SỬA CẬP NHẬT]'));
      // Tổng số lượng bài không bị nhân đôi
      expect(cachedAfterUpdate.length, equals(initialCount));
    });

    test('7. Kiểm tra Thuật toán Xóa Khỏi Cache (removeTopicFromCache & Null Safety Guard)', () {
      const slug = 'kien-thuc-co-ban';
      // Nạp cache
      final normalTopics = ForumCategoryDataHelper.getTopicsForCategory(slug);
      final pinnedTopics = ForumCategoryDataHelper.getPinnedTopicsForCategory(slug);
      final initialNormalCount = normalTopics.length;
      final initialPinnedCount = pinnedTopics.length;

      // 1. Kiểm tra Null Safety Guard (không được throw exception)
      expect(() => ForumCategoryDataHelper.removeTopicFromCache(null, 'some_id'), returnsNormally);
      expect(() => ForumCategoryDataHelper.removeTopicFromCache(slug, null), returnsNormally);
      expect(() => ForumCategoryDataHelper.removeTopicFromCache('', 'some_id'), returnsNormally);
      expect(() => ForumCategoryDataHelper.removeTopicFromCache('unknown-slug', 'some_id'), returnsNormally);

      // 2. Xóa 1 bài viết thường
      final targetNormalId = normalTopics.first['id'];
      ForumCategoryDataHelper.removeTopicFromCache(slug, targetNormalId);
      final afterRemoveNormal = ForumCategoryDataHelper.getTopicsForCategory(slug);
      expect(afterRemoveNormal.length, equals(initialNormalCount - 1));
      expect(afterRemoveNormal.any((t) => t['id'] == targetNormalId), isFalse);

      // 3. Xóa 1 bài viết ghim
      final targetPinnedId = pinnedTopics.first['id'];
      ForumCategoryDataHelper.removeTopicFromCache(slug, targetPinnedId);
      final afterRemovePinned = ForumCategoryDataHelper.getPinnedTopicsForCategory(slug);
      expect(afterRemovePinned.length, equals(initialPinnedCount - 1));
      expect(afterRemovePinned.any((p) => p['id'] == targetPinnedId), isFalse);
    });

    test('8. Kiểm tra Giải Phóng Bộ Nhớ Có Chọn Lọc (clearCacheForSlug)', () {
      // Nạp cache cho 2 chuyên mục khác nhau
      ForumCategoryDataHelper.getTopicsForCategory('kien-thuc-co-ban');
      ForumCategoryDataHelper.getTopicsForCategory('kien-thuc-tu-vi');

      // Chỉ giải phóng cache cho kien-thuc-co-ban
      ForumCategoryDataHelper.clearCacheForSlug('kien-thuc-co-ban');

      // kien-thuc-tu-vi vẫn còn nguyên vẹn trong cache (không bị xóa toàn bộ)
      final tuviTopics = ForumCategoryDataHelper.getTopicsForCategory('kien-thuc-tu-vi');
      expect(tuviTopics, isNotEmpty);
    });

    test('9. Kiểm tra Cờ Môi Trường (Environment Segregation: useMockData)', () {
      // Khi useMockData = false (mặc định), thong-bao-su-kien trả về rỗng
      ForumCategoryDataHelper.useMockData = false;
      ForumCategoryDataHelper.clearCacheForSlug('thong-bao-su-kien');
      expect(ForumCategoryDataHelper.getPinnedTopicsForCategory('thong-bao-su-kien'), isEmpty);
      expect(ForumCategoryDataHelper.getTopicsForCategory('thong-bao-su-kien'), isEmpty);

      // Khi useMockData = true (UI Test), thong-bao-su-kien trả về mock data
      ForumCategoryDataHelper.useMockData = true;
      ForumCategoryDataHelper.clearCacheForSlug('thong-bao-su-kien');
      expect(ForumCategoryDataHelper.getPinnedTopicsForCategory('thong-bao-su-kien'), isNotEmpty);
      expect(ForumCategoryDataHelper.getTopicsForCategory('thong-bao-su-kien'), isNotEmpty);

      // Reset lại cờ an toàn
      ForumCategoryDataHelper.useMockData = false;
      ForumCategoryDataHelper.clearCacheForSlug('thong-bao-su-kien');
    });
  });
}
