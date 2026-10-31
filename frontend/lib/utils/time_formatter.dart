/// TimeFormatter - Tiêu chuẩn Định dạng Thời gian Tuyệt đối Chuẩn 2026 (UTC+7)
/// Tự động quét createdAt, lastTime, updatedAt, bắt lỗi kiểu dữ liệu và ép về chuẩn HH:mm, dd/MM/yy.
class TimeFormatter {
  static String formatVietnamTime(dynamic input, {String fallback = '10:30, 26/10/26'}) {
    if (input == null) return fallback;
    final s = input.toString().trim();
    if (s.isEmpty || s == 'null' || s == 'undefined') return fallback;

    // Nếu đã ở dạng 'HH:mm, dd/MM/yy'
    final viPattern = RegExp(r'^\d{1,2}:\d{2},\s*\d{1,2}/\d{1,2}/\d{2,4}$');
    if (viPattern.hasMatch(s)) {
      return s;
    }

    try {
      final dt = DateTime.parse(s).toUtc().add(const Duration(hours: 7));
      final hh = dt.hour.toString().padLeft(2, '0');
      final mm = dt.minute.toString().padLeft(2, '0');
      final dd = dt.day.toString().padLeft(2, '0');
      final mo = dt.month.toString().padLeft(2, '0');
      final yy = (dt.year % 100).toString().padLeft(2, '0');
      return '$hh:$mm, $dd/$mo/$yy';
    } catch (_) {
      if (input is int || int.tryParse(s) != null) {
        try {
          final ts = input is int ? input : int.parse(s);
          final isMillis = ts > 10000000000;
          final dt = DateTime.fromMillisecondsSinceEpoch(isMillis ? ts : ts * 1000, isUtc: true).add(const Duration(hours: 7));
          final hh = dt.hour.toString().padLeft(2, '0');
          final mm = dt.minute.toString().padLeft(2, '0');
          final dd = dt.day.toString().padLeft(2, '0');
          final mo = dt.month.toString().padLeft(2, '0');
          final yy = (dt.year % 100).toString().padLeft(2, '0');
          return '$hh:$mm, $dd/$mo/$yy';
        } catch (_) {}
      }
      return s.isNotEmpty ? s : fallback;
    }
  }

  static String extractAndFormatTopicTime(Map<String, dynamic> topic, {String fallback = '10:30, 26/10/26'}) {
    final raw = topic['time'] ??
        topic['created_at'] ??
        topic['createdAt'] ??
        topic['lastTime'] ??
        topic['last_time'] ??
        topic['updatedAt'] ??
        topic['updated_at'];
    return formatVietnamTime(raw, fallback: fallback);
  }
}
