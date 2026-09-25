import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/screens/forum/ucp_messages_screen.dart';
import 'package:frontend/screens/forum/member_profile_screen.dart';

void main() {
  testWidgets('Xác nhận tiêu đề Soạn tin nhắn, 8 nhóm trong khối Thêm nhóm và đồng bộ Footer breadcrumb',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      const MaterialApp(
        home: UcpMessagesScreen(),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Kiểm tra Tiêu đề Header
    expect(find.byIcon(Icons.email), findsWidgets);
    expect(find.text('Soạn tin nhắn'), findsWidgets);

    // Xác nhận tiêu đề Header nằm cạnh icon phong bì màu vàng
    final headerTitleFinder = find.byWidgetPredicate((widget) {
      if (widget is Text && widget.data == 'Soạn tin nhắn') {
        return widget.style?.color == const Color(0xFFFFD700) &&
            widget.style?.fontSize == 18 &&
            widget.style?.fontWeight == FontWeight.bold;
      }
      return false;
    });
    expect(headerTitleFinder, findsOneWidget);

    // 2. Kiểm tra khối "Thêm nhóm:" và 8 nhóm
    expect(find.text('Thêm nhóm:'), findsOneWidget);

    final expectedGroups = [
      'Ban tư vấn',
      'Hội viên Kim cương',
      'Quản lý',
      'Điều hành',
      'Cặp đôi lý số',
      'Tư vấn phong Thủy',
      'Tư vấn Tử vi',
      'Tư vấn Tứ Trụ',
    ];

    final listViewFinder = find.ancestor(
      of: find.text('Ban tư vấn'),
      matching: find.byType(ListView),
    );
    expect(listViewFinder, findsOneWidget);

    final ListView listView = tester.widget(listViewFinder);
    final childrenDelegate = listView.childrenDelegate as SliverChildListDelegate;
    expect(childrenDelegate.children.length, equals(8));

    for (int i = 0; i < expectedGroups.length; i++) {
      final child = childrenDelegate.children[i] as Padding;
      final textWidget = child.child as Text;
      expect(textWidget.data, equals(expectedGroups[i]));
      expect(textWidget.style?.color, equals(Colors.white));
      expect(textWidget.style?.fontSize, equals(13));
    }

    // Kiểm tra container chứa danh sách nhóm có nền #131A30 và viền #2E3B5F
    final listContainerFinder = find.byWidgetPredicate((widget) {
      if (widget is Container && widget.decoration is BoxDecoration) {
        final box = widget.decoration as BoxDecoration;
        return box.color == const Color(0xFF131A30) &&
            box.border?.top.color == const Color(0xFF2E3B5F);
      }
      return false;
    });
    expect(listContainerFinder, findsWidgets);

    // 3. Kiểm tra Footer Breadcrumb hiển thị đầy đủ
    // Trang chủ < Diễn đàn < Thiết lập cá nhân < Tin nhắn < Soạn tin nhắn
    expect(find.text('Trang chủ'), findsWidgets);
    expect(find.text('Diễn đàn'), findsWidgets);
    expect(find.text('Thiết lập cá nhân'), findsWidgets);
    expect(find.text('Tin nhắn'), findsWidgets);
  });

  testWidgets(
      'Kiểm tra chuyển sang "Tin nhắn nháp" (Hình 2) và "Hộp thư nhận" (Hình 5) liền mạch Dark Navy 1024px',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      const MaterialApp(
        home: UcpMessagesScreen(),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Kiểm tra Bảng mã màu loại tin nhắn (5 mục) trong sidebar
    expect(find.text('Phân loại tin nhắn'), findsOneWidget);
    expect(find.text('Tin nhắn đã được đánh dấu'), findsOneWidget);
    expect(find.text('Tin nhắn quan trọng'), findsOneWidget);
    expect(find.text('Tin nhắn chưa đọc'), findsOneWidget);
    expect(find.text('Tin nhắn từ bạn bè'), findsOneWidget);
    expect(find.text('Tin nhắn đã đọc'), findsOneWidget);

    // 2. Chuyển sang "Tin nhắn nháp"
    final draftsTabFinder = find.text('Tin nhắn nháp');
    expect(draftsTabFinder, findsWidgets);
    await tester.tap(draftsTabFinder.first);
    await tester.pumpAndSettle();

    // Xác nhận nội dung "Tin nhắn nháp" theo đúng Hình 2
    expect(find.text('Bản nháp đã lưu'), findsOneWidget);
    expect(
      find.text('Với bảng điều khiển này, bạn có thể xem, sửa và xóa những bản nháp đã lưu của mình.'),
      findsOneWidget,
    );
    expect(find.text('Không có bản nháp nào được lưu.'), findsOneWidget);

    // 3. Chuyển sang "Hộp thư nhận"
    final inboxTabFinder = find.text('Hộp thư nhận');
    expect(inboxTabFinder, findsOneWidget);
    await tester.tap(inboxTabFinder);
    await tester.pumpAndSettle();

    // Xác nhận nội dung "Hộp thư nhận" theo đúng Hình 5
    expect(find.text('Xem tin nhắn: Hộp tin nhận'), findsOneWidget);
    expect(
      find.text('Thư mục 5% đã đầy (27 trong số 500 tin nhắn được lưu trữ)'),
      findsOneWidget,
    );

    // Kiểm tra LinearProgressIndicator value 27 / 500
    final progressFinder = find.byType(LinearProgressIndicator);
    expect(progressFinder, findsOneWidget);
    final LinearProgressIndicator indicator = tester.widget(progressFinder);
    expect(indicator.value, closeTo(27 / 500, 0.001));

    // Kiểm tra nút "Tin nhắn mới", header cột "Chọn", nút "Chuyển"
    expect(find.text('Tin nhắn mới'), findsOneWidget);
    expect(find.text('Chọn'), findsOneWidget);
    expect(find.text('Chuyển'), findsWidgets);
    expect(find.text('Đánh dấu đã đọc tất cả • Có 27 tin nhắn'), findsOneWidget);

    // Kiểm tra các tin nhắn đặc trưng của hoangnguyenhuu và phamquynh
    expect(find.text('TL: trả lời tổng kết'), findsWidgets);
    expect(find.text('TL: Xem lá số cho em'), findsWidgets);
    expect(find.text('TL: Toàn bộ gửi qua email của bạn'), findsOneWidget);
    expect(find.text('TL: A vẫn mãi là cánh chim độc cô hành mà thôi!'), findsOneWidget);
    expect(find.text('chào anh'), findsWidgets);

    // Kiểm tra badge 37 trên Hộp thư nhận
    expect(find.text('37'), findsOneWidget);

    // 4. Bấm nút "Tin nhắn mới" chuyển về "Soạn tin nhắn"
    await tester.tap(find.text('Tin nhắn mới'));
    await tester.pumpAndSettle();
    expect(find.text('Thêm những người nhận:'), findsOneWidget);
    expect(find.text('Thêm nhóm:'), findsOneWidget);
  });

  testWidgets(
      'Kiểm tra "Hộp thư chuyển đi" (Hình 2) và "Hộp thư đã gửi" (Hình 5) phẳng phiu Dark Navy 1024px',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      const MaterialApp(
        home: UcpMessagesScreen(),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Chuyển sang "Hộp thư chuyển đi" (Hình 2)
    final outboxFinder = find.text('Hộp thư chuyển đi');
    expect(outboxFinder, findsOneWidget);
    await tester.tap(outboxFinder);
    await tester.pumpAndSettle();

    // Xác nhận tiêu đề và thông tin dung lượng
    expect(find.text('Xem tin nhắn: Hộp tin chuyển đi'), findsOneWidget);
    expect(
      find.text('Thư mục 0% đã đầy (0 trong số 500 tin nhắn được lưu trữ)'),
      findsOneWidget,
    );

    // Xác nhận LinearProgressIndicator 0%
    final progressFinderOutbox = find.byType(LinearProgressIndicator);
    expect(progressFinderOutbox, findsOneWidget);
    final LinearProgressIndicator indicatorOutbox = tester.widget(progressFinderOutbox);
    expect(indicatorOutbox.value, equals(0.0));

    // Xác nhận badge 0 và dòng chữ in đậm "Không có tin nhắn nào"
    expect(find.text('0'), findsOneWidget);
    expect(find.text('Không có tin nhắn nào'), findsOneWidget);
    expect(find.text('Tin nhắn mới'), findsOneWidget);

    // 2. Chuyển sang "Hộp thư đã gửi" (Hình 5)
    final sentFinder = find.text('Hộp thư đã gửi');
    expect(sentFinder, findsOneWidget);
    await tester.tap(sentFinder);
    await tester.pumpAndSettle();

    // Xác nhận tiêu đề và thông tin dung lượng 2%
    expect(find.text('Xem tin nhắn: Hộp tin đã gửi'), findsOneWidget);
    expect(
      find.text('Thư mục 2% đã đầy (12 trong số 500 tin nhắn được lưu trữ)'),
      findsOneWidget,
    );

    // Xác nhận LinearProgressIndicator 12/500
    final progressFinderSent = find.byType(LinearProgressIndicator);
    expect(progressFinderSent, findsOneWidget);
    final LinearProgressIndicator indicatorSent = tester.widget(progressFinderSent);
    expect(indicatorSent.value, closeTo(12 / 500, 0.001));

    // Xác nhận badge 12 và thanh điều hướng trên
    expect(find.text('12'), findsOneWidget);
    expect(
      find.text('Đánh dấu đã đọc tất cả • Có 12 tin nhắn • Trang 1 trên 1'),
      findsOneWidget,
    );

    // Xác nhận tiêu đề cột bảng
    expect(find.text('Tin nhắn'), findsWidgets);
    expect(find.text('Chọn'), findsOneWidget);

    // Xác nhận toàn bộ 12 tiêu đề tin nhắn gốc (Hình 5)
    expect(find.text('trả lời tổng kết'), findsOneWidget);
    expect(find.text('Trả lời'), findsOneWidget);
    expect(find.text('Xem lá số cho em'), findsOneWidget);
    expect(find.text('Anh gửi cho em rùi mà'), findsOneWidget);
    expect(find.text('em cần hỏi chuyện gì ?'), findsOneWidget);
    expect(find.text('Thế không sợ chồng ghen hả?'), findsOneWidget);
    expect(find.text('A vẫn mãi là cánh chim độc cô hành mà thôi!?'), findsOneWidget);
    expect(find.text('nhìn nick không nhận ra anh hả'), findsOneWidget);
    expect(find.text('Toàn bộ gửi qua email của bạn'), findsOneWidget);
    expect(find.text('Bạn có đủ bộ bản phủ đó không'), findsOneWidget);
    expect(find.text('xin chao cao nhan'), findsOneWidget);
    expect(find.text('sao khong tra loi vay'), findsOneWidget);

    // Xác nhận người nhận hiển thị đầy đủ
    expect(find.text('binh131091'), findsWidgets);
    expect(find.text('phamquynh'), findsWidgets);
    expect(find.text('hoangnguyenhuu'), findsWidgets);

    // Xác nhận cụm công cụ đáy
    expect(find.text('Xuất thư mục đang xem:'), findsOneWidget);
    expect(find.text('Định dạng CSV'), findsOneWidget);
    expect(find.text('Đánh dấu/Bỏ đánh dấu quan trọng'), findsOneWidget);
    expect(find.text('Chuyển'), findsWidgets);
    expect(find.text('Chọn tất cả'), findsOneWidget);
    expect(find.text('Bỏ chọn tất cả'), findsOneWidget);
    expect(find.text('Có 12 tin nhắn • Trang 1 trên 1'), findsOneWidget);

    // 3. Thao tác nút Chọn tất cả và Bỏ chọn tất cả
    await tester.tap(find.text('Chọn tất cả'), warnIfMissed: false);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Bỏ chọn tất cả'), warnIfMissed: false);
    await tester.pumpAndSettle();

    // 4. Bấm "Tin nhắn mới" từ Hộp thư đã gửi quay về màn hình soạn tin
    await tester.tap(find.text('Tin nhắn mới'));
    await tester.pumpAndSettle();
    expect(find.text('Thêm những người nhận:'), findsOneWidget);
  });

  testWidgets(
      'Kiểm tra màn hình "Bộ lọc và thư mục tin" (Hình 2) hiển thị đủ 3 khối: Bộ lọc tự động, Tùy chọn thư mục, Cấu hình quá dung lượng',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      const MaterialApp(
        home: UcpMessagesScreen(),
      ),
    );
    await tester.pumpAndSettle();

    // Chuyển sang "Bộ lọc và thư mục tin"
    final rulesFinder = find.text('Bộ lọc và thư mục tin');
    expect(rulesFinder, findsOneWidget);
    await tester.tap(rulesFinder);
    await tester.pumpAndSettle();

    // 1. Tiêu đề
    expect(find.text('Bộ lọc và thư mục tin'), findsWidgets);

    // 2. Khối 1: Bộ lọc tự động
    expect(find.text('NHỮNG BỘ LỌC TIN NHẮN TỰ ĐỘNG ĐÃ CÓ'), findsOneWidget);
    expect(find.text('1. Không có quy tắc nào được xác định.'), findsOneWidget);
    expect(find.text('THÊM QUY TẮC MỚI'), findsOneWidget);
    expect(find.text('Nếu:'), findsOneWidget);
    expect(find.text('Bước kế tiếp'), findsOneWidget);

    // 3. Khối 2: Tùy chọn thư mục
    expect(find.text('TÙY CHỌN THƯ MỤC'), findsOneWidget);
    expect(find.text('Thêm thư mục:'), findsOneWidget);
    expect(find.text('Thêm vào'), findsWidgets);

    // 4. Khối 3: Cấu hình quá dung lượng
    expect(
      find.text('Nếu thư mục này vượt quá dung lượng cho phép:'),
      findsOneWidget,
    );
    expect(find.text('Xóa những tin nhắn cũ'), findsWidgets);
    expect(find.text('Di chuyển đến thư mục:'), findsOneWidget);
    expect(
      find.text('Không nhận thêm những tin nhắn mới (Những tin nhắn mới sẽ quay lại khi nào dung lượng đủ cho phép)'),
      findsOneWidget,
    );

    // 5. Khối 4: Thiết lập mặc định
    expect(find.text('Thiết lập mặc định:'), findsOneWidget);
    expect(find.text('Thay đổi'), findsOneWidget);
  });

  testWidgets(
      'Kiểm tra màn hình Xem thông tin cá nhân về Gacon1980 (Hình 5) chuẩn Theme Dark Navy 1024px và 100% nội dung gốc',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      const MaterialApp(
        home: MemberProfileScreen(username: 'Gacon1980'),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Tiêu đề Card thông tin
    expect(find.text('Đang xem thông tin cá nhân về Gacon1980'), findsOneWidget);

    // 2. Tên đăng nhập và nút [ Sửa hồ sơ ]
    expect(find.text('Tên đăng nhập: '), findsOneWidget);
    expect(find.text('Gacon1980'), findsWidgets);
    expect(find.text(' [ Sửa hồ sơ ]'), findsOneWidget);

    // 3. Xếp hạng và 2 sao vàng
    expect(find.text('Xếp hạng: '), findsOneWidget);
    expect(find.text('Chính thức'), findsOneWidget);
    expect(find.byIcon(Icons.star), findsNWidgets(2));

    // 4. Tuổi
    expect(find.text('Tuổi: '), findsOneWidget);
    expect(find.text('45'), findsOneWidget);

    // 5. Nhóm và nút Chuyển
    expect(find.text('Nhóm: '), findsOneWidget);
    expect(find.text('Thành viên'), findsWidgets);
    expect(find.text('Chuyển'), findsOneWidget);

    // 6. Đến từ
    expect(find.text('Đến từ: '), findsOneWidget);
    expect(
      find.text('Linh quy thiên tuế thần khí vượng.Báo ngọc vạn niên quý minh trường.'),
      findsOneWidget,
    );

    // 7. Cột Liên hệ
    expect(find.text('LIÊN HỆ GACON1980'), findsOneWidget);
    expect(find.text('Địa chỉ email: '), findsOneWidget);
    expect(find.text('Gửi email cho'), findsOneWidget);
    expect(find.text('Tin nhắn: '), findsOneWidget);
    expect(find.text('Gửi tin nhắn'), findsOneWidget);

    // 8. Cột Thống kê thành viên
    expect(find.text('THỐNG KÊ THÀNH VIÊN'), findsOneWidget);
    expect(find.text('Tham gia: '), findsOneWidget);
    expect(find.text('12:03, 04/07/12'), findsOneWidget);
    expect(find.text('Lần hoạt động trước: '), findsOneWidget);
    expect(find.text('-'), findsOneWidget);
    expect(find.text('Số bài viết: '), findsOneWidget);
    expect(find.text('35'), findsOneWidget);
    expect(find.text('Tìm tất cả bài viết của thành viên này'), findsOneWidget);
    expect(find.text('(0.00% trong tổng số bài viết / 0.01 bài viết/ngày)'), findsOneWidget);

    // 9. Khối Chữ ký cá nhân (2 câu thơ Hình 5)
    expect(find.text('CHỮ KÝ CÁ NHÂN'), findsOneWidget);
    expect(find.text('Ánh Dương văn võ ngàn năm tỏa'), findsOneWidget);
    expect(find.text('Phẩm giá thanh cao rạng núi sông'), findsOneWidget);

    // 10. Dropdown Chuyển đến
    expect(find.text('Chuyển đến'), findsOneWidget);
  });
}


