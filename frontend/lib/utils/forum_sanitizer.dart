/// ForumSanitizer - Khử trùng Rich Text và văn bản đầu vào chống tấn công XSS chuẩn 2026
class ForumSanitizer {
  static final RegExp _scriptPattern = RegExp(
    r'<script\b[^<]*(?:(?!<\/script>)<[^<]*)*<\/script>',
    caseSensitive: false,
    multiLine: true,
  );
  static final RegExp _iframePattern = RegExp(
    r'<iframe\b[^<]*(?:(?!<\/iframe>)<[^<]*)*<\/iframe>',
    caseSensitive: false,
    multiLine: true,
  );
  static final RegExp _objectPattern = RegExp(
    r'<object\b[^<]*(?:(?!<\/object>)<[^<]*)*<\/object>',
    caseSensitive: false,
    multiLine: true,
  );
  static final RegExp _eventHandlerPattern = RegExp(
    r'\bon\w+\s*=\s*(?:["\x27]?[^"\x27>]+["\x27]?|[^\s>]+)',
    caseSensitive: false,
  );
  static final RegExp _javascriptUriPattern = RegExp(
    r'javascript\s*:[^"\x27>]*',
    caseSensitive: false,
  );

  /// Khử trùng triệt để các mã thực thi ẩn và script độc hại
  static String sanitize(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    String sanitized = raw;
    sanitized = sanitized.replaceAll(_scriptPattern, '');
    sanitized = sanitized.replaceAll(_iframePattern, '');
    sanitized = sanitized.replaceAll(_objectPattern, '');
    sanitized = sanitized.replaceAll(_eventHandlerPattern, '');
    sanitized = sanitized.replaceAll(_javascriptUriPattern, '');
    return sanitized;
  }
}
