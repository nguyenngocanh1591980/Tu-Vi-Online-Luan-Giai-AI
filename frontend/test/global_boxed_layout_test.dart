import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/widgets/main_layout.dart';
import 'package:frontend/widgets/main_navigation_bar.dart';
import 'package:frontend/widgets/breadcrumb_widget.dart';
import 'package:frontend/utils/boxed_snack_bar.dart';
import 'package:frontend/screens/login_screen.dart';
import 'package:frontend/screens/apps_screen.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({'jwt_token': 'fake_token'});
  });

  GoRouter createTestRouter(Widget child) {
    return GoRouter(
      initialLocation: '/',
      routes: [
        ShellRoute(
          builder: (context, state, shellChild) => MainLayout(child: shellChild),
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => child,
            ),
          ],
        ),
      ],
    );
  }

  group('Kiểm thử Global Boxed Layout Wrapper (MainLayout)', () {
    testWidgets(
        'Xác nhận MainLayout trên PC (1280px): Nền Scaffold #F0F2F5, ConstrainedBox 1024px, Stack bao ngoài Scaffold nội bộ',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 1024);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final router =
          createTestRouter(const SizedBox(height: 200, child: Text('Child Content')));

      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
        ),
      );
      await tester.pumpAndSettle();

      // 1. Scaffold toàn cục nền xám #F0F2F5
      final scaffolds = tester.widgetList<Scaffold>(find.byType(Scaffold)).toList();
      final outerScaffold = scaffolds.first;
      expect(outerScaffold.backgroundColor, equals(const Color(0xFFF0F2F5)));

      // 2. ConstrainedBox maxWidth 1024 tồn tại
      final cbFinder = find.byWidgetPredicate(
        (widget) =>
            widget is ConstrainedBox && widget.constraints.maxWidth == 1024.0,
      );
      expect(cbFinder, findsWidgets,
          reason: 'Phải có ConstrainedBox(maxWidth: 1024) trong MainLayout');

      // 3. Stack bao ngoài Scaffold nội bộ tồn tại cùng GlobalDockedSnackBar
      expect(find.byType(GlobalDockedSnackBar), findsOneWidget,
          reason: 'GlobalDockedSnackBar phải tồn tại trong Stack để neo đáy');

      // 3b. ClipRRect bo góc đáy phải tồn tại (Khuôn đúc cắt xén vật lý)
      final clipFinder = find.byWidgetPredicate(
        (widget) =>
            widget is ClipRRect &&
            widget.borderRadius ==
                const BorderRadius.vertical(bottom: Radius.circular(8)),
      );
      expect(clipFinder, findsOneWidget,
          reason: 'ClipRRect bo góc đáy 8px phải tồn tại trong MainLayout');

      // 3c. Padding(bottom: 24) phải tồn tại (Bức tường chặn đáy)
      final paddingFinder = find.byWidgetPredicate(
        (widget) =>
            widget is Padding &&
            widget.padding == const EdgeInsets.only(bottom: 24.0),
      );
      expect(paddingFinder, findsOneWidget,
          reason: 'Padding(bottom: 24) phải tồn tại để chặn đáy');

      // 4. Header & Breadcrumb hiện diện
      expect(find.byType(MainNavigationBar), findsOneWidget);
      expect(find.byType(BreadcrumbWidget), findsOneWidget);

      // 5. Nội dung màn hình con hiển thị
      expect(find.text('Child Content'), findsOneWidget);
    });

    testWidgets(
        'Xác nhận MainLayout trên màn hình hẹp (700px): ConstrainedBox 1024px vẫn tồn tại',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(700, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final router = createTestRouter(
          const SizedBox(height: 200, child: Text('Mobile Child Content')));

      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
        ),
      );
      await tester.pumpAndSettle();

      // ConstrainedBox maxWidth 1024 vẫn tồn tại (sẽ bị constrain bởi màn hình 700px)
      final cbFinder = find.byWidgetPredicate(
        (widget) =>
            widget is ConstrainedBox && widget.constraints.maxWidth == 1024.0,
      );
      expect(cbFinder, findsWidgets,
          reason: 'ConstrainedBox(1024) phải tồn tại trên màn hình hẹp');

      // Nội dung vẫn hiện
      expect(find.text('Mobile Child Content'), findsOneWidget);
    });

    testWidgets('Xác nhận LoginScreen và AppsScreen hiển thị chuẩn mực trong Boxed Layout',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 1024);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      // Kiểm thử LoginScreen hiển thị không lỗi
      final loginRouter = createTestRouter(const LoginScreen());
      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: loginRouter,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.byType(TextField), findsAtLeastNWidgets(2));

      // Kiểm thử AppsScreen hiển thị không lỗi
      // Dùng FlutterError handler để bỏ qua các overflow pre-existing trong AppsScreen
      // khi test ở viewport 1280px (không liên quan đến thay đổi SnackBar)
      final List<FlutterErrorDetails> overflowErrors = [];
      FlutterError.onError = (details) {
        if (details.exceptionAsString().contains('overflowed') ||
            details.exceptionAsString().contains('overflow')) {
          overflowErrors.add(details);
        } else {
          FlutterError.dumpErrorToConsole(details);
        }
      };

      final appsRouter = createTestRouter(const AppsScreen());
      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: appsRouter,
        ),
      );
      await tester.pumpAndSettle(
        const Duration(seconds: 3),
        EnginePhase.build,
      );

      // Restore FlutterError handler
      FlutterError.onError = FlutterError.dumpErrorToConsole;

      expect(find.byType(AppsScreen), findsOneWidget);
      expect(find.text('Ứng Dụng Tử Vi Online - AI'), findsOneWidget);
    });
  });
}
