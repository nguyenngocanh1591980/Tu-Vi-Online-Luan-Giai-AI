import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/screens/forum/forum_home_screen.dart';

void main() {
  group('Kiểm thử Giao diện ForumHomeScreen (Section Headers & Admin Toolbar)', () {
    testWidgets('Xác nhận Header "Chuyên mục 1", "Chuyên mục 2" và Thanh công cụ Admin khi ĐÃ ĐĂNG NHẬP',
        (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('jwt_token', 'fake_admin_token');
      
      tester.view.physicalSize = const Size(1280, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ForumHomeScreen(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Kiểm tra Section Header "Chuyên mục"
      expect(find.text('Chuyên mục'), findsWidgets);

      // 3. Kiểm tra khối Lớp học Lý số vẫn giữ nguyên
      expect(find.text('Lớp học Lý số'), findsOneWidget);

      // 4. Kiểm tra nút cũ "Tạo Chủ Đề(Admin)" đã bị xóa bỏ hoàn toàn
      expect(find.text('Tạo Chủ Đề(Admin)'), findsNothing,
          reason: 'Nút "Tạo Chủ Đề(Admin)" cũ phải bị xóa bỏ');

      // 5. Kiểm tra nút mới đầu dòng: "Tạo thêm Chuyên mục và Lớp học Lý số mới (Admin)"
      final createBtn = find.text('Tạo thêm Chuyên mục và Lớp học Lý số mới (Admin)');
      expect(createBtn, findsOneWidget,
          reason: 'Phải có nút "Tạo thêm Chuyên mục và Lớp học Lý số mới (Admin)"');
      final createBtnWidget = find.ancestor(of: createBtn, matching: find.byWidgetPredicate((w) => w is ElevatedButton));
      expect(createBtnWidget, findsOneWidget);
      final elevatedCreateBtn = tester.widget<ElevatedButton>(createBtnWidget);
      expect(elevatedCreateBtn.style?.backgroundColor?.resolve({}), equals(Colors.teal),
          reason: 'Nút Tạo thêm Chuyên mục phải có màu nền xanh ngọc Colors.teal');
      expect(find.byIcon(Icons.add_circle_outline), findsOneWidget);

      // 6. Kiểm tra nút cuối dòng: "Xóa Chuyên mục và Lớp học Lý Số (Admin)"
      final deleteBtn = find.byWidgetPredicate((w) => w is Text && w.data != null && w.data!.startsWith('Xóa') && w.data!.contains('Lớp học Lý'));
      expect(deleteBtn, findsOneWidget,
          reason: 'Phải có nút xóa Chuyên mục và Lớp học Lý Số (Admin)');
      expect(
        find.ancestor(of: deleteBtn, matching: find.byWidgetPredicate((w) => w is ElevatedButton)),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.delete_outline), findsWidgets);

      // 7. Kiểm tra nút giữa: "Sửa Chuyên mục và Lớp học Lý số (Admin)"
      expect(find.text('Sửa Chuyên mục và Lớp học Lý số (Admin)'), findsOneWidget);
    });

    testWidgets('Xác nhận Thanh công cụ Admin KHÔNG HIỂN THỊ khi CHƯA ĐĂNG NHẬP',
        (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      tester.view.physicalSize = const Size(1280, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ForumHomeScreen(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Headers vẫn hiển thị
      expect(find.text('Chuyên mục'), findsWidgets);

      // Nút Admin hoàn toàn không hiển thị
      expect(find.text('Tạo thêm Chuyên mục và Lớp học Lý số mới (Admin)'), findsNothing);
      expect(find.text('Sửa Chuyên mục và Lớp học Lý số (Admin)'), findsNothing);
      expect(find.byWidgetPredicate((w) => w is Text && w.data != null && w.data!.startsWith('Xóa') && w.data!.contains('Lớp học Lý')), findsNothing);
    });
  });
}
