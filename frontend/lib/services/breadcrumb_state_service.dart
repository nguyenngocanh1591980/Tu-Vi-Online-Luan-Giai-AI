import 'package:flutter/foundation.dart';

/// Dữ liệu Breadcrumb của Topic đang xem hoặc đang trả lời
class TopicBreadcrumbData {
  final String topicId;
  final String categorySlug;
  final String categoryTitle;
  final String topicTitle;

  const TopicBreadcrumbData({
    required this.topicId,
    required this.categorySlug,
    required this.categoryTitle,
    required this.topicTitle,
  });
}

/// Navigation State Guard (Chuẩn Công Nghệ 2026):
/// Quản lý trạng thái Breadcrumb toàn cục cho các màn hình Diễn đàn (Chi tiết bài viết & Trả lời),
/// loại bỏ hoàn toàn việc bọc query parameters làm xấu URL khi chia sẻ link,
/// đồng thời đóng vai trò fallback khi người dùng refresh hoặc truy cập trực tiếp qua bookmark.
class BreadcrumbStateService {
  BreadcrumbStateService._();

  static final ValueNotifier<TopicBreadcrumbData?> currentTopic =
      ValueNotifier<TopicBreadcrumbData?>(null);

  // Bộ nhớ cache theo topicId
  static final Map<String, TopicBreadcrumbData> _topicCache = {};

  /// Cập nhật dữ liệu Topic hiện tại
  static void updateCurrentTopic({
    required String topicId,
    required String categorySlug,
    required String categoryTitle,
    required String topicTitle,
  }) {
    final effectiveSlug = categorySlug.isNotEmpty ? categorySlug : 'thong-bao-su-kien';
    final effectiveTitle = categoryTitle.isNotEmpty ? categoryTitle : 'Thông báo - Sự kiện';

    final data = TopicBreadcrumbData(
      topicId: topicId,
      categorySlug: effectiveSlug,
      categoryTitle: effectiveTitle,
      topicTitle: topicTitle,
    );
    _topicCache[topicId] = data;
    currentTopic.value = data;
  }

  /// Lấy dữ liệu Topic từ cache hoặc state hiện tại
  static TopicBreadcrumbData? getCachedTopic(String topicId) {
    if (currentTopic.value?.topicId == topicId) {
      return currentTopic.value;
    }
    return _topicCache[topicId];
  }

  /// Xóa trạng thái khi rời khỏi diễn đàn
  static void clear() {
    currentTopic.value = null;
  }
}
