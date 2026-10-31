import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/theme/app_theme.dart';
import 'package:frontend/utils/boxed_snack_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _buildTestApp(Widget child) {
  return MaterialApp(
    theme: AppTheme.lightTheme,
    home: Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      body: Padding(
        padding: const EdgeInsets.only(bottom: 24.0),
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1024),
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(8),
              ),
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  Scaffold(
                    backgroundColor: const Color(0xFF1E2640),
                    body: child,
                  ),
                  const Align(
                    alignment: Alignment.bottomCenter,
                    child: GlobalDockedSnackBar(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    SharedPreferences.setMockInitialValues({});
  });

  setUp(() {
    globalSnackBarNotifier.value = null;
  });

  tearDown(() {
    globalSnackBarNotifier.value = null;
  });

  group('Kiểm thử SnackBar Global Theme & Kiến Trúc Mỏ Neo Mới', () {
    // ─── Test 1: Xác nhận thông số AppTheme.snackBarTheme ───────────────────
    test('Xác nhận thông số cấu hình SnackBarThemeData (behavior: fixed)', () {
      final theme = AppTheme.snackBarTheme;
      expect(theme.behavior, equals(SnackBarBehavior.fixed),
          reason: 'Kiến trúc mới dùng fixed để neo sát đáy Scaffold cục bộ 1024px');
      expect(theme.backgroundColor, equals(const Color(0xFF323232)));
      expect(theme.shape, isA<RoundedRectangleBorder>());
      final shape = theme.shape as RoundedRectangleBorder;
      // Bo góc chỉ ở phía đáy
      expect(
        shape.borderRadius,
        equals(const BorderRadius.only(
          bottomLeft: Radius.circular(8),
          bottomRight: Radius.circular(8),
        )),
      );
    });

    // ─── Test 2: showBoxedSnackBar() trên Desktop — hiển thị & behavior ─────
    testWidgets(
      'Xác nhận SnackBar trên Desktop (1280px): neo đáy trong MainLayout, nội dung đúng',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1280, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(
          _buildTestApp(
            Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showBoxedSnackBar(
                    context,
                    'Đang tạo chế độ xem trước...',
                  );
                },
                child: const Text('Hiện thông báo'),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Hiện thông báo'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // Nội dung đúng
        expect(find.text('Đang tạo chế độ xem trước...'), findsOneWidget);
        expect(find.byType(GlobalDockedSnackBar), findsOneWidget);
      },
    );

    // ─── Test 3: Mobile (360px) — không overflow ─────────────────────────────
    testWidgets(
      'Xác nhận SnackBar trên Mobile (360px): hiển thị đúng, không overflow',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(360, 640);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(
          _buildTestApp(
            Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showBoxedSnackBar(
                    context,
                    'Tài khoản không đủ Coin. Vui lòng nạp thêm!',
                  );
                },
                child: const Text('Hiện thông báo'),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Hiện thông báo'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(
            find.text('Tài khoản không đủ Coin. Vui lòng nạp thêm!'),
            findsOneWidget);
        // Không có lỗi overflow
        expect(tester.takeException(), isNull);
      },
    );

    // ─── Test 4: AppTheme.lightTheme chứa snackBarTheme đúng ────────────────
    test('AppTheme.lightTheme phải nhúng snackBarTheme chuẩn', () {
      final theme = AppTheme.lightTheme;
      expect(theme.snackBarTheme.behavior, equals(SnackBarBehavior.fixed));
      expect(theme.snackBarTheme.backgroundColor,
          equals(const Color(0xFF323232)));
    });

    // ─── Test 5: responsiveSnackBarBuilder tương thích ngược ─────────────────
    testWidgets(
      'responsiveSnackBarBuilder vẫn hoạt động cho tương thích ngược',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1280, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            builder: AppTheme.responsiveSnackBarBuilder,
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Đang tạo chế độ xem trước...'),
                      ),
                    );
                  },
                  child: const Text('Hiện thông báo'),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Hiện thông báo'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.text('Đang tạo chế độ xem trước...'), findsOneWidget);
        expect(find.byType(SnackBar), findsOneWidget);
      },
    );
  });
}
