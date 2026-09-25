import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/screens/login_screen.dart';

void main() {
  setUpAll(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Mô phỏng đăng nhập sai 3 lần và xác nhận chuẩn Boxed SnackBar 1024px', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final router = GoRouter(
      initialLocation: '/login',
      routes: [
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(initialIsLogin: true),
        ),
        GoRoute(
          path: '/',
          builder: (context, state) => const Scaffold(body: Text('Màn hình chính diễn đàn')),
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    final textFields = find.byType(TextField);
    expect(textFields, findsNWidgets(2));

    await tester.enterText(textFields.at(0), 'ngocanh?');
    await tester.enterText(textFields.at(1), 'wrongpass');
    await tester.pump();

    final submitBtn = find.widgetWithText(ElevatedButton, 'Đăng Nhập');
    expect(submitBtn, findsOneWidget);

    void verifyBoxedSnackBarProperties() {
      final snackBarFinder = find.byType(SnackBar);
      expect(snackBarFinder, findsOneWidget);

      final SnackBar snackBar = tester.widget(snackBarFinder);
      expect(snackBar.behavior, equals(SnackBarBehavior.floating), reason: 'Phải là floating SnackBar');
      expect(snackBar.backgroundColor, equals(Colors.transparent), reason: 'Nền SnackBar phải trong suốt');
      expect(snackBar.elevation, equals(0), reason: 'Elevation SnackBar phải bằng 0');
      expect(snackBar.padding, equals(EdgeInsets.zero), reason: 'Padding SnackBar phải là zero');
      expect(snackBar.margin, equals(const EdgeInsets.only(bottom: 24)), reason: 'Margin đáy phải là 24');

      final centerFinder = find.descendant(of: snackBarFinder, matching: find.byType(Center));
      expect(centerFinder, findsWidgets, reason: 'Phải có Center bên trong SnackBar');

      final constrainedBoxFinder = find.descendant(of: centerFinder, matching: find.byType(ConstrainedBox));
      expect(constrainedBoxFinder, findsWidgets, reason: 'Phải có ConstrainedBox bên trong Center');

      final ConstrainedBox constrainedBox = tester.widget(constrainedBoxFinder.first);
      expect(constrainedBox.constraints.maxWidth, equals(1024), reason: 'ConstrainedBox phải có maxWidth: 1024');

      final containerFinder = find.descendant(of: constrainedBoxFinder, matching: find.byType(Container));
      expect(containerFinder, findsWidgets, reason: 'Phải có Container bên trong ConstrainedBox');

      final Container container = tester.widget(containerFinder.first);
      final decoration = container.decoration as BoxDecoration?;
      expect(decoration, isNotNull);
      expect(decoration!.color, equals(const Color(0xFF323232)), reason: 'Màu nền Container phải là #323232');
      expect(decoration.borderRadius, equals(BorderRadius.circular(8)), reason: 'Bo góc phải là 8');
      expect(container.padding, equals(const EdgeInsets.symmetric(vertical: 16, horizontal: 24)), reason: 'Padding nội bộ phải là 16v, 24h');
    }

    // --- LẦN 1: Nhập sai ---
    await tester.tap(submitBtn);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.textContaining('(Lần 1/3)'), findsOneWidget);
    verifyBoxedSnackBarProperties();

    // --- LẦN 2: Nhập sai tiếp ---
    await tester.tap(submitBtn);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.textContaining('(Lần 2/3)'), findsOneWidget);
    verifyBoxedSnackBarProperties();

    // --- LẦN 3: Nhập sai lần 3 -> Thông báo chuyển hướng về diễn đàn chính ---
    await tester.tap(submitBtn);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Đăng nhập sai 3 lần. Đang chuyển hướng về diễn đàn chính.'), findsOneWidget);
    verifyBoxedSnackBarProperties();

    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Màn hình chính diễn đàn'), findsOneWidget);
  });
}
