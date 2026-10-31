import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/models/forum_category_model.dart';
import 'package:frontend/providers/forum_category_provider.dart';
import 'package:frontend/services/forum_category_repository.dart';

class MockForumCategoryRepository implements ForumCategoryRepository {
  final Map<String, List<ForumCategoryItem>> _mockDb = {
    'group1': [],
    'group2': [],
    'group3': [],
  };

  @override
  Future<Map<String, List<ForumCategoryItem>>?> fetchAllCategories({dynamic client}) async {
    return _mockDb;
  }

  @override
  Future<bool> createCategory(ForumCategoryItem item, {dynamic client}) async {
    if (item.groupType == 'Chuyên mục 1' || item.groupType == 'ChuyenMuc1') {
      _mockDb['group1']!.add(item);
    } else if (item.groupType == 'Lớp học Lý số' || item.groupType == 'LopHoc') {
      _mockDb['group2']!.add(item);
    } else {
      _mockDb['group3']!.add(item);
    }
    return true;
  }

  @override
  Future<bool> deleteCategories(Iterable<ForumCategoryItem> items, {dynamic client}) async {
    final titles = items.map((e) => e.title).toSet();
    _mockDb['group1']!.removeWhere((c) => titles.contains(c.title));
    _mockDb['group2']!.removeWhere((c) => titles.contains(c.title));
    _mockDb['group3']!.removeWhere((c) => titles.contains(c.title));
    return true;
  }

  @override
  Future<bool> updateCategory(String oldTitle, ForumCategoryItem item, {dynamic client}) async {
    return true;
  }
}

void main() {
  group('Kiểm thử Mô hình Repository Pattern & Lưu trữ bền vững Provider', () {
    test('1. Tạo mới: Chờ Backend 200 OK mới cập nhật UI State', () async {
      final mockRepo = MockForumCategoryRepository();
      final provider = ForumCategoryProvider(repository: mockRepo, autoFetch: false);

      const newItem = ForumCategoryItem(
        title: 'Học vui và vui học',
        description: 'học vui',
        groupType: 'Chuyên mục 1',
      );

      final success = await provider.addCategory(newItem);
      expect(success, isTrue);
      expect(provider.group1Categories.any((c) => c.title == 'Học vui và vui học'), isTrue);
      expect(mockRepo._mockDb['group1']!.any((c) => c.title == 'Học vui và vui học'), isTrue);
    });

    test('2. Xóa: Gọi API DELETE và xóa khỏi UI State sau khi thành công', () async {
      final mockRepo = MockForumCategoryRepository();
      final provider = ForumCategoryProvider(repository: mockRepo, autoFetch: false);

      const newItem = ForumCategoryItem(
        title: 'Học vui và vui học',
        description: 'học vui',
        groupType: 'Chuyên mục 1',
      );

      await provider.addCategory(newItem);
      expect(provider.group1Categories.any((c) => c.title == 'Học vui và vui học'), isTrue);

      final deleteSuccess = await provider.removeCategories([newItem]);
      expect(deleteSuccess, isTrue);
      expect(provider.group1Categories.any((c) => c.title == 'Học vui và vui học'), isFalse);
      expect(mockRepo._mockDb['group1']!.any((c) => c.title == 'Học vui và vui học'), isFalse);
    });
  });
}
