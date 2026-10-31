/// ForumTextHelper - Dynamic Text Localization chuẩn 2026
/// Tự động thích ứng danh xưng 'Sự kiện' cho chuyên mục "Thông báo - Sự kiện"
/// và bảo toàn tuyệt đối danh xưng 'Chủ đề' cho tất cả các chuyên mục khác.
class ForumTextHelper {
  static bool isEventCategory(String? slug) {
    if (slug == null) return false;
    final s = slug.toLowerCase().trim();
    return s == 'thong-bao-su-kien' || s == 'thong-bao' || s.contains('su-kien');
  }

  /// Tên định danh nhóm bài viết: 'Sự kiện' hoặc 'Chủ đề'
  static String getTopicNoun(String? slug) {
    return isEventCategory(slug) ? 'Sự kiện' : 'Chủ đề';
  }

  /// Nút 1: 'Thông báo và Sự kiện mới' / 'Thông báo và Chủ đề mới'
  static String getNewTopicButtonLabel(String? slug) {
    return isEventCategory(slug) ? 'Thông báo và Sự kiện mới' : 'Thông báo và Chủ đề mới';
  }

  /// Nút 2: 'Sửa Thông báo và Sự kiện' / 'Sửa Thông Báo và Chủ đề'
  static String getEditTopicButtonLabel(String? slug) {
    return isEventCategory(slug) ? 'Sửa Thông báo và Sự kiện' : 'Sửa Thông Báo và Chủ đề';
  }

  /// Nút 3: 'Xóa Thông báo và Sự kiện' / 'Xóa Thông Báo và Chủ đề'
  static String getDeleteTopicButtonLabel(String? slug) {
    return isEventCategory(slug) ? 'Xóa Thông báo và Sự kiện' : 'Xóa Thông Báo và Chủ đề';
  }

  /// Tiêu đề tab tạo mới: 'Tạo thêm Sự kiện mới' / 'Tạo thêm Chủ đề mới'
  static String getCreateTabLabel(String? slug, {bool isEditMode = false}) {
    if (isEditMode) {
      return isEventCategory(slug) ? 'Sửa Sự kiện' : 'Sửa Chủ đề';
    }
    return isEventCategory(slug) ? 'Tạo thêm Sự kiện mới' : 'Tạo thêm Chủ đề mới';
  }

  /// Nhãn TextField tiêu đề: 'Tên Sự kiện mới' / 'Tên Chủ đề mới'
  static String getTitleFieldLabel(String? slug, {bool isEditMode = false, String selectedType = 'chu_de'}) {
    if (selectedType == 'thong_bao') {
      return isEditMode ? 'Tên Thông báo' : 'Tên Thông báo mới';
    }
    if (isEditMode) {
      return isEventCategory(slug) ? 'Tên Sự kiện' : 'Tên Chủ đề';
    }
    return isEventCategory(slug) ? 'Tên Sự kiện mới' : 'Tên Chủ đề mới';
  }

  /// Hint TextField tiêu đề: 'Nhập Tên Sự kiện mới' / 'Nhập Tên Chủ đề mới'
  static String getTitleFieldHint(String? slug, {bool isEditMode = false, String selectedType = 'chu_de'}) {
    if (selectedType == 'thong_bao') {
      return isEditMode ? 'Nhập Tên Thông báo' : 'Nhập Tên Thông báo mới';
    }
    if (isEditMode) {
      return isEventCategory(slug) ? 'Nhập Tên Sự kiện' : 'Nhập Tên Chủ đề';
    }
    return isEventCategory(slug) ? 'Nhập Tên Sự kiện mới' : 'Nhập Tên Chủ đề mới';
  }

  /// Nhãn nút nội dung: 'Nội dung Sự kiện mới' / 'Nội dung Chủ đề mới'
  static String getContentSectionLabel(String? slug, {String selectedType = 'chu_de'}) {
    if (selectedType == 'thong_bao') {
      return 'Nội dung Thông báo mới';
    }
    return isEventCategory(slug) ? 'Nội dung Sự kiện mới' : 'Nội dung Chủ đề mới';
  }

  /// Tiêu đề breadcrumb hoặc header tạo bài viết
  static String getCreatePageTitle(String? slug, {bool isEditMode = false}) {
    if (isEditMode) {
      return isEventCategory(slug) ? 'Sửa Thông báo và Sự kiện' : 'Sửa Thông báo và Chủ đề';
    }
    return isEventCategory(slug)
        ? 'Tạo thêm thông báo và Sự kiện mới (Ban Quản Trị)'
        : 'Tạo thêm thông báo và Chủ đề mới (Ban Quản Trị)';
  }

  /// Tiêu đề breadcrumb màn hình Xóa: 'Xóa Thông báo và Sự kiện' / 'Xóa Thông báo và Chủ đề'
  static String getDeletePageTitle(String? slug) {
    return isEventCategory(slug) ? 'Xóa Thông báo và Sự kiện' : 'Xóa Thông báo và Chủ đề';
  }

  /// Tiêu đề thanh vàng header màn hình Xóa: 'Xóa Thông báo - Sự kiện' / 'Xóa Thông báo - Chủ đề'
  static String getDeleteHeaderBarTitle(String? slug) {
    return isEventCategory(slug) ? 'Xóa Thông báo - Sự kiện' : 'Xóa Thông báo - Chủ đề';
  }

  /// Câu hỏi khu vực trống số 1: 'Bạn định xóa Thông báo hay Sự kiện nào ?'
  static String getDeleteQuestionText(String? slug) {
    return isEventCategory(slug)
        ? 'Bạn định xóa Thông báo hay Sự kiện nào ?'
        : 'Bạn định xóa Thông báo hay Chủ đề nào ?';
  }
}
