/// Extension an toàn cho việc giải mã URI component / Query parameters (Chuẩn Dart 3.x / 2026)
/// Chống đứng tuyệt đối ngoại lệ: Invalid argument(s): Illegal percent encoding in URI
extension SafeUriDecodeStringExt on String? {
  /// Giải mã an toàn chuỗi URI/URL query parameter:
  /// - Nếu null hoặc rỗng/chỉ chứa khoảng trắng -> trả về [fallback].
  /// - Nếu là chuỗi thuần không chứa '%' (chuỗi tiếng Việt có dấu đã giải mã) -> trả về trực tiếp.
  /// - Nếu chứa '%' -> cố gắng decode an toàn với `try-catch`. Nếu chuỗi lỗi cú pháp '%' -> trả về chuỗi gốc mà không văng ngoại lệ sập giao diện.
  String safeUriDecode([String fallback = '']) {
    final self = this;
    if (self == null || self.trim().isEmpty) {
      return fallback;
    }
    final trimmed = self.trim();
    if (trimmed.contains('%')) {
      try {
        return Uri.decodeComponent(trimmed);
      } catch (_) {
        return trimmed;
      }
    }
    return trimmed;
  }
}
