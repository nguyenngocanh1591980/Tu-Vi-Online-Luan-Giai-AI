import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/screens/forum/ucp_screen.dart';
import 'package:frontend/screens/forum/ucp_messages_screen.dart';
import 'package:frontend/screens/forum/ucp_groups_screen.dart';
import 'package:frontend/services/ucp_state_service.dart';
import 'package:frontend/widgets/main_layout.dart';

void main() {
  testWidgets('Xác nhận Boxed Layout 1024px, Theme Dark Navy và nội dung tab Tin nhắn & Nhóm',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    // 1. Kiểm tra màn hình UcpScreen bên trong MainLayout qua GoRouter
    final testRouter = GoRouter(
      initialLocation: '/forum/ucp',
      routes: [
        ShellRoute(
          builder: (context, state, shellChild) => MainLayout(child: shellChild),
          routes: [
            GoRoute(
              path: '/forum/ucp',
              builder: (context, state) => const UcpScreen(),
            ),
          ],
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: testRouter,
      ),
    );
    await tester.pumpAndSettle();

    // Xác nhận Scaffold background là #F0F2F5
    final scaffoldFinder = find.byType(Scaffold);
    expect(scaffoldFinder, findsOneWidget);
    final Scaffold scaffold = tester.widget(scaffoldFinder);
    expect(scaffold.backgroundColor, equals(const Color(0xFFF0F2F5)));

    // Xác nhận ConstrainedBox(maxWidth: 1024)
    final constrainedBoxFinder = find.byWidgetPredicate(
      (w) => w is ConstrainedBox && w.constraints.maxWidth == 1024,
    );
    expect(constrainedBoxFinder, findsWidgets);

    // Xác nhận Container tổng nền #1E2640 và bo góc đáy
    final mainCardFinder = find.descendant(
      of: constrainedBoxFinder,
      matching: find.byWidgetPredicate(
        (w) => w is Container && (w.decoration is BoxDecoration && (w.decoration as BoxDecoration).color == const Color(0xFF1E2640)),
      ),
    );
    expect(mainCardFinder, findsWidgets);

    // --- 2. CLICK VÀO TAB "TIN NHẮN" ---
    final messagesTabFinder = find.text('Tin nhắn');
    expect(messagesTabFinder, findsOneWidget);
    await tester.tap(messagesTabFinder);
    await tester.pumpAndSettle();

    // Xác nhận đã chuyển sang tab Tin nhắn
    expect(UcpStateService.navigationState.value.tab, equals('Tin nhắn'));

    // Xác nhận UcpMessagesContent được hiển thị
    expect(find.byType(UcpMessagesContent), findsOneWidget);

    // Xác nhận Sidebar của Tin nhắn
    expect(find.text('Soạn tin nhắn'), findsWidgets);
    expect(find.text('Tin nhắn nháp'), findsWidgets);
    expect(find.text('Hộp thư nhận'), findsOneWidget);
    expect(find.text('Hộp thư chuyển đi'), findsOneWidget);
    expect(find.text('Hộp thư đã gửi'), findsOneWidget);
    expect(find.text('Bộ lọc và thư mục tin'), findsOneWidget);
    expect(find.text('Bạn thân'), findsOneWidget);
    expect(find.text('Phân loại tin nhắn'), findsOneWidget);

    // Chuyển sang "Hộp thư nhận"
    await tester.tap(find.text('Hộp thư nhận'));
    await tester.pumpAndSettle();

    // Xác nhận Dung lượng hộp thư (27 trong số 500 tin nhắn) và Progress Indicator
    expect(
      find.text('Thư mục 5% đã đầy (27 trong số 500 tin nhắn được lưu trữ)'),
      findsOneWidget,
    );
    final progressFinder = find.descendant(
      of: find.byType(UcpMessagesContent),
      matching: find.byType(LinearProgressIndicator),
    );
    expect(progressFinder, findsOneWidget);
    final LinearProgressIndicator progress = tester.widget(progressFinder);
    expect(progress.value, closeTo(27 / 500, 0.001));

    // Xác nhận tiêu đề và người gửi trong danh sách 27 tin nhắn chuẩn tiền tố TL:
    expect(find.text('TL: trả lời tổng kết'), findsWidgets);
    expect(find.text('TL: Xem lá số cho em'), findsWidgets);
    expect(
      find.byWidgetPredicate(
        (w) => w is RichText && w.text.toPlainText().contains('hoangnguyenhuu'),
      ),
      findsWidgets,
    );

    // Xác nhận việc sử dụng Wrap chống tràn viền (Overflow) ở đáy bảng tin nhắn
    final wrapFinder = find.descendant(
      of: find.byType(UcpMessagesContent),
      matching: find.byType(Wrap),
    );
    expect(wrapFinder, findsWidgets);

    // Xác nhận Khối Khám phá thêm của Tab Tin nhắn (Hình 5)
    expect(find.text('Trang trí nhà và nội thất'), findsOneWidget);
    expect(find.text('Lịch sử'), findsOneWidget);
    expect(find.text('Đạo Phật'), findsOneWidget);

    // --- 3. CLICK VÀO TAB "NHÓM" ---
    final groupsTabFinder = find.text('Nhóm');
    expect(groupsTabFinder, findsOneWidget);
    await tester.tap(groupsTabFinder);
    await tester.pumpAndSettle();

    // Xác nhận đã chuyển sang tab Nhóm
    expect(UcpStateService.navigationState.value.tab, equals('Nhóm'));

    // Xác nhận UcpGroupsContent được hiển thị
    expect(find.byType(UcpGroupsContent), findsOneWidget);

    // Xác nhận Sidebar của Nhóm (Hình 2)
    expect(find.text('Sửa tư cách thành viên'), findsWidgets);
    expect(find.text('Quản lí nhóm'), findsOneWidget);

    // Xác nhận đoạn văn giới thiệu nhóm (bảo toàn 100%)
    expect(
      find.textContaining('Những nhóm được thêm do ban quản trị diễn đàn liên lạc'),
      findsOneWidget,
    );

    // Xác nhận Bảng 1: Tư cách thành viên của nhóm
    expect(find.text('Tư cách thành viên của nhóm'), findsOneWidget);
    expect(find.textContaining('Đây là một nhóm mặc định'), findsOneWidget);
    expect(find.text('Thành viên'), findsWidgets);

    // Xác nhận Bảng 2: Không phải là thành viên của nhóm
    expect(find.text('Không phải là thành viên của nhóm'), findsOneWidget);
    expect(find.text('BQL Trung Châu'), findsOneWidget);
    expect(find.text('Ban tư vấn'), findsOneWidget);
    expect(find.text('Hội viên Kim cương'), findsOneWidget);
    expect(find.text('Quản trị'), findsOneWidget);
    expect(find.text('Điều hành'), findsOneWidget);

    // Xác nhận các Radio selection xuất hiện cho các nhóm
    expect(find.byType(Radio<String>), findsWidgets);

    // Xác nhận thanh thao tác nhóm
    expect(find.text('Xem thông tin của nhóm'), findsOneWidget);

    // Xác nhận Khối Khám phá thêm của Tab Nhóm (Hình 5)
    expect(find.text('Lá số Tứ trụ'), findsOneWidget);
    expect(find.text('Xem Phong Thủy'), findsOneWidget);
    expect(find.text('Hướng dẫn và thông tin du lịch'), findsOneWidget);

    // Kiểm tra chuyển sang menu "Quản lí nhóm" (Hình 2)
    final manageGroupMenuFinder = find.text('Quản lí nhóm');
    expect(manageGroupMenuFinder, findsOneWidget);
    await tester.tap(manageGroupMenuFinder);
    await tester.pumpAndSettle();

    // Xác nhận thông báo đặc trưng của Quản lí nhóm
    expect(
      find.text('Bạn không phải là người điều hành của bất kì nhóm nào.'),
      findsOneWidget,
    );
  });

  testWidgets('Kiểm tra màn hình độc lập UcpMessagesScreen và UcpGroupsScreen',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    // Màn hình độc lập UcpMessagesScreen
    await tester.pumpWidget(
      const MaterialApp(
        home: UcpMessagesScreen(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(UcpMessagesContent), findsOneWidget);

    // Màn hình độc lập UcpGroupsScreen
    await tester.pumpWidget(
      const MaterialApp(
        home: UcpGroupsScreen(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(UcpGroupsContent), findsOneWidget);
  });
}
