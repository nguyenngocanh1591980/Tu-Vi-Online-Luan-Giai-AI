import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/screens/forum/user_posts_screen.dart';
import 'package:frontend/screens/forum/unread_posts_screen.dart';
import 'package:frontend/widgets/main_layout.dart';

void main() {
  group('Kiểm thử màn hình "Bài của bạn" (UserPostsScreen) - Bảo toàn 100% Hình 2', () {
    testWidgets('Hiển thị đầy đủ thông tin Header, 10 Chủ đề và Khối Khám phá thêm', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 1024);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final router = GoRouter(
        initialLocation: '/forum/user-posts',
        routes: [
          ShellRoute(
            builder: (context, state, child) => MainLayout(child: child),
            routes: [
              GoRoute(
                path: '/forum/user-posts',
                builder: (context, state) => const UserPostsScreen(),
              ),
            ],
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
        ),
      );
      await tester.pumpAndSettle();

      // 1. Kiểm tra Header & Tìm kiếm & Phân trang
      expect(find.text('Đã tìm thấy 10 kết quả'), findsWidgets);
      expect(find.text('< Quay về tìm kiếm nâng cao'), findsWidgets);
      expect(find.text('Tìm trong những kết quả'), findsOneWidget);
      expect(find.text('Đã tìm thấy 10 kết quả • Trang 1 trên 1'), findsWidgets);

      // 2. Kiểm tra Header cột bảng
      expect(find.text('Chủ đề'), findsOneWidget);
      expect(find.text('Trả lời'), findsOneWidget);
      expect(find.text('Xem'), findsOneWidget);
      expect(find.text('Bài cuối'), findsOneWidget);

      // 3. Kiểm tra 10 Chủ đề gốc từ Hình 2
      expect(find.text('Mong mọi người giúp đỡ, em đang khá phân vân chuyện học hành'), findsOneWidget);
      expect(find.text('LÁ SỐ HÓA KHOA LỘC MÃ TẠI PHU....CHỒNG ẮT HẲN GIÀU CÓ ĐỊA VỊ HƠN NGƯỜI'), findsOneWidget);
      expect(find.text('Khi nào bé mới có chồng? Sao bạn bè cưới hết rồi, còn mình bé thui. :('), findsOneWidget);
      expect(find.text('Mệnh vô chính diệu - Lận đận mãi sao ạ?'), findsOneWidget);
      expect(find.text('TỬ VI NGHIỆM LÝ - DÀNH CHO NGƯỜI TRÊN 30 TUỔI.'), findsOneWidget);
      expect(find.text('anh em vào giải dùm ! nhìn tử vi buồn quá !'), findsOneWidget);
      expect(find.text('Hà xinh tươi đẹp rạng ngời :D'), findsOneWidget);
      expect(find.text('Số này làm đại gia'), findsOneWidget);
      expect(find.text('Mong các bác cao nhân xem giúp ah'), findsOneWidget);
      expect(find.text('Xem giúp xem bao giờ em lấy chồng với! Và chồng em là người?'), findsOneWidget);

      // 4. Kiểm tra tác giả trong RichText
      expect(
        find.byWidgetPredicate(
          (w) => w is RichText && w.text.toPlainText().contains('lebkue'),
        ),
        findsWidgets,
      );
      expect(
        find.byWidgetPredicate(
          (w) => w is RichText && w.text.toPlainText().contains('vuulan'),
        ),
        findsOneWidget,
      );
      expect(
        find.byWidgetPredicate(
          (w) => w is RichText && w.text.toPlainText().contains('Gacon1980'),
        ),
        findsWidgets,
      );

      // 5. Kiểm tra đúng 3 mục Khám phá thêm của Hình 2
      expect(find.text('Khám phá thêm'), findsOneWidget);
      expect(find.text('Nguồn Mở'), findsOneWidget);
      expect(find.text('Đặt lịch tư vấn'), findsOneWidget);
      expect(find.text('Sách tử vi'), findsOneWidget);

      // 6. Kiểm tra Boxed Layout 1024px và Theme Dark Navy
      final constrainedBoxFinder = find.byWidgetPredicate(
        (widget) => widget is ConstrainedBox && widget.constraints.maxWidth == 1024,
      );
      expect(constrainedBoxFinder, findsWidgets);

      final containerFinder = find.byWidgetPredicate(
        (widget) =>
            widget is Container &&
            widget.decoration is BoxDecoration &&
            (widget.decoration as BoxDecoration).color == const Color(0xFF1E2640),
      );
      expect(containerFinder, findsWidgets);
    });
  });

  group('Kiểm thử màn hình "Bài chưa xem" (UnreadPostsScreen) - Bảo toàn 100% Hình 4', () {
    testWidgets('Hiển thị đầy đủ thông tin Header, 25 Chủ đề và Khối Khám phá thêm', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 1024);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final router = GoRouter(
        initialLocation: '/forum/unread-posts',
        routes: [
          ShellRoute(
            builder: (context, state, child) => MainLayout(child: child),
            routes: [
              GoRoute(
                path: '/forum/unread-posts',
                builder: (context, state) => const UnreadPostsScreen(),
              ),
            ],
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
        ),
      );
      await tester.pumpAndSettle();

      // 1. Kiểm tra Header & Tìm kiếm & Cụm phân trang
      expect(find.text('Bài chưa xem'), findsWidgets);
      expect(find.text('< Quay về tìm kiếm nâng cao'), findsWidgets);
      expect(find.text('Tìm trong những kết quả'), findsOneWidget);
      expect(find.text('Đánh dấu tất cả các forum là đã đọc'), findsOneWidget);
      expect(find.text('Có 114 bài này, nằm với 12 trang'), findsWidgets);

      // 2. Kiểm tra Header cột bảng
      expect(find.text('Chủ đề'), findsOneWidget);
      expect(find.text('Trả lời'), findsOneWidget);
      expect(find.text('Xem'), findsOneWidget);
      expect(find.text('Bài cuối'), findsOneWidget);

      // 3. Kiểm tra các Chủ đề gốc tiêu biểu từ Hình 4
      expect(find.text('Một năm quá nhiều áp lực, kính mong được xem lá số và cho lời khuyên'), findsOneWidget);
      expect(find.text('Lá số phật thích ca mâu ni'), findsOneWidget);
      expect(find.text('THAM TỌA QUANG QUÝ là hiện thân của cát hướng và thiện nghiệp(nguoivikhieu.net)'), findsOneWidget);
      expect(find.text('MỆNH VCD CHỈ CÓ 1 CÂU MUỐN HỎI ĐÁP'), findsOneWidget);
      expect(find.text('Mệnh - Thân-Thê-Phu bị Không Kiếp xâm phạm nơi cần giải?'), findsOneWidget);
      expect(find.text('Kính nhờ anh Bradley xem giúp em với ạ.'), findsOneWidget);
      expect(find.text('Tìm giờ sinh chính xác'), findsOneWidget);
      expect(find.text('Mong muốn được giải đoán lá số Thái Dương Hãm Lại nghịch'), findsOneWidget);
      expect(find.text('Bát cháo hành'), findsOneWidget);
      expect(find.text('Hợi vận Thái tuế có đáng sợ không ạ?'), findsOneWidget);
      expect(find.text('Lá số thứ'), findsOneWidget);
      expect(find.text('Cảm live Rơ ca'), findsOneWidget);
      expect(find.text('Lá số Trạng Trình, 1 trong các nhà tiên tri nổi danh nhất thế giới'), findsOneWidget);

      // 4. Kiểm tra đúng 3 mục Khám phá thêm của Hình 4
      expect(find.text('Khám phá thêm'), findsOneWidget);
      expect(find.text('Nguồn Mở'), findsOneWidget);
      expect(find.text('Thiết kế và nghệ thuật thị giác'), findsOneWidget);
      expect(find.text('Thuốc nhuộm & Chất nhuộm'), findsOneWidget);

      // 5. Kiểm tra Boxed Layout 1024px và Theme Dark Navy
      final constrainedBoxFinder = find.byWidgetPredicate(
        (widget) => widget is ConstrainedBox && widget.constraints.maxWidth == 1024,
      );
      expect(constrainedBoxFinder, findsWidgets);

      final containerFinder = find.byWidgetPredicate(
        (widget) =>
            widget is Container &&
            widget.decoration is BoxDecoration &&
            (widget.decoration as BoxDecoration).color == const Color(0xFF1E2640),
      );
      expect(containerFinder, findsWidgets);
    });
  });
}
