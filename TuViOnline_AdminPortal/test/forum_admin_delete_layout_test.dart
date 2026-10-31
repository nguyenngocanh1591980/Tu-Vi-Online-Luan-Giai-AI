import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/providers/forum_category_provider.dart';
import 'package:frontend/screens/forum/admin_delete_categories_screen.dart';
import 'package:frontend/widgets/breadcrumb_widget.dart';
import 'package:frontend/widgets/main_layout.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({'jwt_token': 'fake_admin_token'});
  });

  group('Kiểm thử Màn hình Xóa Chuyên mục (AdminDeleteCategoriesScreen) - Boxed Layout & UI Hợp nhất', () {
    testWidgets('Xác nhận Boxed Layout 1024px, Container nền #1E2640 nguyên khối bo góc 8px, Top Bar chuẩn và Footer chuẩn',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 1024);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final categoryProvider = ForumCategoryProvider();

      final testRouter = GoRouter(
        initialLocation: '/forum/delete-categories',
        routes: [
          ShellRoute(
            builder: (context, state, shellChild) => MainLayout(child: shellChild),
            routes: [
              GoRoute(
                path: '/forum/delete-categories',
                builder: (context, state) => const AdminDeleteCategoriesScreen(),
              ),
            ],
          ),
        ],
      );

      await tester.pumpWidget(
        ChangeNotifierProvider<ForumCategoryProvider>.value(
          value: categoryProvider,
          child: MaterialApp.router(
            routerConfig: testRouter,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Scaffold ngoài cùng nền xám sáng #F0F2F5
      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).first);
      expect(scaffold.backgroundColor, equals(const Color(0xFFF0F2F5)));

      // 2. ConstrainedBox maxWidth 1024
      final cbFinder = find.byWidgetPredicate(
        (w) => w is ConstrainedBox && w.constraints.maxWidth == 1024,
      );
      expect(cbFinder, findsWidgets);

      // 3. Khối AdminDeleteCategoriesScreen bọc trong Container nền #1E2640 bo góc 8px
      final containerFinder = find.descendant(
        of: find.byType(AdminDeleteCategoriesScreen),
        matching: find.byWidgetPredicate(
          (w) => w is Container && (w.decoration is BoxDecoration &&
                 (w.decoration as BoxDecoration).color == const Color(0xFF1E2640) &&
                 (w.decoration as BoxDecoration).borderRadius == BorderRadius.circular(8)),
        ),
      );
      expect(containerFinder, findsOneWidget);

      // 4. Thanh Breadcrumb ở đỉnh trang (BreadcrumbWidget) hiển thị chuẩn
      final bcFinder = find.byType(BreadcrumbWidget);
      expect(find.descendant(of: bcFinder, matching: find.text('Trang chủ')), findsOneWidget);
      expect(find.descendant(of: bcFinder, matching: find.text('Diễn đàn')), findsOneWidget);
      expect(find.descendant(of: bcFinder, matching: find.text('Xóa các Chuyên mục và Lớp học Lý số (Admin)')), findsOneWidget);

      // 5. Thanh Top Bar chuẩn nhận diện motif Hình 4 (Nền #131A30, viền #2A3450, icon vàng, text vàng, nút "< Về Diễn đàn")
      expect(find.text('Xóa các Chuyên mục và Lớp học Lý số (Admin)'), findsNWidgets(3)); // 1 ở Top Breadcrumb, 1 ở Top Bar, 1 ở Footer Breadcrumb
      expect(find.text('Về Diễn đàn'), findsOneWidget);
      expect(find.byIcon(Icons.remove_circle_outline), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back_ios), findsOneWidget);

      // 6. Footer phpBB ở chân trang liền mạch
      expect(find.text('Powered by phpBB® Forum Software © phpBB Limited'), findsOneWidget);
      expect(find.text('Chính sách bảo mật'), findsOneWidget);
      expect(find.text('Điều khoản tham gia'), findsOneWidget);
    });
  });
}
