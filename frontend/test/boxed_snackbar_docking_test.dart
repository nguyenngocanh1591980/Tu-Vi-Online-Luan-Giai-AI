import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/theme/app_theme.dart';
import 'package:frontend/utils/boxed_snack_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─── Helper: Widget test con đơn giản để gọi showBoxedSnackBar ───────────────

class _TestChildScreen extends StatelessWidget {
  final String message;
  final Color backgroundColor;
  final VoidCallback? onPressed;

  const _TestChildScreen({
    required this.message,
    this.backgroundColor = const Color(0xFF323232),
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: ElevatedButton(
          onPressed: onPressed ??
              () => showBoxedSnackBar(
                    context,
                    message,
                    backgroundColor: backgroundColor,
                  ),
          child: const Text('Hiện thông báo'),
        ),
      ),
    );
  }
}

/// App bọc Stack bao ngoài Scaffold nội bộ trong ConstrainedBox(1024px) —
/// mô phỏng đúng 100% kiến trúc MainLayout chuẩn.
Widget _buildBoxedApp({
  String message = 'Thông báo kiểm thử',
  Color snackBg = const Color(0xFF323232),
  VoidCallback? onPressed,
}) {
  return MaterialApp(
    theme: AppTheme.lightTheme,
    home: Scaffold(
      backgroundColor: const Color(0xFFF0F2F5), // nền xám ngoài
      body: Padding(
        padding: const EdgeInsets.only(bottom: 24.0), // Bức tường chặn đáy
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
                    backgroundColor: const Color(0xFF1E2640), // nền tím trong
                    body: _TestChildScreen(
                      message: message,
                      backgroundColor: snackBg,
                      onPressed: onPressed,
                    ),
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
  setUpAll(() {
    SharedPreferences.setMockInitialValues({});
  });

  setUp(() {
    globalSnackBarNotifier.value = null;
  });

  tearDown(() {
    globalSnackBarNotifier.value = null;
  });

  group('Kiểm thử Neo SnackBar Bên Trong Khối Boxed Layout 1024px', () {
    // ─── Test 1: SnackBar hiển thị đúng ────────────────────────────────────
    testWidgets(
      'SnackBar phải hiển thị đúng khi gọi showBoxedSnackBar()',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1280, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(_buildBoxedApp(message: 'Tin nhắn kiểm thử A'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Hiện thông báo'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.text('Tin nhắn kiểm thử A'), findsOneWidget);
        expect(find.byType(GlobalDockedSnackBar), findsOneWidget);
      },
    );

    // ─── Test 2: Neo sát đáy Scaffold nội bộ trong Stack 1024px ─────────────
    testWidgets(
      'GlobalDockedSnackBar neo sát đáy Scaffold nội bộ 1024px bằng Align(bottomCenter)',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1280, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(_buildBoxedApp());
        await tester.pumpAndSettle();

        await tester.tap(find.text('Hiện thông báo'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        final snackBarFinder = find.byType(GlobalDockedSnackBar);
        expect(snackBarFinder, findsOneWidget);

        // Xác nhận GlobalDockedSnackBar nằm trong Align bottomCenter
        final alignFinder = find.ancestor(
          of: snackBarFinder,
          matching: find.byWidgetPredicate(
            (widget) =>
                widget is Align && widget.alignment == Alignment.bottomCenter,
          ),
        );
        expect(alignFinder, findsWidgets,
            reason: 'GlobalDockedSnackBar phải nằm trong Align(alignment: Alignment.bottomCenter)');
      },
    );

    // ─── Test 3: Kiến trúc Boxed: Stack và ConstrainedBox(1024) cùng tồn tại ──────
    testWidgets(
      'Kiến trúc Boxed: Stack bao ngoài Scaffold nội bộ và ConstrainedBox(1024) cùng tồn tại',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1280, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(_buildBoxedApp());
        await tester.pumpAndSettle();

        // Xác nhận GlobalDockedSnackBar tồn tại trong cây widget
        expect(
          find.byType(GlobalDockedSnackBar),
          findsOneWidget,
          reason: 'Phải có GlobalDockedSnackBar trong cây widget',
        );

        // Xác nhận ConstrainedBox(1024px) tồn tại
        final constrainedBoxFinder = find.byWidgetPredicate(
          (widget) =>
              widget is ConstrainedBox &&
              widget.constraints.maxWidth == 1024.0,
        );
        expect(
          constrainedBoxFinder,
          findsWidgets,
          reason: 'Phải có ConstrainedBox(maxWidth: 1024) làm khung neo',
        );
      },
    );

    // ─── Test 4: Tọa độ Y đáy SnackBar nằm trong viewport ──────────────────
    testWidgets(
      'Tọa độ Y đáy SnackBar phải nằm TRONG giới hạn viewport 1024px (không trôi)',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1280, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(_buildBoxedApp(message: 'Kiểm tra tọa độ Y'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Hiện thông báo'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.text('Kiểm tra tọa độ Y'), findsOneWidget);

        final snackBarFinder = find.byType(GlobalDockedSnackBar);
        expect(snackBarFinder, findsOneWidget);

        final Rect snackBarRect = tester.getRect(snackBarFinder);
        final double screenHeight =
            tester.view.physicalSize.height / tester.view.devicePixelRatio;

        // Đáy SnackBar phải ≤ chiều cao màn hình
        expect(
          snackBarRect.bottom,
          lessThanOrEqualTo(screenHeight),
          reason: 'Đáy SnackBar (${snackBarRect.bottom}px) '
              'không được vượt quá chiều cao màn hình (${screenHeight}px)',
        );

        // SnackBar phải có chiều cao > 0
        expect(
          snackBarRect.height,
          greaterThan(0),
          reason: 'SnackBar phải có chiều cao dương (đang hiển thị)',
        );
      },
    );

    // ─── Test 5: SnackBar màu tùy chỉnh (showLoginRequiredSnackBar) ──────────
    testWidgets(
      'showLoginRequiredSnackBar() hiển thị nền đỏ Chu Sa #C62828 và viền vàng Kim',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1280, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        const testMsg = 'Đăng Ký hoặc Đăng Nhập ngay!';

        await tester.pumpWidget(
          _buildBoxedApp(
            onPressed: () => showLoginRequiredSnackBar(tester.element(find.byType(ElevatedButton)), testMsg),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Hiện thông báo'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.text(testMsg), findsOneWidget);

        final containerFinder = find.descendant(
          of: find.byType(GlobalDockedSnackBar),
          matching: find.byWidgetPredicate(
            (widget) =>
                widget is Container &&
                widget.decoration is BoxDecoration &&
                (widget.decoration as BoxDecoration).color == const Color(0xFFC62828),
          ),
        );
        expect(containerFinder, findsOneWidget,
            reason: 'SnackBar đăng nhập phải có nền đỏ Chu Sa #C62828');
      },
    );

    // ─── Test 6: Responsive mobile (360px) ─────────────────────────────────
    testWidgets(
      'Trên mobile (360px), SnackBar hiển thị đầy đủ không bị overflow',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(360, 640);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(_buildBoxedApp(message: 'Thông báo mobile'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Hiện thông báo'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.text('Thông báo mobile'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    // ─── Test 7: showErrorSnackBar ───────────────────────────────────────────
    testWidgets(
      'showErrorSnackBar() hiển thị nền đen mặc định (#323232)',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1280, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(
          _buildBoxedApp(
            onPressed: () => showErrorSnackBar(tester.element(find.byType(ElevatedButton)), 'Sai tên đăng nhập hoặc mật khẩu'),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Hiện thông báo'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.text('Sai tên đăng nhập hoặc mật khẩu'), findsOneWidget);

        final containerFinder = find.descendant(
          of: find.byType(GlobalDockedSnackBar),
          matching: find.byWidgetPredicate(
            (widget) =>
                widget is Container &&
                widget.decoration is BoxDecoration &&
                (widget.decoration as BoxDecoration).color == const Color(0xFF323232),
          ),
        );
        expect(containerFinder, findsOneWidget,
            reason: 'showErrorSnackBar phải có nền đen #323232');
      },
    );

    // ─── Test 8: showSuccessSnackBar ─────────────────────────────────────────
    testWidgets(
      'showSuccessSnackBar() hiển thị nền xanh lá (#2E7D32)',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1280, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(
          _buildBoxedApp(
            onPressed: () => showSuccessSnackBar(tester.element(find.byType(ElevatedButton)), 'Lưu thành công!'),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Hiện thông báo'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.text('Lưu thành công!'), findsOneWidget);

        final containerFinder = find.descendant(
          of: find.byType(GlobalDockedSnackBar),
          matching: find.byWidgetPredicate(
            (widget) =>
                widget is Container &&
                widget.decoration is BoxDecoration &&
                (widget.decoration as BoxDecoration).color == const Color(0xFF2E7D32),
          ),
        );
        expect(containerFinder, findsOneWidget,
            reason: 'showSuccessSnackBar phải có nền xanh lá #2E7D32');
      },
    );

    // ─── Test 9: Nút đóng ẩn thông báo ───────────────────────────────────────
    testWidgets(
      'Bấm nút đóng (Icons.close) ẩn thanh thông báo',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1280, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(_buildBoxedApp(message: 'Thông báo đóng được'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Hiện thông báo'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.text('Thông báo đóng được'), findsOneWidget);
        expect(find.byIcon(Icons.close), findsOneWidget);

        await tester.tap(find.byIcon(Icons.close));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));

        expect(find.text('Thông báo đóng được'), findsNothing);
      },
    );
  });
}
