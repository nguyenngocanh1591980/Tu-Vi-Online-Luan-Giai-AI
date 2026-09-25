import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/screens/forum/ucp_screen.dart';
import 'package:frontend/screens/forum/ucp_friends_screen.dart';
import 'package:frontend/screens/forum/member_search_dialog.dart';
import 'package:frontend/services/ucp_state_service.dart';

void main() {
  testWidgets('Xác nhận Boxed Layout 1024px, Theme Dark Navy và nội dung tab Bạn Bè (Bạn thân & Kẻ thù)',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    // 1. Kiểm tra màn hình UcpScreen
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

    // --- 2. CLICK VÀO TAB "BẠN BÈ" ---
    final friendsTabFinder = find.text('Bạn bè');
    expect(friendsTabFinder, findsOneWidget);
    await tester.tap(friendsTabFinder);
    await tester.pumpAndSettle();

    // Xác nhận đã chuyển sang tab Bạn bè
    expect(UcpStateService.navigationState.value.tab, equals('Bạn bè'));

    // Xác nhận UcpFriendsContent được hiển thị
    expect(find.byType(UcpFriendsContent), findsOneWidget);

    // Xác nhận Sidebar của Bạn bè
    expect(find.text('Quản lí bạn thân'), findsWidgets);
    expect(find.text('Quản lí kẻ thù'), findsOneWidget);
    expect(find.text('Bạn thân'), findsOneWidget);

    // Xác nhận đoạn văn giới thiệu Quản lí bạn thân (Hình 2)
    expect(
      find.textContaining('Bạn thân là những thành viên đã được bạn thiết lập mặc định'),
      findsOneWidget,
    );

    // Xác nhận ListBox hiển thị bạn thân hiện tại
    expect(find.text('hoangnguyenhuu'), findsWidgets);
    expect(find.text('phamquynh'), findsWidgets);

    // Xác nhận Form Thêm bạn thân mới & Link "Tìm một thành viên"
    expect(find.text('Thêm bạn thân mới:'), findsOneWidget);
    expect(find.text('Tìm một thành viên'), findsOneWidget);
    expect(find.text('Xác nhận'), findsOneWidget);

    // --- 3. CHUYỂN SANG MỤC "QUẢN LÍ KẺ THÙ" (Hình 5) ---
    final enemyMenuFinder = find.text('Quản lí kẻ thù');
    await tester.tap(enemyMenuFinder);
    await tester.pumpAndSettle();

    // Xác nhận đoạn văn giới thiệu Quản lí kẻ thù (Hình 5)
    expect(
      find.textContaining('Kẻ thù là những thành viên đã được bạn thiết lập mặc định không quan hệ'),
      findsOneWidget,
    );

    // Xác nhận câu thông báo "Không có kẻ thù nào được xác định"
    expect(find.text('Không có kẻ thù nào được xác định'), findsOneWidget);

    // Xác nhận Form Thêm kẻ thù mới
    expect(find.text('Thêm kẻ thù mới:'), findsOneWidget);
    expect(find.text('Tìm một thành viên'), findsOneWidget);

    // --- 4. BẤM VÀO LINK "TÌM MỘT THÀNH VIÊN" MỞ POPUP/DIALOG (Hình 4) ---
    final searchLinkFinder = find.text('Tìm một thành viên');
    await tester.tap(searchLinkFinder);
    await tester.pumpAndSettle();

    // Xác nhận MemberSearchContent xuất hiện trong Dialog
    expect(find.byType(MemberSearchContent), findsOneWidget);

    // Xác nhận văn bản hướng dẫn nguyên văn từ Hình 4
    expect(
      find.textContaining('Công cụ này sẽ giúp bạn tìm kiếm những thành viên xác định trong hệ thống'),
      findsOneWidget,
    );

    // Xác nhận Form tìm kiếm
    expect(find.text('Tên đăng nhập:'), findsOneWidget);
    expect(find.text('Tham gia:'), findsOneWidget);
    expect(find.text('Nhóm:'), findsOneWidget);
    expect(find.text('Bài viết:'), findsOneWidget);
    expect(find.text('Sắp xếp theo:'), findsOneWidget);
    expect(find.text('Tìm kiếm'), findsOneWidget);

    // Xác nhận Bộ lọc chữ cái & Số lượng thành viên
    expect(find.text('Tất cả'), findsOneWidget);
    expect(find.text('25999 thành viên'), findsOneWidget);

    // Xác nhận Bảng thành viên mẫu từ Hình 4
    expect(find.text('Admin'), findsOneWidget);
    expect(find.text('nncuong'), findsOneWidget);
    expect(find.text('phuclongusdt'), findsOneWidget);
    expect(find.text('phanthithao'), findsOneWidget);
    expect(find.text('tarvin'), findsOneWidget);
    expect(find.text('http://www.hungloc.net'), findsOneWidget);

    // Xác nhận Badges
    expect(find.text('QUẢN LÝ'), findsWidgets);
    expect(find.text('SÁNG LẬP'), findsOneWidget);
    expect(find.text('HỘI VIÊN'), findsOneWidget);

    // Xác nhận cụm thao tác đáy
    expect(find.text('Chọn đánh dấu'), findsOneWidget);
    expect(find.text('Chọn tất cả'), findsOneWidget);
    expect(find.text('Bỏ chọn tất cả'), findsOneWidget);

    // Click [ Chọn ] cho thành viên Admin
    final chooseFinder = find.text('[ Chọn ]');
    expect(chooseFinder, findsWidgets);
    await tester.tap(chooseFinder.first);
    await tester.pumpAndSettle();

    // Xác nhận Dialog đóng lại và tên Admin đã được điền vào TextField
    expect(find.byType(MemberSearchContent), findsNothing);
    expect(find.textContaining('Admin'), findsOneWidget);
  });

  testWidgets('Kiểm tra màn hình độc lập UcpFriendsScreen và MemberSearchScreen',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    // Màn hình độc lập UcpFriendsScreen
    await tester.pumpWidget(
      const MaterialApp(
        home: UcpFriendsScreen(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(UcpFriendsContent), findsOneWidget);

    // Màn hình độc lập MemberSearchScreen
    await tester.pumpWidget(
      const MaterialApp(
        home: MemberSearchScreen(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(MemberSearchContent), findsOneWidget);
  });
}
