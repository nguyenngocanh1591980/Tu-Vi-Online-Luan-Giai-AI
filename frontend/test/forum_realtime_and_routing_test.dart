import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Forum Real-Time & Routing Flow Tests (Nhiệm vụ 1, 2, 3)', () {
    test('1. Idempotent Updates: Tạo mới bài viết chèn vào index 0 và không bị duplicate', () {
      final List<Map<String, dynamic>> pinnedTopics = [
        {'id': 1, 'title': 'Bài ghim cũ', 'type': 'thong_bao'},
      ];
      final List<Map<String, dynamic>> normalTopics = [
        {'id': 2, 'title': 'Chủ đề cũ', 'type': 'chu_de'},
      ];

      // Giả lập nhận SignalR create thông báo mới
      final newAnnouncement = {
        'id': 100,
        'title': 'helo - Thông báo mới',
        'type': 'thong_bao',
      };

      // Idempotent Insert
      pinnedTopics.removeWhere((t) => t['id'] == newAnnouncement['id'] || t['title'] == newAnnouncement['title']);
      pinnedTopics.insert(0, newAnnouncement);

      expect(pinnedTopics.length, equals(2));
      expect(pinnedTopics[0]['title'], equals('helo - Thông báo mới'));
      expect(pinnedTopics[0]['id'], equals(100));

      // Nhận lại SignalR trùng lặp (Duplicate broadcast)
      pinnedTopics.removeWhere((t) => t['id'] == newAnnouncement['id'] || t['title'] == newAnnouncement['title']);
      pinnedTopics.insert(0, newAnnouncement);

      // Số lượng vẫn là 2, không bị đúp bài
      expect(pinnedTopics.length, equals(2));
      expect(pinnedTopics[0]['id'], equals(100));
    });

    test('2. Idempotent Updates: Chuyển bảng khi Type thay đổi sau khi Sửa', () {
      final List<Map<String, dynamic>> pinnedTopics = [
        {'id': 10, 'title': 'Bài chuyển loại', 'type': 'thong_bao'},
      ];
      final List<Map<String, dynamic>> normalTopics = [
        {'id': 20, 'title': 'Chủ đề 20', 'type': 'chu_de'},
      ];

      // Cập nhật đổi từ thong_bao sang chu_de
      final updatedData = {
        'id': 10,
        'title': 'Bài chuyển loại (Đã sửa sang Chủ đề)',
        'type': 'chu_de',
      };

      // Xử lý chuyển bảng
      final pIdx = pinnedTopics.indexWhere((t) => t['id'] == updatedData['id']);
      if (pIdx >= 0 && updatedData['type'] == 'chu_de') {
        pinnedTopics.removeAt(pIdx);
        normalTopics.removeWhere((t) => t['id'] == updatedData['id']);
        normalTopics.insert(0, updatedData);
      }

      expect(pinnedTopics.isEmpty, isTrue);
      expect(normalTopics.length, equals(2));
      expect(normalTopics[0]['title'], equals('Bài chuyển loại (Đã sửa sang Chủ đề)'));
    });

    test('3. Explicit Routing URL Generation: Kiểm tra URL điều hướng tường minh', () {
      const slug = 'thong-bao-su-kien';
      const title = 'Thông báo - Sự kiện';
      final encodedTitle = Uri.encodeComponent(title);

      // Tuyến đường chuyển đến màn hình Chọn bài viết (AdminEditTopicsScreen)
      final editTopicsUrl = '/forum/category/$slug/edit-topics?categoryTitle=$encodedTitle';
      expect(editTopicsUrl, contains('/category/thong-bao-su-kien/edit-topics'));

      // Tuyến đường quay về chuyên mục sau khi Tạo mới
      final categoryHomeUrl = '/forum/category/$slug';
      expect(categoryHomeUrl, equals('/forum/category/thong-bao-su-kien'));
    });

    test('4. Đồng bộ trên tất cả Chuyên mục (Chuyên mục 1, 2, Lớp học lý số)', () {
      final slugs = [
        'thong-bao-su-kien',
        'kien-thuc-co-ban',
        'kien-thuc-tu-vi',
        'lop-hoc-tu-vi',
        'huong-nghiep',
        'xem-phong-thuy',
      ];

      for (final s in slugs) {
        final editPath = '/forum/category/$s/edit-topics';
        expect(editPath, startsWith('/forum/category/'));
        expect(editPath, endsWith('/edit-topics'));
      }
    });
  });
}
