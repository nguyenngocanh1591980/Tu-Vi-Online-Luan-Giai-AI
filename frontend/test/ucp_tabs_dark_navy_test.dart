import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/screens/forum/ucp_screen.dart';
import 'package:frontend/screens/forum/ucp_personal_screen.dart';
import 'package:frontend/screens/forum/ucp_system_screen.dart';
import 'package:frontend/services/ucp_state_service.dart';
import 'package:frontend/widgets/breadcrumb_widget.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    UcpStateService.reset();
  });

  group('UCP Tab Cá nhân & Tab Hệ thống Tests', () {
    testWidgets('Xác nhận Boxed Layout 1024px, Theme Dark Navy và form Tab Cá nhân & Hệ thống',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1920, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      // 1. Khởi tạo UcpScreen
      await tester.pumpWidget(
        const MaterialApp(
          home: UcpScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Xác nhận Scaffold background là #F0F2F5
      final scaffoldFinder = find.byType(Scaffold);
      expect(scaffoldFinder, findsOneWidget);
      final Scaffold scaffold = tester.widget(scaffoldFinder);
      expect(scaffold.backgroundColor, equals(const Color(0xFFF0F2F5)));

      // Xác nhận Center > ConstrainedBox(maxWidth: 1024)
      final constrainedBoxFinder = find.descendant(
        of: find.byType(Center),
        matching: find.byType(ConstrainedBox),
      );
      expect(constrainedBoxFinder, findsWidgets);
      final ConstrainedBox cb = tester.widget(constrainedBoxFinder.first);
      expect(cb.constraints.maxWidth, equals(1024));

      // Xác nhận Container tổng có margin: EdgeInsets.only(top: 0, bottom: 24) và nền #1E2640
      final mainCardFinder = find.descendant(
        of: constrainedBoxFinder,
        matching: find.byType(Container),
      );
      final Container mainCard = tester.widget(mainCardFinder.first);
      expect(mainCard.margin, equals(const EdgeInsets.only(top: 0, bottom: 24.0)));
      final BoxDecoration cardDec = mainCard.decoration as BoxDecoration;
      expect(cardDec.color, equals(const Color(0xFF1E2640)));
      expect(cardDec.borderRadius, equals(const BorderRadius.vertical(bottom: Radius.circular(8))));

      // --- 2. CLICK VÀO TAB "CÁ NHÂN" (Hình 2 & 3) ---
      final personalTabFinder = find.text('Cá nhân');
      expect(personalTabFinder, findsOneWidget);
      await tester.tap(personalTabFinder);
      await tester.pumpAndSettle();

      // Xác nhận UcpStateService được cập nhật đúng subItem mặc định
      expect(UcpStateService.navigationState.value.tab, equals('Cá nhân'));
      expect(UcpStateService.navigationState.value.subItem, equals('Sửa thông tin cá nhân'));

      // Xác nhận UcpPersonalContent được hiển thị
      expect(find.byType(UcpPersonalContent), findsOneWidget);

      // Xác nhận Sidebar 5 mục chuẩn của Tab Cá nhân (Hình 2)
      expect(find.text('Sửa thông tin cá nhân'), findsWidgets);
      expect(find.text('Sửa hình đại diện'), findsOneWidget);
      expect(find.text('Sửa email, mật khẩu'), findsOneWidget);
      expect(find.text('Quản lý khóa "Ghi nhớ tôi"'), findsOneWidget);
      expect(find.text('Liên kết tài khoản ngoài'), findsOneWidget);

      // Xác nhận khối Bạn thân
      expect(find.text('Bạn thân'), findsOneWidget);
      expect(find.text('hoangnguyenhuu'), findsOneWidget);

      // Xác nhận Form "Sửa thông tin cá nhân" bảo toàn 100% dữ liệu gốc (Hình 2)
      expect(find.text('[ Xem hồ sơ ]'), findsOneWidget);
      expect(
        find.textContaining('Xin lưu ý rằng thông tin này có thể được xem cho các thành viên khác'),
        findsOneWidget,
      );
      expect(find.text('Họ và tên đầy đủ *:'), findsOneWidget);
      expect(find.text('Nguyễn Ngọc Ánh'), findsOneWidget);
      expect(find.text('Số điện thoại *:'), findsOneWidget);
      expect(find.text('0989517820'), findsOneWidget);
      expect(find.text('Nơi sinh *:'), findsOneWidget);
      expect(find.text('Giới tính *:'), findsOneWidget);
      expect(find.text('Nam'), findsOneWidget);
      expect(find.text('Nữ'), findsOneWidget);
      expect(find.text('Không'), findsOneWidget);
      expect(find.text('Giờ sinh *:'), findsOneWidget);
      expect(find.text('Ngày sinh *:'), findsOneWidget);
      expect(find.text('Sở thích:'), findsOneWidget);
      expect(find.text('Nghề nghiệp:'), findsOneWidget);
      expect(find.text('Website:'), findsOneWidget);
      expect(find.text('Đến từ:'), findsOneWidget);
      expect(find.text('Linh quy thiên tuệ thiện tri'), findsOneWidget);
      expect(find.text('Facebook:'), findsOneWidget);
      expect(find.text('Skype:'), findsOneWidget);
      expect(find.text('Twitter:'), findsOneWidget);
      expect(find.text('YouTube:'), findsOneWidget);

      // Xác nhận Khối Khám phá thêm của Tab Cá nhân (Hình 2)
      expect(find.text('Hóa học'), findsOneWidget);
      expect(find.text('Diễn đàn trực tuyến'), findsOneWidget);
      expect(find.text('Lá số Tứ trụ'), findsOneWidget);

      // Test click nút "Xác nhận" của form cá nhân
      final personalConfirmBtn = find.widgetWithText(ElevatedButton, 'Xác nhận');
      expect(personalConfirmBtn, findsOneWidget);
      await tester.ensureVisible(personalConfirmBtn);
      await tester.tap(personalConfirmBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Đã cập nhật thông tin cá nhân thành công.'), findsOneWidget);
      await tester.pump(const Duration(seconds: 4));

      // --- 2b. CHỌN MỤC "SỬA HÌNH ĐẠI DIỆN" (Hình 2) ---
      final avatarMenuFinder = find.text('Sửa hình đại diện');
      expect(avatarMenuFinder, findsOneWidget);
      await tester.tap(avatarMenuFinder);
      await tester.pumpAndSettle();

      // Xác nhận subItem đã chuyển sang 'Sửa hình đại diện'
      expect(UcpStateService.navigationState.value.subItem, equals('Sửa hình đại diện'));

      // Xác nhận cấu trúc Form Sửa hình đại diện (Hình 2)
      expect(find.text('Hình đại diện hiện tại:'), findsOneWidget);
      expect(
        find.textContaining('Kích thước tối đa; rộng: 145 pixels, cao: 290 pixels và dung lượng 98.00 KB.'),
        findsOneWidget,
      );
      expect(find.text('Xóa hình đại diện hiện tại'), findsOneWidget);
      expect(find.text('CHỌN HÌNH ĐẠI DIỆN'), findsOneWidget);
      expect(find.text('Loại hình đại diện:'), findsOneWidget);
      expect(find.text('Thư viện hình đại diện'), findsOneWidget);
      expect(
        find.textContaining('Bạn có thể chọn hình đại diện của bạn từ một tập có sẵn trên máy chủ'),
        findsOneWidget,
      );
      expect(find.text('Chủ đề hình đại diện:'), findsOneWidget);
      expect(find.text('Không có hình đại diện nào'), findsOneWidget);
      expect(find.text('Chuyển'), findsOneWidget);

      // Xác nhận lưới 4 ô placeholder avatar kèm Radio buttons
      expect(find.byType(Radio<int>), findsNWidgets(4));

      // Xác nhận khối Khám phá thêm đặc trưng của Sửa hình đại diện (Hình 2)
      expect(find.text('Xem Tử Vi'), findsOneWidget);
      expect(find.text('Lá số Tứ trụ'), findsOneWidget);
      expect(find.text('Tạo Diễn Đàn'), findsOneWidget);

      // Click nút "Xác nhận" của Form Sửa hình đại diện
      final avatarConfirmBtn = find.widgetWithText(ElevatedButton, 'Xác nhận');
      expect(avatarConfirmBtn, findsOneWidget);
      await tester.ensureVisible(avatarConfirmBtn);
      await tester.tap(avatarConfirmBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Đã lưu và cập nhật hình đại diện thành công.'), findsOneWidget);
      await tester.pump(const Duration(seconds: 4));

      // --- 2c. CHỌN MỤC "SỬA EMAIL, MẬT KHẨU" (Hình 5) ---
      final emailMenuFinder = find.text('Sửa email, mật khẩu');
      expect(emailMenuFinder, findsOneWidget);
      await tester.tap(emailMenuFinder);
      await tester.pumpAndSettle();

      // Xác nhận subItem đã chuyển sang 'Sửa email, mật khẩu'
      expect(UcpStateService.navigationState.value.subItem, equals('Sửa email, mật khẩu'));

      // Xác nhận cấu trúc Form Sửa email, mật khẩu (Hình 5)
      expect(find.text('Tên đăng nhập:'), findsOneWidget);
      expect(find.text('Gacon1980'), findsOneWidget);
      expect(
        find.textContaining('Tên thành viên không được phép ít hơn 3 ký tự và vượt quá 20 ký tự.'),
        findsOneWidget,
      );
      expect(find.text('Địa chỉ email:'), findsOneWidget);
      expect(find.text('phuongcuonganh@yahoo.com'), findsOneWidget);
      expect(find.text('Mật khẩu mới:'), findsOneWidget);
      expect(
        find.textContaining('Mật khẩu của bạn phải nhiều hơn 6 ký tự. Không đặt các mật khẩu quá dễ'),
        findsOneWidget,
      );
      expect(find.text('Xác nhận mật khẩu:'), findsOneWidget);
      expect(
        find.textContaining('Bạn chỉ cần xác nhận lại mật khẩu nếu như bạn muốn thay đổi mật khẩu hiện tại'),
        findsOneWidget,
      );
      expect(find.text('Mật khẩu hiện tại:'), findsOneWidget);
      expect(
        find.textContaining('Để đổi mật khẩu, hộp thư, tên đăng nhập bạn phải nhập mật khẩu hiện tại.'),
        findsOneWidget,
      );

      // Xác nhận khối Khám phá thêm đặc trưng của Sửa email, mật khẩu (Hình 5)
      expect(find.text('Lý số Việt Nam'), findsOneWidget);
      expect(find.text('Lịch Vạn Sự'), findsOneWidget);
      expect(find.text('Kiến thức Phong thủy'), findsOneWidget);

      // Click nút "Xác nhận" của Form Sửa email, mật khẩu
      final emailConfirmBtn = find.widgetWithText(ElevatedButton, 'Xác nhận');
      expect(emailConfirmBtn, findsOneWidget);
      await tester.ensureVisible(emailConfirmBtn);
      await tester.tap(emailConfirmBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Đã lưu và cập nhật mật khẩu thành công.'), findsOneWidget);
      await tester.pump(const Duration(seconds: 4));

      // --- 3. CLICK VÀO TAB "HỆ THỐNG" (Hình 4 & 5) ---
      final systemTabFinder = find.text('Hệ thống');
      expect(systemTabFinder, findsOneWidget);
      await tester.tap(systemTabFinder);
      await tester.pumpAndSettle();

      // Xác nhận UcpStateService đã chuyển sang tab Hệ thống với subItem 'Sửa thiết lập cá nhân'
      expect(UcpStateService.navigationState.value.tab, equals('Hệ thống'));
      expect(UcpStateService.navigationState.value.subItem, equals('Sửa thiết lập cá nhân'));

      // Xác nhận UcpSystemContent được hiển thị
      expect(find.byType(UcpSystemContent), findsOneWidget);

      // Xác nhận Sidebar 4 mục của Hệ thống (Hình 5)
      expect(find.text('Sửa thiết lập cá nhân'), findsWidgets);
      expect(find.text('Sửa thiết lập gửi bài viết'), findsWidgets);
      expect(find.text('Sửa thiết lập xem bài viết'), findsOneWidget);
      expect(find.text('Sửa tùy chọn thông báo'), findsOneWidget);

      // Xác nhận Form Radio Buttons & Dropdowns của Tab Hệ thống
      expect(find.text('Cho phép các thành viên khác liên hệ với tôi qua email:'), findsOneWidget);
      expect(find.text('Nhận những thông tin qua email từ quản trị viên:'), findsOneWidget);
      expect(find.text('Nhận tin nhắn từ các thành viên khác:'), findsOneWidget);
      expect(find.text('Luôn ẩn trạng thái trực tuyến của tôi:'), findsOneWidget);
      expect(find.text('Giao diện:'), findsOneWidget);
      expect(find.text('LySoVN'), findsOneWidget);
      expect(find.text('Múi giờ:'), findsOneWidget);
      expect(find.text('Định dạng ngày tháng của bạn:'), findsOneWidget);

      // Xác nhận Khối Khám phá thêm của Tab Hệ thống (Hình 5)
      expect(find.text('Toán học'), findsOneWidget);
      expect(find.text('Quản lý Kiến thức'), findsOneWidget);

      // Click thử nút Xác nhận Tab Hệ thống
      final systemConfirmBtn = find.widgetWithText(ElevatedButton, 'Xác nhận');
      expect(systemConfirmBtn, findsOneWidget);
      await tester.ensureVisible(systemConfirmBtn);
      await tester.tap(systemConfirmBtn);
      await tester.pumpAndSettle();
      expect(find.byType(UcpSuccessMessage), findsOneWidget);
      expect(find.text('Sở thích cá nhân của bạn đã được cập nhật thành công.'), findsOneWidget);
    });

    testWidgets('Xác nhận Breadcrumb hiển thị chính xác "Sửa thiết lập gửi bài viết" khi vào /forum/ucp/system',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final testRouter = GoRouter(
        initialLocation: '/forum/ucp/system',
        routes: [
          GoRoute(
            path: '/forum/ucp/system',
            builder: (context, state) => const Scaffold(
              body: Column(
                children: [
                  BreadcrumbWidget(),
                  Expanded(child: UcpSystemScreen()),
                ],
              ),
            ),
          ),
          GoRoute(
            path: '/forum',
            builder: (context, state) => const Scaffold(body: Text('Forum')),
          ),
          GoRoute(
            path: '/forum/ucp',
            builder: (context, state) => const Scaffold(body: Text('UcpScreen')),
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: testRouter,
        ),
      );
      await tester.pumpAndSettle();

      // Kiểm tra chuỗi Breadcrumb theo Hình 5:
      // Trang chủ < Diễn đàn < Thiết lập cá nhân < Hệ thống < Sửa thiết lập cá nhân
      final breadcrumbFinder = find.byType(BreadcrumbWidget);
      expect(find.descendant(of: breadcrumbFinder, matching: find.text('Trang chủ')), findsOneWidget);
      expect(find.descendant(of: breadcrumbFinder, matching: find.text('Diễn đàn')), findsOneWidget);
      expect(find.descendant(of: breadcrumbFinder, matching: find.text('Thiết lập cá nhân')), findsOneWidget);
      expect(find.descendant(of: breadcrumbFinder, matching: find.text('Hệ thống')), findsOneWidget);
      expect(find.descendant(of: breadcrumbFinder, matching: find.text('Sửa thiết lập cá nhân')), findsOneWidget);
    });
  });
}
