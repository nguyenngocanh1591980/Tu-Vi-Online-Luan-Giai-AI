import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/utils/uri_safe_extension.dart';

void main() {
  group('SafeUriDecodeStringExt Unit Tests - Chặn đứng ngoại lệ Illegal percent encoding in URI', () {
    test('1. Xử lý chuỗi null và chuỗi rỗng / khoảng trắng', () {
      String? nullStr;
      expect(nullStr.safeUriDecode(), equals(''));
      expect(nullStr.safeUriDecode('Thông báo - Sự kiện'), equals('Thông báo - Sự kiện'));

      const emptyStr = '';
      expect(emptyStr.safeUriDecode(), equals(''));
      expect(emptyStr.safeUriDecode('Mặc định'), equals('Mặc định'));

      const whitespaceStr = '   \t\n  ';
      expect(whitespaceStr.safeUriDecode(), equals(''));
      expect(whitespaceStr.safeUriDecode('Dự phòng'), equals('Dự phòng'));
    });

    test('2. Xử lý chuỗi tiếng Việt Unicode nguyên bản (không chứa %)', () {
      // Các trường hợp thực tế từ Hình 1, Hình 2 và toàn bộ chuyên mục Hình 4
      const title1 = 'Thông báo - Sự kiện';
      const title2 = 'Kiến thức Tử vi';
      const title3 = 'Lớp học tử vi';
      const title4 = 'Xem Phong thủy';
      const title5 = 'Hướng nghiệp';
      const title6 = 'Cổ học - Văn hóa - Tín ngưỡng';

      expect(title1.safeUriDecode('Fallback'), equals('Thông báo - Sự kiện'));
      expect(title2.safeUriDecode('Fallback'), equals('Kiến thức Tử vi'));
      expect(title3.safeUriDecode('Fallback'), equals('Lớp học tử vi'));
      expect(title4.safeUriDecode('Fallback'), equals('Xem Phong thủy'));
      expect(title5.safeUriDecode('Fallback'), equals('Hướng nghiệp'));
      expect(title6.safeUriDecode('Fallback'), equals('Cổ học - Văn hóa - Tín ngưỡng'));
    });

    test('3. Xử lý chuỗi được mã hóa URL (Percent-encoded hợp lệ)', () {
      final encoded1 = Uri.encodeComponent('Thông báo - Sự kiện');
      final encoded2 = Uri.encodeComponent('Kiến thức Tử vi');
      const encodedSimple = 'Xin%20chao%20Viet%20Nam';

      expect(encoded1.safeUriDecode(), equals('Thông báo - Sự kiện'));
      expect(encoded2.safeUriDecode(), equals('Kiến thức Tử vi'));
      expect(encodedSimple.safeUriDecode(), equals('Xin chao Viet Nam'));
    });

    test('4. Xử lý chuỗi chứa % nhưng sai định dạng mã hóa (Chặn đứng ArgumentError)', () {
      // Những chuỗi này nếu gọi trực tiếp Uri.decodeComponent() sẽ NÉM Illegal percent encoding in URI
      const malformed1 = '%';
      const malformed2 = '100% thành công';
      const malformed3 = 'Tỷ lệ giảm giá 50% & quà tặng';
      const malformed4 = '%G1%ZZ test';
      const malformed5 = 'abc%1';

      expect(() => Uri.decodeComponent(malformed1), throwsA(isA<ArgumentError>()));
      expect(() => Uri.decodeComponent(malformed2), throwsA(isA<ArgumentError>()));
      expect(() => Uri.decodeComponent(malformed3), throwsA(isA<ArgumentError>()));

      // Với safeUriDecode, tuyệt đối KHÔNG throw mà trả về an toàn
      expect(malformed1.safeUriDecode(), equals('%'));
      expect(malformed2.safeUriDecode(), equals('100% thành công'));
      expect(malformed3.safeUriDecode(), equals('Tỷ lệ giảm giá 50% & quà tặng'));
      expect(malformed4.safeUriDecode(), equals('%G1%ZZ test'));
      expect(malformed5.safeUriDecode(), equals('abc%1'));
    });

    test('5. Mô phỏng luồng GoRouter queryParameters cho tất cả chuyên mục Hình 4', () {
      // Khi GoRouter tự động giải mã query parameters, title nhận được là chuỗi tiếng Việt thô
      final mockQueryParams = <String, String>{
        'thong-bao-su-kien': 'Thông báo - Sự kiện',
        'kien-thuc-tu-vi': 'Kiến thức Tử vi',
        'lop-hoc-tu-vi': 'Lớp học tử vi',
        'huong-nghiep': 'Hướng nghiệp',
        'xem-phong-thuy': 'Xem Phong thủy',
      };

      for (final entry in mockQueryParams.entries) {
        final rawTitle = entry.value;
        // Kiểm tra không được ném ngoại lệ và trả về chính xác tiêu đề
        final decoded = rawTitle.safeUriDecode('Thông báo - Sự kiện');
        expect(decoded, equals(entry.value));
      }
    });
  });
}
