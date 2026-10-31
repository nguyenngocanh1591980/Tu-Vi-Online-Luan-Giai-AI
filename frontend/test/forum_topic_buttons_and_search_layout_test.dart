import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/screens/forum/category_topics_screen.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({
      'auth_token': 'mock_token',
      'jwt_token': 'mock_token',
      'role': 'Admin',
      'username': 'admin_user',
    });
  });

  group('Kiểm thử Bố cục Layout Mới: Đảo vị trí triệt tiêu Overflow & Mở quyền Admin', () {
    testWidgets('1. Thông báo - Sự kiện: Dòng 1 là 3 nút Admin, Dòng 2 là Tìm kiếm chung hàng với Phân trang', (tester) async {
      tester.view.physicalSize = const Size(1280, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CategoryTopicsScreen(slug: 'thong-bao-su-kien'),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      // Xác nhận các thành phần tồn tại
      final searchFinder = find.widgetWithText(TextField, 'Tìm trong chuyên mục...');
      final btnNewFinder = find.text('Thông báo và Sự kiện mới');
      final btnEditFinder = find.text('Sửa Thông báo và Sự kiện');
      final btnDeleteFinder = find.text('Xóa Thông báo và Sự kiện');
      final paginationFinder = find.text('Đánh dấu đã xem tất cả • 247 chủ đề');

      expect(searchFinder, findsWidgets);
      expect(btnNewFinder, findsOneWidget);
      expect(btnEditFinder, findsOneWidget);
      expect(btnDeleteFinder, findsOneWidget);
      expect(paginationFinder, findsWidgets);

      final searchTopPos = tester.getTopLeft(searchFinder.first);
      final btnNewPos = tester.getTopLeft(btnNewFinder);
      final btnEditPos = tester.getTopLeft(btnEditFinder);
      final btnDeletePos = tester.getTopLeft(btnDeleteFinder);
      final paginationPos = tester.getTopLeft(paginationFinder.first);

      // QUY TẮC 1: Cụm 3 nút Admin nằm ở DÒNG 1 (TRÊN CÙNG): y của nút nhỏ hơn y của thanh tìm kiếm
      expect(btnNewPos.dy < searchTopPos.dy, isTrue,
          reason: 'Cụm 3 nút Admin phải nằm ở Dòng 1 phía trên thanh tìm kiếm');

      // QUY TẮC 2: Thanh tìm kiếm và Cụm phân trang nằm CÙNG HÀNG NGANG ở Dòng 2
      expect((searchTopPos.dy - paginationPos.dy).abs() < 15.0, isTrue,
          reason: 'Thanh tìm kiếm và phân trang phải nằm cùng một dòng ngang ở Dòng 2');

      // QUY TẮC 3: Cụm 3 nút chụm lại sát nhau ở lề trái
      expect(btnNewPos.dx < btnEditPos.dx, isTrue);
      expect(btnEditPos.dx < btnDeletePos.dx, isTrue);

      // QUY TẮC 4: Thanh tìm kiếm nằm bên trái phân trang
      expect(searchTopPos.dx < paginationPos.dx, isTrue);
    });

    testWidgets('2. Kiến thức Cơ bản: Dòng 1 là 3 nút Admin, Dòng 2 là nút Chủ đề mới + Tìm kiếm + Phân trang', (tester) async {
      tester.view.physicalSize = const Size(1280, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CategoryTopicsScreen(slug: 'kien-thuc-co-ban'),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      final searchFinder = find.widgetWithText(TextField, 'Tìm trong chuyên mục...');
      final topicNewBtnFinder = find.text('Chủ đề mới');
      final btnNewFinder = find.text('Thông báo và Chủ đề mới');
      final paginationFinder = find.text('Đánh dấu đã xem tất cả • 47 chủ đề');

      expect(searchFinder, findsWidgets);
      expect(topicNewBtnFinder, findsWidgets);
      expect(btnNewFinder, findsOneWidget);
      expect(paginationFinder, findsWidgets);

      final searchPos = tester.getTopLeft(searchFinder.first);
      final btnNewPos = tester.getTopLeft(btnNewFinder);
      final paginationPos = tester.getTopLeft(paginationFinder.first);

      // Cụm nút Admin ở Dòng 1 (trên cùng)
      expect(btnNewPos.dy < searchPos.dy, isTrue);

      // Thanh tìm kiếm cùng dòng ngang với phân trang ở Dòng 2
      expect((searchPos.dy - paginationPos.dy).abs() < 15.0, isTrue);
    });

    testWidgets('3. Lớp học Lý số: Tài khoản Admin mở ra giao diện làm việc đầy đủ (không bị chặn)', (tester) async {
      tester.view.physicalSize = const Size(1280, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CategoryTopicsScreen(slug: 'lop-hoc-tu-vi'),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      // Xác nhận KHÔNG có thông báo bị chặn của khách/user
      expect(find.text('Bạn không được cấp phép để xem các chủ đề trong chuyên mục này.'), findsNothing);
      expect(find.text('Thể loại này không có chuyên mục.'), findsNothing);

      // Xác nhận CÓ cụm 3 nút Admin làm việc
      expect(find.text('Thông báo và Chủ đề mới'), findsOneWidget);
      expect(find.text('Sửa Thông Báo và Chủ đề'), findsOneWidget);
      expect(find.text('Xóa Thông Báo và Chủ đề'), findsOneWidget);

      // Xác nhận CÓ danh sách bài giảng/chủ đề lớp học
      expect(find.text('Giáo trình Tử Vi căn bản: Ý nghĩa 14 Chính tinh và các sao Phụ tinh'), findsOneWidget);
    });
  });
}
