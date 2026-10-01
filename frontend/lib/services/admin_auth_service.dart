import 'package:shared_preferences/shared_preferences.dart';

class AdminAuthService {
  static const String lockoutKey = 'admin_delete_lockout_until';
  static const String sessionKey = 'admin_delete_session_valid';

  // Kiểm tra Admin có đang bị khóa 24h hay không (Đã tạm thời gỡ bỏ khóa theo yêu cầu)
  static Future<bool> isLockedOut() async {
    final prefs = await SharedPreferences.getInstance();
    // Tự động xóa key lockout cũ nếu còn lưu lại trong máy để giải phóng ngay
    await prefs.remove(lockoutKey);
    return false;
  }

  // Lấy thời gian còn lại của hình phạt 24h
  static Future<Duration> getRemainingLockout() async {
    return Duration.zero;
  }

  // Kích hoạt khóa phạt 24h (Tạm thời vô hiệu hóa)
  static Future<void> triggerLockout() async {
    // Tạm thời vô hiệu hóa cơ chế khóa phạt 24h theo yêu cầu
  }

  // Xóa hình phạt (dùng cho testing/reset)
  static Future<void> clearLockout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(lockoutKey);
    await prefs.remove(sessionKey);
  }

  // Xác thực tuần tự từng lớp mật khẩu (Step 1 -> 2 -> 3)
  static Future<Map<String, dynamic>> verifyStep(int step, String input) async {
    final normalized = input.trim().toLowerCase();
    bool isCorrect = false;

    switch (step) {
      case 1:
        isCorrect = normalized == 'xóa' || normalized == 'xoa';
        break;
      case 2:
        isCorrect = normalized == 'chuyên mục' || normalized == 'chuyen muc';
        break;
      case 3:
        isCorrect = normalized == 'lớp học lý số' || normalized == 'lop hoc ly so';
        break;
      default:
        isCorrect = false;
    }

    if (isCorrect) {
      if (step == 3) {
        // Xác thực thành công toàn bộ 3 lớp!
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(sessionKey, DateTime.now().toIso8601String());
        return {
          'success': true,
          'completed': true,
          'sessionToken': 'admin_del_token_${DateTime.now().millisecondsSinceEpoch}',
          'message': 'Xác thực 3 lớp thành công!',
        };
      } else {
        return {
          'success': true,
          'completed': false,
          'nextStep': step + 1,
          'message': 'Xác thực lớp $step thành công!',
        };
      }
    } else {
      // Nhập sai ở BẤT KỲ lớp nào -> Không phạt khóa 24h, chỉ báo lỗi để đẩy về Trang chủ
      return {
        'success': false,
        'locked': false,
        'message': 'Mật khẩu lớp $step không chính xác! Đang quay về Trang chủ...',
      };
    }
  }

  // Kiểm tra phiên xác thực 3 lớp có hợp lệ không (trong vòng 30 phút)
  static Future<bool> isSessionValid() async {
    final prefs = await SharedPreferences.getInstance();
    final sessionStr = prefs.getString(sessionKey);
    if (sessionStr == null) return false;

    try {
      final sessionTime = DateTime.parse(sessionStr);
      final elapsed = DateTime.now().difference(sessionTime);
      return elapsed.inMinutes < 30;
    } catch (_) {
      return false;
    }
  }

  // Kết thúc phiên xóa chuyên mục
  static Future<void> endSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(sessionKey);
  }
}
