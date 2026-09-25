import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/screens/forum/category_topics_screen.dart';
import 'package:frontend/screens/forum/forum_home_screen.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('CategoryTopicsScreen Tests - 6 Chuyên Mục Diễn Đàn Chuẩn Boxed 1024px & Dark Navy', () {
    testWidgets('Màn hình Thông báo - Sự kiện: Boxed Layout 1024px, Dark Navy và bảo toàn 100% nội dung Hình 1', (tester) async {
      tester.view.physicalSize = const Size(1280, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: CategoryTopicsScreen(slug: 'thong-bao-su-kien'),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Tiêu đề và mô tả
      expect(find.text('Thông báo - Sự kiện'), findsWidgets);
      expect(find.text('Thông báo chính thức của Ban quản trị diễn đàn Lý Số Việt Nam'), findsOneWidget);

      // 2. Phân trang và tìm kiếm
      expect(find.text('Đánh dấu đã xem tất cả • 247 chủ đề'), findsWidgets);
      expect(find.text('Tìm trong chuyên mục...'), findsWidgets);

      // 3. 5 chủ đề ghim
      expect(find.text('Talkshow hướng nghiệp tháng 7/2026'), findsOneWidget);
      expect(find.text('Tư vấn có ủng hộ phí để duy trì diễn đàn'), findsOneWidget);
      expect(find.text('Hướng dẫn sử dụng diễn đàn'), findsOneWidget);
      expect(find.text('Bảng giá dịch vụ tư vấn tại Lý số Hội quán'), findsOneWidget);
      expect(find.text('Nội quy diễn đàn Lý số Việt Nam'), findsOneWidget);

      // 4. Các chủ đề thường tiêu biểu từ Hình 1
      expect(find.text('Nhân dịp KN 15 năm thành lập diễn đàn, tặng 50% giá trị gói tư vấn lý số khảo trắc'), findsOneWidget);
      expect(find.text('Diễn đàn tuyển Điều hành viên, Biên tập viên'), findsOneWidget);
      expect(find.text('KHAI XUÂN CÙNG RƯỢU MƠ NÚI TẢN'), findsOneWidget);
      expect(find.text('Thông báo về tư vấn trực tuyến'), findsOneWidget);
      expect(find.text('Mở lại lớp tử vi nâng cao online trên diễn đàn.'), findsOneWidget);

      // 5. Trực tuyến, cấp phép và khám phá thêm
      expect(find.text('Đang trực tuyến'), findsOneWidget);
      expect(find.text('Cấp phép chuyên mục'), findsOneWidget);
      expect(find.text('Khám phá thêm'), findsOneWidget);
      expect(find.text('Hướng dẫn và thông tin du lịch'), findsOneWidget);
      expect(find.text('quản trị'), findsOneWidget);
      expect(find.text('Người Đông Nam Á & Cư dân vùng Đảo Thái Bình Dương'), findsOneWidget);

      // 6. Boxed Layout 1024px & margin: top 0, bottom 24
      final cbFinder = find.descendant(
        of: find.byType(Center),
        matching: find.byType(ConstrainedBox),
      );
      expect(cbFinder, findsWidgets);
      final ConstrainedBox cb = tester.widget(cbFinder.first);
      expect(cb.constraints.maxWidth, equals(1024));

      final cardFinder = find.descendant(
        of: cbFinder,
        matching: find.byType(Container),
      );
      final Container card = tester.widget(cardFinder.first);
      expect(card.margin, equals(const EdgeInsets.only(top: 0, bottom: 24.0)));
      final BoxDecoration dec = card.decoration as BoxDecoration;
      expect(dec.color, equals(const Color(0xFF1E2640)));
      expect(dec.borderRadius, equals(const BorderRadius.vertical(bottom: Radius.circular(8))));
    });

    testWidgets('Màn hình Kiến thức Cơ bản: Khung nội quy đỏ, Boxed 1024px, Hình 2', (tester) async {
      tester.view.physicalSize = const Size(1280, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: CategoryTopicsScreen(slug: 'kien-thuc-co-ban'),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Tiêu đề và mô tả
      expect(find.text('Kiến thức Cơ bản'), findsWidgets);
      expect(find.textContaining('Trao đổi kiến thức cơ bản về Lý số'), findsOneWidget);

      // 2. Khung Nội quy chuyên mục
      expect(find.text('Nội quy chuyên mục'), findsWidgets);
      expect(find.textContaining('Đây là chuyên mục trao đổi kiến thức về thiên văn'), findsOneWidget);

      // 3. Nút Chủ đề mới và phân trang 47 chủ đề
      expect(find.text('Chủ đề mới'), findsWidgets);
      expect(find.text('Đánh dấu đã xem tất cả • 47 chủ đề'), findsWidgets);

      // 4. 5 chủ đề ghim
      expect(find.text('Talkshow hướng nghiệp tháng 7/2026'), findsOneWidget);
      expect(find.text('Hướng dẫn sử dụng diễn đàn'), findsOneWidget);

      // 5. Các chủ đề thường tiêu biểu từ Hình 2
      expect(find.textContaining('Cảnh báo năm 2026 với người có ngón tay áp út dài hơn ngón trỏ'), findsOneWidget);
      expect(find.textContaining('CÁCH THỨC TỰ XEM VỀ CƯỚI GẢ'), findsOneWidget);
      expect(find.text('Bàn về Sinh-Vượng-Mộ-Tuyệt'), findsOneWidget);
      expect(find.text('Luận bàn về cách tính giờ'), findsOneWidget);
      expect(find.textContaining('Nếu Việt Nam đổi múi giờ thành GMT+8'), findsOneWidget);
    });

    testWidgets('Màn hình Kiến thức Tử vi: Boxed 1024px, Dark Navy, Hình 3', (tester) async {
      tester.view.physicalSize = const Size(1280, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: CategoryTopicsScreen(slug: 'kien-thuc-tu-vi'),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Tiêu đề và mô tả
      expect(find.text('Kiến thức Tử vi'), findsWidgets);
      expect(find.text('Trao đổi kiến thức về bộ môn tử vi'), findsOneWidget);

      // 2. Khung Nội quy chuyên mục (có link Xem tử vi)
      expect(find.text('Nội quy chuyên mục'), findsWidgets);
      expect(find.textContaining('Đây là chuyên mục trao đổi kiến thức về tử vi'), findsOneWidget);
      expect(find.textContaining('Xem tử vi'), findsWidgets);

      // 3. Nút Chủ đề mới & phân trang 689 chủ đề
      expect(find.text('Chủ đề mới'), findsWidgets);
      expect(find.text('Đánh dấu đã xem tất cả • 689 chủ đề'), findsWidgets);

      // 4. 5 chủ đề ghim
      expect(find.text('Talkshow hướng nghiệp tháng 7/2026'), findsOneWidget);
      expect(find.text('Hướng dẫn sử dụng diễn đàn'), findsOneWidget);

      // 5. Các chủ đề thường tiêu biểu của Kiến thức Tử vi từ Hình 3
      expect(find.text('Danh mục tra cứu sao tử vi'), findsOneWidget);
      expect(find.text('E rất muốn có chồng, mà ko ai lấy ạ'), findsOneWidget);
      expect(find.text('Lộc ám đới trước. Âm lộc. Âm danh. Nhân quả đời trước.'), findsOneWidget);
      expect(find.text('Không Kiếp'), findsOneWidget);
      expect(find.text('Kình Đà'), findsOneWidget);

      // 6. Trực tuyến & Khám phá thêm chuẩn Hình 3
      expect(find.textContaining('Gacon1980, ngochan7890 và 115 khách.'), findsOneWidget);
      expect(find.text('Tra Bách Khoa'), findsOneWidget);
      expect(find.text('Đọc Cẩm Nang'), findsOneWidget);
      expect(find.text('Tạo Diễn Đàn'), findsOneWidget);

      // 7. Boxed Layout 1024px
      final cbFinder = find.descendant(
        of: find.byType(Center),
        matching: find.byType(ConstrainedBox),
      );
      expect(cbFinder, findsWidgets);
      final ConstrainedBox cb = tester.widget(cbFinder.first);
      expect(cb.constraints.maxWidth, equals(1024));
    });

    testWidgets('Màn hình Kiến thức Tứ trụ: Boxed 1024px, Dark Navy, Hình 4', (tester) async {
      tester.view.physicalSize = const Size(1280, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: CategoryTopicsScreen(slug: 'kien-thuc-tu-tru'),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Tiêu đề và mô tả
      expect(find.text('Kiến thức Tứ trụ'), findsWidgets);
      expect(find.text('Trao đổi kiến thức về tứ trụ (tử bình, bát tự)'), findsOneWidget);

      // 2. Khung Nội quy chuyên mục (có link Xem tứ trụ)
      expect(find.text('Nội quy chuyên mục'), findsWidgets);
      expect(find.textContaining('Đây là chuyên mục trao đổi kiến thức về tứ trụ'), findsOneWidget);
      expect(find.textContaining('Xem tứ trụ'), findsWidgets);

      // 3. Nút Chủ đề mới & phân trang 72 chủ đề
      expect(find.text('Chủ đề mới'), findsWidgets);
      expect(find.text('Đánh dấu đã xem tất cả • 72 chủ đề'), findsWidgets);

      // 4. 5 chủ đề ghim
      expect(find.text('Talkshow hướng nghiệp tháng 7/2026'), findsOneWidget);
      expect(find.text('Hướng dẫn sử dụng diễn đàn'), findsOneWidget);

      // 5. Các chủ đề thường tiêu biểu của Kiến thức Tứ trụ từ Hình 4
      expect(find.text('TÊN GỌI VỚI MỆNH LÝ'), findsOneWidget);
      expect(find.textContaining('b "Thuyết Vũ Trụ Cổ Xưa"'), findsOneWidget);
      expect(find.text('Thìn là Kho của các Khố, VUA của các Khố.'), findsOneWidget);
      expect(find.text('Đặc tính của địa chi Thìn trong Bát Tự'), findsOneWidget);

      // 6. Trực tuyến & Khám phá thêm chuẩn Hình 4
      expect(find.textContaining('Gacon1980 và 13 khách.'), findsOneWidget);
      expect(find.text('Chính phủ'), findsOneWidget);
      expect(find.text('trong'), findsOneWidget);
      expect(find.text('Trống'), findsOneWidget);

      // 7. Boxed Layout 1024px
      final cbFinder = find.descendant(
        of: find.byType(Center),
        matching: find.byType(ConstrainedBox),
      );
      expect(cbFinder, findsWidgets);
      final ConstrainedBox cb = tester.widget(cbFinder.first);
      expect(cb.constraints.maxWidth, equals(1024));
    });

    testWidgets('Màn hình Kiến thức Độn toán: Boxed 1024px, Dark Navy, Hình 5', (tester) async {
      tester.view.physicalSize = const Size(1280, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: CategoryTopicsScreen(slug: 'kien-thuc-don-toan'),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Tiêu đề và mô tả
      expect(find.text('Kiến thức Độn toán'), findsWidgets);
      expect(find.textContaining('Trao đổi kiến thức về các môn độn toán'), findsOneWidget);

      // 2. Khung Nội quy chuyên mục (có link Xem quẻ)
      expect(find.text('Nội quy chuyên mục'), findsWidgets);
      expect(find.textContaining('Đây là chuyên mục trao đổi kiến thức về các môn Dịch lý'), findsOneWidget);
      expect(find.textContaining('Xem quẻ'), findsWidgets);

      // 3. Nút Chủ đề mới & phân trang 59 chủ đề
      expect(find.text('Chủ đề mới'), findsWidgets);
      expect(find.text('Đánh dấu đã xem tất cả • 59 chủ đề'), findsWidgets);

      // 4. 5 chủ đề ghim
      expect(find.text('Talkshow hướng nghiệp tháng 7/2026'), findsOneWidget);
      expect(find.text('Hướng dẫn sử dụng diễn đàn'), findsOneWidget);

      // 5. Các chủ đề thường tiêu biểu của Kiến thức Độn toán từ Hình 5
      expect(find.textContaining('Độn giáp học - Cái nhìn tổng quát'), findsOneWidget);
      expect(find.text('Hà Đồ - Lạc Thư'), findsOneWidget);
      expect(find.textContaining('Phần mềm tổng hợp kỳ môn độn giáp'), findsOneWidget);
      expect(find.text('Tượng Hào'), findsOneWidget);
      expect(find.textContaining('Học Bát tự hà lạc'), findsOneWidget);
      expect(find.textContaining('Phương pháp đếm số trong Dịch'), findsOneWidget);

      // 6. Trực tuyến & Khám phá thêm chuẩn Hình 5
      expect(find.textContaining('dacon1980 và 27 khách.'), findsOneWidget);
      expect(find.text('Thử Phần Mềm'), findsOneWidget);
      expect(find.text('Đọc Cẩm Nang'), findsOneWidget);
      expect(find.text('Tải Tài Liệu'), findsWidgets);

      // 7. Boxed Layout 1024px và dính khít Header
      final cbFinder = find.descendant(
        of: find.byType(Center),
        matching: find.byType(ConstrainedBox),
      );
      expect(cbFinder, findsWidgets);
      final ConstrainedBox cb = tester.widget(cbFinder.first);
      expect(cb.constraints.maxWidth, equals(1024));

      final cardFinder = find.descendant(
        of: cbFinder,
        matching: find.byType(Container),
      );
      final Container card = tester.widget(cardFinder.first);
      expect(card.margin, equals(const EdgeInsets.only(top: 0, bottom: 24.0)));
      final BoxDecoration dec = card.decoration as BoxDecoration;
      expect(dec.color, equals(const Color(0xFF1E2640)));
    });

    testWidgets('Màn hình Kiến thức Phong thủy: Boxed 1024px, Dark Navy, chuẩn hóa 100% bản gốc', (tester) async {
      tester.view.physicalSize = const Size(1280, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: CategoryTopicsScreen(slug: 'kien-thuc-phong-thuy'),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Tiêu đề và mô tả
      expect(find.text('Kiến thức Phong thủy'), findsWidgets);
      expect(find.text('Trao đổi kiến thức về Phong thủy, địa lý'), findsOneWidget);

      // 2. Khung Nội quy chuyên mục (có link Xem phong thủy)
      expect(find.text('Nội quy chuyên mục'), findsWidgets);
      expect(find.textContaining('Đây là chuyên mục trao đổi kiến thức về phong thủy, địa lý'), findsOneWidget);
      expect(find.textContaining('Xem phong thủy'), findsWidgets);

      // 3. Nút Chủ đề mới & phân trang 189 chủ đề
      expect(find.text('Chủ đề mới'), findsWidgets);
      expect(find.text('Đánh dấu đã xem tất cả • 189 chủ đề'), findsWidgets);

      // 4. 5 chủ đề ghim
      expect(find.text('Talkshow hướng nghiệp tháng 7/2026'), findsOneWidget);
      expect(find.text('Hướng dẫn sử dụng diễn đàn'), findsOneWidget);

      // 5. Chủ đề thường tiêu biểu của Kiến thức Phong thủy từ bản gốc
      expect(find.textContaining('Chùa cổ Việt Nam (NguyenVu)'), findsOneWidget);
      expect(find.textContaining('Gương Phong Thủy (NguyenVu)'), findsOneWidget);
      expect(find.textContaining('Tổng hợp các bài viết của thầy NguyenVu'), findsOneWidget);
      expect(find.textContaining('Động thổ thì động ở đâu trước'), findsOneWidget);
      expect(find.textContaining('Làm Nhà - Một Vài Lưu Ý'), findsOneWidget);
      expect(find.textContaining('Cầu Thang - Làm Thế Nào Để Hợp Lý'), findsOneWidget);
      expect(find.textContaining('Ảnh hưởng của hướng Nam trong phong thủy'), findsOneWidget);

      // 6. Trực tuyến & Khám phá thêm
      expect(find.textContaining('Gacon1980 và 5 khách.'), findsOneWidget);
      expect(find.text('Hướng dẫn và thông tin du lịch'), findsOneWidget);
      expect(find.text('Thời gian & Lịch'), findsOneWidget);
      expect(find.text('Bảng giá dịch vụ'), findsOneWidget);

      // 7. Boxed Layout 1024px và dính khít Header
      final cbFinder = find.descendant(
        of: find.byType(Center),
        matching: find.byType(ConstrainedBox),
      );
      expect(cbFinder, findsWidgets);
      final ConstrainedBox cb = tester.widget(cbFinder.first);
      expect(cb.constraints.maxWidth, equals(1024));

      final cardFinder = find.descendant(
        of: cbFinder,
        matching: find.byType(Container),
      );
      final Container card = tester.widget(cardFinder.first);
      expect(card.margin, equals(const EdgeInsets.only(top: 0, bottom: 24.0)));
      final BoxDecoration dec = card.decoration as BoxDecoration;
      expect(dec.color, equals(const Color(0xFF1E2640)));
    });

    testWidgets('Kiểm tra điều hướng từ ForumHomeScreen đến cả 6 chuyên mục', (tester) async {
      tester.view.physicalSize = const Size(1280, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final router = GoRouter(
        initialLocation: '/forum',
        routes: [
          GoRoute(
            path: '/forum',
            builder: (context, state) => const ForumHomeScreen(),
          ),
          GoRoute(
            path: '/forum/category/:slug',
            builder: (context, state) => CategoryTopicsScreen(slug: state.pathParameters['slug'] ?? ''),
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      // 1. Bấm vào "Thông báo - Sự kiện"
      await tester.tap(find.text('Thông báo - Sự kiện'));
      await tester.pumpAndSettle();
      expect(find.text('Đánh dấu đã xem tất cả • 247 chủ đề'), findsWidgets);

      // 2. Quay lại /forum và bấm "Kiến thức Cơ bản"
      router.go('/forum');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Kiến thức Cơ bản'));
      await tester.pumpAndSettle();
      expect(find.text('Đánh dấu đã xem tất cả • 47 chủ đề'), findsWidgets);

      // 3. Quay lại /forum và bấm "Kiến thức Tử vi"
      router.go('/forum');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Kiến thức Tử vi'));
      await tester.pumpAndSettle();
      expect(find.text('Danh mục tra cứu sao tử vi'), findsOneWidget);
      expect(find.text('Tra Bách Khoa'), findsOneWidget);

      // 4. Quay lại /forum và bấm "Kiến thức Tứ trụ"
      router.go('/forum');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Kiến thức Tứ trụ'));
      await tester.pumpAndSettle();
      expect(find.text('TÊN GỌI VỚI MỆNH LÝ'), findsOneWidget);
      expect(find.text('Chính phủ'), findsOneWidget);

      // 5. Quay lại /forum và bấm "Kiến thức Độn toán"
      router.go('/forum');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Kiến thức Độn toán'));
      await tester.pumpAndSettle();
      expect(find.text('Đánh dấu đã xem tất cả • 59 chủ đề'), findsWidgets);
      expect(find.textContaining('Độn giáp học - Cái nhìn tổng quát'), findsOneWidget);
      expect(find.text('Thử Phần Mềm'), findsOneWidget);

      // 6. Quay lại /forum và bấm "Kiến thức Phong thủy"
      router.go('/forum');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Kiến thức Phong thủy'));
      await tester.pumpAndSettle();
      expect(find.text('Đánh dấu đã xem tất cả • 189 chủ đề'), findsWidgets);
      expect(find.textContaining('Chùa cổ Việt Nam (NguyenVu)'), findsOneWidget);
      expect(find.text('Thời gian & Lịch'), findsOneWidget);

      // 7. Quay lại /forum và bấm "Lớp học tử vi"
      router.go('/forum');
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Lớp học tử vi'));
      await tester.tap(find.text('Lớp học tử vi'));
      await tester.pumpAndSettle();
      expect(find.text('Chuyên mục dành cho lớp học tử vi'), findsOneWidget);
      expect(find.text('Bạn không được cấp phép để xem các chủ đề trong chuyên mục này.'), findsOneWidget);

      // 8. Quay lại /forum và bấm "Lớp học tứ trụ"
      router.go('/forum');
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Lớp học tứ trụ'));
      await tester.tap(find.text('Lớp học tứ trụ'));
      await tester.pumpAndSettle();
      expect(find.text('Lớp học tứ trụ cơ bản, dành cho người mới bắt đầu'), findsOneWidget);
      expect(find.text('Bạn không được cấp phép để xem các chủ đề trong chuyên mục này.'), findsOneWidget);

      // 9. Quay lại /forum và bấm "Lớp học chiêm tinh"
      router.go('/forum');
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Lớp học chiêm tinh'));
      await tester.tap(find.text('Lớp học chiêm tinh'));
      await tester.pumpAndSettle();
      expect(find.text('Khu vực dành riêng cho lớp học V.'), findsOneWidget);
      expect(find.text('Bạn không được cấp phép để xem các chủ đề trong chuyên mục này.'), findsOneWidget);

      // 10. Quay lại /forum và bấm "Lớp học Phong thủy"
      router.go('/forum');
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Lớp học Phong thủy').first);
      await tester.tap(find.text('Lớp học Phong thủy').first);
      await tester.pumpAndSettle();
      expect(find.text('Khu vực dành riêng cho lớp học TV.'), findsOneWidget);
      expect(find.text('Bạn không được cấp phép để xem các chủ đề trong chuyên mục này.'), findsOneWidget);

      // 11. Quay lại /forum và bấm "Lớp học tổng hợp"
      router.go('/forum');
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Lớp học tổng hợp'));
      await tester.tap(find.text('Lớp học tổng hợp'));
      await tester.pumpAndSettle();
      expect(find.text('Khu vực thực hành luận đoán của các học viên. Các thành viên có thể giao lưu.'), findsOneWidget);
      expect(find.text('Bạn không được cấp phép để xem các chủ đề trong chuyên mục này.'), findsOneWidget);
      expect(find.text('Tải Tài Liệu'), findsOneWidget);

      // 12. Quay lại /forum và bấm "Lớp học Dịch lý"
      router.go('/forum');
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Lớp học Dịch lý'));
      await tester.tap(find.text('Lớp học Dịch lý'));
      await tester.pumpAndSettle();
      expect(find.text('Chuyên mục dành cho lớp học quẻ dịch'), findsOneWidget);
      expect(find.text('Bạn không được cấp phép để xem các chủ đề trong chuyên mục này.'), findsOneWidget);
    });

    testWidgets('Màn hình Kiến thức Lý số khác: Boxed 1024px, Dark Navy, Cờ 1 & Cờ 2 chuẩn xác 100%', (tester) async {
      tester.view.physicalSize = const Size(1280, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: CategoryTopicsScreen(slug: 'kien-thuc-ly-so-khac'),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Tiêu đề & mô tả
      expect(find.text('Kiến thức Lý số khác'), findsWidgets);
      expect(find.text('Kiến thức chung về Lý số hoặc chưa được phân loại'), findsOneWidget);
      expect(find.text('Đánh dấu đã xem tất cả • 85 chủ đề'), findsWidgets);

      // 2. Cờ 2: TÌM HƯỚNG CẢI CÁCH LÁ SỐ TỬ VI.
      expect(find.text('TÌM HƯỚNG CẢI CÁCH LÁ SỐ TỬ VI.'), findsOneWidget);
      expect(find.text('335'), findsOneWidget);
      expect(find.text('136843'), findsOneWidget);
      expect(find.text('10:01, 02/06/25'), findsOneWidget);

      // 3. Cờ 1: Vũ Trụ Là Vĩnh Hằng theo "Học Thuyết Âm Dương Ngũ Hành"
      expect(find.text('Vũ Trụ Là Vĩnh Hằng theo "Học Thuyết Âm Dương Ngũ Hành"'), findsOneWidget);
      expect(find.text('16:03, 16/12/12'), findsOneWidget);

      // 4. Boxed Layout 1024px & Dark Navy
      final cbFinder = find.descendant(
        of: find.byType(Center),
        matching: find.byType(ConstrainedBox),
      );
      final ConstrainedBox cb = tester.widget(cbFinder.first);
      expect(cb.constraints.maxWidth, equals(1024));
    });

    testWidgets('Màn hình Thư ngỏ - Ý kiến: Cờ 3 bỏ quảng cáo, Cờ 4 gianguyenthaonguyen, Boxed 1024px', (tester) async {
      tester.view.physicalSize = const Size(1280, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: CategoryTopicsScreen(slug: 'thu-ngo-y-kien'),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Tiêu đề & mô tả
      expect(find.text('Thư ngỏ - Ý kiến'), findsWidgets);
      expect(find.text('Gửi lời tri ân, thư ngỏ và đóng góp ý kiến về diễn đàn'), findsOneWidget);
      expect(find.text('Đánh dấu đã xem tất cả • 722 chủ đề'), findsWidgets);

      // 2. Cờ 3: Header Thông báo KHÔNG chứa badge "Tìm kiếm bài viết"
      expect(find.text('Thông báo'), findsWidgets);
      expect(find.text('Tìm kiếm bài viết'), findsNothing);

      // 3. Cờ 4: Cảnh báo về tình trạng lừa đảo hiện nay (tác giả gianguyenthaonguyen)
      expect(find.text('Cảnh báo về tình trạng lừa đảo hiện nay'), findsOneWidget);
      expect(find.text('gianguyenthaonguyen'), findsOneWidget);
      expect(find.text('22:26, 03/12/17'), findsOneWidget);

      // 4. 6 chủ đề ghim
      expect(find.text('Talkshow hướng nghiệp tháng 7/2026'), findsOneWidget);
      expect(find.text('Hướng dẫn đăng lá số'), findsOneWidget);
      expect(find.text('Tư vấn có ủng hộ phí để duy trì diễn đàn'), findsOneWidget);
      expect(find.text('Hướng dẫn sử dụng diễn đàn'), findsOneWidget);
      expect(find.text('Bảng giá dịch vụ tư vấn tại Lý số Hội quán'), findsOneWidget);
      expect(find.text('Nội quy diễn đàn Lý số Việt Nam'), findsOneWidget);
    });

    testWidgets('Màn hình Lớp học tử vi: Boxed 1024px, Dark Navy, 2 ô thông báo không có quyền, 3 mục Khám phá thêm', (tester) async {
      tester.view.physicalSize = const Size(1280, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: CategoryTopicsScreen(slug: 'lop-hoc-tu-vi'),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Tiêu đề & mô tả
      expect(find.text('Lớp học tử vi'), findsWidgets);
      expect(find.text('Chuyên mục dành cho lớp học tử vi'), findsOneWidget);

      // 2. Hai ô thông báo giới hạn quyền
      expect(find.text('Bạn không được cấp phép để xem các chủ đề trong chuyên mục này.'), findsOneWidget);
      expect(find.text('Thể loại này không có chuyên mục.'), findsOneWidget);

      // 3. Đang trực tuyến
      expect(find.text('Đang trực tuyến'), findsOneWidget);
      expect(find.textContaining('Gacon1980 và 0 khách.'), findsOneWidget);

      // 4. 3 mục Khám phá thêm
      expect(find.text('Khám phá thêm'), findsOneWidget);
      expect(find.text('Thời gian & Lịch'), findsOneWidget);
      expect(find.text('Trang trí nhà và nội thất'), findsOneWidget);
      expect(find.text('Nhà cung cấp dịch vụ diễn đàn và trò chuyện'), findsOneWidget);

      // 5. Boxed Layout 1024px & Dark Navy
      final cbFinder = find.descendant(
        of: find.byType(Center),
        matching: find.byType(ConstrainedBox),
      );
      final ConstrainedBox cb = tester.widget(cbFinder.first);
      expect(cb.constraints.maxWidth, equals(1024));

      final cardFinder = find.descendant(
        of: cbFinder,
        matching: find.byType(Container),
      );
      final Container card = tester.widget(cardFinder.first);
      expect(card.margin, equals(const EdgeInsets.only(top: 0, bottom: 24.0)));
      final BoxDecoration dec = card.decoration as BoxDecoration;
      expect(dec.color, equals(const Color(0xFF1E2640)));
    });

    testWidgets('Màn hình Lớp học tứ trụ: Boxed 1024px, Dark Navy, 2 ô thông báo không có quyền, không có Khám phá thêm', (tester) async {
      tester.view.physicalSize = const Size(1280, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: CategoryTopicsScreen(slug: 'lop-hoc-tu-tru'),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Tiêu đề & mô tả
      expect(find.text('Lớp học tứ trụ'), findsWidgets);
      expect(find.text('Lớp học tứ trụ cơ bản, dành cho người mới bắt đầu'), findsOneWidget);

      // 2. Hai ô thông báo giới hạn quyền
      expect(find.text('Bạn không được cấp phép để xem các chủ đề trong chuyên mục này.'), findsOneWidget);
      expect(find.text('Thể loại này không có chuyên mục.'), findsOneWidget);

      // 3. Đang trực tuyến
      expect(find.text('Đang trực tuyến'), findsOneWidget);
      expect(find.textContaining('Gacon1980 và 0 khách.'), findsOneWidget);

      // 4. Khám phá thêm không hiển thị
      expect(find.text('Khám phá thêm'), findsNothing);

      // 5. Boxed Layout 1024px & Dark Navy
      final cbFinder = find.descendant(
        of: find.byType(Center),
        matching: find.byType(ConstrainedBox),
      );
      final ConstrainedBox cb = tester.widget(cbFinder.first);
      expect(cb.constraints.maxWidth, equals(1024));

      final cardFinder = find.descendant(
        of: cbFinder,
        matching: find.byType(Container),
      );
      final Container card = tester.widget(cardFinder.first);
      expect(card.margin, equals(const EdgeInsets.only(top: 0, bottom: 24.0)));
      final BoxDecoration dec = card.decoration as BoxDecoration;
      expect(dec.color, equals(const Color(0xFF1E2640)));
    });

    testWidgets('Màn hình Lớp học chiêm tinh: Boxed 1024px, Dark Navy, 2 ô thông báo không có quyền, 3 mục Khám phá thêm, 1 khách', (tester) async {
      tester.view.physicalSize = const Size(1280, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: CategoryTopicsScreen(slug: 'lop-hoc-chiem-tinh'),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Tiêu đề & mô tả (Cờ 1)
      expect(find.text('Lớp học chiêm tinh'), findsWidgets);
      expect(find.text('Khu vực dành riêng cho lớp học V.'), findsOneWidget);

      // 2. Hai ô thông báo giới hạn quyền
      expect(find.text('Bạn không được cấp phép để xem các chủ đề trong chuyên mục này.'), findsOneWidget);
      expect(find.text('Thể loại này không có chuyên mục.'), findsOneWidget);

      // 3. Đang trực tuyến (1 khách)
      expect(find.text('Đang trực tuyến'), findsOneWidget);
      expect(find.textContaining('1 khách.'), findsOneWidget);

      // 4. 3 mục Khám phá thêm chuẩn Hình 2
      expect(find.text('Khám phá thêm'), findsOneWidget);
      expect(find.text('Chọn Tour ASEAN'), findsOneWidget);
      expect(find.text('Giải Bài Tập'), findsOneWidget);
      expect(find.text('Tư vấn phong thủy'), findsOneWidget);

      // 5. Boxed Layout 1024px & Dark Navy
      final cbFinder = find.descendant(
        of: find.byType(Center),
        matching: find.byType(ConstrainedBox),
      );
      final ConstrainedBox cb = tester.widget(cbFinder.first);
      expect(cb.constraints.maxWidth, equals(1024));

      final cardFinder = find.descendant(
        of: cbFinder,
        matching: find.byType(Container),
      );
      final Container card = tester.widget(cardFinder.first);
      expect(card.margin, equals(const EdgeInsets.only(top: 0, bottom: 24.0)));
      final BoxDecoration dec = card.decoration as BoxDecoration;
      expect(dec.color, equals(const Color(0xFF1E2640)));
    });

    testWidgets('Màn hình Lớp học Phong thủy: Boxed 1024px, Dark Navy, 2 ô thông báo không có quyền, không có Khám phá thêm, 0 khách', (tester) async {
      tester.view.physicalSize = const Size(1280, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: CategoryTopicsScreen(slug: 'lop-hoc-phong-thuy'),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Tiêu đề & mô tả (Cờ 2)
      expect(find.text('Lớp học Phong thủy'), findsWidgets);
      expect(find.text('Khu vực dành riêng cho lớp học TV.'), findsOneWidget);

      // 2. Hai ô thông báo giới hạn quyền
      expect(find.text('Bạn không được cấp phép để xem các chủ đề trong chuyên mục này.'), findsOneWidget);
      expect(find.text('Thể loại này không có chuyên mục.'), findsOneWidget);

      // 3. Đang trực tuyến (0 khách)
      expect(find.text('Đang trực tuyến'), findsOneWidget);
      expect(find.textContaining('0 khách.'), findsOneWidget);

      // 4. Khám phá thêm không hiển thị (chuẩn Hình 4)
      expect(find.text('Khám phá thêm'), findsNothing);

      // 5. Boxed Layout 1024px & Dark Navy
      final cbFinder = find.descendant(
        of: find.byType(Center),
        matching: find.byType(ConstrainedBox),
      );
      final ConstrainedBox cb = tester.widget(cbFinder.first);
      expect(cb.constraints.maxWidth, equals(1024));

      final cardFinder = find.descendant(
        of: cbFinder,
        matching: find.byType(Container),
      );
      final Container card = tester.widget(cardFinder.first);
      expect(card.margin, equals(const EdgeInsets.only(top: 0, bottom: 24.0)));
      final BoxDecoration dec = card.decoration as BoxDecoration;
      expect(dec.color, equals(const Color(0xFF1E2640)));
    });

    testWidgets('Màn hình Lớp học tổng hợp: Boxed 1024px, Dark Navy, 2 ô thông báo không có quyền, badge Tải Tài Liệu, 3 mục Khám phá thêm, 0 khách', (tester) async {
      tester.view.physicalSize = const Size(1280, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: CategoryTopicsScreen(slug: 'lop-hoc-tong-hop'),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Tiêu đề & mô tả (Cờ 2)
      expect(find.text('Lớp học tổng hợp'), findsWidgets);
      expect(find.text('Khu vực thực hành luận đoán của các học viên. Các thành viên có thể giao lưu.'), findsOneWidget);

      // 2. Hai ô thông báo giới hạn quyền
      expect(find.text('Bạn không được cấp phép để xem các chủ đề trong chuyên mục này.'), findsOneWidget);
      expect(find.text('Thể loại này không có chuyên mục.'), findsOneWidget);

      // 3. Đang trực tuyến (0 khách) & badge Tải Tài Liệu (Cờ 1)
      expect(find.text('Đang trực tuyến'), findsOneWidget);
      expect(find.textContaining('0 khách.'), findsOneWidget);
      expect(find.text('Tải Tài Liệu'), findsOneWidget);

      // 4. 3 mục Khám phá thêm chuẩn Hình 2
      expect(find.text('Khám phá thêm'), findsOneWidget);
      expect(find.text('Chạy Quảng Cáo'), findsOneWidget);
      expect(find.text('Xem Tin Công-Ty'), findsOneWidget);
      expect(find.text('Tạo Thiết Kế'), findsOneWidget);

      // 5. Boxed Layout 1024px & Dark Navy
      final cbFinder = find.descendant(
        of: find.byType(Center),
        matching: find.byType(ConstrainedBox),
      );
      final ConstrainedBox cb = tester.widget(cbFinder.first);
      expect(cb.constraints.maxWidth, equals(1024));

      final cardFinder = find.descendant(
        of: cbFinder,
        matching: find.byType(Container),
      );
      final Container card = tester.widget(cardFinder.first);
      expect(card.margin, equals(const EdgeInsets.only(top: 0, bottom: 24.0)));
      final BoxDecoration dec = card.decoration as BoxDecoration;
      expect(dec.color, equals(const Color(0xFF1E2640)));
    });

    testWidgets('Màn hình Lớp học Dịch lý: Boxed 1024px, Dark Navy, 2 ô thông báo không có quyền, không có Khám phá thêm, 0 khách', (tester) async {
      tester.view.physicalSize = const Size(1280, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: CategoryTopicsScreen(slug: 'lop-hoc-dich-ly'),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Tiêu đề & mô tả
      expect(find.text('Lớp học Dịch lý'), findsWidgets);
      expect(find.text('Chuyên mục dành cho lớp học quẻ dịch'), findsOneWidget);

      // 2. Hai ô thông báo giới hạn quyền
      expect(find.text('Bạn không được cấp phép để xem các chủ đề trong chuyên mục này.'), findsOneWidget);
      expect(find.text('Thể loại này không có chuyên mục.'), findsOneWidget);

      // 3. Đang trực tuyến (0 khách)
      expect(find.text('Đang trực tuyến'), findsOneWidget);
      expect(find.textContaining('0 khách.'), findsOneWidget);

      // 4. Khám phá thêm không hiển thị (chuẩn Hình 4)
      expect(find.text('Khám phá thêm'), findsNothing);

      // 5. Boxed Layout 1024px & Dark Navy
      final cbFinder = find.descendant(
        of: find.byType(Center),
        matching: find.byType(ConstrainedBox),
      );
      final ConstrainedBox cb = tester.widget(cbFinder.first);
      expect(cb.constraints.maxWidth, equals(1024));

      final cardFinder = find.descendant(
        of: cbFinder,
        matching: find.byType(Container),
      );
      final Container card = tester.widget(cardFinder.first);
      expect(card.margin, equals(const EdgeInsets.only(top: 0, bottom: 24.0)));
      final BoxDecoration dec = card.decoration as BoxDecoration;
      expect(dec.color, equals(const Color(0xFF1E2640)));
    });

    testWidgets('Màn hình Xem Phong thủy: Boxed 1024px, Dark Navy, xác nhận 100% dữ liệu cờ', (tester) async {
      tester.view.physicalSize = const Size(1280, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: CategoryTopicsScreen(slug: 'xem-phong-thuy'),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Tiêu đề & mô tả
      expect(find.text('Xem Phong thủy'), findsWidgets);
      expect(find.text('Hỏi đáp, tư vấn về phong thủy, địa lý'), findsOneWidget);

      // 2. Nội dung các chủ đề đã xác nhận
      expect(find.text('Hướng dẫn: Chọn hướng theo Bát trạch'), findsOneWidget);
      expect(find.textContaining('nncuong'), findsOneWidget);
      expect(find.text('117378'), findsOneWidget);
      expect(find.textContaining('Hoàng Huy Đạt'), findsOneWidget);

      expect(find.text('Nữ - Kỷ mùi kính mong các bác cho lời khuyên hướng bàn thờ ạ'), findsOneWidget);
      expect(find.textContaining('qu4ngnm'), findsOneWidget);
      expect(find.text('3750'), findsOneWidget);
      expect(find.textContaining('EinEMC2'), findsOneWidget);

      expect(find.text('Nên trưng bày bộ 3 kiếm nhật ở đâu trong nhà'), findsOneWidget);
      expect(find.textContaining('Npminh91'), findsOneWidget);
      expect(find.textContaining('Diệu Khởi'), findsWidgets);

      expect(find.text('Tình trạng bóng đè'), findsOneWidget);
      expect(find.textContaining('PhHGiaLinh'), findsOneWidget);

      expect(find.text('Đặt gạch.'), findsOneWidget);
      expect(find.textContaining('Hungternopil'), findsWidgets);

      // 3. Trực tuyến & Khám phá thêm
      expect(find.textContaining('34 khách.'), findsOneWidget);
      expect(find.text('Hỗ trợ qua điện thoại'), findsOneWidget);
      expect(find.text('Thảo luận trực tuyến'), findsOneWidget);
    });

    testWidgets('Màn hình Xem ngày, luận tuổi: Boxed 1024px, Dark Navy, Tú Trương, Akicho, đã bỏ nút Mua Lịch Mới', (tester) async {
      tester.view.physicalSize = const Size(1280, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: CategoryTopicsScreen(slug: 'xem-ngay-luan-tuoi'),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Tiêu đề & mô tả
      expect(find.text('Xem ngày, luận tuổi'), findsWidgets);
      expect(find.text('Xem ngày tốt, luận tuổi theo âm dương, ngũ hành, can chi, bát quái, cửu cung'), findsOneWidget);

      // 2. Nội dung các bài đã xác nhận
      expect(find.text('Tú Trương'), findsOneWidget);
      expect(find.textContaining('Phá Hữu Pháp Vương'), findsWidgets);

      expect(find.text('Tuổi Nhâm Thân sinh con 2025 có được không các bác ?'), findsOneWidget);
      expect(find.textContaining('Akicho'), findsOneWidget);

      // 3. Nút Mua Lịch Mới đã bị bỏ vì là quảng cáo
      expect(find.text('Mua Lịch Mới'), findsNothing);

      // 4. Trực tuyến & Khám phá thêm
      expect(find.textContaining('98 khách.'), findsOneWidget);
      expect(find.text('Sấm Kinh Thiên-Văn'), findsOneWidget);
      expect(find.text('Đọc Cẩm Nang'), findsOneWidget);
    });

    testWidgets('Màn hình Xem Lý số Phương tây: Boxed 1024px, Dark Navy, 3 chủ đề, Hình 2, đã bỏ nút Toán học', (tester) async {
      tester.view.physicalSize = const Size(1280, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: CategoryTopicsScreen(slug: 'xem-ly-so-phuong-tay'),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Tiêu đề & mô tả
      expect(find.text('Xem Lý số Phương tây'), findsWidgets);
      expect(find.text('Hỏi đáp về tử vi tây phương, thần số học'), findsOneWidget);

      // 2. Nội dung 3 bài chủ đề
      expect(find.text('Xem Hạn Tử vi cho đại chúng'), findsOneWidget);
      expect(find.text('Rajneeshbible'), findsWidgets);
      expect(find.text('>>> 888 linh tinh về 12 cung Hoàng Đạo <<<'), findsOneWidget);
      expect(find.textContaining('begauhn'), findsOneWidget);
      expect(find.textContaining('46210'), findsOneWidget);
      expect(find.text('Chọn nghề theo ngày sinh (cung Hoàng Đạo)'), findsOneWidget);
      expect(find.textContaining('phudongsoft'), findsWidgets);
      expect(find.textContaining('2791'), findsOneWidget);

      // 3. Đã bỏ nút quảng cáo Toán học
      expect(find.text('Toán học'), findsNothing);

      // 4. Trực tuyến & Khám phá thêm
      expect(find.textContaining('4 khách.'), findsOneWidget);
      expect(find.text('Đặt lịch tư vấn'), findsOneWidget);
      expect(find.text('Chính trị'), findsOneWidget);
      expect(find.text('Nguồn Mở'), findsOneWidget);
    });

    testWidgets('Màn hình Xem tướng, đặt tên, sinh trắc: Boxed 1024px, Dark Navy, 3 chủ đề, Hình 4, đã bỏ Chọn Tour ASEAN và Chống Trộm Data', (tester) async {
      tester.view.physicalSize = const Size(1280, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: CategoryTopicsScreen(slug: 'xem-tuong-dat-ten-sinh-trac'),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Tiêu đề & mô tả
      expect(find.text('Xem tướng, đặt tên, sinh trắc'), findsWidgets);
      expect(find.text('Các bài viết trao đổi học thuật về môn tướng pháp, chỉ tay...'), findsOneWidget);

      // 2. Nội dung 3 bài chủ đề & badge
      expect(find.text('Tư vấn thương hiệu của Laido'), findsOneWidget);
      expect(find.textContaining('Duccon_cdl13'), findsOneWidget);
      expect(find.text('Xem hôn nhân của nữ giới qua nhân tướng'), findsOneWidget);
      expect(find.text('Huyền bí & Siêu linh'), findsOneWidget);
      expect(find.textContaining('siunhan92dn'), findsWidgets);
      expect(find.text('Chỉ tay bên bàn tay trái của nữ nói lên điều gì?'), findsOneWidget);
      expect(find.textContaining('baochau1611'), findsOneWidget);
      expect(find.textContaining('40380'), findsOneWidget);

      // 3. Đã bỏ quảng cáo Chọn Tour ASEAN và Chống Trộm Data
      expect(find.text('Chọn Tour ASEAN'), findsNothing);
      expect(find.text('Chống Trộm Data'), findsNothing);

      // 4. Trực tuyến & Khám phá thêm
      expect(find.textContaining('199 khách.'), findsOneWidget);
      expect(find.text('Tạo Diễn Đàn'), findsOneWidget);
      expect(find.text('Phối Màu Nhuộm'), findsOneWidget);
      expect(find.text('Lắp Camera'), findsOneWidget);
    });

    testWidgets('Màn hình Xem bằng các môn khác: Boxed 1024px, Dark Navy, 3 chủ đề, 77 khách, Hình 2', (tester) async {
      tester.view.physicalSize = const Size(1280, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: CategoryTopicsScreen(slug: 'xem-bang-cac-mon-khac'),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Tiêu đề & mô tả
      expect(find.text('Xem bằng các môn khác'), findsWidgets);
      expect(find.text('Xem và luận đoán bằng các môn Lý số khác, chưa phân loại'), findsOneWidget);
      expect(find.text('Đánh dấu đã xem tất cả • 764 chủ đề'), findsWidgets);

      // 2. Nội quy chuyên mục
      expect(find.text('Nội quy chuyên mục'), findsWidgets);
      expect(find.textContaining('Đây là chuyên mục dành cho việc xem Lý số chưa được phân loại'), findsOneWidget);

      // 3. Nội dung 3 bài chủ đề chuẩn xác 100%
      expect(find.text('Dự đoán tương lai qua giấc mơ (P2) Mơ thấy Lửa'), findsOneWidget);
      expect(find.textContaining('3024'), findsOneWidget);
      expect(find.text('Dự đoán tương lai qua giấc mơ (P1) Mơ thấy nước'), findsOneWidget);
      expect(find.textContaining('4789'), findsOneWidget);
      expect(find.text('Khi yêu người biết xem lá số'), findsOneWidget);
      expect(find.textContaining('2006'), findsOneWidget);
      expect(find.textContaining('loppo'), findsOneWidget);
      expect(find.textContaining('begauhn'), findsWidgets);
      expect(find.textContaining('Zalo O'), findsWidgets);

      // 4. Trực tuyến
      expect(find.textContaining('77 khách.'), findsOneWidget);
    });

    testWidgets('Màn hình Cổ học - Văn hóa - Tín ngưỡng: Boxed 1024px, Dark Navy, 6 bài ghim, 3 chủ đề, 223 khách, Hình 4', (tester) async {
      tester.view.physicalSize = const Size(1280, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: CategoryTopicsScreen(slug: 'co-hoc-van-hoa-tin-nguong'),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Tiêu đề & mô tả
      expect(find.text('Cổ học - Văn hóa - Tín ngưỡng'), findsWidgets);
      expect(find.text('Trao đổi về y học, võ thuật, văn hóa, phong tục, tín ngưỡng'), findsOneWidget);
      expect(find.text('Đánh dấu đã xem tất cả • 808 chủ đề'), findsWidgets);

      // 2. Nội quy chuyên mục
      expect(find.text('Nội quy chuyên mục'), findsWidgets);
      expect(find.text('Không tranh luận về chính trị và tôn giáo'), findsOneWidget);

      // 3. 6 bài ghim (có bài số 3 CHON NGAY)
      expect(find.text('CHON NGAY'), findsOneWidget);
      expect(find.textContaining('PHEPMAU'), findsOneWidget);
      expect(find.textContaining('107531'), findsOneWidget);

      // 4. 3 bài chủ đề
      expect(find.text('Kinh Thi mỗi tuần.'), findsOneWidget);
      expect(find.textContaining('Minh Di'), findsOneWidget);
      expect(find.textContaining('13910'), findsOneWidget);
      expect(find.textContaining('truy mệnh'), findsOneWidget);

      expect(find.text('Y HỌC & SỨC KHỎE...'), findsOneWidget);
      expect(find.textContaining('lavi'), findsOneWidget);
      expect(find.textContaining('23220'), findsOneWidget);
      expect(find.textContaining('Bội Ngân'), findsOneWidget);

      expect(find.text('Thầy Pói Pất đắc dĩ'), findsOneWidget);
      expect(find.textContaining('Phá Hữu Pháp Vương'), findsWidgets);
      expect(find.text('29'), findsOneWidget);

      // 5. Trực tuyến
      expect(find.textContaining('223 khách.'), findsOneWidget);
    });

    testWidgets('Màn hình Cuộc sống muôn màu: Boxed 1024px, Dark Navy, 5 bài ghim, 3 chủ đề, 368 khách, Hình 2', (tester) async {
      tester.view.physicalSize = const Size(1280, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: CategoryTopicsScreen(slug: 'cuoc-song-muon-mau'),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Tiêu đề & mô tả
      expect(find.text('Cuộc sống muôn màu'), findsWidgets);
      expect(find.text('Chia sẻ thơ ca, nhạc họa, các trải nghiệm của cuộc sống'), findsOneWidget);
      expect(find.text('Đánh dấu đã xem tất cả • 2630 chủ đề'), findsWidgets);

      // 2. Không có khung nội quy
      expect(find.text('Nội quy chuyên mục'), findsNothing);

      // 3. Đã bỏ badge nút quảng cáo Thơ ca
      expect(find.text('Thơ ca'), findsNothing);
      expect(find.text('Đọc Tập Thơ'), findsNothing);

      // 4. 5 bài ghim
      expect(find.text('Talkshow hướng nghiệp tháng 7/2026'), findsOneWidget);
      expect(find.text('Tư vấn có ủng hộ phí để duy trì diễn đàn'), findsOneWidget);
      expect(find.text('Hướng dẫn sử dụng diễn đàn'), findsOneWidget);
      expect(find.text('Bảng giá dịch vụ tư vấn tại Lý số Hội quán'), findsOneWidget);
      expect(find.text('Nội quy diễn đàn Lý số Việt Nam'), findsOneWidget);

      // 5. 3 bài chủ đề
      expect(find.text('CƯỜI MỘT TÍ...'), findsOneWidget);
      expect(find.textContaining('124931'), findsOneWidget);
      expect(find.textContaining('sthlikethat'), findsOneWidget);

      expect(find.text('Thơ Dịch...Dịch Thơ'), findsOneWidget);
      expect(find.textContaining('154216'), findsOneWidget);
      expect(find.textContaining('Diệu Khởi'), findsOneWidget);

      expect(find.text('Sử vui'), findsOneWidget);
      expect(find.textContaining('Rommel'), findsWidgets);
      expect(find.textContaining('1074'), findsOneWidget);

      // 6. Trực tuyến & Khám phá thêm
      expect(find.textContaining('368 khách.'), findsOneWidget);
      expect(find.text('Chọn Tour ASEAN'), findsOneWidget);
      expect(find.text('Forum'), findsOneWidget);
      expect(find.text('Tìm Nhà Hàng'), findsOneWidget);

      // 7. Boxed 1024px & Dark Navy
      final cbFinder = find.descendant(
        of: find.byType(Center),
        matching: find.byType(ConstrainedBox),
      );
      final ConstrainedBox cb = tester.widget(cbFinder.first);
      expect(cb.constraints.maxWidth, equals(1024));

      final cardFinder = find.descendant(
        of: cbFinder,
        matching: find.byType(Container),
      );
      final Container card = tester.widget(cardFinder.first);
      expect(card.margin, equals(const EdgeInsets.only(top: 0, bottom: 24.0)));
      final BoxDecoration dec = card.decoration as BoxDecoration;
      expect(dec.color, equals(const Color(0xFF1E2640)));
    });

    testWidgets('Màn hình Câu lạc bộ - Giao lưu - Kết bạn: Boxed 1024px, Dark Navy, 7 bài ghim, 2 chủ đề, 744 khách, Hình 4', (tester) async {
      tester.view.physicalSize = const Size(1280, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: CategoryTopicsScreen(slug: 'cau-lac-bo-giao-luu-ket-ban'),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Tiêu đề & mô tả
      expect(find.text('Câu lạc bộ - Giao lưu - Kết bạn'), findsWidgets);
      expect(find.text('Dành cho thành viên giao lưu, kết bạn, buôn chuyện'), findsOneWidget);
      expect(find.text('Đánh dấu đã xem tất cả • 1703 chủ đề'), findsWidgets);

      // 2. Không có khung nội quy
      expect(find.text('Nội quy chuyên mục'), findsNothing);

      // 3. 7 bài ghim
      expect(find.text('Talkshow hướng nghiệp tháng 7/2026'), findsOneWidget);
      expect(find.text('LỊCH SINH HOẠT HÀNG THÁNG CỦA CLB LÝ SỐ HÀ NỘI.'), findsOneWidget);
      expect(find.textContaining('19180'), findsOneWidget);
      expect(find.text('Tư vấn có ủng hộ phí để duy trì diễn đàn'), findsOneWidget);
      expect(find.text('Tuyển Điều hành viên khu vực phía Nam'), findsOneWidget);
      expect(find.textContaining('28280'), findsOneWidget);
      expect(find.text('Hướng dẫn sử dụng diễn đàn'), findsOneWidget);
      expect(find.text('Bảng giá dịch vụ tư vấn tại Lý số Hội quán'), findsOneWidget);
      expect(find.text('Nội quy diễn đàn Lý số Việt Nam'), findsOneWidget);

      // 4. 2 bài chủ đề
      expect(find.text('Nội quy - Danh sách thành viên CLB'), findsOneWidget);
      expect(find.textContaining('10:47, 12/07/10'), findsOneWidget);
      expect(find.textContaining('31117'), findsOneWidget);
      expect(find.textContaining('wwwbinh179'), findsOneWidget);

      expect(find.text('Em nhờ diễn đàn xíu ạ'), findsOneWidget);
      expect(find.textContaining('397'), findsOneWidget);
      expect(find.textContaining('Nhờ Admin'), findsWidgets);

      // 5. Trực tuyến & Khám phá thêm
      expect(find.textContaining('744 khách.'), findsOneWidget);
      expect(find.textContaining('True laurel'), findsOneWidget);
      expect(find.text('Giải mã giấc mơ'), findsOneWidget);
      expect(find.text('Chọn ngày tốt'), findsOneWidget);
      expect(find.text('Dự đoán tương lai'), findsOneWidget);

      // 6. Boxed 1024px & Dark Navy
      final cbFinder = find.descendant(
        of: find.byType(Center),
        matching: find.byType(ConstrainedBox),
      );
      final ConstrainedBox cb = tester.widget(cbFinder.first);
      expect(cb.constraints.maxWidth, equals(1024));

      final cardFinder = find.descendant(
        of: cbFinder,
        matching: find.byType(Container),
      );
      final Container card = tester.widget(cardFinder.first);
      expect(card.margin, equals(const EdgeInsets.only(top: 0, bottom: 24.0)));
      final BoxDecoration dec = card.decoration as BoxDecoration;
      expect(dec.color, equals(const Color(0xFF1E2640)));
    });
  });
}
