import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/screens/forum/members_screen.dart';
import 'package:frontend/screens/forum/about_us_screen.dart';
import 'package:frontend/screens/forum/recent_posts_screen.dart';
import 'package:frontend/widgets/breadcrumb_widget.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets('MembersScreen bọc trong Boxed Layout 1024px và Theme Dark Navy', (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(
        home: MembersScreen(),
      ),
    );
    await tester.pumpAndSettle();

    // Xác nhận tiêu đề Thành viên
    expect(find.text('Thành viên'), findsWidgets);

    // Xác nhận bộ lọc chữ cái và phân trang
    expect(find.text('Tìm một thành viên'), findsOneWidget);
    expect(find.text('206024 thành viên'), findsNWidgets(2)); // Cả trên và dưới
    expect(find.text('8241'), findsWidgets);

    // Xác nhận một số thành viên tiêu biểu từ Hình 2
    expect(find.text('Admin'), findsOneWidget);
    expect(find.text('nncuong'), findsOneWidget);
    expect(find.text('phudongsoft'), findsOneWidget);
    expect(find.text('phamthaihoa'), findsOneWidget);
    expect(find.text('locvtn'), findsOneWidget);
    expect(find.text('http://www.hungloc.net'), findsOneWidget);
    expect(find.text('am_duongH'), findsOneWidget);

    // Xác nhận các huy hiệu xếp hạng
    expect(find.text('QUẢN LÝ'), findsWidgets);
    expect(find.text('SÁNG LẬP'), findsOneWidget);
    expect(find.text('HỘI VIÊN'), findsOneWidget);

    // Xác nhận ConstrainedBox maxWidth 1024
    final constrainedBoxes = tester.widgetList<ConstrainedBox>(find.byType(ConstrainedBox));
    final box1024 = constrainedBoxes.any((box) => box.constraints.maxWidth == 1024);
    expect(box1024, isTrue);
  });

  testWidgets('AboutUsScreen bảo toàn 5 nhóm và Dark Navy 1024px', (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(
        home: AboutUsScreen(),
      ),
    );
    await tester.pumpAndSettle();

    // Tiêu đề
    expect(find.text('Chúng tôi'), findsWidgets);

    // 5 nhóm phân cấp từ Hình 3
    expect(find.text('Quản trị viên'), findsWidgets);
    expect(find.text('Siêu quản lý'), findsOneWidget);
    expect(find.text('Quản lý'), findsWidgets);
    expect(find.text('Điều hành'), findsWidgets);
    expect(find.text('Ban tư vấn'), findsWidgets);

    // Thông báo nhóm Siêu quản lý rỗng
    expect(
      find.text('Không tìm thấy thành viên nào thoả điều kiện tìm kiếm này.'),
      findsOneWidget,
    );

    // Thành viên ban tư vấn tiêu biểu
    expect(find.text('Kim Hải Đông'), findsOneWidget);
    expect(find.text('Lão Nông'), findsOneWidget);
    expect(find.text('TRƯỜNG GIANG'), findsOneWidget);
    expect(find.text('Điều hành 2'), findsOneWidget);
    expect(find.text('Điều hành 9'), findsOneWidget);

    // Khung 1024
    final constrainedBoxes = tester.widgetList<ConstrainedBox>(find.byType(ConstrainedBox));
    final box1024 = constrainedBoxes.any((box) => box.constraints.maxWidth == 1024);
    expect(box1024, isTrue);
  });

  testWidgets('RecentPostsScreen bảo toàn 25 chủ đề và 3 mục Khám phá thêm', (tester) async {
    tester.view.physicalSize = const Size(1280, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(
        home: RecentPostsScreen(),
      ),
    );
    await tester.pumpAndSettle();

    // Tiêu đề và link quay lại
    expect(find.text('Bài gần đây'), findsWidgets);
    expect(find.text('Quay về tìm kiếm nâng cao'), findsNWidgets(2));
    expect(find.text('Có 114 bài này, nằm với 12 trang'), findsNWidgets(2));

    // Chủ đề tiêu biểu từ Hình 5
    expect(find.text('Lá số phật thích ca mâu ni'), findsOneWidget);
    expect(find.text('MỆNH VCD CHỈ CÓ 1 CÂU MUỐN HỎI ĐÁP'), findsOneWidget);
    expect(find.text('Bát cháo hành'), findsOneWidget);
    expect(find.text('Hòa Thượng Thích Minh Châu'), findsOneWidget);

    // 3 mục Khám phá thêm
    expect(find.text('Khám phá thêm'), findsOneWidget);
    expect(find.text('Nâng Cấp Gói'), findsOneWidget);
    expect(find.text('Thuật Thư kim'), findsOneWidget);
    expect(find.text('Thẻ Công Cụ'), findsOneWidget);

    // Khung 1024
    final constrainedBoxes = tester.widgetList<ConstrainedBox>(find.byType(ConstrainedBox));
    final box1024 = constrainedBoxes.any((box) => box.constraints.maxWidth == 1024);
    expect(box1024, isTrue);
  });

  testWidgets('BreadcrumbWidget hiển thị PopupMenuButton Liên kết và Bài gần đây', (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final testRouter = GoRouter(
      initialLocation: '/forum',
      routes: [
        GoRoute(
          path: '/forum',
          builder: (context, state) => const Scaffold(
            body: Column(
              children: [
                BreadcrumbWidget(),
                Text('Nội dung diễn đàn'),
              ],
            ),
          ),
        ),
        GoRoute(
          path: '/forum/members',
          builder: (context, state) => const Scaffold(body: Text('Trang Thành viên')),
        ),
        GoRoute(
          path: '/forum/team',
          builder: (context, state) => const Scaffold(body: Text('Trang Chúng tôi')),
        ),
        GoRoute(
          path: '/forum/recent-posts',
          builder: (context, state) => const Scaffold(body: Text('Trang Bài gần đây')),
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: testRouter,
      ),
    );
    await tester.pumpAndSettle();

    // Tìm thấy nút "Liên kết" và "Bài gần đây"
    expect(find.text('Liên kết'), findsOneWidget);
    expect(find.text('Bài gần đây'), findsOneWidget);

    // Bấm vào nút "Liên kết"
    await tester.tap(find.text('Liên kết'));
    await tester.pumpAndSettle();

    // Menu Popup xuất hiện với 2 tùy chọn
    expect(find.text('Thành viên'), findsOneWidget);
    expect(find.text('Chúng tôi'), findsOneWidget);

    // Bấm chọn "Thành viên"
    await tester.tap(find.text('Thành viên'));
    await tester.pumpAndSettle();
    expect(find.text('Trang Thành viên'), findsOneWidget);
  });
}
