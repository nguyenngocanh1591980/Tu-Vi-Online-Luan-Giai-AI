import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/screens/login_screen.dart';
import 'package:frontend/widgets/main_layout.dart';
import 'package:frontend/utils/boxed_snack_bar.dart';
import 'package:frontend/theme/app_theme.dart';

void main() {
  setUpAll(() {
    SharedPreferences.setMockInitialValues({});
  });

  setUp(() {
    globalSnackBarNotifier.value = null;
  });

  tearDown(() {
    globalSnackBarNotifier.value = null;
  });

  testWidgets(
      'Mô phỏng đăng nhập sai 3 lần và xác nhận SnackBar hiện đúng với kiến trúc mới',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final router = GoRouter(
      initialLocation: '/login',
      routes: [
        ShellRoute(
          builder: (context, state, child) => MainLayout(child: child),
          routes: [
            GoRoute(
              path: '/login',
              builder: (context, state) => const LoginScreen(initialIsLogin: true),
            ),
            GoRoute(
              path: '/',
              builder: (context, state) =>
                  const Material(color: Colors.transparent, child: Center(child: Text('Màn hình chính diễn đàn'))),
            ),
          ],
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: router,
        theme: AppTheme.lightTheme,
      ),
    );
    await tester.pumpAndSettle();

    final textFields = find.byType(TextField);
    expect(textFields, findsNWidgets(2));

    await tester.enterText(textFields.at(0), 'ngocanh?');
    await tester.enterText(textFields.at(1), 'wrongpass');
    await tester.pump();

    final submitBtn = find.widgetWithText(ElevatedButton, 'Đăng Nhập');
    expect(submitBtn, findsOneWidget);

    /// Xác nhận GlobalDockedSnackBar hiển thị với kiến trúc mới neo đáy 1024px
    void verifySnackBarAppears(String expectedTextContains) {
      expect(find.byType(GlobalDockedSnackBar), findsOneWidget,
          reason: 'GlobalDockedSnackBar phải xuất hiện sau khi đăng nhập sai');

      // Nội dung thông báo phải xuất hiện
      expect(find.textContaining(expectedTextContains), findsOneWidget,
          reason: 'Nội dung thông báo "$expectedTextContains" phải hiển thị');
    }

    // --- LẦN 1: Nhập sai ---
    await tester.tap(submitBtn);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    verifySnackBarAppears('Lần 1/3');

    // --- LẦN 2: Nhập sai tiếp ---
    await tester.tap(submitBtn);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    verifySnackBarAppears('Lần 2/3');

    // --- LẦN 3: Nhập sai lần 3 → Thông báo chuyển hướng ---
    await tester.tap(submitBtn);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Thông báo khi sai 3 lần (chuyển hướng về trang chủ)
    expect(
      find.textContaining('Đang chuyển hướng về trang chủ'),
      findsOneWidget,
      reason: 'Phải hiển thị thông báo chuyển hướng sau 3 lần sai',
    );

    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Màn hình chính diễn đàn'), findsOneWidget);
  });
}
